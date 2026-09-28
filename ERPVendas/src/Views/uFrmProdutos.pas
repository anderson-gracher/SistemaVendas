unit uFrmProdutos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus,
  Data.DB,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer, cxEdit, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, cxCheckBox, cxCurrencyEdit, cxDBEdit, cxButtons, cxPC,
  dxBarBuiltInMenu, cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, cxDBData,
  cxGridLevel, cxClasses, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid,
  uFrmCadastroBase;

type
  TfrmProdutos = class(TfrmCadastroBase)
    lblCodigo: TLabel;
    edtCodigo: TcxDBTextEdit;
    lblDescricao: TLabel;
    edtDescricao: TcxDBTextEdit;
    chkAtivo: TcxDBCheckBox;
    lblUnidade: TLabel;
    cbUnidade: TcxDBComboBox;
    lblPreco: TLabel;
    edtPreco: TcxDBCurrencyEdit;
    lblEstoque: TLabel;
    edtEstoque: TcxDBCurrencyEdit;
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
  frmProdutos: TfrmProdutos;

implementation

{$R *.dfm}

uses
  uUtilsDB;

function TfrmProdutos.NomeTabela: string;
begin
  Result := 'PRODUTO';
end;

function TfrmProdutos.NomeGenerator: string;
begin
  Result := 'GEN_PRODUTO_ID';
end;

function TfrmProdutos.SqlConsulta: string;
begin
  Result := 'SELECT ID, DESCRICAO, UNIDADE, PRECO, ESTOQUE, ATIVO, DATA_CADASTRO FROM PRODUTO';
end;

function TfrmProdutos.FiltroPesquisa: string;
begin
  Result := 'DESCRICAO CONTAINING CAST(:PESQ AS VARCHAR(100))';
end;

function TfrmProdutos.OrdemConsulta: string;
begin
  Result := 'DESCRICAO';
end;

procedure TfrmProdutos.PrepararTela;
begin
  cbUnidade.Properties.Items.CommaText := 'UN,PC,CX,KG,G,LT,ML,M';
end;

procedure TfrmProdutos.ConfigurarCampos;
begin
  inherited;
  DefinirCampo(qryDados, 'DESCRICAO', 'Descrição');
  DefinirCampo(qryDados, 'UNIDADE', 'Unidade');
  DefinirCampo(qryDados, 'PRECO', 'Preço', ',0.00');
  DefinirCampo(qryDados, 'ESTOQUE', 'Estoque', ',0.###');
  DefinirCampo(qryDados, 'ATIVO', 'Ativo');
  DefinirCampo(qryDados, 'DATA_CADASTRO', 'Cadastrado em', 'dd/mm/yyyy');
end;

procedure TfrmProdutos.AoNovoRegistro;
begin
  Campo('UNIDADE').AsString := 'UN';
  Campo('PRECO').AsCurrency := 0;
  Campo('ESTOQUE').AsFloat := 0;
  Campo('ATIVO').AsBoolean := True;
  Campo('DATA_CADASTRO').AsDateTime := Now;
end;

procedure TfrmProdutos.FocarPrimeiroCampo;
begin
  if edtDescricao.CanFocus then
    edtDescricao.SetFocus;
end;

procedure TfrmProdutos.ValidarRegistro;
begin
  inherited;
  Campo('DESCRICAO').AsString := Trim(Campo('DESCRICAO').AsString);
  Exigir(Length(Campo('DESCRICAO').AsString) >= 3,
    'Informe a descrição do produto (mínimo de 3 caracteres).', edtDescricao);
  Campo('UNIDADE').AsString := UpperCase(Trim(Campo('UNIDADE').AsString));
  Exigir(Campo('UNIDADE').AsString <> '', 'Informe a unidade de medida.', cbUnidade);
  Exigir(Campo('PRECO').AsCurrency > 0, 'O preço deve ser maior que zero.', edtPreco);
  Exigir(Campo('ESTOQUE').AsFloat >= 0, 'O estoque não pode ser negativo.', edtEstoque);
end;

end.
