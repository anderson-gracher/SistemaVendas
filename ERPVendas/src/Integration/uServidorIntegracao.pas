unit uServidorIntegracao;

/// Servidor HTTP (Indy) que recebe os callbacks do ERP Financeiro.
///   GET  /api/health                      (sem autenticação)
///   GET  /api/vendas/{id}
///   POST /api/vendas/{id}/quitacao        {dataPagamento, valorPago, formaPagamento}
///   POST /api/vendas/{id}/cancelamento    {motivo}
/// Demais rotas exigem o header X-Api-Key. Respostas em JSON;
/// erros no formato {"erro": "mensagem"} com 400/401/404/409/500.
/// Cada requisição roda em uma thread do Indy e usa uma conexão própria do pool.

interface

uses System.SysUtils, System.Classes, System.JSON,
     IdBaseComponent, IdComponent, IdContext, IdCustomTCPServer, IdCustomHTTPServer, IdHTTPServer;

type
  TServidorIntegracao = class
  private
    FHttp: TIdHTTPServer;
    FPorta: Integer;
    procedure HttpCommand(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);
    procedure Responder(AResponseInfo: TIdHTTPResponseInfo; ACodigo: Integer; AJson: TJSONObject);
    procedure ResponderErro(AResponseInfo: TIdHTTPResponseInfo; ACodigo: Integer; const AMensagem: string);
    function LerCorpo(ARequestInfo: TIdHTTPRequestInfo): TJSONObject;
    function ConsultarVenda(AIdVenda: Integer): TJSONObject;
    function RegistrarQuitacao(AIdVenda: Integer; ACorpo: TJSONObject): TJSONObject;
    function RegistrarCancelamento(AIdVenda: Integer; ACorpo: TJSONObject): TJSONObject;
  public
    constructor Create(APorta: Integer);
    destructor Destroy; override;
    procedure Iniciar;
    procedure Parar;
    function Ativo: Boolean;
    property Porta: Integer read FPorta;
  end;

implementation

uses
  System.DateUtils, System.StrUtils, FireDAC.Comp.Client, FireDAC.Stan.Param,
  uConfig, uConexao, uLog, uExcecoes, uEventos, uVendaService, uProcessadorFila;

{ TServidorIntegracao }

constructor TServidorIntegracao.Create(APorta: Integer);
begin
  inherited Create;
  FPorta := APorta;
  FHttp := TIdHTTPServer.Create(nil);
  FHttp.DefaultPort := APorta;
  FHttp.OnCommandGet := HttpCommand;   // GET e POST
  FHttp.OnCommandOther := HttpCommand; // PUT, DELETE...
end;

destructor TServidorIntegracao.Destroy;
begin
  Parar;
  FHttp.Free;
  inherited;
end;

procedure TServidorIntegracao.Iniciar;
begin
  FHttp.Active := True;
  Log('Servidor de integração ouvindo na porta %d.', [FPorta]);
end;

procedure TServidorIntegracao.Parar;
begin
  if FHttp.Active then
  begin
    FHttp.Active := False;
    Log('Servidor de integração parado.');
  end;
end;

function TServidorIntegracao.Ativo: Boolean;
begin
  Result := FHttp.Active;
end;

procedure TServidorIntegracao.Responder(AResponseInfo: TIdHTTPResponseInfo; ACodigo: Integer;
  AJson: TJSONObject);
begin
  try
    AResponseInfo.ResponseNo := ACodigo;
    AResponseInfo.ContentType := 'application/json';
    AResponseInfo.CharSet := 'utf-8';
    AResponseInfo.ContentText := AJson.ToJSON;
  finally
    AJson.Free;
  end;
end;

procedure TServidorIntegracao.ResponderErro(AResponseInfo: TIdHTTPResponseInfo; ACodigo: Integer;
  const AMensagem: string);
var
  Json: TJSONObject;
begin
  Json := TJSONObject.Create;
  Json.AddPair('erro', AMensagem);
  Responder(AResponseInfo, ACodigo, Json);
end;

function TServidorIntegracao.LerCorpo(ARequestInfo: TIdHTTPRequestInfo): TJSONObject;
var
  Texto: string;
  Stream: TStringStream;
  Valor: TJSONValue;
