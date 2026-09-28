unit uFrmPrincipal;

/// Tela principal: menu, inicialização (banco, servidor de integração)

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  Vcl.Menus,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxButtons,
  uServidorIntegracao;

type
  TfrmPrincipal = class(TForm)
    pnlTitulo: TPanel;
    lblTitulo: TLabel;
    lblSubtitulo: TLabel;
    pnlMenu: TPanel;
    btnClientes: TcxButton;
    btnProdutos: TcxButton;
    btnVendas: TcxButton;
    btnFila: TcxButton;
    btnSair: TcxButton;
    sbStatus: TStatusBar;
    tmrStatus: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnClientesClick(Sender: TObject);
    procedure btnProdutosClick(Sender: TObject);
    procedure btnVendasClick(Sender: TObject);
    procedure btnFilaClick(Sender: TObject);
    procedure btnSairClick(Sender: TObject);
    procedure tmrStatusTimer(Sender: TObject);
  private
    FServidor: TServidorIntegracao;
    FIniciado: Boolean;
    function Inicializar: Boolean;
    procedure AtualizarStatus;
    procedure AbrirModal(AClasse: TFormClass);
    procedure TratarExcecao(Sender: TObject; E: Exception);
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.dfm}

uses
  FireDAC.Comp.Client,
  uConfig, uConexao, uLog, uExcecoes, uProcessadorFila,
  uFrmClientes, uFrmProdutos, uFrmVendas, uFrmFila;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  Application.OnException := TratarExcecao;
  FIniciado := Inicializar;
  if not FIniciado then
  begin
    Application.ShowMainForm := False;
    Application.Terminate;
    Exit;
  end;
  AtualizarStatus;
  tmrStatus.Enabled := True;
end;

function TfrmPrincipal.Inicializar: Boolean;
var
  Cfg: TConfig;
begin
  Result := False;
  Cfg := TConfig.Instancia;
  Log('==== ERP Vendas iniciando (config: %s) ====', [Cfg.Arquivo]);
  ForceDirectories(Cfg.PastaPedidos);

  // 1) Banco de dados (obrigatório)
  try
    RegistrarConexao;
    Conexao;
  except
    on E: Exception do
    begin
      Log('Falha ao conectar no banco: %s', [E.Message]);
      MessageDlg('Não foi possível conectar ao banco de dados.' + sLineBreak + sLineBreak +
        E.Message + sLineBreak + sLineBreak +
        'Verifique a seção [Banco] do arquivo:' + sLineBreak + Cfg.Arquivo, mtError, [mbOK], 0);
      Exit;
    end;
  end;

  // 2) Servidor de callbacks do Financeiro (o sistema funciona sem ele)
  FServidor := TServidorIntegracao.Create(Cfg.ServidorPorta);
  try
    FServidor.Iniciar;
  except
    on E: Exception do
    begin
      Log('Falha ao iniciar o servidor de integração: %s', [E.Message]);
      MessageDlg(Format('Não foi possível abrir a porta %d para receber os retornos do Financeiro:' +
        sLineBreak + '%s' + sLineBreak + sLineBreak +
        'O sistema continuará funcionando, mas quitações e cancelamentos não serão recebidos. ' +
        'Verifique a seção [Servidor] do arquivo de configuração.',
        [Cfg.ServidorPorta, E.Message]), mtWarning, [mbOK], 0);
    end;
  end;

  // 3) Processador da fila de integração (envio de títulos e e-mails)
  ProcessadorFila := TProcessadorFila.Create;
  Result := True;
end;

procedure TfrmPrincipal.FormDestroy(Sender: TObject);
begin
  tmrStatus.Enabled := False;
  FreeAndNil(FServidor);        // para de receber callbacks primeiro
  FreeAndNil(ProcessadorFila);  // aguarda o item em andamento terminar
  Log('==== ERP Vendas encerrado ====');
end;

procedure TfrmPrincipal.AtualizarStatus;
var
  Pendentes, Erros: Integer;
begin
  if not FIniciado then
    Exit;
  sbStatus.Panels[0].Text := 'Banco: ' + TConfig.Instancia.DBServidor + ':' + TConfig.Instancia.DBCaminho;
  if Assigned(FServidor) and FServidor.Ativo then
    sbStatus.Panels[1].Text := Format('Integração: ouvindo na porta %d', [FServidor.Porta])
  else
    sbStatus.Panels[1].Text := 'Integração: servidor PARADO';
  try
    Pendentes := Conexao.ExecSQLScalar('SELECT COUNT(*) FROM INTEGRACAO_FILA WHERE STATUS = ''PENDENTE''');
    Erros := Conexao.ExecSQLScalar('SELECT COUNT(*) FROM INTEGRACAO_FILA WHERE STATUS = ''ERRO''');
    sbStatus.Panels[2].Text := Format('Fila: %d pendente(s), %d com erro', [Pendentes, Erros]);
  except
    on E: Exception do
      sbStatus.Panels[2].Text := 'Fila: indisponível (' + E.Message + ')';
  end;
end;

procedure TfrmPrincipal.tmrStatusTimer(Sender: TObject);
begin
  AtualizarStatus;
end;

procedure TfrmPrincipal.AbrirModal(AClasse: TFormClass);
var
  Form: TForm;
begin
  Form := AClasse.Create(nil);
  try
    Form.ShowModal;
  finally
    Form.Free;
  end;
  AtualizarStatus;
end;

procedure TfrmPrincipal.btnClientesClick(Sender: TObject);
begin
  AbrirModal(TfrmClientes);
end;

procedure TfrmPrincipal.btnProdutosClick(Sender: TObject);
begin
  AbrirModal(TfrmProdutos);
end;

procedure TfrmPrincipal.btnVendasClick(Sender: TObject);
begin
  AbrirModal(TfrmVendas);
end;

procedure TfrmPrincipal.btnFilaClick(Sender: TObject);
begin
  AbrirModal(TfrmFila);
end;

procedure TfrmPrincipal.btnSairClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmPrincipal.TratarExcecao(Sender: TObject; E: Exception);
begin
  if (E is EValidacao) or (E is ERegraNegocio) or (E is ENaoEncontrado) then
    MessageDlg(E.Message, mtWarning, [mbOK], 0)
  else
  begin
    Log('Erro não tratado: %s: %s', [E.ClassName, E.Message]);
    MessageDlg('Ocorreu um erro inesperado:' + sLineBreak + sLineBreak + MensagemAmigavel(E),
      mtError, [mbOK], 0);
  end;
end;

end.
