using System;
using System.Windows.Forms;
using DevExpress.XtraEditors;
using ERPFinanceiro.Dominio;

namespace ERPFinanceiro.Telas
{
    /// <summary>Informa o motivo do cancelamento de um título em aberto.</summary>
    public partial class FrmCancelamento : XtraForm
    {
        public FrmCancelamento(Titulo titulo)
        {
            InitializeComponent();
            memoMotivo.Properties.MaxLength = 200;
            lblTitulo.Text = string.Format("Venda {0}  -  {1}{2}Valor: {3:C2}   |   Vencimento: {4:dd/MM/yyyy}",
                titulo.IdVenda, titulo.ClienteNome, Environment.NewLine, titulo.Valor, titulo.DataVencimento);
        }

        public string Motivo => (memoMotivo.Text ?? string.Empty).Trim();

        private void btnConfirmar_Click(object sender, EventArgs e)
        {
            if (Motivo.Length < 5)
            {
                memoMotivo.Focus();
                throw new ValidacaoException("Descreva o motivo do cancelamento (mínimo de 5 caracteres).");
            }
            if (!Ui.Confirmar(this, "Confirma o cancelamento do título?" + Environment.NewLine +
                                    "A venda será cancelada no ERP Vendas e o estoque estornado."))
                return;
            DialogResult = DialogResult.OK;
        }
    }
}
