unit uProcessadorFila;

/// Integração de fila
///  - ENVIAR_TITULO: POST do título no ERP Financeiro;
///  - ENVIAR_EMAIL : gera o PDF do pedido e envia ao cliente.
///
/// Falhas transitórias são reprocessadas com backoff exponencial
/// (1, 2, 4, 8, 16 e no máximo 30 min) até FilaMaxTentativas; falhas
/// definitivas (dados recusados) vão direto para ERRO. Itens em ERRO podem
/// ser reprocessados pela tela "Fila de integração".

interface

uses System.Classes, System.SyncObjs, FireDAC.Comp.Client;

type
  
  TProcessadorFila = class(TThread)
  private
    
	FSinal: TEvent;
    procedure ProcessarPendentes;
    procedure ProcessarItem(AConexao: TFDConnection; AIdFila: Integer; const ATipo: string; AIdVenda, ATentativas: Integer);
    procedure EnviarTitulo(AConexao: TFDConnection; AIdVenda: Integer);
    procedure EnviarEmail(AConexao: TFDConnection; AIdVenda: Integer);
  protected
    
	procedure Execute; override;
  public
    
	constructor Create;
    destructor Destroy; override;    
    procedure Sinalizar;
  end;

var ProcessadorFila: TProcessadorFila;

implementation

uses
  System.SysUtils, System.Math, System.DateUtils, System.IOUtils, System.StrUtils,
  System.NetEncoding, System.Generics.Collections, FireDAC.Stan.Param,
  uConfig, uConexao, uLog, uExcecoes, uEventos, uFilaIntegracao, uVendaService,
  uFinanceiroClient, uEmailService, uRelatorioPedido;

type
  TItemFila = record
    Id: Integer;
    Tipo: string;
    IdVenda: Integer;
    Tentativas: Integer;
  end;

function HtmlConfirmacao(const ANome: string; AIdVenda: Integer; AValorPago: Currency;
  ADataPagamento: TDateTime; const AForma, AEmpresa: string): string;
begin
  Result :=
    '<html><body style="font-family:Arial,Helvetica,sans-serif;color:#333;font-size:14px">' +
    '<h2 style="color:#294A70">Pagamento confirmado!</h2>' +
    '<p>Olá, ' + TNetEncoding.HTML.Encode(ANome) + '.</p>' +
    Format('<p>Recebemos o pagamento do seu pedido <b>nº %d</b>.</p>', [AIdVenda]) +
    '<table cellpadding="4" style="border-collapse:collapse">' +
    '<tr><td>Valor pago:</td><td><b>R$ ' + FormatFloat('#,##0.00', AValorPago) + '</b></td></tr>' +
    '<tr><td>Data do pagamento:</td><td>' + FormatDateTime('dd/mm/yyyy', ADataPagamento) + '</td></tr>' +
    '<tr><td>Forma de pagamento:</td><td>' +
      TNetEncoding.HTML.Encode(IfThen(AForma = '', '-', AForma)) + '</td></tr>' +
    '</table>' +
    '<p>A confirmação do pedido segue em anexo (PDF).</p>' +
    '<p>Obrigado pela preferência!<br><b>' + TNetEncoding.HTML.Encode(AEmpresa) + '</b></p>' +
    '</body></html>';
end;

{ TProcessadorFila }

constructor TProcessadorFila.Create;
begin
  FSinal := TEvent.Create(nil, False, False, ''); // auto-reset
  inherited Create(False);
end;

destructor TProcessadorFila.Destroy;
begin
  
  Terminate;
  
  if Assigned(FSinal) then begin
  
    FSinal.SetEvent;
  end; 
  
  inherited Destroy;
  FSinal.Free;
end;

procedure TProcessadorFila.Sinalizar;
begin
  
  FSinal.SetEvent;
end;

procedure TProcessadorFila.Execute;

var Intervalo: Cardinal;

begin
  
  NameThreadForDebugging('ProcessadorFila');
  Intervalo := Cardinal(TConfig.Instancia.FilaIntervaloSeg) * 1000;
  while not Terminated do
  begin
    
	try
      
	  ProcessarPendentes;
    except on E: Exception do
      
	  Log('Processador da fila: %s', [E.Message]);
    end;
    if not Terminated then
      FSinal.WaitFor(Intervalo);
  end;
