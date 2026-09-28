unit uFrmVendaEdit;

/// Edição de uma venda (cabeçalho + itens). Os itens ficam em memória
/// (TFDMemTable) e são gravados de uma vez pelo TVendaService, em transação.
/// Vendas que não estão ABERTAS abrem somente para leitura.

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus,
  Data.DB,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer, cxEdit, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, cxCalendar, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxMemo, cxCurrencyEdit, cxButtons, cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxNavigator, cxDBData, cxGridLevel, cxClasses, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid;

type
  TfrmVendaEdit = class(TForm)
    pnlCabecalho: TPanel;
    lblNumero: TLabel;
    lblCliente: TLabel;
    lcbCliente: TcxLookupComboBox;
    lblData: TLabel;
    dtData: TcxDateEdit;
    lblObservacao: TLabel;
    memObservacao: TcxMemo;
    pnlItem: TPanel;
    lblProduto: TLabel;
    lcbProduto: TcxLookupComboBox;
    lblQuantidade: TLabel;
    edtQuantidade: TcxCurrencyEdit;
    lblPreco: TLabel;
    edtPreco: TcxCurrencyEdit;
    btnAdicionar: TcxButton;
    btnRemover: TcxButton;
    grdItens: TcxGrid;
    tvItens: TcxGridDBTableView;
    lvItens: TcxGridLevel;
    pnlRodape: TPanel;
    lblTotalTitulo: TLabel;
    lblTotal: TLabel;
    btnSalvar: TcxButton;
    btnCancelar: TcxButton;
    qryClientes: TFDQuery;
    dsClientes: TDataSource;
    qryProdutos: TFDQuery;
    dsProdutos: TDataSource;
    mtItens: TFDMemTable;
    dsItens: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure lcbProdutoPropertiesEditValueChanged(Sender: TObject);
    procedure btnAdicionarClick(Sender: TObject);
    procedure btnRemoverClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
  private
    FIdVenda: Integer;
    FSomenteLeitura: Boolean;
    procedure CriarEstruturaItens;
    procedure Carregar(AIdVenda: Integer);
    procedure AplicarModo(const AStatus: string);
    procedure AtualizarTotal;
    procedure LimparItem;
  public
    /// Abre a tela. AIdVenda = 0 cria uma venda nova.
    /// Retorna o ID gravado ou 0 se o usuário cancelou.
    class function Executar(AIdVenda: Integer): Integer;
  end;

var
  frmVendaEdit: TfrmVendaEdit;

implementation

{$R *.dfm}

uses
  System.Math, uConexao, uExcecoes, uUtilsDB, uVendaService;

function SemValor(const AValor: Variant): Boolean;
begin
  Result := VarIsNull(AValor) or VarIsEmpty(AValor);
end;

class function TfrmVendaEdit.Executar(AIdVenda: Integer): Integer;
var
  Form: TfrmVendaEdit;
begin
  Result := 0;
  Form := TfrmVendaEdit.Create(nil);
  try
    Form.Carregar(AIdVenda);
    if Form.ShowModal = mrOk then
      Result := Form.FIdVenda;
  finally
    Form.Free;
  end;
end;

procedure TfrmVendaEdit.FormCreate(Sender: TObject);
begin
  qryClientes.Connection := Conexao;
  qryProdutos.Connection := Conexao;

  lcbCliente.Properties.ListSource := dsClientes;
  lcbCliente.Properties.KeyFieldNames := 'ID';
  lcbCliente.Properties.ListFieldNames := 'NOME;DOCUMENTO';
  lcbCliente.Properties.ListFieldIndex := 0;
  lcbCliente.Properties.DropDownWidth := 520;

  lcbProduto.Properties.ListSource := dsProdutos;
  lcbProduto.Properties.KeyFieldNames := 'ID';
  lcbProduto.Properties.ListFieldNames := 'DESCRICAO;UNIDADE;PRECO;ESTOQUE';
  lcbProduto.Properties.ListFieldIndex := 0;
  lcbProduto.Properties.DropDownWidth := 600;

  qryProdutos.Open('SELECT ID, DESCRICAO, UNIDADE, PRECO, ESTOQUE FROM PRODUTO ' +
    'WHERE ATIVO = TRUE ORDER BY DESCRICAO');
  DefinirCampo(qryProdutos, 'DESCRICAO', 'Produto');
  DefinirCampo(qryProdutos, 'UNIDADE', 'Un.');
  DefinirCampo(qryProdutos, 'PRECO', 'Preço', ',0.00');
  DefinirCampo(qryProdutos, 'ESTOQUE', 'Estoque', ',0.###');

  edtQuantidade.Properties.DecimalPlaces := 3;
  edtQuantidade.Properties.DisplayFormat := ',0.###';
  edtPreco.Properties.DecimalPlaces := 2;
  edtPreco.Properties.DisplayFormat := ',0.00';

  CriarEstruturaItens;
  LimparItem;
