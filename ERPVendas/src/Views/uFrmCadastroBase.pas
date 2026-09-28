unit uFrmCadastroBase;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus,
  Data.DB,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer, cxEdit, cxTextEdit,
  cxButtons, cxPC, dxBarBuiltInMenu, cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxNavigator, cxDBData, cxGridLevel, cxClasses, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid;

type
  TfrmCadastroBase = class(TForm)
    pgcPrincipal: TcxPageControl;
    tsConsulta: TcxTabSheet;
    tsCadastro: TcxTabSheet;
    pnlPesquisa: TPanel;
    lblPesquisa: TLabel;
    edtPesquisa: TcxTextEdit;
    btnPesquisar: TcxButton;
    grdConsulta: TcxGrid;
    tvConsulta: TcxGridDBTableView;
    lvConsulta: TcxGridLevel;
    pnlBotoes: TPanel;
    btnNovo: TcxButton;
    btnEditar: TcxButton;
    btnExcluir: TcxButton;
    btnSalvar: TcxButton;
    btnCancelar: TcxButton;
    btnFechar: TcxButton;
    qryDados: TFDQuery;
    dsDados: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnPesquisarClick(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnFecharClick(Sender: TObject);
    procedure edtPesquisaKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure tvConsultaDblClick(Sender: TObject);
    procedure dsDadosStateChange(Sender: TObject);
    procedure qryDadosBeforePost(DataSet: TDataSet);
    procedure pgcPrincipalPageChanging(Sender: TObject; NewPage: TcxTabSheet; var AllowChange: Boolean);
  private
    procedure AtualizarBotoes;
    procedure CriarColunas;
  protected
    // -- Metodos virtuais para os descendentes'
    function NomeTabela: string; virtual; abstract;
    function NomeGenerator: string; virtual; abstract;
    function SqlConsulta: string; virtual; abstract;    
    function FiltroPesquisa: string; virtual; abstract;
    function OrdemConsulta: string; virtual; abstract;
    procedure PrepararTela; virtual;
    procedure ConfigurarCampos; virtual;
    procedure ValidarRegistro; virtual;
    procedure AoNovoRegistro; virtual;
    procedure FocarPrimeiroCampo; virtual;
    // --- Utilitários ---
    function Campo(const ANome: string): TField;
    procedure Exigir(ACondicao: Boolean; const AMensagem: string; AControle: TWinControl = nil);
    procedure Pesquisar;
  end;

var
  frmCadastroBase: TfrmCadastroBase;

implementation

{$R *.dfm}

uses
  uConexao, uExcecoes, uUtilsDB;

{ Contrato padrão }

procedure TfrmCadastroBase.PrepararTela;
begin
  // opcional nos descendentes
end;

procedure TfrmCadastroBase.ConfigurarCampos;
begin
  DefinirCampo(qryDados, 'ID', 'Código');
end;

procedure TfrmCadastroBase.ValidarRegistro;
begin
  // opcional nos descendentes
end;

procedure TfrmCadastroBase.AoNovoRegistro;
begin
  // opcional nos descendentes
end;

procedure TfrmCadastroBase.FocarPrimeiroCampo;
begin
  // opcional nos descendentes
end;

{ Utilitários }

function TfrmCadastroBase.Campo(const ANome: string): TField;
begin
  Result := qryDados.FieldByName(ANome);
end;

procedure TfrmCadastroBase.Exigir(ACondicao: Boolean; const AMensagem: string; AControle: TWinControl);
begin
  if ACondicao then
    Exit;
  if Assigned(AControle) and AControle.CanFocus then
    AControle.SetFocus;
  raise EValidacao.Create(AMensagem);
end;

procedure TfrmCadastroBase.Pesquisar;
var
  IdAtual: Integer;
begin
  IdAtual := 0;
  if qryDados.Active then
  begin
    if qryDados.State in dsEditModes then
      Exit;
    if not qryDados.IsEmpty then
      IdAtual := qryDados.FieldByName('ID').AsInteger;
  end;

  tvConsulta.BeginUpdate;
  try
    qryDados.Close;
    qryDados.SQL.Text := SqlConsulta + ' WHERE ' + FiltroPesquisa + ' ORDER BY ' + OrdemConsulta;
    qryDados.ParamByName('PESQ').AsString := Trim(edtPesquisa.Text);
    qryDados.Open;
    ConfigurarCampos;
    if tvConsulta.ColumnCount = 0 then
      CriarColunas;
    if IdAtual > 0 then
      qryDados.Locate('ID', IdAtual, []);
  finally
    tvConsulta.EndUpdate;
  end;
  AtualizarBotoes;
end;

procedure TfrmCadastroBase.CriarColunas;
var
  I: Integer;
  Coluna: TcxGridDBColumn;
  Campo: TField;
begin
  tvConsulta.DataController.CreateAllItems;
  for I := 0 to tvConsulta.ColumnCount - 1 do
  begin
    Coluna := tvConsulta.Columns[I];
    Campo := qryDados.FindField(Coluna.DataBinding.FieldName);
    if Assigned(Campo) then
    begin
      Coluna.Caption := Campo.DisplayLabel;
      Coluna.Visible := Campo.Visible;
    end;
  end;
  tvConsulta.ApplyBestFit;
end;

procedure TfrmCadastroBase.AtualizarBotoes;
var
  Editando, TemRegistro: Boolean;
begin
  Editando := qryDados.State in dsEditModes;
  TemRegistro := qryDados.Active and not qryDados.IsEmpty;
  btnNovo.Enabled := not Editando;
  btnEditar.Enabled := (not Editando) and TemRegistro;
  btnExcluir.Enabled := (not Editando) and TemRegistro;
  btnSalvar.Enabled := Editando;
  btnCancelar.Enabled := Editando;
  btnFechar.Enabled := not Editando;
  pnlPesquisa.Enabled := not Editando;
  grdConsulta.Enabled := not Editando;
end;

{ Eventos }

procedure TfrmCadastroBase.FormCreate(Sender: TObject);
begin
  qryDados.Connection := Conexao;
  qryDados.UpdateOptions.UpdateTableName := NomeTabela;
  qryDados.UpdateOptions.KeyFields := 'ID';
  qryDados.UpdateOptions.AutoIncFields := 'ID';
  qryDados.UpdateOptions.GeneratorName := NomeGenerator;
  qryDados.UpdateOptions.FetchGeneratorsPoint := gpImmediate;
  tvConsulta.DataController.KeyFieldNames := 'ID';
  edtPesquisa.Properties.MaxLength := 60;
  pgcPrincipal.ActivePage := tsConsulta;
  PrepararTela;
  Pesquisar;
end;

procedure TfrmCadastroBase.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if qryDados.State in dsEditModes then
  begin
    CanClose := MessageDlg('Há alterações não salvas. Deseja descartá-las?', mtConfirmation,
      [mbYes, mbNo], 0, mbNo) = mrYes;
    if CanClose then
      qryDados.Cancel;
  end;
end;

procedure TfrmCadastroBase.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_F2:
      if btnNovo.Enabled then btnNovoClick(nil);
    VK_F3:
      if btnEditar.Enabled then btnEditarClick(nil);
    VK_F10:
      begin
        if btnSalvar.Enabled then btnSalvarClick(nil);
        Key := 0;
      end;
    VK_ESCAPE:
      begin
        if btnCancelar.Enabled then
          btnCancelarClick(nil)
        else if pgcPrincipal.ActivePage = tsCadastro then
          pgcPrincipal.ActivePage := tsConsulta
        else
          Close;
        Key := 0;
      end;
  end;
end;

procedure TfrmCadastroBase.btnPesquisarClick(Sender: TObject);
begin
  Pesquisar;
end;

procedure TfrmCadastroBase.edtPesquisaKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Pesquisar;
    Key := 0;
  end;
end;

procedure TfrmCadastroBase.btnNovoClick(Sender: TObject);
begin
  if not qryDados.Active then
    Pesquisar;
  qryDados.Append;
  AoNovoRegistro;
  pgcPrincipal.ActivePage := tsCadastro;
  FocarPrimeiroCampo;
end;

procedure TfrmCadastroBase.btnEditarClick(Sender: TObject);
begin
  if qryDados.IsEmpty then
    Exit;
  qryDados.Edit;
  pgcPrincipal.ActivePage := tsCadastro;
  FocarPrimeiroCampo;
end;

procedure TfrmCadastroBase.btnExcluirClick(Sender: TObject);
begin
  if qryDados.IsEmpty then
    Exit;
  if MessageDlg('Confirma a exclusão do registro selecionado?', mtConfirmation, [mbYes, mbNo], 0,
    mbNo) <> mrYes then
    Exit;
  try
    qryDados.Delete;
  except on E: EFDDBEngineException do
    begin
    
      qryDados.Refresh;
      raise EValidacao.Create(MensagemAmigavel(E));
    end;
  end;
end;

procedure TfrmCadastroBase.btnSalvarClick(Sender: TObject);
begin
  try
    

	qryDados.Post; 
  except on E: EFDDBEngineException do
    raise EValidacao.Create(MensagemAmigavel(E));
  end;
  
  pgcPrincipal.ActivePage := tsConsulta;
end;

procedure TfrmCadastroBase.btnCancelarClick(Sender: TObject);
begin
  
  qryDados.Cancel;
  pgcPrincipal.ActivePage := tsConsulta;
end;

procedure TfrmCadastroBase.btnFecharClick(Sender: TObject);
begin
  
  Close;
end;

procedure TfrmCadastroBase.tvConsultaDblClick(Sender: TObject);
begin
  
  if btnEditar.Enabled then begin
    btnEditarClick(nil);
  end;
end;

procedure TfrmCadastroBase.dsDadosStateChange(Sender: TObject);
begin
  AtualizarBotoes;
end;

procedure TfrmCadastroBase.qryDadosBeforePost(DataSet: TDataSet);
begin
  ValidarRegistro;
end;

procedure TfrmCadastroBase.pgcPrincipalPageChanging(Sender: TObject; NewPage: TcxTabSheet; var AllowChange: Boolean);
begin

  AllowChange := not ((NewPage = tsConsulta) and (qryDados.State in dsEditModes));
end;

end.