begin
  Texto := '';
  if Assigned(ARequestInfo.PostStream) and (ARequestInfo.PostStream.Size > 0) then
  begin
    Stream := TStringStream.Create('', TEncoding.UTF8);
    try
      Stream.CopyFrom(ARequestInfo.PostStream, 0);
      Texto := Stream.DataString;
    finally
      Stream.Free;
    end;
  end;
  if Trim(Texto) = '' then
    Exit(TJSONObject.Create);

  Valor := TJSONObject.ParseJSONValue(Texto);
  if not (Valor is TJSONObject) then
  begin
    Valor.Free;
    raise EValidacao.Create('O corpo da requisição deve ser um objeto JSON válido.');
  end;
  Result := TJSONObject(Valor);
end;

procedure TServidorIntegracao.HttpCommand(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo);
var
  Metodo: string;
  Partes: TArray<string>;
  IdVenda: Integer;
  Corpo, Resposta: TJSONObject;
begin
  Metodo := UpperCase(ARequestInfo.Command);
  Partes := ARequestInfo.Document.Split(['/'], TStringSplitOptions.ExcludeEmpty);
  Log('HTTP %s %s (de %s)', [Metodo, ARequestInfo.Document, ARequestInfo.RemoteIP]);
  try
    // GET /api/health
    if (Metodo = 'GET') and (Length(Partes) = 2) and SameText(Partes[0], 'api') and
      SameText(Partes[1], 'health') then
    begin
      Resposta := TJSONObject.Create;
      Resposta.AddPair('status', 'ok');
      Resposta.AddPair('servico', 'ERP Vendas');
      Resposta.AddPair('dataHora', DateToISO8601(Now, False));
      Responder(AResponseInfo, 200, Resposta);
      Exit;
    end;

    if ARequestInfo.RawHeaders.Values['X-Api-Key'] <> TConfig.Instancia.ServidorApiKey then
    begin
      ResponderErro(AResponseInfo, 401, 'API key inválida ou ausente (header X-Api-Key).');
      Exit;
    end;

    // /api/vendas/{id}[/acao]
    if (Length(Partes) < 3) or not SameText(Partes[0], 'api') or not SameText(Partes[1], 'vendas') or
      not TryStrToInt(Partes[2], IdVenda) then
    begin
      ResponderErro(AResponseInfo, 404, 'Recurso não encontrado.');
      Exit;
    end;

    if (Metodo = 'GET') and (Length(Partes) = 3) then
      Responder(AResponseInfo, 200, ConsultarVenda(IdVenda))
    else if (Metodo = 'POST') and (Length(Partes) = 4) and SameText(Partes[3], 'quitacao') then
    begin
      Corpo := LerCorpo(ARequestInfo);
      try
        Responder(AResponseInfo, 200, RegistrarQuitacao(IdVenda, Corpo));
      finally
        Corpo.Free;
      end;
    end
    else if (Metodo = 'POST') and (Length(Partes) = 4) and SameText(Partes[3], 'cancelamento') then
    begin
      Corpo := LerCorpo(ARequestInfo);
      try
        Responder(AResponseInfo, 200, RegistrarCancelamento(IdVenda, Corpo));
      finally
        Corpo.Free;
      end;
    end
    else
      ResponderErro(AResponseInfo, 404, 'Recurso não encontrado.');
  except
    on E: EValidacao do
      ResponderErro(AResponseInfo, 400, E.Message);
    on E: ENaoEncontrado do
      ResponderErro(AResponseInfo, 404, E.Message);
    on E: ERegraNegocio do
      ResponderErro(AResponseInfo, 409, E.Message);
    on E: Exception do
    begin
      Log('Erro no servidor de integração: %s: %s', [E.ClassName, E.Message]);
      ResponderErro(AResponseInfo, 500, 'Erro interno ao processar a requisição.');
    end;
  end;
end;

function TServidorIntegracao.ConsultarVenda(AIdVenda: Integer): TJSONObject;
var
  Conn: TFDConnection;
  Qry: TFDQuery;
