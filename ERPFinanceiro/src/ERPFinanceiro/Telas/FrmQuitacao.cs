using System;
using System.Windows.Forms;
using DevExpress.XtraEditors;
using ERPFinanceiro.Dominio;

namespace ERPFinanceiro.Telas
{
    /// <summary>Informa data, valor e forma de pagamento para quitar um título.</summary>
    public partial class FrmQuitacao : XtraForm
    {
        private readonly Titulo _titulo;

        public FrmQuitacao(Titulo titulo)
        {
            InitializeComponent();
            _titulo = titulo;

            Ui.GarantirBotao(dtPagamento);
            Ui.GarantirBotao(cbForma);
            Ui.GarantirBotao(txtValor);
            cbForma.Properties.Items.AddRange(FormasPagamento.Todas);
            txtValor.Properties.DisplayFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
            txtValor.Properties.DisplayFormat.FormatString = "n2";
            txtValor.Properties.EditFormat.FormatType = DevExpress.Utils.FormatType.Numeric;
            txtValor.Properties.EditFormat.FormatString = "n2";

            lblTitulo.Text = string.Format(
                "Venda {0}  -  {1} ({2}){3}Valor: {4:C2}   |   Emissão: {5:dd/MM/yyyy}   |   Vencimento: {6:dd/MM/yyyy}{7}",
                titulo.IdVenda, titulo.ClienteNome, titulo.ClienteDocumentoFormatado, Environment.NewLine,
                titulo.Valor, titulo.DataEmissao, titulo.DataVencimento,
                titulo.Vencido ? string.Format("   |   VENCIDO há {0} dia(s)", titulo.DiasAtraso) : string.Empty);

            dtPagamento.DateTime = DateTime.Today;
            txtValor.Value = titulo.Valor;
            cbForma.SelectedIndex = 0;
        }

        public DateTime DataPagamento => dtPagamento.DateTime.Date;
        public decimal ValorPago => txtValor.Value;
        public string FormaPagamento => cbForma.Text.Trim();

        private void btnConfirmar_Click(object sender, EventArgs e)
        {
            if (dtPagamento.EditValue == null)
            {
                dtPagamento.Focus();
                throw new ValidacaoException("Informe a data do pagamento.");
            }
            if (DataPagamento > DateTime.Today)
            {
                dtPagamento.Focus();
                throw new ValidacaoException("A data de pagamento não pode ser futura.");
            }
            if (ValorPago < _titulo.Valor)
            {
                txtValor.Focus();
                throw new ValidacaoException(string.Format(
                    "O valor pago não pode ser menor que o valor do título ({0:C2}).", _titulo.Valor));
            }
            if (FormaPagamento.Length == 0)
            {
                cbForma.Focus();
                throw new ValidacaoException("Informe a forma de pagamento.");
            }
            if (ValorPago > _titulo.Valor &&
                !Ui.Confirmar(this, string.Format("O valor pago ({0:C2}) é maior que o valor do título ({1:C2}) " +
                    "(juros/multa). Confirma?", ValorPago, _titulo.Valor)))
                return;

            DialogResult = DialogResult.OK;
        }
    }
}
