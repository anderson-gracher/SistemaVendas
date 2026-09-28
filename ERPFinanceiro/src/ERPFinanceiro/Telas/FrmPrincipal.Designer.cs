namespace ERPFinanceiro.Telas
{
    partial class FrmPrincipal
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
            this.components = new System.ComponentModel.Container();
            this.pnlResumo = new System.Windows.Forms.Panel();
            this.lblAVencer = new System.Windows.Forms.Label();
            this.lblVencido = new System.Windows.Forms.Label();
            this.lblRecebido = new System.Windows.Forms.Label();
            this.lblCancelado = new System.Windows.Forms.Label();
            this.pnlFiltros = new System.Windows.Forms.Panel();
            this.lblEmissao = new System.Windows.Forms.Label();
            this.dtDe = new DevExpress.XtraEditors.DateEdit();
            this.lblAte = new System.Windows.Forms.Label();
            this.dtAte = new DevExpress.XtraEditors.DateEdit();
            this.lblSituacao = new System.Windows.Forms.Label();
            this.cbSituacao = new DevExpress.XtraEditors.ComboBoxEdit();
            this.lblCliente = new System.Windows.Forms.Label();
            this.txtCliente = new DevExpress.XtraEditors.TextEdit();
            this.btnPesquisar = new System.Windows.Forms.Button();
            this.gridTitulos = new DevExpress.XtraGrid.GridControl();
            this.gvTitulos = new DevExpress.XtraGrid.Views.Grid.GridView();
            this.pnlBotoes = new System.Windows.Forms.Panel();
            this.btnQuitar = new System.Windows.Forms.Button();
            this.btnCancelarTitulo = new System.Windows.Forms.Button();
            this.btnRelatorio = new System.Windows.Forms.Button();
            this.btnFila = new System.Windows.Forms.Button();
            this.btnAtualizar = new System.Windows.Forms.Button();
            this.statusStrip = new System.Windows.Forms.StatusStrip();
            this.lblStatusBanco = new System.Windows.Forms.ToolStripStatusLabel();
            this.lblStatusApi = new System.Windows.Forms.ToolStripStatusLabel();
            this.lblStatusFila = new System.Windows.Forms.ToolStripStatusLabel();
            this.timerStatus = new System.Windows.Forms.Timer(this.components);
            this.pnlResumo.SuspendLayout();
            this.pnlFiltros.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dtDe.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtAte.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.cbSituacao.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.txtCliente.Properties)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.gridTitulos)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.gvTitulos)).BeginInit();
            this.pnlBotoes.SuspendLayout();
            this.statusStrip.SuspendLayout();
            this.SuspendLayout();
            //
            // pnlResumo
            //
            this.pnlResumo.Controls.Add(this.lblAVencer);
            this.pnlResumo.Controls.Add(this.lblVencido);
            this.pnlResumo.Controls.Add(this.lblRecebido);
            this.pnlResumo.Controls.Add(this.lblCancelado);
            this.pnlResumo.Dock = System.Windows.Forms.DockStyle.Top;
            this.pnlResumo.Location = new System.Drawing.Point(0, 0);
            this.pnlResumo.Name = "pnlResumo";
            this.pnlResumo.Size = new System.Drawing.Size(1180, 84);
            this.pnlResumo.TabIndex = 0;
            //
            // lblAVencer
            //
            this.lblAVencer.BackColor = System.Drawing.Color.FromArgb(41, 74, 112);
            this.lblAVencer.Font = new System.Drawing.Font("Segoe UI", 10F, System.Drawing.FontStyle.Bold);
            this.lblAVencer.ForeColor = System.Drawing.Color.White;
            this.lblAVencer.Location = new System.Drawing.Point(12, 10);
            this.lblAVencer.Name = "lblAVencer";
            this.lblAVencer.Size = new System.Drawing.Size(280, 64);
            this.lblAVencer.TabIndex = 0;
            this.lblAVencer.Text = "A VENCER";
            this.lblAVencer.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            //
            // lblVencido
            //
            this.lblVencido.BackColor = System.Drawing.Color.Firebrick;
            this.lblVencido.Font = new System.Drawing.Font("Segoe UI", 10F, System.Drawing.FontStyle.Bold);
            this.lblVencido.ForeColor = System.Drawing.Color.White;
            this.lblVencido.Location = new System.Drawing.Point(302, 10);
            this.lblVencido.Name = "lblVencido";
            this.lblVencido.Size = new System.Drawing.Size(280, 64);
            this.lblVencido.TabIndex = 1;
            this.lblVencido.Text = "VENCIDOS";
            this.lblVencido.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            //
            // lblRecebido
            //
            this.lblRecebido.BackColor = System.Drawing.Color.ForestGreen;
            this.lblRecebido.Font = new System.Drawing.Font("Segoe UI", 10F, System.Drawing.FontStyle.Bold);
            this.lblRecebido.ForeColor = System.Drawing.Color.White;
            this.lblRecebido.Location = new System.Drawing.Point(592, 10);
            this.lblRecebido.Name = "lblRecebido";
            this.lblRecebido.Size = new System.Drawing.Size(280, 64);
            this.lblRecebido.TabIndex = 2;
            this.lblRecebido.Text = "RECEBIDO";
            this.lblRecebido.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            //
            // lblCancelado
            //
            this.lblCancelado.BackColor = System.Drawing.Color.DimGray;
            this.lblCancelado.Font = new System.Drawing.Font("Segoe UI", 10F, System.Drawing.FontStyle.Bold);
            this.lblCancelado.ForeColor = System.Drawing.Color.White;
            this.lblCancelado.Location = new System.Drawing.Point(882, 10);
            this.lblCancelado.Name = "lblCancelado";
            this.lblCancelado.Size = new System.Drawing.Size(280, 64);
            this.lblCancelado.TabIndex = 3;
            this.lblCancelado.Text = "CANCELADOS";
            this.lblCancelado.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            //
            // pnlFiltros
            //
            this.pnlFiltros.Controls.Add(this.lblEmissao);
            this.pnlFiltros.Controls.Add(this.dtDe);
            this.pnlFiltros.Controls.Add(this.lblAte);
            this.pnlFiltros.Controls.Add(this.dtAte);
            this.pnlFiltros.Controls.Add(this.lblSituacao);
            this.pnlFiltros.Controls.Add(this.cbSituacao);
            this.pnlFiltros.Controls.Add(this.lblCliente);
            this.pnlFiltros.Controls.Add(this.txtCliente);
            this.pnlFiltros.Controls.Add(this.btnPesquisar);
            this.pnlFiltros.Dock = System.Windows.Forms.DockStyle.Top;
            this.pnlFiltros.Location = new System.Drawing.Point(0, 84);
            this.pnlFiltros.Name = "pnlFiltros";
            this.pnlFiltros.Size = new System.Drawing.Size(1180, 46);
            this.pnlFiltros.TabIndex = 1;
            //
            // lblEmissao
            //
            this.lblEmissao.AutoSize = true;
            this.lblEmissao.Location = new System.Drawing.Point(12, 16);
            this.lblEmissao.Name = "lblEmissao";
            this.lblEmissao.Text = "Emissão de";
            //
            // dtDe
            //
            this.dtDe.Location = new System.Drawing.Point(84, 12);
            this.dtDe.Name = "dtDe";
            this.dtDe.Size = new System.Drawing.Size(110, 20);
            this.dtDe.TabIndex = 0;
            //
            // lblAte
            //
            this.lblAte.AutoSize = true;
            this.lblAte.Location = new System.Drawing.Point(202, 16);
            this.lblAte.Name = "lblAte";
            this.lblAte.Text = "até";
            //
            // dtAte
            //
            this.dtAte.Location = new System.Drawing.Point(230, 12);
            this.dtAte.Name = "dtAte";
            this.dtAte.Size = new System.Drawing.Size(110, 20);
            this.dtAte.TabIndex = 1;
            //
            // lblSituacao
            //
            this.lblSituacao.AutoSize = true;
            this.lblSituacao.Location = new System.Drawing.Point(356, 16);
            this.lblSituacao.Name = "lblSituacao";
            this.lblSituacao.Text = "Situação";
            //
            // cbSituacao
            //
            this.cbSituacao.Location = new System.Drawing.Point(414, 12);
            this.cbSituacao.Name = "cbSituacao";
            this.cbSituacao.Size = new System.Drawing.Size(120, 20);
            this.cbSituacao.TabIndex = 2;
            //
            // lblCliente
            //
            this.lblCliente.AutoSize = true;
            this.lblCliente.Location = new System.Drawing.Point(550, 16);
            this.lblCliente.Name = "lblCliente";
            this.lblCliente.Text = "Cliente / CPF-CNPJ";
            //
            // txtCliente
            //
            this.txtCliente.Location = new System.Drawing.Point(666, 12);
            this.txtCliente.Name = "txtCliente";
            this.txtCliente.Size = new System.Drawing.Size(220, 20);
            this.txtCliente.TabIndex = 3;
            this.txtCliente.KeyDown += new System.Windows.Forms.KeyEventHandler(this.txtCliente_KeyDown);
            //
            // btnPesquisar
            //
            this.btnPesquisar.Location = new System.Drawing.Point(898, 9);
            this.btnPesquisar.Name = "btnPesquisar";
            this.btnPesquisar.Size = new System.Drawing.Size(100, 28);
            this.btnPesquisar.TabIndex = 4;
            this.btnPesquisar.Text = "Pesquisar";
            this.btnPesquisar.UseVisualStyleBackColor = true;
            this.btnPesquisar.Click += new System.EventHandler(this.btnPesquisar_Click);
            //
            // gridTitulos
            //
            this.gridTitulos.Dock = System.Windows.Forms.DockStyle.Fill;
            this.gridTitulos.Location = new System.Drawing.Point(0, 130);
            this.gridTitulos.MainView = this.gvTitulos;
            this.gridTitulos.Name = "gridTitulos";
            this.gridTitulos.Size = new System.Drawing.Size(1180, 456);
            this.gridTitulos.TabIndex = 2;
            this.gridTitulos.ViewCollection.AddRange(new DevExpress.XtraGrid.Views.Base.BaseView[] { this.gvTitulos });
            //
            // gvTitulos
            //
            this.gvTitulos.GridControl = this.gridTitulos;
            this.gvTitulos.Name = "gvTitulos";
            //
            // pnlBotoes
            //
            this.pnlBotoes.Controls.Add(this.btnQuitar);
            this.pnlBotoes.Controls.Add(this.btnCancelarTitulo);
            this.pnlBotoes.Controls.Add(this.btnRelatorio);
            this.pnlBotoes.Controls.Add(this.btnFila);
            this.pnlBotoes.Controls.Add(this.btnAtualizar);
            this.pnlBotoes.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.pnlBotoes.Location = new System.Drawing.Point(0, 586);
            this.pnlBotoes.Name = "pnlBotoes";
            this.pnlBotoes.Size = new System.Drawing.Size(1180, 52);
            this.pnlBotoes.TabIndex = 3;
            //
            // btnQuitar
            //
            this.btnQuitar.Location = new System.Drawing.Point(12, 10);
            this.btnQuitar.Name = "btnQuitar";
            this.btnQuitar.Size = new System.Drawing.Size(110, 32);
            this.btnQuitar.TabIndex = 0;
            this.btnQuitar.Text = "Quitar";
            this.btnQuitar.UseVisualStyleBackColor = true;
            this.btnQuitar.Click += new System.EventHandler(this.btnQuitar_Click);
            //
            // btnCancelarTitulo
            //
            this.btnCancelarTitulo.Location = new System.Drawing.Point(128, 10);
            this.btnCancelarTitulo.Name = "btnCancelarTitulo";
            this.btnCancelarTitulo.Size = new System.Drawing.Size(110, 32);
            this.btnCancelarTitulo.TabIndex = 1;
            this.btnCancelarTitulo.Text = "Cancelar";
            this.btnCancelarTitulo.UseVisualStyleBackColor = true;
            this.btnCancelarTitulo.Click += new System.EventHandler(this.btnCancelarTitulo_Click);
            //
            // btnRelatorio
            //
            this.btnRelatorio.Location = new System.Drawing.Point(254, 10);
            this.btnRelatorio.Name = "btnRelatorio";
            this.btnRelatorio.Size = new System.Drawing.Size(140, 32);
            this.btnRelatorio.TabIndex = 2;
            this.btnRelatorio.Text = "Relatório financeiro";
            this.btnRelatorio.UseVisualStyleBackColor = true;
            this.btnRelatorio.Click += new System.EventHandler(this.btnRelatorio_Click);
            //
            // btnFila
            //
            this.btnFila.Location = new System.Drawing.Point(400, 10);
            this.btnFila.Name = "btnFila";
            this.btnFila.Size = new System.Drawing.Size(170, 32);
            this.btnFila.TabIndex = 3;
            this.btnFila.Text = "Notificações ao Vendas";
            this.btnFila.UseVisualStyleBackColor = true;
            this.btnFila.Click += new System.EventHandler(this.btnFila_Click);
            //
            // btnAtualizar
            //
            this.btnAtualizar.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnAtualizar.Location = new System.Drawing.Point(1058, 10);
            this.btnAtualizar.Name = "btnAtualizar";
            this.btnAtualizar.Size = new System.Drawing.Size(110, 32);
            this.btnAtualizar.TabIndex = 4;
            this.btnAtualizar.Text = "Atualizar (F5)";
            this.btnAtualizar.UseVisualStyleBackColor = true;
            this.btnAtualizar.Click += new System.EventHandler(this.btnAtualizar_Click);
            //
            // statusStrip
            //
            this.statusStrip.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
                this.lblStatusBanco, this.lblStatusApi, this.lblStatusFila });
            this.statusStrip.Location = new System.Drawing.Point(0, 638);
            this.statusStrip.Name = "statusStrip";
            this.statusStrip.Size = new System.Drawing.Size(1180, 22);
            this.statusStrip.TabIndex = 4;
            //
            // lblStatusBanco
            //
            this.lblStatusBanco.Name = "lblStatusBanco";
            this.lblStatusBanco.BorderSides = System.Windows.Forms.ToolStripStatusLabelBorderSides.Right;
            this.lblStatusBanco.Text = "Banco";
            //
            // lblStatusApi
            //
            this.lblStatusApi.Name = "lblStatusApi";
            this.lblStatusApi.BorderSides = System.Windows.Forms.ToolStripStatusLabelBorderSides.Right;
            this.lblStatusApi.Text = "API";
            //
            // lblStatusFila
            //
            this.lblStatusFila.Name = "lblStatusFila";
            this.lblStatusFila.Text = "Fila";
            //
            // timerStatus
            //
            this.timerStatus.Interval = 10000;
            this.timerStatus.Tick += new System.EventHandler(this.timerStatus_Tick);
            //
            // FrmPrincipal
            //
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1180, 660);
            this.Controls.Add(this.gridTitulos);
            this.Controls.Add(this.pnlFiltros);
            this.Controls.Add(this.pnlResumo);
            this.Controls.Add(this.pnlBotoes);
            this.Controls.Add(this.statusStrip);
            this.KeyPreview = true;
            this.MinimumSize = new System.Drawing.Size(1100, 560);
            this.Name = "FrmPrincipal";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "ERP Financeiro";
            this.WindowState = System.Windows.Forms.FormWindowState.Maximized;
            this.KeyDown += new System.Windows.Forms.KeyEventHandler(this.FrmPrincipal_KeyDown);
            this.pnlResumo.ResumeLayout(false);
            this.pnlFiltros.ResumeLayout(false);
            this.pnlFiltros.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dtDe.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.dtAte.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.cbSituacao.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.txtCliente.Properties)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.gridTitulos)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.gvTitulos)).EndInit();
            this.pnlBotoes.ResumeLayout(false);
            this.statusStrip.ResumeLayout(false);
            this.statusStrip.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();
        }

        #endregion

        private System.Windows.Forms.Panel pnlResumo;
        private System.Windows.Forms.Label lblAVencer;
        private System.Windows.Forms.Label lblVencido;
        private System.Windows.Forms.Label lblRecebido;
        private System.Windows.Forms.Label lblCancelado;
        private System.Windows.Forms.Panel pnlFiltros;
        private System.Windows.Forms.Label lblEmissao;
        private DevExpress.XtraEditors.DateEdit dtDe;
        private System.Windows.Forms.Label lblAte;
        private DevExpress.XtraEditors.DateEdit dtAte;
        private System.Windows.Forms.Label lblSituacao;
        private DevExpress.XtraEditors.ComboBoxEdit cbSituacao;
        private System.Windows.Forms.Label lblCliente;
        private DevExpress.XtraEditors.TextEdit txtCliente;
        private System.Windows.Forms.Button btnPesquisar;
        private DevExpress.XtraGrid.GridControl gridTitulos;
        private DevExpress.XtraGrid.Views.Grid.GridView gvTitulos;
        private System.Windows.Forms.Panel pnlBotoes;
        private System.Windows.Forms.Button btnQuitar;
        private System.Windows.Forms.Button btnCancelarTitulo;
        private System.Windows.Forms.Button btnRelatorio;
        private System.Windows.Forms.Button btnFila;
        private System.Windows.Forms.Button btnAtualizar;
        private System.Windows.Forms.StatusStrip statusStrip;
        private System.Windows.Forms.ToolStripStatusLabel lblStatusBanco;
        private System.Windows.Forms.ToolStripStatusLabel lblStatusApi;
        private System.Windows.Forms.ToolStripStatusLabel lblStatusFila;
        private System.Windows.Forms.Timer timerStatus;
    }
}
