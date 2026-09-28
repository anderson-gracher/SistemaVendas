unit uFrmVendas;

/// Consulta de vendas e ações do ciclo de vida:
/// Nova / Editar (ou Visualizar) / Excluir / Faturar / Cancelar /
/// Imprimir pedido / Reenviar e-mail.
/// A grade é atualizada automaticamente quando o Financeiro quita/cancela
/// uma venda ou quando a fila conclui uma integração.

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus,
  Data.DB,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer, cxEdit, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, cxCalendar, cxButtons, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxNavigator, cxDBData, cxGridLevel, cxClasses, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid;

type
  TfrmVendas = class(TForm)
    pnlFiltros: TPanel;
    lblPeriodo: TLabel;
    dtDe: TcxDateEdit;
    lblAte: TLabel;
    dtAte: TcxDateEdit;
    lblStatus: TLabel;
    cbStatus: TcxComboBox;
    lblCliente: TLabel;
    edtCliente: TcxTextEdit;
    btnPesquisar: TcxButton;
    grdVendas: TcxGrid;
    tvVendas: TcxGridDBTableView;
    lvVendas: TcxGridLevel;
    pnlBotoes: TPanel;
    btnNova: TcxButton;
    btnEditar: TcxButton;
    btnExcluir: TcxButton;
    btnFaturar: TcxButton;
    btnCancelar: TcxButton;
    btnImprimir: TcxButton;
    btnReenviarEmail: TcxButton;
    btnFechar: TcxButton;
    qryVendas: TFDQuery;
    dsVendas: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnPesquisarClick(Sender: TObject);
    procedure edtClienteKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure tvVendasDblClick(Sender: TObject);
    procedure dsVendasDataChange(Sender: TObject; Field: TField);
    procedure btnNovaClick(Sender: TObject);
    procedure btnEditarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure btnFaturarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure btnReenviarEmailClick(Sender: TObject);
    procedure btnFecharClick(Sender: TObject);
  private
    function IdSelecionado: Integer;
    function StatusSelecionado: string;
    procedure Pesquisar(AIdLocalizar: Integer = 0);
    procedure ConfigurarCampos;
    procedure CriarColunas;
    procedure AtualizarBotoes;
    procedure VendaAtualizada(AIdVenda: Integer);
  end;

var
  frmVendas: TfrmVendas;

implementation

{$R *.dfm}

uses
  System.DateUtils, System.StrUtils,
  uConexao, uExcecoes, uUtilsDB, uEventos, uVendaService, uProcessadorFila,
  uRelatorioPedido, uFrmVendaEdit;

{ TfrmVendas }

procedure TfrmVendas.FormCreate(Sender: TObject);
begin
  qryVendas.Connection := Conexao;
  tvVendas.DataController.KeyFieldNames := 'ID';
  dtDe.Date := StartOfTheMonth(Date);
  dtAte.Date := Date;
  cbStatus.ItemIndex := 0;
  AssinarVendaAtualizada(VendaAtualizada);
  Pesquisar;
end;

procedure TfrmVendas.FormDestroy(Sender: TObject);
begin
  CancelarVendaAtualizada(VendaAtualizada);
end;

procedure TfrmVendas.VendaAtualizada(AIdVenda: Integer);
begin
  Pesquisar(IdSelecionado);
end;

function TfrmVendas.IdSelecionado: Integer;
begin
  if qryVendas.Active and not qryVendas.IsEmpty then
    Result := qryVendas.FieldByName('ID').AsInteger
  else
    Result := 0;
end;

function TfrmVendas.StatusSelecionado: string;
begin
  if qryVendas.Active and not qryVendas.IsEmpty then
    Result := qryVendas.FieldByName('STATUS').AsString
  else
    Result := '';
end;

procedure TfrmVendas.Pesquisar(AIdLocalizar: Integer);
var
  Sql: string;
