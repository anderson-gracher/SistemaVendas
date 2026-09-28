using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.Common;
using System.Drawing;
using System.Windows.Forms;
using DevExpress.Data;
using DevExpress.Utils;
using DevExpress.XtraEditors;
using DevExpress.XtraGrid.Views.Grid;
using ERPFinanceiro.Dominio;
using ERPFinanceiro.Infra;
using ERPFinanceiro.Relatorios;
using ERPFinanceiro.Servicos;

namespace ERPFinanceiro.Telas
{
    /// <summary>
    /// Tela principal: consulta de títulos (informações financeiras), quitação,
    /// cancelamento, relatório financeiro e acompanhamento da integração.
    /// </summary>
    public partial class FrmPrincipal : XtraForm
    {
        private static readonly string[] CodigosSituacao =
            { "", FiltroTitulos.EmAberto, StatusTitulo.Aberto, StatusTitulo.Vencido, StatusTitulo.Quitado, StatusTitulo.Cancelado };

        private static readonly string[] TextosSituacao =
            { "Todas", "Em aberto", "A vencer", "Vencidos", "Quitados", "Cancelados" };

        private readonly TituloService _titulos = new TituloService();
        private readonly NotificacaoService _notificacoes = new NotificacaoService();
        private readonly string _apiUrl;
        private List<Titulo> _lista = new List<Titulo>();
        private FiltroTitulos _filtroAtual = new FiltroTitulos();

        /// <param name="apiUrl">URL da API ativa, ou null se ela não pôde ser iniciada.</param>
        public FrmPrincipal(string apiUrl)
        {
            InitializeComponent();
            _apiUrl = apiUrl;
            ConfigurarFiltros();
            ConfigurarGrade();
        }

        // ------------------------------------------------------------------
        // Inicialização
        // ------------------------------------------------------------------

        private void ConfigurarFiltros()
        {
            Ui.GarantirBotao(dtDe);
            Ui.GarantirBotao(dtAte);
            Ui.GarantirBotao(cbSituacao);
            cbSituacao.Properties.TextEditStyle = DevExpress.XtraEditors.Controls.TextEditStyles.DisableTextEditor;
            cbSituacao.Properties.Items.AddRange(TextosSituacao);
            cbSituacao.SelectedIndex = 1; // Em aberto

            var hoje = DateTime.Today;
            dtDe.DateTime = new DateTime(hoje.Year, hoje.Month, 1).AddMonths(-2);
            dtAte.DateTime = hoje;
        }

        private void ConfigurarGrade()
        {
            gvTitulos.OptionsBehavior.Editable = false;
            gvTitulos.OptionsView.ShowGroupPanel = false;
            gvTitulos.OptionsView.ShowFooter = true;
            gvTitulos.OptionsView.ShowIndicator = true;
            gvTitulos.OptionsSelection.EnableAppearanceFocusedCell = false;

            Ui.Coluna(gvTitulos, "IdVenda", "Venda", 60)
                .Summary.Add(SummaryItemType.Count, "IdVenda", "{0} título(s)");
            Ui.Coluna(gvTitulos, "ClienteNome", "Cliente", 220);
            Ui.Coluna(gvTitulos, "ClienteDocumentoFormatado", "CPF/CNPJ", 130);
            Ui.Coluna(gvTitulos, "DataEmissao", "Emissão", 110, FormatType.DateTime, "dd/MM/yyyy HH:mm");
            Ui.Coluna(gvTitulos, "DataVencimento", "Vencimento", 85, FormatType.DateTime, "dd/MM/yyyy");
            Ui.Coluna(gvTitulos, "Valor", "Valor", 100, FormatType.Numeric, "n2")
                .Summary.Add(SummaryItemType.Sum, "Valor", "{0:n2}");
            Ui.Coluna(gvTitulos, "SituacaoDescricao", "Situação", 85);
            Ui.Coluna(gvTitulos, "DiasAtraso", "Dias atraso", 70);
            Ui.Coluna(gvTitulos, "DataPagamento", "Pagamento", 85, FormatType.DateTime, "dd/MM/yyyy");
            Ui.Coluna(gvTitulos, "ValorPago", "Valor pago", 100, FormatType.Numeric, "n2")
                .Summary.Add(SummaryItemType.Sum, "ValorPago", "{0:n2}");
            Ui.Coluna(gvTitulos, "FormaPagamento", "Forma", 110);
            Ui.Coluna(gvTitulos, "MotivoCancelamento", "Motivo do cancelamento", 200);

            gvTitulos.RowStyle += GvTitulos_RowStyle;
            gvTitulos.CustomColumnDisplayText += GvTitulos_CustomColumnDisplayText;
            gvTitulos.FocusedRowChanged += (s, e) => AtualizarBotoes();
            gvTitulos.DoubleClick += (s, e) => { if (btnQuitar.Enabled) btnQuitar.PerformClick(); };
        }

        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            Text = "ERP Financeiro";
            Eventos.TituloAlterado += AoTituloAlterado;
            Eventos.FilaAlterada += AoFilaAlterada;
            Pesquisar();
            AtualizarStatus();
            timerStatus.Start();
        }

