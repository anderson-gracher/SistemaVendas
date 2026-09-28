using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using ERPFinanceiro.Configuracao;
using ERPFinanceiro.Dominio;
using ERPFinanceiro.Servicos;
using FastReport;
using FastReport.Export.Pdf;
using FastReport.Format;
using FastReport.Utils;

namespace ERPFinanceiro.Relatorios
{
    /// <summary>Linha do relatório (objeto de negócio registrado no FastReport como "Titulos").</summary>
    public class ItemRelatorioFinanceiro
    {
        public int IdVenda { get; set; }
        public string Cliente { get; set; }
        public string Documento { get; set; }
        public DateTime Emissao { get; set; }
        public DateTime Vencimento { get; set; }
        public decimal Valor { get; set; }
        public int Ordem { get; set; }
        public string Situacao { get; set; }
        public string Pagamento { get; set; }
        public decimal ValorPago { get; set; }
        public string Forma { get; set; }

        public static ItemRelatorioFinanceiro De(Titulo t)
        {
            return new ItemRelatorioFinanceiro
            {
                IdVenda = t.IdVenda,
                Cliente = t.ClienteNome,
                Documento = t.ClienteDocumentoFormatado,
                Emissao = t.DataEmissao,
                Vencimento = t.DataVencimento,
                Valor = t.Valor,
                Ordem = StatusTitulo.Ordem(t.Situacao),
                Situacao = t.SituacaoDescricao,
                Pagamento = t.DataPagamento.HasValue ? t.DataPagamento.Value.ToString("dd/MM/yyyy") : string.Empty,
                ValorPago = t.ValorPago ?? 0m,
                Forma = t.Status == StatusTitulo.Cancelado ? "Cancelado: " + t.MotivoCancelamento : t.FormaPagamento
            };
        }
    }

    /// <summary>
    /// Relatório financeiro das vendas (FastReport .NET), montado em código:
    ///   ReportTitle   - empresa, título, filtro aplicado
    ///   PageHeader    - cabeçalho das colunas (repete por página)
    ///   GroupHeader   - situação (Vencido, A vencer, Quitado, Cancelado)
    ///   Data          - títulos
    ///   GroupFooter   - subtotais da situação
    ///   ReportSummary - quadro-resumo (em aberto, vencido, recebido, cancelado)
    ///   PageFooter    - emissão e paginação
    /// </summary>
    public sealed class RelatorioFinanceiro
    {
        private const float LarguraUtil = 277f; // A4 paisagem com margens de 10 mm
        private int _sequencia;

        public void Visualizar(IList<Titulo> titulos, FiltroTitulos filtro)
        {
            using (var relatorio = Montar(titulos, filtro))
            {
                relatorio.Prepare();
                relatorio.ShowPrepared();
            }
        }

        public void ExportarPdf(IList<Titulo> titulos, FiltroTitulos filtro, string arquivo)
        {
            using (var relatorio = Montar(titulos, filtro))
            using (var pdf = new PDFExport())
            {
                relatorio.Prepare();
                relatorio.Export(pdf, arquivo);
            }
        }