end;

procedure TfrmVendaEdit.CriarEstruturaItens;
var
  Soma: TcxGridDBTableSummaryItem;
  I: Integer;
  Coluna: TcxGridDBColumn;
begin
  mtItens.Close;
  mtItens.FieldDefs.Clear;
  mtItens.FieldDefs.Add('ID_PRODUTO', ftInteger);
  mtItens.FieldDefs.Add('DESCRICAO', ftWideString, 100);
  mtItens.FieldDefs.Add('UNIDADE', ftWideString, 6);
  mtItens.FieldDefs.Add('QUANTIDADE', ftFloat);
  mtItens.FieldDefs.Add('VALOR_UNITARIO', ftCurrency);
  mtItens.FieldDefs.Add('VALOR_TOTAL', ftCurrency);
  mtItens.CreateDataSet;

  TCurrencyField(mtItens.FieldByName('VALOR_UNITARIO')).Currency := False;
  TCurrencyField(mtItens.FieldByName('VALOR_TOTAL')).Currency := False;
  DefinirCampo(mtItens, 'ID_PRODUTO', 'Cód.');
  DefinirCampo(mtItens, 'DESCRICAO', 'Produto');
  DefinirCampo(mtItens, 'UNIDADE', 'Un.');
  DefinirCampo(mtItens, 'QUANTIDADE', 'Quantidade', ',0.###');
  DefinirCampo(mtItens, 'VALOR_UNITARIO', 'Vl. unitário', ',0.00');
  DefinirCampo(mtItens, 'VALOR_TOTAL', 'Total', ',0.00');

  tvItens.DataController.CreateAllItems;
  for I := 0 to tvItens.ColumnCount - 1 do
  begin
    Coluna := tvItens.Columns[I];
    Coluna.Caption := mtItens.FieldByName(Coluna.DataBinding.FieldName).DisplayLabel;
  end;
  tvItens.OptionsView.Footer := True;
  Soma := TcxGridDBTableSummaryItem(tvItens.DataController.Summary.FooterSummaryItems.Add);
  Soma.Column := tvItens.GetColumnByFieldName('VALOR_TOTAL');
  Soma.Kind := skSum;
  Soma.Format := ',0.00';
  tvItens.GetColumnByFieldName('DESCRICAO').Width := 360;
end;

procedure TfrmVendaEdit.Carregar(AIdVenda: Integer);
var
  Qry: TFDQuery;
  Status: string;
  IdCliente: Integer;
