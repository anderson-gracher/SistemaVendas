using System;
using ERPFinanceiro.Dominio;

namespace ERPFinanceiro.Servicos
{
    /// <summary>Corpo do POST /api/titulos enviado pelo ERP Vendas.</summary>
    public class TituloEntradaDto
    {
        public int IdVenda { get; set; }
        public string ClienteNome { get; set; }
        public string ClienteDocumento { get; set; }
        public string ClienteEmail { get; set; }
        public decimal Valor { get; set; }
        public DateTime DataEmissao { get; set; }
        public DateTime DataVencimento { get; set; }
    }

    public class QuitacaoDto
    {
        public DateTime? DataPagamento { get; set; }
        public decimal ValorPago { get; set; }
        public string FormaPagamento { get; set; }
    }

    public class CancelamentoDto
    {
        public string Motivo { get; set; }
    }

    /// <summary>Representação pública de um título (respostas da API).</summary>
    public class TituloDto
    {
        public int IdVenda { get; set; }
        public string ClienteNome { get; set; }
        public string ClienteDocumento { get; set; }
        public string ClienteEmail { get; set; }
        public decimal Valor { get; set; }
        public DateTime DataEmissao { get; set; }
        public DateTime DataVencimento { get; set; }
        public string Status { get; set; }
        public string Situacao { get; set; }
        public int DiasAtraso { get; set; }
        public DateTime? DataPagamento { get; set; }
        public decimal? ValorPago { get; set; }
        public string FormaPagamento { get; set; }
        public DateTime? DataCancelamento { get; set; }
        public string MotivoCancelamento { get; set; }

        public static TituloDto De(Titulo t)
        {
            return new TituloDto
            {
                IdVenda = t.IdVenda,
                ClienteNome = t.ClienteNome,
                ClienteDocumento = t.ClienteDocumento,
                ClienteEmail = t.ClienteEmail,
                Valor = t.Valor,
                DataEmissao = t.DataEmissao,
                DataVencimento = t.DataVencimento,
                Status = t.Status,
                Situacao = t.Situacao,
                DiasAtraso = t.DiasAtraso,
                DataPagamento = t.DataPagamento,
                ValorPago = t.ValorPago,
                FormaPagamento = t.FormaPagamento,
                DataCancelamento = t.DataCancelamento,
                MotivoCancelamento = t.MotivoCancelamento
            };
        }
    }

    /// <summary>Filtro da consulta de títulos (tela, relatório e API).</summary>
    public class FiltroTitulos
    {
        /// <summary>Valor especial de Situacao: todos os títulos em aberto (a vencer + vencidos).</summary>
        public const string EmAberto = "EM_ABERTO";

        public DateTime? EmissaoDe { get; set; }
        public DateTime? EmissaoAte { get; set; }
        /// <summary>EM_ABERTO, ABERTO (a vencer), VENCIDO, QUITADO, CANCELADO ou vazio (todos).</summary>
        public string Situacao { get; set; }
        /// <summary>Parte do nome ou do CPF/CNPJ do cliente.</summary>
        public string Cliente { get; set; }

        public string Descricao()
        {
            var partes = new System.Collections.Generic.List<string>();
            if (EmissaoDe.HasValue || EmissaoAte.HasValue)
                partes.Add(string.Format("Emissão: {0} a {1}",
                    EmissaoDe.HasValue ? EmissaoDe.Value.ToString("dd/MM/yyyy") : "início",
                    EmissaoAte.HasValue ? EmissaoAte.Value.ToString("dd/MM/yyyy") : "hoje"));
            partes.Add("Situação: " + (string.IsNullOrEmpty(Situacao) ? "todas"
                : Situacao == EmAberto ? "em aberto" : StatusTitulo.Descricao(Situacao)));
            if (!string.IsNullOrWhiteSpace(Cliente))
                partes.Add("Cliente: " + Cliente.Trim());
            return string.Join("   |   ", partes);
        }
    }

    /// <summary>Resultado do registro de um título (idempotente).</summary>
    public class ResultadoRegistro
    {
        public ResultadoRegistro(Titulo titulo, bool criado)
        {
            Titulo = titulo;
            Criado = criado;
        }

        public Titulo Titulo { get; }
        public bool Criado { get; }
    }
}
