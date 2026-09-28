unit uFinanceiroClient;

/// Cliente REST do ERP Financeiro.

interface

uses
  System.SysUtils, uExcecoes;

type
  TTituloDTO = record
    IdVenda: Integer;
    ClienteNome: string;
    ClienteDocumento: string;
    ClienteEmail: string;
    Valor: Currency;
    DataEmissao: TDateTime;
    DataVencimento: TDateTime;
  end;
  
  EFinanceiroIndisponivel = class(Exception);
  EFinanceiroRejeitou = class(EFalhaDefinitiva);

  TFinanceiroClient = class
  private
    class function Url(const ACaminho: string): string;
  public
    class procedure CriarTitulo(const ATitulo: TTituloDTO);
  end;

implementation

uses
  System.Classes, System.JSON, System.DateUtils, System.Net.HttpClient, System.Net.URLClient,
  uConfig, uLog;

class function TFinanceiroClient.Url(const ACaminho: string): string;
var
  Base: string;
begin
  Base := Trim(TConfig.Instancia.FinanceiroUrl);
  while Base.EndsWith('/') do
    Base := Base.Substring(0, Base.Length - 1);
  Result := Base + ACaminho;
end;

class procedure TFinanceiroClient.CriarTitulo(const ATitulo: TTituloDTO);
var
  Cfg: TConfig;
  Json: TJSONObject;
  Corpo: TStringStream;
  Cliente: THTTPClient;
  Resposta: IHTTPResponse;
  Codigo: Integer;
  Destino, Retorno: string;
begin
  Cfg := TConfig.Instancia;
  Destino := Url('/api/titulos');

  Json := TJSONObject.Create;
  try
    Json.AddPair('idVenda', TJSONNumber.Create(ATitulo.IdVenda));
    Json.AddPair('clienteNome', ATitulo.ClienteNome);
    Json.AddPair('clienteDocumento', ATitulo.ClienteDocumento);
    Json.AddPair('clienteEmail', ATitulo.ClienteEmail);
    Json.AddPair('valor', TJSONNumber.Create(Double(ATitulo.Valor)));
    Json.AddPair('dataEmissao', DateToISO8601(ATitulo.DataEmissao, False));
    Json.AddPair('dataVencimento', DateToISO8601(ATitulo.DataVencimento, False));
    Corpo := TStringStream.Create(Json.ToJSON, TEncoding.UTF8);
  finally
    Json.Free;
  end;

  Cliente := THTTPClient.Create;
  try
    Cliente.ConnectionTimeout := Cfg.FinanceiroTimeoutMs;
    Cliente.ResponseTimeout := Cfg.FinanceiroTimeoutMs;
    Cliente.ContentType := 'application/json; charset=utf-8';
    Cliente.Accept := 'application/json';
    Cliente.CustomHeaders['X-Api-Key'] := Cfg.FinanceiroApiKey;

    try
      Resposta := Cliente.Post(Destino, Corpo);
    except
      on E: Exception do
        raise EFinanceiroIndisponivel.CreateFmt('Não foi possível comunicar com o Financeiro (%s): %s',
          [Destino, E.Message]);
    end;

    Codigo := Resposta.StatusCode;
    Retorno := Resposta.ContentAsString(TEncoding.UTF8);
    Resposta := nil;

    if (Codigo = 200) or (Codigo = 201) then
    begin
      Log('Título da venda %d registrado no Financeiro (HTTP %d).', [ATitulo.IdVenda, Codigo]);
      Exit;
    end;
    if (Codigo >= 400) and (Codigo < 500) and (Codigo <> 408) and (Codigo <> 429) then
      raise EFinanceiroRejeitou.CreateFmt('Financeiro rejeitou o título da venda %d (HTTP %d): %s',
        [ATitulo.IdVenda, Codigo, Retorno]);
    raise EFinanceiroIndisponivel.CreateFmt('Financeiro respondeu HTTP %d: %s', [Codigo, Retorno]);
  finally
    Resposta := nil;
    Cliente.Free;
    Corpo.Free;
  end;
end;

end.
