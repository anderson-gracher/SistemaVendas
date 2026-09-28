namespace ERPFinanceiro.Telas
{
    partial class FrmCancelamento
    {
        private System.ComponentModel.IContainer components = null;

        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
                components.Dispose();
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        private void InitializeComponent()
        {
            this.lblTitulo = new System.Windows.Forms.Label();
            this.lblMotivo = new System.Windows.Forms.Label();
            this.memoMotivo = new DevExpress.XtraEditors.MemoEdit();
            this.btnConfirmar = new System.Windows.Forms.Button();
            this.btnVoltar = new System.Windows.Forms.Button();
            ((System.ComponentModel.ISupportInitialize)(this.memoMotivo.Properties)).BeginInit();
            this.SuspendLayout();
            //
            // lblTitulo
            //
            this.lblTitulo.Font = new System.Drawing.Font("Segoe UI", 9F, System.Drawing.FontStyle.Bold);
            this.lblTitulo.Location = new System.Drawing.Point(12, 12);
            this.lblTitulo.Name = "lblTitulo";
            this.lblTitulo.Size = new System.Drawing.Size(456, 36);
            this.lblTitulo.Text = "Título";
            //
            // lblMotivo
            //
            this.lblMotivo.AutoSize = true;
            this.lblMotivo.Location = new System.Drawing.Point(12, 58);
            this.lblMotivo.Name = "lblMotivo";
            this.lblMotivo.Text = "Motivo do cancelamento *";
            //
            // memoMotivo
            //
            this.memoMotivo.Location = new System.Drawing.Point(12, 76);
            this.memoMotivo.Name = "memoMotivo";
            this.memoMotivo.Size = new System.Drawing.Size(456, 70);
            this.memoMotivo.TabIndex = 0;
            //
            // btnConfirmar
            //
            this.btnConfirmar.Location = new System.Drawing.Point(262, 158);
            this.btnConfirmar.Name = "btnConfirmar";
            this.btnConfirmar.Size = new System.Drawing.Size(100, 30);
            this.btnConfirmar.TabIndex = 1;
            this.btnConfirmar.Text = "Cancelar título";
            this.btnConfirmar.UseVisualStyleBackColor = true;
            this.btnConfirmar.Click += new System.EventHandler(this.btnConfirmar_Click);
            //
            // btnVoltar
            //
            this.btnVoltar.DialogResult = System.Windows.Forms.DialogResult.Cancel;
            this.btnVoltar.Location = new System.Drawing.Point(368, 158);
            this.btnVoltar.Name = "btnVoltar";
            this.btnVoltar.Size = new System.Drawing.Size(100, 30);
            this.btnVoltar.TabIndex = 2;
            this.btnVoltar.Text = "Voltar";
            this.btnVoltar.UseVisualStyleBackColor = true;
            //
            // FrmCancelamento
            //
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.CancelButton = this.btnVoltar;
            this.ClientSize = new System.Drawing.Size(480, 200);
            this.Controls.Add(this.lblTitulo);
            this.Controls.Add(this.lblMotivo);
            this.Controls.Add(this.memoMotivo);
            this.Controls.Add(this.btnConfirmar);
            this.Controls.Add(this.btnVoltar);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "FrmCancelamento";
            this.ShowInTaskbar = false;
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterParent;
            this.Text = "Cancelar título";
            ((System.ComponentModel.ISupportInitialize)(this.memoMotivo.Properties)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();
        }

        #endregion

        private System.Windows.Forms.Label lblTitulo;
        private System.Windows.Forms.Label lblMotivo;
        private DevExpress.XtraEditors.MemoEdit memoMotivo;
        private System.Windows.Forms.Button btnConfirmar;
        private System.Windows.Forms.Button btnVoltar;
    }
}