begin
  Conn := NovaConexao(True);
  try
    Qry := TFDQuery.Create(nil);
    try
      Qry.Connection := Conn;
      Qry.Open(
        'SELECT V.STATUS, V.VALOR_TOTAL, V.DATA_VENDA, V.EMAIL_ENVIADO, C.NOME ' +
        'FROM VENDA V JOIN CLIENTE C ON C.ID = V.ID_CLIENTE WHERE V.ID = :ID', [AIdVenda]);
      if Qry.IsEmpty then
        raise ENaoEncontrado.CreateFmt('Venda %d não encontrada.', [AIdVenda]);
      Result := TJSONObject.Create;
      Result.AddPair('idVenda', TJSONNumber.Create(AIdVenda));
      Result.AddPair('status', Qry.FieldByName('STATUS').AsString);
      Result.AddPair('valorTotal', TJSONNumber.Create(Qry.FieldByName('VALOR_TOTAL').AsFloat));
      Result.AddPair('dataVenda', DateToISO8601(Qry.FieldByName('DATA_VENDA').AsDateTime, False));
      Result.AddPair('cliente', Qry.FieldByName('NOME').AsString);
      Result.AddPair('emailEnviado', TJSONBool.Create(Qry.FieldByName('EMAIL_ENVIADO').AsBoolean));
    finally
      Qry.Free;
    end;
  finally
    Conn.Free;
  end;
end;

function TServidorIntegracao.RegistrarQuitacao(AIdVenda: Integer; ACorpo: TJSONObject): TJSONObject;
var
  Conn: TFDConnection;
  Servico: TVendaService;
  Texto, Forma: string;
  DataPagamento: TDateTime;
  ValorPago: Double;
  Alterou: Boolean;
begin
  if ACorpo.TryGetValue<string>('dataPagamento', Texto) and (Trim(Texto) <> '') then
  begin
    try
      DataPagamento := ISO8601ToDate(Texto, False);
    except
      raise EValidacao.Create('dataPagamento inválida: use o formato ISO 8601.');
    end;
  end
  else
    DataPagamento := Now;
  if not ACorpo.TryGetValue<Double>('valorPago', ValorPago) then
    raise EValidacao.Create('valorPago é obrigatório e deve ser numérico.');
  if not ACorpo.TryGetValue<string>('formaPagamento', Forma) then
    Forma := '';

  Conn := NovaConexao(True);
  try
    Servico := TVendaService.Create(Conn);
    try
      Alterou := Servico.RegistrarQuitacao(AIdVenda, DataPagamento, ValorPago, Forma);
    finally
      Servico.Free;
    end;
  finally
    Conn.Free;
  end;

  if Alterou then
  begin
    Log('Venda %d quitada pelo Financeiro.', [AIdVenda]);
    if Assigned(ProcessadorFila) then
      ProcessadorFila.Sinalizar;
    NotificarVendaAtualizada(AIdVenda);
  end;

  Result := TJSONObject.Create;
  Result.AddPair('idVenda', TJSONNumber.Create(AIdVenda));
  Result.AddPair('status', STATUS_QUITADA);
  Result.AddPair('mensagem', IfThen(Alterou,
    'Quitação registrada. O e-mail de confirmação foi enfileirado.',
    'A venda já estava quitada (requisição repetida).'));
end;

function TServidorIntegracao.RegistrarCancelamento(AIdVenda: Integer; ACorpo: TJSONObject): TJSONObject;
var
  Conn: TFDConnection;
  Servico: TVendaService;
  Motivo: string;
  Alterou: Boolean;
begin
  if not ACorpo.TryGetValue<string>('motivo', Motivo) or (Trim(Motivo) = '') then
    Motivo := 'Cancelada no ERP Financeiro';

  Conn := NovaConexao(True);
  try
    Servico := TVendaService.Create(Conn);
    try
      Alterou := Servico.RegistrarCancelamentoFinanceiro(AIdVenda, Motivo);
    finally
      Servico.Free;
    end;
  finally
    Conn.Free;
  end;

  if Alterou then
  begin
    Log('Venda %d cancelada pelo Financeiro: %s', [AIdVenda, Motivo]);
    NotificarVendaAtualizada(AIdVenda);
  end;

  Result := TJSONObject.Create;
  Result.AddPair('idVenda', TJSONNumber.Create(AIdVenda));
  Result.AddPair('status', STATUS_CANCELADA);
  Result.AddPair('mensagem', IfThen(Alterou,
    'Cancelamento registrado e estoque estornado.',
    'A venda já estava cancelada (requisição repetida).'));
end;

end.
