using System.Windows.Forms;
using DevExpress.Utils;
using DevExpress.XtraEditors;
using DevExpress.XtraEditors.Controls;
using DevExpress.XtraGrid.Columns;
using DevExpress.XtraGrid.Views.Grid;

namespace ERPFinanceiro.Telas
{
    /// <summary>Utilitários de interface compartilhados pelas telas.</summary>
    internal static class Ui
    {
        public const string Titulo = "ERP Financeiro";

        /// <summary>Garante o botão de dropdown em editores criados pelo designer/código.</summary>
        public static void GarantirBotao(ButtonEdit editor)
        {
            if (editor.Properties.Buttons.Count == 0)
                editor.Properties.Buttons.Add(new EditorButton(ButtonPredefines.Combo));
        }

        public static GridColumn Coluna(GridView view, string campo, string titulo, int largura,
            FormatType tipo = FormatType.None, string formato = null)
        {
            var coluna = view.Columns.AddVisible(campo, titulo);
            coluna.Width = largura;
            if (tipo != FormatType.None)
            {
                coluna.DisplayFormat.FormatType = tipo;
                coluna.DisplayFormat.FormatString = formato;
            }
            return coluna;
        }

        public static void Informar(IWin32Window dono, string mensagem) =>
            XtraMessageBox.Show(dono, mensagem, Titulo, MessageBoxButtons.OK, MessageBoxIcon.Information);

        public static void Avisar(IWin32Window dono, string mensagem) =>
            XtraMessageBox.Show(dono, mensagem, Titulo, MessageBoxButtons.OK, MessageBoxIcon.Warning);

        public static void Erro(IWin32Window dono, string mensagem) =>
            XtraMessageBox.Show(dono, mensagem, Titulo, MessageBoxButtons.OK, MessageBoxIcon.Error);

        public static bool Confirmar(IWin32Window dono, string mensagem) =>
            XtraMessageBox.Show(dono, mensagem, Titulo, MessageBoxButtons.YesNo, MessageBoxIcon.Question,
                MessageBoxDefaultButton.Button2) == DialogResult.Yes;
    }
}
