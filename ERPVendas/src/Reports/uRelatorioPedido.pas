unit uRelatorioPedido;

/// Relatório de confirmação de pedido

interface

uses
  System.SysUtils, System.Classes, Data.DB, FireDAC.Comp.Client,
  ppClass, ppComm, ppRelatv, ppProd, ppReport, ppBands, ppCache, ppPrnabl,
  ppCtrls, ppDB, ppDBPipe, ppVar, ppTypes;

type
  TRelatorioPedido = class
  private
    FConexao: TFDConnection;
    FQryCabecalho: TFDQuery;
    FQryItens: TFDQuery;
    FDsItens: TDataSource;
    FPipeline: TppDBPipeline;
    FReport: TppReport;
    procedure CarregarDados(AIdVenda: Integer);
    procedure MontarLayout;
    procedure Preparar(AIdVenda: Integer);
    function Rotulo(ABanda: TppBand; const ATexto: string; AEsquerda, ATopo, ALargura: Single;
      ATamanho: Integer = 9; ANegrito: Boolean = False;
      AAlinhamento: TppTextAlignment = taLeftJustified): TppLabel;
    function CampoItem(const ACampo: string; AEsquerda, ALargura: Single;
      const AFormato: string = ''; AAlinhamento: TppTextAlignment = taLeftJustified): TppDBText;
    procedure Linha(ABanda: TppBand; ATopo: Single);
  public
    constructor Create(AConexao: TFDConnection);
    destructor Destroy; override;
    procedure Visualizar(AIdVenda: Integer);
    procedure ExportarPDF(AIdVenda: Integer; const AArquivo: string);
    /// Gera o PDF usando uma conexão própria. Chamar na thread principal.
    class procedure GerarPDF(AIdVenda: Integer; const AArquivo: string);
  end;

implementation

uses
  System.UITypes, Vcl.Graphics, Vcl.Forms,
  FireDAC.Stan.Param, uConexao, uConfig, uExcecoes, uValidacoes, uVendaService;

const
  LARGURA_UTIL = 190;
  COL_CODIGO = 0;
  COL_DESCRICAO = 16;
  COL_UNIDADE = 106;
  COL_QUANTIDADE = 118;
  COL_UNITARIO = 142;
  COL_TOTAL = 166;

function DescricaoStatus(const AStatus: string): string;
begin
  if AStatus = STATUS_ABERTA then Result := 'Em aberto'
  else if AStatus = STATUS_FATURADA then Result := 'Aguardando pagamento'
  else if AStatus = STATUS_QUITADA then Result := 'Pago'
  else if AStatus = STATUS_CANCELADA then Result := 'Cancelado'
  else Result := AStatus;
end;

{ TRelatorioPedido }

constructor TRelatorioPedido.Create(AConexao: TFDConnection);
begin
  inherited Create;
  FConexao := AConexao;
  FQryCabecalho := TFDQuery.Create(nil);
  FQryCabecalho.Connection := FConexao;
  FQryItens := TFDQuery.Create(nil);
  FQryItens.Connection := FConexao;
  FDsItens := TDataSource.Create(nil);
  FDsItens.DataSet := FQryItens;
  FPipeline := TppDBPipeline.Create(nil);
  FPipeline.DataSource := FDsItens;
  FPipeline.UserName := 'Itens';
end;

destructor TRelatorioPedido.Destroy;
begin
  FReport.Free;
  FPipeline.Free;
  FDsItens.Free;
  FQryItens.Free;
  FQryCabecalho.Free;
  inherited;
end;

procedure TRelatorioPedido.CarregarDados(AIdVenda: Integer);
begin
  FQryCabecalho.Close;
  FQryCabecalho.Open(
    'SELECT V.ID, V.DATA_VENDA, V.STATUS, V.VALOR_TOTAL, V.OBSERVACAO, V.DATA_QUITACAO, ' +
    '       V.VALOR_PAGO, V.FORMA_PAGAMENTO, C.NOME, C.CPF_CNPJ, C.EMAIL, C.TELEFONE, C.CIDADE, C.UF ' +
    'FROM VENDA V JOIN CLIENTE C ON C.ID = V.ID_CLIENTE WHERE V.ID = :ID', [AIdVenda]);
  if FQryCabecalho.IsEmpty then
    raise ENaoEncontrado.CreateFmt('Venda %d não encontrada.', [AIdVenda]);

  FQryItens.Close;
  FQryItens.Open(
    'SELECT I.ID_PRODUTO, P.DESCRICAO, P.UNIDADE, I.QUANTIDADE, I.VALOR_UNITARIO, I.VALOR_TOTAL ' +
    'FROM VENDA_ITEM I JOIN PRODUTO P ON P.ID = I.ID_PRODUTO ' +
    'WHERE I.ID_VENDA = :ID ORDER BY I.ID', [AIdVenda]);
end;

function TRelatorioPedido.Rotulo(ABanda: TppBand; const ATexto: string; AEsquerda, ATopo,
  ALargura: Single; ATamanho: Integer; ANegrito: Boolean; AAlinhamento: TppTextAlignment): TppLabel;