begin
  FIdVenda := AIdVenda;
  Status := STATUS_ABERTA;
  IdCliente := 0;

  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := Conexao;
    if AIdVenda > 0 then
    begin
      Qry.Open('SELECT ID_CLIENTE, DATA_VENDA, OBSERVACAO, STATUS FROM VENDA WHERE ID = :ID', [AIdVenda]);
      if Qry.IsEmpty then
        raise ENaoEncontrado.CreateFmt('Venda %d não encontrada.', [AIdVenda]);
      IdCliente := Qry.FieldByName('ID_CLIENTE').AsInteger;
      dtData.Date := Qry.FieldByName('DATA_VENDA').AsDateTime;
      memObservacao.Text := Qry.FieldByName('OBSERVACAO').AsString;
      Status := Qry.FieldByName('STATUS').AsString;
      Qry.Close;

      Qry.Open(
        'SELECT I.ID_PRODUTO, P.DESCRICAO, P.UNIDADE, I.QUANTIDADE, I.VALOR_UNITARIO, I.VALOR_TOTAL ' +
        'FROM VENDA_ITEM I JOIN PRODUTO P ON P.ID = I.ID_PRODUTO ' +
        'WHERE I.ID_VENDA = :ID ORDER BY I.ID', [AIdVenda]);
      mtItens.DisableControls;
      try
        while not Qry.Eof do
        begin
          mtItens.Append;
          mtItens.FieldByName('ID_PRODUTO').AsInteger := Qry.FieldByName('ID_PRODUTO').AsInteger;
          mtItens.FieldByName('DESCRICAO').AsString := Qry.FieldByName('DESCRICAO').AsString;
          mtItens.FieldByName('UNIDADE').AsString := Qry.FieldByName('UNIDADE').AsString;
          mtItens.FieldByName('QUANTIDADE').AsFloat := Qry.FieldByName('QUANTIDADE').AsFloat;
          mtItens.FieldByName('VALOR_UNITARIO').AsCurrency := Qry.FieldByName('VALOR_UNITARIO').AsCurrency;
          mtItens.FieldByName('VALOR_TOTAL').AsCurrency := Qry.FieldByName('VALOR_TOTAL').AsCurrency;
          mtItens.Post;
          Qry.Next;
        end;
        mtItens.First;
      finally
        mtItens.EnableControls;
      end;
    end
    else
      dtData.Date := Now;
  finally
    Qry.Free;
  end;

  // Clientes ativos + o cliente atual da venda (mesmo que inativo)
  qryClientes.Close;
  qryClientes.Open('SELECT ID, NOME, CPF_CNPJ AS DOCUMENTO FROM CLIENTE ' +
    'WHERE ATIVO = TRUE OR ID = :ID ORDER BY NOME', [IdCliente]);
  DefinirCampo(qryClientes, 'NOME', 'Cliente');
  DefinirCampo(qryClientes, 'DOCUMENTO', 'CPF/CNPJ');
  if IdCliente > 0 then
    lcbCliente.EditValue := IdCliente;

  AplicarModo(Status);
  AtualizarTotal;
end;

procedure TfrmVendaEdit.AplicarModo(const AStatus: string);
begin
  FSomenteLeitura := AStatus <> STATUS_ABERTA;
  if FIdVenda = 0 then
    lblNumero.Caption := 'Nova venda'
  else
    lblNumero.Caption := Format('Venda nº %d  -  %s', [FIdVenda, AStatus]);

  if FSomenteLeitura then
  begin
    lblNumero.Caption := lblNumero.Caption + '  (somente leitura)';
    lcbCliente.Properties.ReadOnly := True;
    dtData.Properties.ReadOnly := True;
    memObservacao.Properties.ReadOnly := True;
    pnlItem.Visible := False;
    btnSalvar.Visible := False;
    btnCancelar.Caption := 'Fechar';
  end;
  Caption := lblNumero.Caption;
end;

procedure TfrmVendaEdit.LimparItem;
begin
  lcbProduto.EditValue := Null;
  edtQuantidade.Value := 1;
  edtPreco.Value := 0;
end;

procedure TfrmVendaEdit.AtualizarTotal;
var
  Total: Currency;
  Marca: TBookmark;
begin
  Total := 0;
  mtItens.DisableControls;
  Marca := mtItens.GetBookmark;
  try
    mtItens.First;
    while not mtItens.Eof do
    begin
      Total := Total + mtItens.FieldByName('VALOR_TOTAL').AsCurrency;
      mtItens.Next;
    end;
    if mtItens.BookmarkValid(Marca) then
      mtItens.GotoBookmark(Marca);
  finally
    mtItens.FreeBookmark(Marca);
    mtItens.EnableControls;
  end;
  lblTotal.Caption := 'R$ ' + FormatFloat('#,##0.00', Total);
end;

