unit uFilaIntegracao;

/// Fila de integração



interface

uses
  FireDAC.Comp.Client;

const
  FILA_ENVIAR_TITULO = 'ENVIAR_TITULO';
  FILA_ENVIAR_EMAIL = 'ENVIAR_EMAIL';

  FILA_PENDENTE = 'PENDENTE';
  FILA_PROCESSADO = 'PROCESSADO';
  FILA_ERRO = 'ERRO';

type
  TFilaIntegracao = class
  public
    class procedure Enfileirar(AConexao: TFDConnection; const ATipo: string; AIdVenda: Integer);
    class function ReprocessarErros(AConexao: TFDConnection): Integer;
  end;

implementation

uses
  System.SysUtils, System.Variants;

class procedure TFilaIntegracao.Enfileirar(AConexao: TFDConnection; const ATipo: string; AIdVenda: Integer);

var Pendentes: Integer;

begin
  
  Pendentes := AConexao.ExecSQLScalar(
    'SELECT COUNT(*) FROM INTEGRACAO_FILA ' +
    'WHERE TIPO = :TIPO AND ID_VENDA = :VENDA AND STATUS = ''PENDENTE''',
    [ATipo, AIdVenda]);
  if Pendentes > 0 then begin
    
	exit;
  end;

  AConexao.ExecSQL(
    'INSERT INTO INTEGRACAO_FILA (TIPO, ID_VENDA, STATUS, TENTATIVAS, PROXIMA_TENTATIVA) ' +
    'VALUES (:TIPO, :VENDA, ''PENDENTE'', 0, :AGORA)',
    [ATipo, AIdVenda, Now]);
end;

class function TFilaIntegracao.ReprocessarErros(AConexao: TFDConnection): Integer;
begin
  Result := AConexao.ExecSQL(
    'UPDATE INTEGRACAO_FILA SET STATUS = ''PENDENTE'', TENTATIVAS = 0, ' +
    'PROXIMA_TENTATIVA = :AGORA WHERE STATUS = ''ERRO''', [Now]);
end;

end.