begin
  if VarIsNull(dtDe.EditValue) or VarIsNull(dtAte.EditValue) then
    raise EValidacao.Create('Informe o período da pesquisa.');

  Sql :=
    'SELECT V.ID, V.DATA_VENDA, C.NOME AS CLIENTE, V.VALOR_TOTAL, V.STATUS, ' +
    '       V.DATA_FATURAMENTO, V.DATA_QUITACAO, V.FORMA_PAGAMENTO, V.EMAIL_ENVIADO ' +
    'FROM VENDA V JOIN CLIENTE C ON C.ID = V.ID_CLIENTE ' +
    'WHERE V.DATA_VENDA >= :DE AND V.DATA_VENDA < :ATE ' +
    '  AND C.NOME CONTAINING CAST(:CLIENTE AS VARCHAR(100)) ';
  if cbStatus.ItemIndex > 0 then
    Sql := Sql + '  AND V.STATUS = :STATUS ';
  Sql := Sql + 'ORDER BY V.ID DESC';

  tvVendas.BeginUpdate;
  try
    qryVendas.Close;
    qryVendas.SQL.Text := Sql;
    qryVendas.ParamByName('DE').AsDateTime := DateOf(dtDe.Date);
    qryVendas.ParamByName('ATE').AsDateTime := DateOf(dtAte.Date) + 1;
    qryVendas.ParamByName('CLIENTE').AsString := Trim(edtCliente.Text);
    if cbStatus.ItemIndex > 0 then
      qryVendas.ParamByName('STATUS').AsString := cbStatus.Text;
    qryVendas.Open;
    ConfigurarCampos;
    if tvVendas.ColumnCount = 0 then
      CriarColunas;
    if AIdLocalizar > 0 then
      qryVendas.Locate('ID', AIdLocalizar, []);
  finally
    tvVendas.EndUpdate;
  end;
  AtualizarBotoes;
end;

procedure TfrmVendas.ConfigurarCampos;
begin
  DefinirCampo(qryVendas, 'ID', 'Nº');
  DefinirCampo(qryVendas, 'DATA_VENDA', 'Data', 'dd/mm/yyyy hh:nn');
  DefinirCampo(qryVendas, 'CLIENTE', 'Cliente');
  DefinirCampo(qryVendas, 'VALOR_TOTAL', 'Total', ',0.00');
  DefinirCampo(qryVendas, 'STATUS', 'Status');
  DefinirCampo(qryVendas, 'DATA_FATURAMENTO', 'Faturada em', 'dd/mm/yyyy hh:nn');
  DefinirCampo(qryVendas, 'DATA_QUITACAO', 'Quitada em', 'dd/mm/yyyy hh:nn');
  DefinirCampo(qryVendas, 'FORMA_PAGAMENTO', 'Forma pgto.');
  DefinirCampo(qryVendas, 'EMAIL_ENVIADO', 'E-mail enviado');
end;

procedure TfrmVendas.CriarColunas;
var
  I: Integer;
  Coluna: TcxGridDBColumn;
  Campo: TField;
  Soma: TcxGridDBTableSummaryItem;
begin
  tvVendas.DataController.CreateAllItems;
  for I := 0 to tvVendas.ColumnCount - 1 do
  begin
    Coluna := tvVendas.Columns[I];
    Campo := qryVendas.FindField(Coluna.DataBinding.FieldName);
    if Assigned(Campo) then
      Coluna.Caption := Campo.DisplayLabel;
  end;

  tvVendas.OptionsView.Footer := True;
  Coluna := tvVendas.GetColumnByFieldName('VALOR_TOTAL');
  if Assigned(Coluna) then
  begin
    Soma := TcxGridDBTableSummaryItem(tvVendas.DataController.Summary.FooterSummaryItems.Add);
    Soma.Column := Coluna;
    Soma.Kind := skSum;
    Soma.Format := ',0.00';
  end;
  tvVendas.ApplyBestFit;
end;

procedure TfrmVendas.AtualizarBotoes;
var
  Status: string;
  Tem: Boolean;
begin
  Status := StatusSelecionado;
  Tem := Status <> '';
  btnEditar.Enabled := Tem;
  btnEditar.Caption := IfThen((Status = STATUS_ABERTA) or not Tem, 'Editar', 'Visualizar');
  btnExcluir.Enabled := Status = STATUS_ABERTA;
  btnFaturar.Enabled := Status = STATUS_ABERTA;
  btnCancelar.Enabled := Status = STATUS_ABERTA;
  btnImprimir.Enabled := Tem;
  btnReenviarEmail.Enabled := Status = STATUS_QUITADA;
end;

