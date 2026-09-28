unit uConexao;

/// Conexões FireDAC com o Firebird.

interface

uses
  FireDAC.Comp.Client;

procedure RegistrarConexao;
function NovaConexao(ASegundoPlano: Boolean = False): TFDConnection;
function Conexao: TFDConnection;

implementation

uses
  System.SysUtils, System.Classes,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.Intf,
  FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.DApt, FireDAC.UI.Intf,
  FireDAC.VCLUI.Wait, FireDAC.Comp.UI,
  uConfig;

const
  NOME_DEFINICAO = 'ERP_VENDAS';

var
  FRegistrada: Boolean;
  FDriverLink: TFDPhysFBDriverLink;
  FWaitCursor: TFDGUIxWaitCursor;
  FConexaoPrincipal: TFDConnection;

procedure RegistrarConexao;
var
  Cfg: TConfig;
  Params: TStringList;
begin
  if FRegistrada then
    Exit;
  Cfg := TConfig.Instancia;

  FDriverLink := TFDPhysFBDriverLink.Create(nil);
  if Cfg.DBVendorLib <> '' then
    FDriverLink.VendorLib := Cfg.DBVendorLib;

  FWaitCursor := TFDGUIxWaitCursor.Create(nil);
  FWaitCursor.Provider := 'Forms';

  Params := TStringList.Create;
  try
    Params.Values['Server'] := Cfg.DBServidor;
    Params.Values['Port'] := IntToStr(Cfg.DBPorta);
    Params.Values['Database'] := Cfg.DBCaminho;
    Params.Values['User_Name'] := Cfg.DBUsuario;
    Params.Values['Password'] := Cfg.DBSenha;
    Params.Values['Protocol'] := 'TCPIP';
    Params.Values['CharacterSet'] := 'UTF8';
    Params.Values['Pooled'] := 'True';
    Params.Values['POOL_MaximumItems'] := '20';
    FDManager.AddConnectionDef(NOME_DEFINICAO, 'FB', Params);
  finally
    Params.Free;
  end;
  FDManager.Active := True;
  FRegistrada := True;
end;

function NovaConexao(ASegundoPlano: Boolean): TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  try
    Result.ConnectionDefName := NOME_DEFINICAO;
    Result.LoginPrompt := False;
    // Em segundo plano não há cursor de espera nem diálogos
    Result.ResourceOptions.SilentMode := ASegundoPlano;
    Result.Connected := True;
  except
    Result.Free;
    raise;
  end;
end;

function Conexao: TFDConnection;
begin
  if FConexaoPrincipal = nil then
    FConexaoPrincipal := NovaConexao(False);
  Result := FConexaoPrincipal;
end;

initialization

finalization
  FreeAndNil(FConexaoPrincipal);
  if FRegistrada then
    FDManager.Close;
  FreeAndNil(FWaitCursor);
  FreeAndNil(FDriverLink);

end.