        protected override void OnFormClosed(FormClosedEventArgs e)
        {
            timerStatus.Stop();
            Eventos.TituloAlterado -= AoTituloAlterado;
            Eventos.FilaAlterada -= AoFilaAlterada;
            base.OnFormClosed(e);
        }

        // ------------------------------------------------------------------
        // Eventos vindos de outras threads (API / fila)
        // ------------------------------------------------------------------

        private void AoTituloAlterado(int idVenda) => NaThreadDaTela(() => Pesquisar(IdSelecionado));

        private void AoFilaAlterada() => NaThreadDaTela(AtualizarStatus);

        private void NaThreadDaTela(Action acao)
        {
            if (IsDisposed || !IsHandleCreated)
                return;
            BeginInvoke(new Action(() =>
            {
                if (!IsDisposed)
                    acao();
            }));
        }

        // ------------------------------------------------------------------
        // Consulta
        // ------------------------------------------------------------------

        private Titulo TituloSelecionado => gvTitulos.GetFocusedRow() as Titulo;

        private int? IdSelecionado => TituloSelecionado?.IdVenda;

        private FiltroTitulos MontarFiltro()
        {
            return new FiltroTitulos
            {
                EmissaoDe = dtDe.EditValue == null ? (DateTime?)null : dtDe.DateTime.Date,
                EmissaoAte = dtAte.EditValue == null ? (DateTime?)null : dtAte.DateTime.Date,
                Situacao = cbSituacao.SelectedIndex > 0 ? CodigosSituacao[cbSituacao.SelectedIndex] : null,
                Cliente = txtCliente.Text
            };
        }

        private void Pesquisar(int? localizarVenda = null)
        {
            _filtroAtual = MontarFiltro();
            if (_filtroAtual.EmissaoDe > _filtroAtual.EmissaoAte)
                throw new ValidacaoException("A data inicial não pode ser maior que a final.");

            Cursor = Cursors.WaitCursor;
            try
            {
                _lista = _titulos.Consultar(_filtroAtual);
                gridTitulos.DataSource = _lista;
                gvTitulos.RefreshData();
                if (localizarVenda.HasValue)
                {
                    var linha = gvTitulos.LocateByValue("IdVenda", localizarVenda.Value);
                    if (linha >= 0)
                        gvTitulos.FocusedRowHandle = linha;
                }
            }
            finally
            {
                Cursor = Cursors.Default;
            }
            AtualizarResumo();
            AtualizarBotoes();
        }

        private void AtualizarResumo()
        {
            var r = ResumoFinanceiro.Calcular(_lista);
            lblAVencer.Text = Card("A VENCER", r.QtdAVencer, r.ValorAVencer);
            lblVencido.Text = Card("VENCIDOS", r.QtdVencido, r.ValorVencido);
            lblRecebido.Text = Card("RECEBIDO", r.QtdQuitado, r.ValorRecebido);
            lblCancelado.Text = Card("CANCELADOS", r.QtdCancelado, r.ValorCancelado);
        }

        private static string Card(string titulo, int quantidade, decimal valor) =>
            string.Format("{0}{1}{2:C2}{1}{3} título(s)", titulo, Environment.NewLine, valor, quantidade);

        private void AtualizarBotoes()
        {
            var t = TituloSelecionado;
            btnQuitar.Enabled = t != null && t.PodeQuitar;
            btnCancelarTitulo.Enabled = t != null && t.PodeCancelar;
            btnRelatorio.Enabled = _lista.Count > 0;
        }

