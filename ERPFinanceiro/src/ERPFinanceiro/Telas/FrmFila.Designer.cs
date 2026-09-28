namespace ERPFinanceiro.Telas
{
    partial class FrmFila
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
            this.gridFila = new DevExpress.XtraGrid.GridControl();
            this.gvFila = new DevExpress.XtraGrid.Views.Grid.GridView();
            this.pnlBotoes = new System.Windows.Forms.Panel();
            this.btnAtualizar = new System.Windows.Forms.Button();
            this.btnProcessarAgora = new System.Windows.Forms.Button();
            this.btnReprocessar = new System.Windows.Forms.Button();
            this.btnFechar = new System.Windows.Forms.Button();
            ((System.ComponentModel.ISupportInitialize)(this.gridFila)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.gvFila)).BeginInit();
            this.pnlBotoes.SuspendLayout();
            this.SuspendLayout();
            //
            // gridFila
            //
            this.gridFila.Dock = System.Windows.Forms.DockStyle.Fill;
            this.gridFila.Location = new System.Drawing.Point(0, 0);
            this.gridFila.MainView = this.gvFila;
            this.gridFila.Name = "gridFila";
            this.gridFila.Size = new System.Drawing.Size(1000, 428);
            this.gridFila.TabIndex = 0;
            this.gridFila.ViewCollection.AddRange(new DevExpress.XtraGrid.Views.Base.BaseView[] { this.gvFila });
            //
            // gvFila
            //
            this.gvFila.GridControl = this.gridFila;
            this.gvFila.Name = "gvFila";
            //
            // pnlBotoes
            //
            this.pnlBotoes.Controls.Add(this.btnAtualizar);
            this.pnlBotoes.Controls.Add(this.btnProcessarAgora);
            this.pnlBotoes.Controls.Add(this.btnReprocessar);
            this.pnlBotoes.Controls.Add(this.btnFechar);
            this.pnlBotoes.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.pnlBotoes.Location = new System.Drawing.Point(0, 428);
            this.pnlBotoes.Name = "pnlBotoes";
            this.pnlBotoes.Size = new System.Drawing.Size(1000, 52);
            this.pnlBotoes.TabIndex = 1;
            //
            // btnAtualizar
            //
            this.btnAtualizar.Location = new System.Drawing.Point(12, 10);
            this.btnAtualizar.Name = "btnAtualizar";
            this.btnAtualizar.Size = new System.Drawing.Size(100, 32);
            this.btnAtualizar.TabIndex = 0;
            this.btnAtualizar.Text = "Atualizar";
            this.btnAtualizar.UseVisualStyleBackColor = true;
            this.btnAtualizar.Click += new System.EventHandler(this.btnAtualizar_Click);
            //
            // btnProcessarAgora
            //
            this.btnProcessarAgora.Location = new System.Drawing.Point(118, 10);
            this.btnProcessarAgora.Name = "btnProcessarAgora";
            this.btnProcessarAgora.Size = new System.Drawing.Size(120, 32);
            this.btnProcessarAgora.TabIndex = 1;
            this.btnProcessarAgora.Text = "Processar agora";
            this.btnProcessarAgora.UseVisualStyleBackColor = true;
            this.btnProcessarAgora.Click += new System.EventHandler(this.btnProcessarAgora_Click);
            //
            // btnReprocessar
            //
            this.btnReprocessar.Location = new System.Drawing.Point(244, 10);
            this.btnReprocessar.Name = "btnReprocessar";
            this.btnReprocessar.Size = new System.Drawing.Size(130, 32);
            this.btnReprocessar.TabIndex = 2;
            this.btnReprocessar.Text = "Reprocessar erros";
            this.btnReprocessar.UseVisualStyleBackColor = true;
            this.btnReprocessar.Click += new System.EventHandler(this.btnReprocessar_Click);
            //
            // btnFechar
            //
            this.btnFechar.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnFechar.DialogResult = System.Windows.Forms.DialogResult.Cancel;
            this.btnFechar.Location = new System.Drawing.Point(888, 10);
            this.btnFechar.Name = "btnFechar";
            this.btnFechar.Size = new System.Drawing.Size(100, 32);
            this.btnFechar.TabIndex = 3;
            this.btnFechar.Text = "Fechar";
            this.btnFechar.UseVisualStyleBackColor = true;
            this.btnFechar.Click += new System.EventHandler(this.btnFechar_Click);
            //
            // FrmFila
            //
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.CancelButton = this.btnFechar;
            this.ClientSize = new System.Drawing.Size(1000, 480);
            this.Controls.Add(this.gridFila);
            this.Controls.Add(this.pnlBotoes);
            this.Name = "FrmFila";
            this.ShowInTaskbar = false;
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterParent;
            this.Text = "Notificações ao ERP Vendas";
            ((System.ComponentModel.ISupportInitialize)(this.gridFila)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.gvFila)).EndInit();
            this.pnlBotoes.ResumeLayout(false);
            this.ResumeLayout(false);
        }

        #endregion

        private DevExpress.XtraGrid.GridControl gridFila;
        private DevExpress.XtraGrid.Views.Grid.GridView gvFila;
        private System.Windows.Forms.Panel pnlBotoes;
        private System.Windows.Forms.Button btnAtualizar;
        private System.Windows.Forms.Button btnProcessarAgora;
        private System.Windows.Forms.Button btnReprocessar;
        private System.Windows.Forms.Button btnFechar;
    }
}