begin
  Result := TppLabel.Create(FReport);
  Result.Band := ABanda;
  Result.AutoSize := False;
  Result.Caption := ATexto;
  Result.Font.Name := 'Arial';
  Result.Font.Size := ATamanho;
  if ANegrito then
    Result.Font.Style := [fsBold]
  else
    Result.Font.Style := [];
  Result.TextAlignment := AAlinhamento;
  Result.Left := AEsquerda;
  Result.Top := ATopo;
  Result.Width := ALargura;
  Result.Height := ATamanho * 0.5;
end;

function TRelatorioPedido.CampoItem(const ACampo: string; AEsquerda, ALargura: Single;
  const AFormato: string; AAlinhamento: TppTextAlignment): TppDBText;
begin
  Result := TppDBText.Create(FReport);
  Result.Band := FReport.DetailBand;
  Result.DataPipeline := FPipeline;
  Result.DataField := ACampo;
  Result.AutoSize := False;
  Result.DisplayFormat := AFormato;
  Result.TextAlignment := AAlinhamento;
  Result.Font.Name := 'Arial';
  Result.Font.Size := 9;
  Result.Left := AEsquerda;
  Result.Top := 0.5;
  Result.Width := ALargura;
  Result.Height := 4.5;
end;

procedure TRelatorioPedido.Linha(ABanda: TppBand; ATopo: Single);
var
  L: TppLine;
begin
  L := TppLine.Create(FReport);
  L.Band := ABanda;
  L.Left := 0;
  L.Top := ATopo;
  L.Width := LARGURA_UTIL;
  L.Height := 1;
  L.Weight := 0.75;
end;

procedure TRelatorioPedido.MontarLayout;
var
  Q: TFDQuery;
  Cabecalho: TppHeaderBand;
  Resumo: TppSummaryBand;
  Rodape: TppFooterBand;
  Soma: TppDBCalc;
  Pagina: TppSystemVariable;
  CidadeUF, Obs, Pagamento: string;
  Y: Single;
