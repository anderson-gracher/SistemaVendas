unit uFrmClientes;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus,
  Data.DB,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer, cxEdit, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, cxCheckBox, cxDBEdit, cxButtons, cxPC, dxBarBuiltInMenu, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, cxDBData, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  uFrmCadastroBase;

type
  TfrmClientes = class(TfrmCadastroBase)
    lblCodigo: TLabel;
    edtCodigo: TcxDBTextEdit;
    lblNome: TLabel;
    edtNome: TcxDBTextEdit;
    chkAtivo: TcxDBCheckBox;
    lblDocumento: TLabel;
    edtDocumento: TcxDBTextEdit;
    lblEmail: TLabel;
    edtEmail: TcxDBTextEdit;
    lblTelefone: TLabel;
    edtTelefone: TcxDBTextEdit;
    lblCidade: TLabel;
    edtCidade: TcxDBTextEdit;
    lblUF: TLabel;
    cbUF: TcxDBComboBox;
    lblAjuda: TLabel;
  private
    procedure DocumentoGetText(Sender: TField; var Text: string; DisplayText: Boolean);
  protected
    function NomeTabela: string; override;
    function NomeGenerator: string; override;
    function SqlConsulta: string; override;
    function FiltroPesquisa: string; override;
    function OrdemConsulta: string; override;
    procedure PrepararTela; override;
    procedure ConfigurarCampos; override;
    procedure ValidarRegistro; override;
    procedure AoNovoRegistro; override;
    procedure FocarPrimeiroCampo; override;
  end;

var
  frmClientes: TfrmClientes;

implementation

{$R *.dfm}

uses
  uUtilsDB, uValidacoes;

function TfrmClientes.NomeTabela: string;
begin
  Result := 'CLIENTE';
end;

function TfrmClientes.NomeGenerator: string;
begin
  Result := 'GEN_CLIENTE_ID';
end;

function TfrmClientes.SqlConsulta: string;
begin
  Result := 'SELECT ID, NOME, CPF_CNPJ, EMAIL, TELEFONE, CIDADE, UF, ATIVO, DATA_CADASTRO FROM CLIENTE';
end;

function TfrmClientes.FiltroPesquisa: string;
begin
  // CONTAINING ignora maiúsculas/acentos (collation UNICODE_CI_AI)
  Result := '(NOME CONTAINING CAST(:PESQ AS VARCHAR(100)) ' +
    'OR CPF_CNPJ CONTAINING CAST(:PESQ AS VARCHAR(100)) ' +
    'OR EMAIL CONTAINING CAST(:PESQ AS VARCHAR(100)) ' +
    'OR CIDADE CONTAINING CAST(:PESQ AS VARCHAR(100)))';
end;

function TfrmClientes.OrdemConsulta: string;
begin
  Result := 'NOME';
end;

procedure TfrmClientes.PrepararTela;
begin
  cbUF.Properties.Items.CommaText :=
    'AC,AL,AM,AP,BA,CE,DF,ES,GO,MA,MG,MS,MT,PA,PB,PE,PI,PR,RJ,RN,RO,RR,RS,SC,SE,SP,TO';
end;

procedure TfrmClientes.ConfigurarCampos;
begin
  inherited;
  DefinirCampo(qryDados, 'NOME', 'Nome');
  DefinirCampo(qryDados, 'CPF_CNPJ', 'CPF/CNPJ');
  DefinirCampo(qryDados, 'EMAIL', 'E-mail');
  DefinirCampo(qryDados, 'TELEFONE', 'Telefone');
  DefinirCampo(qryDados, 'CIDADE', 'Cidade');
  DefinirCampo(qryDados, 'UF', 'UF');
  DefinirCampo(qryDados, 'ATIVO', 'Ativo');
  DefinirCampo(qryDados, 'DATA_CADASTRO', 'Cadastrado em', 'dd/mm/yyyy');
  Campo('CPF_CNPJ').OnGetText := DocumentoGetText;
end;

procedure TfrmClientes.DocumentoGetText(Sender: TField; var Text: string; DisplayText: Boolean);
begin
  if DisplayText then
    Text := FormatarDocumento(Sender.AsString)
  else
    Text := Sender.AsString;
end;

procedure TfrmClientes.AoNovoRegistro;
begin
  Campo('ATIVO').AsBoolean := True;
  Campo('DATA_CADASTRO').AsDateTime := Now;
end;

procedure TfrmClientes.FocarPrimeiroCampo;
begin
  if edtNome.CanFocus then
    edtNome.SetFocus;
end;

procedure TfrmClientes.ValidarRegistro;
var
  Documento, Email, UF: string;
begin
  inherited;
  Campo('NOME').AsString := Trim(Campo('NOME').AsString);
  Exigir(Length(Campo('NOME').AsString) >= 3,
    'Informe o nome do cliente (mínimo de 3 caracteres).', edtNome);

  Documento := NormalizarDocumento(Campo('CPF_CNPJ').AsString);
  Exigir(DocumentoValido(Documento), 'CPF/CNPJ inválido. Confira os dígitos informados.', edtDocumento);
  Campo('CPF_CNPJ').AsString := Documento;

  Email := LowerCase(Trim(Campo('EMAIL').AsString));
  Exigir(EmailValido(Email),
    'Informe um e-mail válido: ele recebe a confirmação do pedido após o pagamento.', edtEmail);
  Campo('EMAIL').AsString := Email;

  UF := UpperCase(Trim(Campo('UF').AsString));
  Exigir((UF = '') or (cbUF.Properties.Items.IndexOf(UF) >= 0), 'UF inválida.', cbUF);
  if UF = '' then
    Campo('UF').Clear
  else
    Campo('UF').AsString := UF;
end;

end.