procedure TfrmVendaEdit.lcbProdutoPropertiesEditValueChanged(Sender: TObject);
begin
  if SemValor(lcbProduto.EditValue) then
    Exit;
  if qryProdutos.Locate('ID', lcbProduto.EditValue, []) then
    edtPreco.Value := qryProdutos.FieldByName('PRECO').AsCurrency;
  if edtQuantidade.Value <= 0 then
    edtQuantidade.Value := 1;
end;

procedure TfrmVendaEdit.btnAdicionarClick(Sender: TObject);
var
  IdProduto: Integer;
  Quantidade, Estoque: Double;
  Preco: Currency;
begin
  if SemValor(lcbProduto.EditValue) then
  begin
    lcbProduto.SetFocus;
    raise EValidacao.Create('Selecione o produto.');
  end;
  IdProduto := lcbProduto.EditValue;
  Quantidade := edtQuantidade.Value;
  Preco := edtPreco.Value;
  if Quantidade <= 0 then
  begin
    edtQuantidade.SetFocus;
    raise EValidacao.Create('A quantidade deve ser maior que zero.');
  end;
  if Preco <= 0 then
  begin
    edtPreco.SetFocus;
    raise EValidacao.Create('O preço deve ser maior que zero.');
  end;
  if not qryProdutos.Locate('ID', IdProduto, []) then
    raise ENaoEncontrado.Create('Produto não encontrado ou inativo.');
  Estoque := qryProdutos.FieldByName('ESTOQUE').AsFloat;

  // Mesmo produto duas vezes: soma a quantidade na linha existente
  if mtItens.Locate('ID_PRODUTO', IdProduto, []) then
  begin
    mtItens.Edit;
    mtItens.FieldByName('QUANTIDADE').AsFloat := mtItens.FieldByName('QUANTIDADE').AsFloat + Quantidade;
  end
  else
  begin
    mtItens.Append;
    mtItens.FieldByName('ID_PRODUTO').AsInteger := IdProduto;
    mtItens.FieldByName('DESCRICAO').AsString := qryProdutos.FieldByName('DESCRICAO').AsString;
    mtItens.FieldByName('UNIDADE').AsString := qryProdutos.FieldByName('UNIDADE').AsString;
    mtItens.FieldByName('QUANTIDADE').AsFloat := Quantidade;
  end;
  mtItens.FieldByName('VALOR_UNITARIO').AsCurrency := Preco;
  mtItens.FieldByName('VALOR_TOTAL').AsCurrency :=
    SimpleRoundTo(mtItens.FieldByName('QUANTIDADE').AsFloat * Preco, -2);
  mtItens.Post;

  if mtItens.FieldByName('QUANTIDADE').AsFloat > Estoque then
    MessageDlg(Format('Atenção: a quantidade é maior que o estoque atual (%s). ' +
      'A venda pode ser salva, mas o faturamento será bloqueado enquanto não houver saldo.',
      [FormatFloat(',0.###', Estoque)]), mtWarning, [mbOK], 0);

  LimparItem;
  AtualizarTotal;
  lcbProduto.SetFocus;
end;

procedure TfrmVendaEdit.btnRemoverClick(Sender: TObject);
begin
  if mtItens.IsEmpty then
    Exit;
  mtItens.Delete;
  AtualizarTotal;
end;

procedure TfrmVendaEdit.btnSalvarClick(Sender: TObject);
var
  Servico: TVendaService;
begin
  if SemValor(lcbCliente.EditValue) then
  begin
    lcbCliente.SetFocus;
    raise EValidacao.Create('Selecione o cliente.');
  end;
  if VarIsNull(dtData.EditValue) then
  begin
    dtData.SetFocus;
    raise EValidacao.Create('Informe a data da venda.');
  end;
  if mtItens.IsEmpty then
    raise EValidacao.Create('Adicione ao menos um item à venda.');

  Servico := TVendaService.Create(Conexao);
  try
    FIdVenda := Servico.Salvar(FIdVenda, lcbCliente.EditValue, dtData.Date, Trim(memObservacao.Text), mtItens);
  finally
    Servico.Free;
  end;
  ModalResult := mrOk;
end;

end.