        private Report Montar(IList<Titulo> titulos, FiltroTitulos filtro)
        {
            var itens = titulos.Select(ItemRelatorioFinanceiro.De)
                .OrderBy(i => i.Ordem).ThenBy(i => i.Vencimento).ThenBy(i => i.IdVenda)
                .ToList();
            var resumo = ResumoFinanceiro.Calcular(titulos);

            var relatorio = new Report();
            relatorio.ReportInfo.Name = "Relatório financeiro das vendas";
            relatorio.DoublePass = true; // necessário para [TotalPages#]
            relatorio.RegisterData(itens, "Titulos");
            var fonte = relatorio.GetDataSource("Titulos");
            fonte.Enabled = true;

            var pagina = new ReportPage { Name = "Pagina", Landscape = true };
            pagina.LeftMargin = pagina.RightMargin = pagina.TopMargin = pagina.BottomMargin = 10;
            relatorio.Pages.Add(pagina);

            // ---------- Título ----------
            pagina.ReportTitle = new ReportTitleBand { Name = "Titulo", Height = Mm(24) };
            Texto(pagina.ReportTitle, Config.EmpresaNome, 0, 0, 150, 8, 14, true);
            Texto(pagina.ReportTitle, "RELATÓRIO FINANCEIRO DAS VENDAS", 150, 0, LarguraUtil - 150, 8, 13, true,
                HorzAlign.Right);
            Texto(pagina.ReportTitle, (filtro ?? new FiltroTitulos()).Descricao(), 0, 10, LarguraUtil, 5, 9);
            Texto(pagina.ReportTitle, string.Format("{0} título(s) listado(s)", itens.Count), 0, 16, LarguraUtil, 5, 9);

            // ---------- Cabeçalho das colunas ----------
            pagina.PageHeader = new PageHeaderBand { Name = "Colunas", Height = Mm(7) };
            pagina.PageHeader.Fill = new SolidFill(Color.FromArgb(41, 74, 112));
            var branco = Color.White;
            Texto(pagina.PageHeader, "Venda", 1, 1, 16, 5, 9, true, cor: branco);
            Texto(pagina.PageHeader, "Cliente", 18, 1, 70, 5, 9, true, cor: branco);
            Texto(pagina.PageHeader, "CPF/CNPJ", 89, 1, 34, 5, 9, true, cor: branco);
            Texto(pagina.PageHeader, "Emissão", 124, 1, 21, 5, 9, true, cor: branco);
            Texto(pagina.PageHeader, "Vencimento", 146, 1, 21, 5, 9, true, cor: branco);
            Texto(pagina.PageHeader, "Valor", 168, 1, 26, 5, 9, true, HorzAlign.Right, cor: branco);
            Texto(pagina.PageHeader, "Pagamento", 197, 1, 21, 5, 9, true, cor: branco);
            Texto(pagina.PageHeader, "Valor pago", 219, 1, 26, 5, 9, true, HorzAlign.Right, cor: branco);
            Texto(pagina.PageHeader, "Forma / motivo", 248, 1, 29, 5, 9, true, cor: branco);

            // ---------- Grupo por situação ----------
            var grupo = new GroupHeaderBand
            {
                Name = "GrupoSituacao",
                Condition = "[Titulos.Ordem]",
                Height = Mm(8),
                KeepWithData = true
            };
            grupo.Fill = new SolidFill(Color.FromArgb(230, 236, 244));
            pagina.Bands.Add(grupo);
            Texto(grupo, "[Titulos.Situacao]", 1, 1.5f, 120, 5, 10, true, expressao: true);

            var dados = new DataBand { Name = "Dados", DataSource = fonte, Height = Mm(5.5f) };
            grupo.Data = dados;
            Texto(dados, "[Titulos.IdVenda]", 1, 0.25f, 16, 5, 9, expressao: true);
            Texto(dados, "[Titulos.Cliente]", 18, 0.25f, 70, 5, 9, expressao: true);
            Texto(dados, "[Titulos.Documento]", 89, 0.25f, 34, 5, 9, expressao: true);
            Texto(dados, "[Titulos.Emissao]", 124, 0.25f, 21, 5, 9, expressao: true, formato: Data());
            Texto(dados, "[Titulos.Vencimento]", 146, 0.25f, 21, 5, 9, expressao: true, formato: Data());
            Texto(dados, "[Titulos.Valor]", 168, 0.25f, 26, 5, 9, false, HorzAlign.Right, true, Numero());
            Texto(dados, "[Titulos.Pagamento]", 197, 0.25f, 21, 5, 9, expressao: true);
            Texto(dados, "[Titulos.ValorPago]", 219, 0.25f, 26, 5, 9, false, HorzAlign.Right, true, Numero())
                .HideZeros = true;
            Texto(dados, "[Titulos.Forma]", 248, 0.25f, 29, 5, 8, expressao: true);

            // Subtotais do grupo
            grupo.GroupFooter = new GroupFooterBand { Name = "RodapeGrupo", Height = Mm(9) };
            AdicionarTotal(relatorio, "QtdGrupo", null, dados, grupo.GroupFooter, true, TotalType.Count);
            AdicionarTotal(relatorio, "ValorGrupo", "[Titulos.Valor]", dados, grupo.GroupFooter, true);
            AdicionarTotal(relatorio, "PagoGrupo", "[Titulos.ValorPago]", dados, grupo.GroupFooter, true);
            Texto(grupo.GroupFooter, "Subtotal: [QtdGrupo] título(s)", 1, 1, 120, 5, 9, true, expressao: true);
            Texto(grupo.GroupFooter, "[ValorGrupo]", 168, 1, 26, 5, 9, true, HorzAlign.Right, true, Numero());
            Texto(grupo.GroupFooter, "[PagoGrupo]", 219, 1, 26, 5, 9, true, HorzAlign.Right, true, Numero());

            // ---------- Resumo final ----------
            pagina.ReportSummary = new ReportSummaryBand { Name = "Resumo", Height = Mm(42) };
            var r = pagina.ReportSummary;
            Texto(r, "RESUMO", 0, 3, 100, 6, 11, true);
            LinhaResumo(r, 10, "A vencer", resumo.QtdAVencer, resumo.ValorAVencer);
            LinhaResumo(r, 15, "Vencidos", resumo.QtdVencido, resumo.ValorVencido);
            LinhaResumo(r, 20, "Total em aberto", resumo.QtdEmAberto, resumo.ValorEmAberto, true);
            LinhaResumo(r, 26, "Quitados (valor recebido)", resumo.QtdQuitado, resumo.ValorRecebido);
            LinhaResumo(r, 31, "Cancelados", resumo.QtdCancelado, resumo.ValorCancelado);
            LinhaResumo(r, 37, "Total faturado (sem cancelados)", resumo.QtdEmAberto + resumo.QtdQuitado,
                resumo.ValorFaturado, true);

            // ---------- Rodapé ----------
            pagina.PageFooter = new PageFooterBand { Name = "Rodape", Height = Mm(7) };
            Texto(pagina.PageFooter, "Emitido pelo ERP Financeiro em " + DateTime.Now.ToString("dd/MM/yyyy HH:mm"),
                0, 1, 150, 5, 7);
            Texto(pagina.PageFooter, "Página [Page#] de [TotalPages#]", LarguraUtil - 60, 1, 60, 5, 7, false,
                HorzAlign.Right, true);

            return relatorio;
        }