begin
  Q := FQryCabecalho;

  FReport := TppReport.Create(nil);
  FReport.Units := utMillimeters;
  FReport.PrinterSetup.PaperName := 'A4';
  FReport.DataPipeline := FPipeline;
  FReport.ShowPrintDialog := False;
  FReport.ShowCancelDialog := False;
  FReport.CreateDefaultBands;

  Cabecalho := FReport.HeaderBand;
  Cabecalho.Height := 72;
  FReport.DetailBand.Height := 5.5;
  Rodape := FReport.FooterBand;
  Rodape.Height := 10;
  Resumo := TppSummaryBand.Create(FReport);
  FReport.AddBand(Resumo);
  Resumo.Height := 32;

  // ---------- Cabeçalho ----------
  Rotulo(Cabecalho, TConfig.Instancia.EmpresaNome, 0, 0, 110, 14, True);
  Rotulo(Cabecalho, 'CONFIRMAÇÃO DE PEDIDO', 110, 0, 80, 12, True, taRightJustified);
  Rotulo(Cabecalho, Format('Pedido nº %d', [Q.FieldByName('ID').AsInteger]), 110, 7, 80, 10, True,
    taRightJustified);
  Rotulo(Cabecalho, 'Data: ' + FormatDateTime('dd/mm/yyyy hh:nn', Q.FieldByName('DATA_VENDA').AsDateTime),
    110, 12.5, 80, 9, False, taRightJustified);
  Linha(Cabecalho, 19);

  Rotulo(Cabecalho, 'DADOS DO CLIENTE', 0, 22, LARGURA_UTIL, 9, True);
  Rotulo(Cabecalho, 'Nome: ' + Q.FieldByName('NOME').AsString, 0, 28, 120);
  Rotulo(Cabecalho, 'CPF/CNPJ: ' + FormatarDocumento(Q.FieldByName('CPF_CNPJ').AsString), 122, 28, 68);
  Rotulo(Cabecalho, 'E-mail: ' + Q.FieldByName('EMAIL').AsString, 0, 33, 120);
  Rotulo(Cabecalho, 'Telefone: ' + Q.FieldByName('TELEFONE').AsString, 122, 33, 68);
  CidadeUF := Q.FieldByName('CIDADE').AsString;
  if Trim(Q.FieldByName('UF').AsString) <> '' then
    CidadeUF := CidadeUF + ' / ' + Trim(Q.FieldByName('UF').AsString);
  Rotulo(Cabecalho, 'Cidade/UF: ' + CidadeUF, 0, 38, 120);
  Rotulo(Cabecalho, 'Situação: ' + DescricaoStatus(Q.FieldByName('STATUS').AsString), 122, 38, 68, 9, True);
  Linha(Cabecalho, 44);

  Y := 47;
  if Q.FieldByName('STATUS').AsString = STATUS_QUITADA then
  begin
    Pagamento := Format('Pagamento confirmado em %s - R$ %s', [
      FormatDateTime('dd/mm/yyyy', Q.FieldByName('DATA_QUITACAO').AsDateTime),
      FormatFloat('#,##0.00', Q.FieldByName('VALOR_PAGO').AsCurrency)]);
    if Q.FieldByName('FORMA_PAGAMENTO').AsString <> '' then
      Pagamento := Pagamento + ' (' + Q.FieldByName('FORMA_PAGAMENTO').AsString + ')';
    Rotulo(Cabecalho, Pagamento, 0, Y, LARGURA_UTIL, 10, True);
  end;

  // Títulos das colunas
  Rotulo(Cabecalho, 'Código', COL_CODIGO, 63, 15, 9, True);
  Rotulo(Cabecalho, 'Descrição', COL_DESCRICAO, 63, 88, 9, True);
  Rotulo(Cabecalho, 'Un.', COL_UNIDADE, 63, 11, 9, True);
  Rotulo(Cabecalho, 'Qtde.', COL_QUANTIDADE, 63, 22, 9, True, taRightJustified);
  Rotulo(Cabecalho, 'Vl. unit.', COL_UNITARIO, 63, 22, 9, True, taRightJustified);
  Rotulo(Cabecalho, 'Total', COL_TOTAL, 63, 24, 9, True, taRightJustified);
  Linha(Cabecalho, 69);

  // ---------- Itens ----------
  CampoItem('ID_PRODUTO', COL_CODIGO, 15);
  CampoItem('DESCRICAO', COL_DESCRICAO, 88);
  CampoItem('UNIDADE', COL_UNIDADE, 11);
  CampoItem('QUANTIDADE', COL_QUANTIDADE, 22, '#,##0.###', taRightJustified);
  CampoItem('VALOR_UNITARIO', COL_UNITARIO, 22, '#,##0.00', taRightJustified);
  CampoItem('VALOR_TOTAL', COL_TOTAL, 24, '#,##0.00', taRightJustified);

  // ---------- Resumo (final do relatório) ----------
  Linha(Resumo, 1);
  Rotulo(Resumo, 'TOTAL DO PEDIDO', 96, 4, 60, 11, True, taRightJustified);
  Soma := TppDBCalc.Create(FReport);
  Soma.Band := Resumo;
  Soma.DataPipeline := FPipeline;
  Soma.DataField := 'VALOR_TOTAL';
  Soma.DBCalcType := dcSum;
  Soma.DisplayFormat := 'R$ #,##0.00';
  Soma.AutoSize := False;
  Soma.TextAlignment := taRightJustified;
  Soma.Font.Name := 'Arial';
  Soma.Font.Size := 11;
  Soma.Font.Style := [fsBold];
  Soma.Left := 156;
  Soma.Top := 4;
  Soma.Width := 34;
  Soma.Height := 5.5;

  Obs := Trim(Q.FieldByName('OBSERVACAO').AsString);
  if Obs <> '' then
    Rotulo(Resumo, 'Observações: ' + Obs, 0, 13, LARGURA_UTIL).WordWrap := True;

  // ---------- Rodapé ----------
  Linha(Rodape, 1);
  Rotulo(Rodape, 'Documento gerado pelo ERP Vendas em ' + FormatDateTime('dd/mm/yyyy hh:nn', Now),
    0, 3, 140, 7);
  Rotulo(Rodape, 'Página', 160, 3, 18, 7, False, taRightJustified);
  Pagina := TppSystemVariable.Create(FReport);
  Pagina.Band := Rodape;
  Pagina.VarType := vtPageNo;
  Pagina.AutoSize := False;
  Pagina.TextAlignment := taRightJustified;
  Pagina.Font.Name := 'Arial';
  Pagina.Font.Size := 7;
  Pagina.Left := 179;
  Pagina.Top := 3;
  Pagina.Width := 11;
  Pagina.Height := 3.5;
end;

procedure TRelatorioPedido.Preparar(AIdVenda: Integer);
begin
  FreeAndNil(FReport);
  CarregarDados(AIdVenda);
  MontarLayout;
end;

procedure TRelatorioPedido.Visualizar(AIdVenda: Integer);
begin
  Preparar(AIdVenda);
  FReport.DeviceType := 'Screen';
  FReport.PreviewFormSettings.WindowState := wsMaximized;
  FReport.PreviewFormSettings.ZoomSetting := zsPageWidth;
  FReport.Print;
end;

procedure TRelatorioPedido.ExportarPDF(AIdVenda: Integer; const AArquivo: string);
begin
  Preparar(AIdVenda);
  ForceDirectories(ExtractFilePath(AArquivo));
  FReport.AllowPrintToFile := True;
  FReport.DeviceType := 'PDF';
  FReport.TextFileName := AArquivo;
  FReport.PDFSettings.OpenPDFFile := False;
  FReport.PDFSettings.Title := Format('Pedido %d', [AIdVenda]);
  FReport.Print;
end;

class procedure TRelatorioPedido.GerarPDF(AIdVenda: Integer; const AArquivo: string);
var
  Conn: TFDConnection;
  Relatorio: TRelatorioPedido;
begin
  Conn := NovaConexao(True);
  try
    Relatorio := TRelatorioPedido.Create(Conn);
    try
      Relatorio.ExportarPDF(AIdVenda, AArquivo);
    finally
      Relatorio.Free;
    end;
  finally
    Conn.Free;
  end;
end;

end.
