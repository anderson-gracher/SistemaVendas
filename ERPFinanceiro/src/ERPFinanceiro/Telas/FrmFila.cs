using System;
using System.Drawing;
using DevExpress.Utils;
using DevExpress.XtraEditors;
using DevExpress.XtraGrid.Views.Grid;
using ERPFinanceiro.Dominio;
using ERPFinanceiro.Infra;
using ERPFinanceiro.Servicos;

namespace ERPFinanceiro.Telas
{
    /// <summary>Monitor da fila de notificações ao ERP Vendas (outbox).</summary>
    public partial class FrmFila : XtraForm
    {
        private readonly NotificacaoService _servico = new NotificacaoService();

        public FrmFila()
        {
            InitializeComponent();

            gvFila.OptionsBehavior.Editable = false;
            gvFila.OptionsView.ShowGroupPanel = false;
            gvFila.OptionsView.RowAutoHeight = true;
            Ui.Coluna(gvFila, "Id", "Nº", 50);
            Ui.Coluna(gvFila, "Tipo", "Tipo", 100);
            Ui.Coluna(gvFila, "IdVenda", "Venda", 60);
            Ui.Coluna(gvFila, "Status", "Status", 90);
            Ui.Coluna(gvFila, "Tentativas", "Tentativas", 70);
            Ui.Coluna(gvFila, "DataCriacao", "Criada em", 125, FormatType.DateTime, "dd/MM/yyyy HH:mm:ss");
            Ui.Coluna(gvFila, "ProximaTentativa", "Próxima tentativa", 125, FormatType.DateTime, "dd/MM/yyyy HH:mm:ss");
            Ui.Coluna(gvFila, "DataProcessamento", "Processada em", 125, FormatType.DateTime, "dd/MM/yyyy HH:mm:ss");
            Ui.Coluna(gvFila, "UltimoErro", "Último erro", 400);
            gvFila.RowStyle += GvFila_RowStyle;
        }

        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            Eventos.FilaAlterada += AoFilaAlterada;
            Atualizar();
        }

        protected override void OnFormClosed(System.Windows.Forms.FormClosedEventArgs e)
        {
            Eventos.FilaAlterada -= AoFilaAlterada;
            base.OnFormClosed(e);
        }

        private void AoFilaAlterada()
        {
            if (!IsDisposed && IsHandleCreated)
                BeginInvoke(new Action(() => { if (!IsDisposed) Atualizar(); }));
        }

        private void Atualizar()
        {
            var foco = gvFila.GetFocusedRow() as NotificacaoVendas;
            gridFila.DataSource = _servico.Listar();
            gvFila.RefreshData();
            if (foco != null)
            {
                var linha = gvFila.LocateByValue("Id", foco.Id);
                if (linha >= 0)
                    gvFila.FocusedRowHandle = linha;
            }
        }

        private void GvFila_RowStyle(object sender, RowStyleEventArgs e)
        {
            if (e.RowHandle < 0)
                return;
            var n = gvFila.GetRow(e.RowHandle) as NotificacaoVendas;
            if (n == null)
                return;
            if (n.Status == StatusNotificacao.Erro)
                e.Appearance.ForeColor = Color.Firebrick;
            else if (n.Status == StatusNotificacao.Pendente)
                e.Appearance.ForeColor = Color.DarkOrange;
        }

        private void btnAtualizar_Click(object sender, EventArgs e) => Atualizar();

        private void btnProcessarAgora_Click(object sender, EventArgs e)
        {
            Eventos.NotificarNotificacaoEnfileirada();
            Ui.Informar(this, "Processamento solicitado. A lista é atualizada ao final de cada envio.");
        }

        private void btnReprocessar_Click(object sender, EventArgs e)
        {
            var quantidade = _servico.ReprocessarErros();
            Atualizar();
            Ui.Informar(this, string.Format("{0} notificação(ões) com erro voltaram para a fila.", quantidade));
        }

        private void btnFechar_Click(object sender, EventArgs e) => Close();
    }
}