        private void AtualizarStatus()
        {
            lblStatusApi.Text = _apiUrl != null ? "API: " + _apiUrl : "API: PARADA (títulos do Vendas não serão recebidos)";
            lblStatusApi.ForeColor = _apiUrl != null ? SystemColors.ControlText : Color.Firebrick;
            try
            {
                var builder = new DbConnectionStringBuilder
                {
                    ConnectionString = ConfigurationManager.ConnectionStrings["FinanceiroDb"].ConnectionString
                };
                lblStatusBanco.Text = "Banco: " + builder["DataSource"] + ":" + builder["Database"];
                var pendentes = _notificacoes.ContarPorStatus(StatusNotificacao.Pendente);
                var erros = _notificacoes.ContarPorStatus(StatusNotificacao.Erro);
                lblStatusFila.Text = string.Format("Notificações ao Vendas: {0} pendente(s), {1} com erro", pendentes, erros);
                lblStatusFila.ForeColor = erros > 0 ? Color.Firebrick : SystemColors.ControlText;
            }
            catch (Exception ex)
            {
                lblStatusFila.Text = "Fila: indisponível (" + ex.GetBaseException().Message + ")";
            }
        }

        // ------------------------------------------------------------------
        // Aparência da grade
        // ------------------------------------------------------------------

        private void GvTitulos_RowStyle(object sender, RowStyleEventArgs e)
        {
            if (e.RowHandle < 0)
                return;
            var titulo = gvTitulos.GetRow(e.RowHandle) as Titulo;
            if (titulo == null)
                return;
            switch (titulo.Situacao)
            {
                case StatusTitulo.Vencido:
                    e.Appearance.ForeColor = Color.Firebrick;
                    break;
                case StatusTitulo.Quitado:
                    e.Appearance.ForeColor = Color.ForestGreen;
                    break;
                case StatusTitulo.Cancelado:
                    e.Appearance.ForeColor = Color.Gray;
                    break;
            }
        }

        private void GvTitulos_CustomColumnDisplayText(object sender,
            DevExpress.XtraGrid.Views.Base.CustomColumnDisplayTextEventArgs e)
        {
            if (e.Column.FieldName == "DiasAtraso" && e.Value is int && (int)e.Value == 0)
                e.DisplayText = string.Empty;
        }

        // ------------------------------------------------------------------
        // Ações
        // ------------------------------------------------------------------

        private void btnPesquisar_Click(object sender, EventArgs e) => Pesquisar(IdSelecionado);

        private void txtCliente_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Enter)
            {
                e.SuppressKeyPress = true;
                Pesquisar();
            }
        }

        private void btnQuitar_Click(object sender, EventArgs e)
        {
            var titulo = TituloSelecionado;
            if (titulo == null || !titulo.PodeQuitar)
                return;
            using (var tela = new FrmQuitacao(titulo))
            {
                if (tela.ShowDialog(this) != DialogResult.OK)
                    return;
                _titulos.Quitar(titulo.IdVenda, tela.DataPagamento, tela.ValorPago, tela.FormaPagamento);
            }
            Pesquisar(titulo.IdVenda);
            Ui.Informar(this, string.Format(
                "Título da venda {0} quitado.{1}O ERP Vendas será notificado e enviará a confirmação do pedido ao cliente.",
                titulo.IdVenda, Environment.NewLine));
        }

        private void btnCancelarTitulo_Click(object sender, EventArgs e)
        {
            var titulo = TituloSelecionado;
            if (titulo == null || !titulo.PodeCancelar)
                return;
            using (var tela = new FrmCancelamento(titulo))
            {
                if (tela.ShowDialog(this) != DialogResult.OK)
                    return;
                _titulos.Cancelar(titulo.IdVenda, tela.Motivo);
            }
            Pesquisar(titulo.IdVenda);
            Ui.Informar(this, string.Format(
                "Título da venda {0} cancelado.{1}O ERP Vendas será notificado e estornará o estoque.",
                titulo.IdVenda, Environment.NewLine));
        }

        private void btnRelatorio_Click(object sender, EventArgs e)
        {
            Cursor = Cursors.WaitCursor;
            try
            {
                new RelatorioFinanceiro().Visualizar(_lista, _filtroAtual);
            }
            finally
            {
                Cursor = Cursors.Default;
            }
        }

        private void btnFila_Click(object sender, EventArgs e)
        {
            using (var tela = new FrmFila())
                tela.ShowDialog(this);
            AtualizarStatus();
        }

        private void btnAtualizar_Click(object sender, EventArgs e)
        {
            Pesquisar(IdSelecionado);
            AtualizarStatus();
        }

        private void FrmPrincipal_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.F5)
            {
                e.Handled = true;
                btnAtualizar.PerformClick();
            }
        }

        private void timerStatus_Tick(object sender, EventArgs e)
        {
            AtualizarStatus();
            // Situação "vencido" muda com o tempo: redesenha sem reconsultar
            gvTitulos.LayoutChanged();
        }
    }
}