end;

procedure TProcessadorFila.ProcessarPendentes;
var
  Conn: TFDConnection;
  Qry: TFDQuery;
  Itens: TList<TItemFila>;
  Item: TItemFila;
begin
  Conn := NovaConexao(True);
  Itens := TList<TItemFila>.Create;
  try
    
	Qry := TFDQuery.Create(nil);
    try
      
	  Qry.Connection := Conn;
      Qry.Open(
        'SELECT FIRST 20 ID, TIPO, ID_VENDA, TENTATIVAS FROM INTEGRACAO_FILA ' +
        'WHERE STATUS = ''PENDENTE'' AND PROXIMA_TENTATIVA <= :AGORA ORDER BY ID', [Now]);
      
	  while not Qry.Eof do begin
        
		Item.Id := Qry.FieldByName('ID').AsInteger;
        Item.Tipo := Qry.FieldByName('TIPO').AsString;
        Item.IdVenda := Qry.FieldByName('ID_VENDA').AsInteger;
        Item.Tentativas := Qry.FieldByName('TENTATIVAS').AsInteger;
        Itens.Add(Item);
        Qry.Next;
      end;
	  
    finally
      
	  Qry.Free;
    end;

    for Item in Itens do begin
      
	  if Terminated then begin
        
		break;
	  end;
      
	  ProcessarItem(Conn, Item.Id, Item.Tipo, Item.IdVenda, Item.Tentativas);
    end;
  finally
    
	Itens.Free;
    Conn.Free;
  end;
end;

procedure TProcessadorFila.ProcessarItem(AConexao: TFDConnection; AIdFila: Integer;
  const ATipo: string; AIdVenda, ATentativas: Integer);
var
  Tentativa, Espera: Integer;
  Definitiva: Boolean;
  NovoStatus: string;
begin
  try
    if ATipo = FILA_ENVIAR_TITULO then
      EnviarTitulo(AConexao, AIdVenda)
    else if ATipo = FILA_ENVIAR_EMAIL then
      EnviarEmail(AConexao, AIdVenda)
    else
      raise EFalhaDefinitiva.CreateFmt('Tipo de integração desconhecido: %s', [ATipo]);

    AConexao.ExecSQL(
      'UPDATE INTEGRACAO_FILA SET STATUS = ''PROCESSADO'', TENTATIVAS = TENTATIVAS + 1, ' +
      'ULTIMO_ERRO = NULL, DATA_PROCESSAMENTO = :AGORA WHERE ID = :ID', [Now, AIdFila]);
    Log('Fila #%d (%s, venda %d) processada.', [AIdFila, ATipo, AIdVenda]);
    NotificarVendaAtualizada(AIdVenda);
  except
    on E: Exception do
    begin
      Tentativa := ATentativas + 1;
      Definitiva := (E is EFalhaDefinitiva) or (Tentativa >= TConfig.Instancia.FilaMaxTentativas);
      NovoStatus := IfThen(Definitiva, FILA_ERRO, FILA_PENDENTE);
      Espera := Min(60 * (1 shl Min(Tentativa - 1, 5)), 1800);
      Log('Fila #%d (%s, venda %d) falhou [tentativa %d, %s]: %s',
        [AIdFila, ATipo, AIdVenda, Tentativa, NovoStatus, E.Message]);
      try
        AConexao.ExecSQL(
          'UPDATE INTEGRACAO_FILA SET STATUS = :STATUS, TENTATIVAS = :TENTATIVAS, ' +
          'ULTIMO_ERRO = :ERRO, PROXIMA_TENTATIVA = :PROXIMA WHERE ID = :ID',
          [NovoStatus, Tentativa, Copy(E.Message, 1, 1000), IncSecond(Now, Espera), AIdFila]);
      except
        on E2: Exception do
          Log('Não foi possível registrar a falha da fila #%d: %s', [AIdFila, E2.Message]);
      end;
    end;
  end;
