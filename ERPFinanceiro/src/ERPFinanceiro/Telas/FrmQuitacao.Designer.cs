namespace ERPFinanceiro.Telas
{
    partial class FrmQuitacao
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
            this.lblData = new System.Windows.Forms.Label();
            this.dtPagamento = new DevExpress.XtraEditors.DateEdit();
            this.lblValor = new System.Windows.Forms.Label();
            this.txtValor = new DevExpress.XtraEditors.CalcEdit();
            this.lblForma = new System.Windows.Forms.Label();
            this.cbForma = new DevExpress.XtraEditors.ComboBoxEdit();
            this.btnConfirmar = new System.Windows.Forms.Button();
            this.btnCancelar = new System.Windows.Forms.Button();
            ((System.ComponentModel.ISupportInitialize)(this.dtPagamento.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.txtValor.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.cbForma.Properties)).BeginInit();
            this.SuspendLayout();
            //
            // lblTitulo
            //
            this.lblTitulo.Font = new System.Drawing.Font("Segoe UI", 9F, System.Drawing.FontStyle.Bold);
            this.lblTitulo.Location = new System.Drawing.Point(12, 12);
            this.lblTitulo.Name = "lblTitulo";
            this.lblTitulo.Size = new System.Drawing.Size(496, 44);
            this.lblTitulo.Text = "Título";
            //
            // lblData
            //
            this.lblData.AutoSize = true;
            this.lblData.Location = new System.Drawing.Point(12, 70);
            this.lblData.Name = "lblData";
            this.lblData.Text = "Data do pagamento *";
            //
            // dtPagamento
            //
            this.dtPagamento.Location = new System.Drawing.Point(12, 88);
            this.dtPagamento.Name = "dtPagamento";
            this.dtPagamento.Size = new System.Drawing.Size(140, 20);
            this.dtPagamento.TabIndex = 0;
            //
            // lblValor
            //
            this.lblValor.AutoSize = true;
            this.lblValor.Location = new System.Drawing.Point(166, 70);
            this.lblValor.Name = "lblValor";
            this.lblValor.Text = "Valor pago *";
            //
            // txtValor
            //
            this.txtValor.Location = new System.Drawing.Point(166, 88);
            this.txtValor.Name = "txtValor";
            this.txtValor.Size = new System.Drawing.Size(140, 20);
            this.txtValor.TabIndex = 1;
            //
            // lblForma
            //
            this.lblForma.AutoSize = true;
            this.lblForma.Location = new System.Drawing.Point(320, 70);
            this.lblForma.Name = "lblForma";
            this.lblForma.Text = "Forma de pagamento *";
            //
            // cbForma
            //
            this.cbForma.Location = new System.Drawing.Point(320, 88);
            this.cbForma.Name = "cbForma";
            this.cbForma.Size = new System.Drawing.Size(188, 20);
            this.cbForma.TabIndex = 2;
            //
            // btnConfirmar
            //
            this.btnConfirmar.Location = new System.Drawing.Point(302, 132);
            this.btnConfirmar.Name = "btnConfirmar";
            this.btnConfirmar.Size = new System.Drawing.Size(100, 30);
            this.btnConfirmar.TabIndex = 3;
            this.btnConfirmar.Text = "Quitar";
            this.btnConfirmar.UseVisualStyleBackColor = true;
            this.btnConfirmar.Click += new System.EventHandler(this.btnConfirmar_Click);
            //
            // btnCancelar
            //
            this.btnCancelar.DialogResult = System.Windows.Forms.DialogResult.Cancel;
            this.btnCancelar.Location = new System.Drawing.Point(408, 132);
            this.btnCancelar.Name = "btnCancelar";
            this.btnCancelar.Size = new System.Drawing.Size(100, 30);
            this.btnCancelar.TabIndex = 4;
            this.btnCancelar.Text = "Cancelar";
            this.btnCancelar.UseVisualStyleBackColor = true;
            //
            // FrmQuitacao
            //
            this.AcceptButton = this.btnConfirmar;
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.CancelButton = this.btnCancelar;
            this.ClientSize = new System.Drawing.Size(520, 176);
            this.Controls.Add(this.lblTitulo);
            this.Controls.Add(this.lblData);
            this.Controls.Add(this.dtPagamento);
            this.Controls.Add(this.lblValor);
            this.Controls.Add(this.txtValor);
            this.Controls.Add(this.lblForma);
            this.Controls.Add(this.cbForma);
            this.Controls.Add(this.btnConfirmar);
            this.Controls.Add(this.btnCancelar);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "FrmQuitacao";
            this.ShowInTaskbar = false;
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterParent;
            this.Text = "Quitar título";
            ((System.ComponentModel.ISupportInitialize)(this.dtPagamento.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.txtValor.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.cbForma.Properties)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();
        }

        #endregion

        private System.Windows.Forms.Label lblTitulo;
        private System.Windows.Forms.Label lblData;
        private DevExpress.XtraEditors.DateEdit dtPagamento;
        private System.Windows.Forms.Label lblValor;
        private DevExpress.XtraEditors.CalcEdit txtValor;
        private System.Windows.Forms.Label lblForma;
        private DevExpress.XtraEditors.ComboBoxEdit cbForma;
        private System.Windows.Forms.Button btnConfirmar;
        private System.Windows.Forms.Button btnCancelar;
    }
}