        private void LinhaResumo(BandBase banda, float topo, string descricao, int quantidade, decimal valor,
            bool destaque = false)
        {
            Texto(banda, descricao, 0, topo, 80, 5, 9, destaque);
            Texto(banda, quantidade + " título(s)", 80, topo, 35, 5, 9, destaque, HorzAlign.Right);
            Texto(banda, valor.ToString("C2"), 115, topo, 40, 5, 9, destaque, HorzAlign.Right);
        }

        private static void AdicionarTotal(Report relatorio, string nome, string expressao, DataBand avaliador,
            BandBase imprimirEm, bool zerarAposImprimir, TotalType tipo = TotalType.Sum)
        {
            var total = new Total
            {
                Name = nome,
                TotalType = tipo,
                Evaluator = avaliador,
                PrintOn = imprimirEm,
                ResetAfterPrint = zerarAposImprimir
            };
            if (expressao != null)
                total.Expression = expressao;
            relatorio.Dictionary.Totals.Add(total);
        }

        /// <summary>Texto posicionado em milímetros. Sem expressão por padrão (texto literal).</summary>
        private TextObject Texto(BandBase banda, string texto, float esquerda, float topo, float largura, float altura,
            float tamanho = 9, bool negrito = false, HorzAlign alinhamento = HorzAlign.Left, bool expressao = false,
            FormatBase formato = null, Color? cor = null)
        {
            var objeto = new TextObject
            {
                Name = "Texto" + (++_sequencia),
                Bounds = new RectangleF(Mm(esquerda), Mm(topo), Mm(largura), Mm(altura)),
                Text = texto,
                Font = new Font("Arial", tamanho, negrito ? FontStyle.Bold : FontStyle.Regular),
                HorzAlign = alinhamento,
                VertAlign = VertAlign.Center,
                AllowExpressions = expressao,
                WordWrap = false,
                Trimming = StringTrimming.EllipsisCharacter
            };
            if (formato != null)
                objeto.Format = formato;
            if (cor.HasValue)
                objeto.TextColor = cor.Value;
            banda.Objects.Add(objeto);
            return objeto;
        }

        private static float Mm(float valor) => valor * Units.Millimeters;

        private static FormatBase Data() => new DateFormat { Format = "dd/MM/yyyy" };

        private static FormatBase Numero() => new NumberFormat { UseLocale = true, DecimalDigits = 2 };
    }
}