end;

procedure TProcessadorFila.EnviarTitulo(AConexao: TFDConnection; AIdVenda: Integer);
var
  Qry: TFDQuery;
  Titulo: TTituloDTO;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := AConexao;
    Qry.Open(
      'SELECT V.STATUS, V.VALOR_TOTAL, V.DATA_FATURAMENTO, C.NOME, C.CPF_CNPJ, C.EMAIL ' +
      'FROM VENDA V JOIN CLIENTE C ON C.ID = V.ID_CLIENTE WHERE V.ID = :ID', [AIdVenda]);
    if Qry.IsEmpty then
      raise EFalhaDefinitiva.CreateFmt('Venda %d não encontrada.', [AIdVenda]);
    if Qry.FieldByName('STATUS').AsString <> STATUS_FATURADA then
    begin
      Log('Venda %d está %s: envio do título ignorado.', [AIdVenda, Qry.FieldByName('STATUS').AsString]);
      Exit;
    end;

    Titulo.IdVenda := AIdVenda;
    Titulo.ClienteNome := Qry.FieldByName('NOME').AsString;
    Titulo.ClienteDocumento := Qry.FieldByName('CPF_CNPJ').AsString;
    Titulo.ClienteEmail := Qry.FieldByName('EMAIL').AsString;
    Titulo.Valor := Qry.FieldByName('VALOR_TOTAL').AsCurrency;
    Titulo.DataEmissao := Qry.FieldByName('DATA_FATURAMENTO').AsDateTime;
    Titulo.DataVencimento := IncDay(DateOf(Titulo.DataEmissao), TConfig.Instancia.FinanceiroDiasVencimento);
  finally
    Qry.Free;
  end;

  TFinanceiroClient.CriarTitulo(Titulo);
end;

procedure TProcessadorFila.EnviarEmail(AConexao: TFDConnection; AIdVenda: Integer);
var
  Qry: TFDQuery;
  Nome, Email, Forma, Arquivo, Html: string;
  ValorPago: Currency;
  DataPagamento: TDateTime;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := AConexao;
    Qry.Open(
      'SELECT V.STATUS, V.VALOR_PAGO, V.DATA_QUITACAO, V.FORMA_PAGAMENTO, C.NOME, C.EMAIL ' +
      'FROM VENDA V JOIN CLIENTE C ON C.ID = V.ID_CLIENTE WHERE V.ID = :ID', [AIdVenda]);
    if Qry.IsEmpty then
      raise EFalhaDefinitiva.CreateFmt('Venda %d não encontrada.', [AIdVenda]);
    if Qry.FieldByName('STATUS').AsString <> STATUS_QUITADA then
      raise EFalhaDefinitiva.CreateFmt('Venda %d não está quitada (status %s).',
        [AIdVenda, Qry.FieldByName('STATUS').AsString]);
    Nome := Qry.FieldByName('NOME').AsString;
    Email := Qry.FieldByName('EMAIL').AsString;
    Forma := Qry.FieldByName('FORMA_PAGAMENTO').AsString;
    ValorPago := Qry.FieldByName('VALOR_PAGO').AsCurrency;
    DataPagamento := Qry.FieldByName('DATA_QUITACAO').AsDateTime;
  finally
    Qry.Free;
  end;

  Arquivo := TPath.Combine(TConfig.Instancia.PastaPedidos, Format('Pedido_%.6d.pdf', [AIdVenda]));
  
  Synchronize(
    procedure
    begin
      TRelatorioPedido.GerarPDF(AIdVenda, Arquivo);
    end);

  Html := HtmlConfirmacao(Nome, AIdVenda, ValorPago, DataPagamento, Forma, TConfig.Instancia.EmpresaNome);
  TEmailService.Enviar(Email, Nome, Format('Pedido nº %d confirmado - pagamento recebido', [AIdVenda]),
    Html, Arquivo);

  AConexao.ExecSQL('UPDATE VENDA SET EMAIL_ENVIADO = TRUE, DATA_EMAIL = :AGORA WHERE ID = :ID',
    [Now, AIdVenda]);
end;

end.
