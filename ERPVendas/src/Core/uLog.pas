unit uLog;

/// Log em arquivo, thread-safe

interface

procedure Log(const AMensagem: string); overload;
procedure Log(const AFormato: string; const AArgs: array of const); overload;

implementation

uses System.SysUtils, System.Classes, System.SyncObjs, System.IOUtils;

var FTrava: TCriticalSection;

procedure Log(const AMensagem: string);
var
  
  Pasta, Arquivo, Linha: string;
  Bytes: TBytes;
  Stream: TFileStream;
begin

  FTrava.Enter;

  try
    try
	
      Pasta := TPath.Combine(ExtractFilePath(ParamStr(0)), 'logs');
      ForceDirectories(Pasta);
      Arquivo := TPath.Combine(Pasta, 'ERPVendas_' + FormatDateTime('yyyymmdd', Now) + '.log');
      Linha := Format('%s [%5d] %s', [FormatDateTime('hh:nn:ss.zzz', Now), Integer(TThread.CurrentThread.ThreadID), AMensagem]) + sLineBreak;
      Bytes := TEncoding.UTF8.GetBytes(Linha);
      
	  if FileExists(Arquivo) then begin
        Stream := TFileStream.Create(Arquivo, fmOpenWrite or fmShareDenyWrite)
		
      end else begin
        
		Stream := TFileStream.Create(Arquivo, fmCreate);
	  end;
	  
      try
      
	    Stream.Seek(0, soEnd);
        Stream.WriteBuffer(Bytes[0], Length(Bytes));
      finally

        Stream.Free;
      end;
    except
      // o log nunca pode derrubar a aplicação
    end;
  finally
    FTrava.Leave;
  end;
end;

procedure Log(const AFormato: string; const AArgs: array of const);
begin
  Log(Format(AFormato, AArgs));
end;

initialization
  FTrava := TCriticalSection.Create;

finalization
  FTrava.Free;

end.
