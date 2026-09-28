unit uConfig;

  /// <summary>
  ///   Configurações da aplicação, lidas de ERPVendas.ini 
  /// </summary>

interface

type

  TConfig = class
  private
    FArquivo: string;
    class var FInstancia: TConfig;
  public
    // [Banco]
    DBServidor: string;
    DBPorta: Integer;
    DBCaminho: string;
    DBUsuario: string;
    DBSenha: string;
    DBVendorLib: string;
    // [Servidor] - recebe os callbacks do ERP Financeiro
    ServidorPorta: Integer;
    ServidorApiKey: string;
    // [Financeiro] - API REST do ERP Financeiro
    FinanceiroUrl: string;
    FinanceiroApiKey: string;
    FinanceiroTimeoutMs: Integer;
    FinanceiroDiasVencimento: Integer;
    // [Smtp]
    SmtpHost: string;
    SmtpPorta: Integer;
    SmtpUsuario: string;
    SmtpSenha: string;
    SmtpTLS: Integer; // 0 = sem TLS, 1 = implícito (465), 2 = STARTTLS (587)
    SmtpRemetente: string;
    SmtpRemetenteNome: string;
    // [Fila]
    FilaIntervaloSeg: Integer;
    FilaMaxTentativas: Integer;
    // [Geral]
    EmpresaNome: string;
    PastaPedidos: string;

    constructor Create;
    procedure Carregar;
    class function Instancia: TConfig;
    class destructor Finalizar;
    property Arquivo: string read FArquivo;
  end;

implementation

uses
  System.SysUtils, System.IniFiles, System.IOUtils;

constructor TConfig.Create;
begin
  inherited Create;
  FArquivo := ChangeFileExt(ParamStr(0), '.ini');
end;

class function TConfig.Instancia: TConfig;
begin

  if FInstancia = nil then begin
    
	FInstancia := TConfig.Create;
    FInstancia.Carregar;
  end;
  
  Result := FInstancia;
end;

class destructor TConfig.Finalizar;
begin
  
  FreeAndNil(FInstancia);
end;

procedure TConfig.Carregar;
var
  Ini: TMemIniFile;
  Novo: Boolean;
  PastaExe: string;

  procedure LerTexto(const ASecao, AChave, APadrao: string; var AValor: string);
  begin
    
	AValor := Ini.ReadString(ASecao, AChave, APadrao);
    
	if Novo then begin
      Ini.WriteString(ASecao, AChave, AValor);
	end;
  end;

  procedure LerInteiro(const ASecao, AChave: string; APadrao: Integer; var AValor: Integer);
  begin
    
	AValor := Ini.ReadInteger(ASecao, AChave, APadrao);
    
	if Novo then begin
      Ini.WriteInteger(ASecao, AChave, AValor);
	end;
	
  end;

begin
  
  Novo := not FileExists(FArquivo);
  PastaExe := ExtractFilePath(ParamStr(0));
  Ini := TMemIniFile.Create(FArquivo, TEncoding.UTF8);
  
  try
  
    LerTexto('Banco', 'Servidor', 'localhost', DBServidor);
    LerInteiro('Banco', 'Porta', 3050, DBPorta);
    LerTexto('Banco', 'Caminho', 'C:\ERP\dados\VENDAS.FDB', DBCaminho);
    LerTexto('Banco', 'Usuario', 'SYSDBA', DBUsuario);
    LerTexto('Banco', 'Senha', 'masterkey', DBSenha);
    LerTexto('Banco', 'VendorLib', '', DBVendorLib);

    LerInteiro('Servidor', 'Porta', 9000, ServidorPorta);
    LerTexto('Servidor', 'ApiKey', 'vendas-chave-dev', ServidorApiKey);

    LerTexto('Financeiro', 'Url', 'http://localhost:9001', FinanceiroUrl);
    LerTexto('Financeiro', 'ApiKey', 'financeiro-chave-dev', FinanceiroApiKey);
    LerInteiro('Financeiro', 'TimeoutMs', 10000, FinanceiroTimeoutMs);
    LerInteiro('Financeiro', 'DiasVencimento', 30, FinanceiroDiasVencimento);

    LerTexto('Smtp', 'Host', 'localhost', SmtpHost);
    LerInteiro('Smtp', 'Porta', 25, SmtpPorta);
    LerTexto('Smtp', 'Usuario', '', SmtpUsuario);
    LerTexto('Smtp', 'Senha', '', SmtpSenha);
    LerInteiro('Smtp', 'TLS', 0, SmtpTLS);
    LerTexto('Smtp', 'Remetente', 'vendas@erp.local', SmtpRemetente);
    LerTexto('Smtp', 'RemetenteNome', 'ERP Vendas', SmtpRemetenteNome);

    LerInteiro('Fila', 'IntervaloSegundos', 15, FilaIntervaloSeg);
    LerInteiro('Fila', 'MaxTentativas', 10, FilaMaxTentativas);

    LerTexto('Geral', 'EmpresaNome', 'Minha Empresa Ltda', EmpresaNome);
    LerTexto('Geral', 'PastaPedidos', '', PastaPedidos);

    if Novo then begin
      Ini.UpdateFile;
	end;
	
  finally
    
	Ini.Free;
  end;

  if Trim(PastaPedidos) = '' then begin
    
	PastaPedidos := TPath.Combine(PastaExe, 'pedidos');
  end;
  
  if FilaIntervaloSeg < 1 then begin
  
    FilaIntervaloSeg := 1;
  end;
  
  if FilaMaxTentativas < 1 then begin
  
    FilaMaxTentativas := 1;
  end;
  
end;

end.