procedure TfrmVendas.dsVendasDataChange(Sender: TObject; Field: TField);
begin
  AtualizarBotoes;
end;

procedure TfrmVendas.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_F2: btnNovaClick(nil);
    VK_F5: Pesquisar(IdSelecionado);
    VK_ESCAPE: Close;
  end;
end;

procedure TfrmVendas.btnPesquisarClick(Sender: TObject);
begin
  Pesquisar;
end;

procedure TfrmVendas.edtClienteKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Pesquisar;
    Key := 0;
  end;
end;

procedure TfrmVendas.tvVendasDblClick(Sender: TObject);
begin
  if btnEditar.Enabled then
    btnEditarClick(nil);
end;

procedure TfrmVendas.btnNovaClick(Sender: TObject);
var
  Id: Integer;
begin
  Id := TfrmVendaEdit.Executar(0);
  if Id > 0 then
    Pesquisar(Id);
end;

procedure TfrmVendas.btnEditarClick(Sender: TObject);
var
  Id: Integer;
begin
  Id := IdSelecionado;
  if Id = 0 then
    Exit;
  TfrmVendaEdit.Executar(Id);
  Pesquisar(Id);
end;

procedure TfrmVendas.btnExcluirClick(Sender: TObject);
var
  Id: Integer;
  Servico: TVendaService;
begin
  Id := IdSelecionado;
  if (Id = 0) or (MessageDlg(Format('Excluir a venda nº %d?', [Id]), mtConfirmation,
    [mbYes, mbNo], 0, mbNo) <> mrYes) then
    Exit;
  Servico := TVendaService.Create(Conexao);
  try
    Servico.Excluir(Id);
  finally
    Servico.Free;
  end;
  Pesquisar;
end;

procedure TfrmVendas.btnFaturarClick(Sender: TObject);
var
  Id: Integer;
  Servico: TVendaService;
begin
  Id := IdSelecionado;
  if (Id = 0) or (MessageDlg(Format(
    'Faturar a venda nº %d?' + sLineBreak + sLineBreak +
    'O estoque será baixado e o título será enviado ao ERP Financeiro. ' +
    'Depois disso a venda não poderá mais ser alterada.', [Id]),
    mtConfirmation, [mbYes, mbNo], 0, mbNo) <> mrYes) then
    Exit;

  Servico := TVendaService.Create(Conexao);
  try
    Servico.Faturar(Id);
  finally
    Servico.Free;
  end;
  if Assigned(ProcessadorFila) then
    ProcessadorFila.Sinalizar; // envia ao Financeiro agora, sem esperar o intervalo
  Pesquisar(Id);
end;

procedure TfrmVendas.btnCancelarClick(Sender: TObject);
var
  Id: Integer;
  Motivo: string;
  Servico: TVendaService;
begin
  Id := IdSelecionado;
  if Id = 0 then
    Exit;
  Motivo := '';
  if not InputQuery('Cancelar venda', Format('Motivo do cancelamento da venda nº %d:', [Id]), Motivo) then
    Exit;
  Servico := TVendaService.Create(Conexao);
  try
    Servico.Cancelar(Id, Motivo);
  finally
    Servico.Free;
  end;
  Pesquisar(Id);
end;

procedure TfrmVendas.btnImprimirClick(Sender: TObject);
var
  Relatorio: TRelatorioPedido;
begin
  if IdSelecionado = 0 then
    Exit;
  Relatorio := TRelatorioPedido.Create(Conexao);
  try
    Relatorio.Visualizar(IdSelecionado);
  finally
    Relatorio.Free;
  end;
end;

procedure TfrmVendas.btnReenviarEmailClick(Sender: TObject);
var
  Id: Integer;
  Servico: TVendaService;
begin
  Id := IdSelecionado;
  if Id = 0 then
    Exit;
  Servico := TVendaService.Create(Conexao);
  try
    Servico.ReenviarEmail(Id);
  finally
    Servico.Free;
  end;
  if Assigned(ProcessadorFila) then
    ProcessadorFila.Sinalizar;
  MessageDlg('O e-mail de confirmação foi colocado na fila de envio.', mtInformation, [mbOK], 0);
end;

procedure TfrmVendas.btnFecharClick(Sender: TObject);
begin
  Close;
end;

end.
