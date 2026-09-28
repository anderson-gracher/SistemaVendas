unit uExcecoes;

// Helper para ajudar definir as exceções

interface

uses
  System.SysUtils;

type
  /// Dado inválido informado pelo usuário/cliente da API (HTTP 400).
  EValidacao = class(Exception);
  /// Operação não permitida pela regra de negócio / estado atual (HTTP 409).
  ERegraNegocio = class(Exception);
  /// Registro inexistente (HTTP 404).
  ENaoEncontrado = class(Exception);
  /// Falha de integração que não adianta repetir (a fila marca como ERRO).
  EFalhaDefinitiva = class(Exception);

/// Converte erros do banco (FireDAC) em mensagens compreensíveis ao usuário.
function MensagemAmigavel(E: Exception): string;

implementation

uses
  FireDAC.Stan.Error;

function MensagemAmigavel(E: Exception): string;
begin
  Result := E.Message;
  if E is EFDDBEngineException then
    case EFDDBEngineException(E).Kind of
      ekUKViolated:
        Result := 'Já existe um registro com estes dados (valor duplicado).';
      ekFKViolated:
        Result := 'O registro possui vínculos (por exemplo, vendas) e não pode ser excluído. ' +
          'Desative-o em vez de excluir.';
      ekRecordLocked:
        Result := 'O registro está bloqueado por outro usuário/processo. Tente novamente.';
      ekServerGone:
        Result := 'A conexão com o banco de dados foi perdida. Tente novamente.';
    end;
end;

end.
