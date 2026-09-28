unit uFrmFila;

/// Monitor da fila de integração: pendentes, processados e erros,
/// com a última mensagem de erro e a próxima tentativa.

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus,
  Data.DB,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxContainer, cxEdit, cxButtons,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, cxDBData, cxGridLevel,
  cxClasses, cxGridCustomView, cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid;

type
  TfrmFila = class(TForm)
    grdFila: TcxGrid;
    tvFila: TcxGridDBTableView;
    lvFila: TcxGridLevel;
    pnlBotoes: TPanel;
    btnAtualizar: TcxButton;
    btnProcessarAgora: TcxButton;
    btnReprocessarErros: TcxButton;
    btnFechar: TcxButton;
    qryFila: TFDQuery;
    dsFila: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAtualizarClick(Sender: TObject);
    procedure btnProcessarAgoraClick(Sender: TObject);
    procedure btnReprocessarErrosClick(Sender: TObject);
    procedure btnFecharClick(Sender: TObject);
  private
    procedure Atualizar;
    procedure VendaAtualizada(AIdVenda: Integer);
  end;

var
  frmFila: TfrmFila;

implementation

{$R *.dfm}

uses
  uConexao, uUtilsDB, uEventos, uFilaIntegracao, uProcessadorFila;

procedure TfrmFila.FormCreate(Sender: TObject);
begin
  qryFila.Connection := Conexao;
  tvFila.DataController.KeyFieldNames := 'ID';
  AssinarVendaAtualizada(VendaAtualizada);
  Atualizar;
end;

procedure TfrmFila.FormDestroy(Sender: TObject);
begin
  CancelarVendaAtualizada(VendaAtualizada);
end;

procedure TfrmFila.VendaAtualizada(AIdVenda: Integer);
begin
  Atualizar;
end;

procedure TfrmFila.Atualizar;
var
  IdAtual, I: Integer;
  Coluna: TcxGridDBColumn;
begin
  IdAtual := 0;
  if qryFila.Active and not qryFila.IsEmpty then
    IdAtual := qryFila.FieldByName('ID').AsInteger;

  tvFila.BeginUpdate;
  try
    qryFila.Close;
    qryFila.Open(
      'SELECT FIRST 500 ID, TIPO, ID_VENDA, STATUS, TENTATIVAS, DATA_CRIACAO, ' +
      '       PROXIMA_TENTATIVA, DATA_PROCESSAMENTO, ULTIMO_ERRO ' +
      'FROM INTEGRACAO_FILA ORDER BY ID DESC');
    DefinirCampo(qryFila, 'ID', 'Nº');
    DefinirCampo(qryFila, 'TIPO', 'Tipo');
    DefinirCampo(qryFila, 'ID_VENDA', 'Venda');
    DefinirCampo(qryFila, 'STATUS', 'Status');
    DefinirCampo(qryFila, 'TENTATIVAS', 'Tentativas');
    DefinirCampo(qryFila, 'DATA_CRIACAO', 'Criado em', 'dd/mm/yyyy hh:nn:ss');
    DefinirCampo(qryFila, 'PROXIMA_TENTATIVA', 'Próxima tentativa', 'dd/mm/yyyy hh:nn:ss');
    DefinirCampo(qryFila, 'DATA_PROCESSAMENTO', 'Processado em', 'dd/mm/yyyy hh:nn:ss');
    DefinirCampo(qryFila, 'ULTIMO_ERRO', 'Último erro');
    if tvFila.ColumnCount = 0 then
    begin
      tvFila.DataController.CreateAllItems;
      for I := 0 to tvFila.ColumnCount - 1 do
      begin
        Coluna := tvFila.Columns[I];
        Coluna.Caption := qryFila.FieldByName(Coluna.DataBinding.FieldName).DisplayLabel;
      end;
      tvFila.ApplyBestFit;
    end;
    if IdAtual > 0 then
      qryFila.Locate('ID', IdAtual, []);
  finally
    tvFila.EndUpdate;
  end;
end;

procedure TfrmFila.btnAtualizarClick(Sender: TObject);
begin
  Atualizar;
end;

procedure TfrmFila.btnProcessarAgoraClick(Sender: TObject);
begin
  if Assigned(ProcessadorFila) then
    ProcessadorFila.Sinalizar;
  MessageDlg('Processamento solicitado. A lista é atualizada automaticamente ao final de cada item.',
    mtInformation, [mbOK], 0);
end;

procedure TfrmFila.btnReprocessarErrosClick(Sender: TObject);
var
  Qtde: Integer;
begin
  Qtde := TFilaIntegracao.ReprocessarErros(Conexao);
  if Assigned(ProcessadorFila) then
    ProcessadorFila.Sinalizar;
  Atualizar;
  MessageDlg(Format('%d item(ns) com erro voltaram para a fila.', [Qtde]), mtInformation, [mbOK], 0);
end;

procedure TfrmFila.btnFecharClick(Sender: TObject);
begin
  Close;
end;

end.
