unit uVendaService;

/// Regras de negócio da venda.

interface

uses
  System.SysUtils, Data.DB, FireDAC.Comp.Client;

const
  STATUS_ABERTA = 'ABERTA';
  STATUS_FATURADA = 'FATURADA';
  STATUS_QUITADA = 'QUITADA';
  STATUS_CANCELADA = 'CANCELADA';

type
  TVendaService = class
  private
    FConexao: TFDConnection;
    function StatusAtual(AIdVenda: Integer): string;
  public
    constructor Create(AConexao: TFDConnection);

    /// Grava cabeçalho + itens (AItens: ID_PRODUTO, DESCRICAO, QUANTIDADE,
    /// VALOR_UNITARIO, VALOR_TOTAL). AIdVenda = 0 cria. Retorna o ID.
    function Salvar(AIdVenda, AIdCliente: Integer; AData: TDateTime;
      const AObservacao: string; AItens: TDataSet): Integer;
    procedure Excluir(AIdVenda: Integer);
    /// ABERTA -> FATURADA: baixa estoque e enfileira o envio do título ao Financeiro.
    procedure Faturar(AIdVenda: Integer);
    /// ABERTA -> CANCELADA (venda ainda não enviada ao Financeiro).
    procedure Cancelar(AIdVenda: Integer; const AMotivo: string);
    /// Callback do Financeiro. FATURADA -> QUITADA e enfileira o e-mail.
    /// Idempotente: retorna False se a venda já estava quitada.
    function RegistrarQuitacao(AIdVenda: Integer; ADataPagamento: TDateTime;
      AValorPago: Currency; const AFormaPagamento: string): Boolean;
    /// Callback do Financeiro. FATURADA -> CANCELADA e estorna o estoque.
    /// Idempotente: retorna False se a venda já estava cancelada.
    function RegistrarCancelamentoFinanceiro(AIdVenda: Integer; const AMotivo: string): Boolean;
    procedure ReenviarEmail(AIdVenda: Integer);
  end;

implementation

uses
  System.Variants, FireDAC.Stan.Param, uExcecoes, uFilaIntegracao;

constructor TVendaService.Create(AConexao: TFDConnection);
begin
  inherited Create;
  FConexao := AConexao;
end;

function TVendaService.StatusAtual(AIdVenda: Integer): string;
var
  Valor: Variant;
begin
  Valor := FConexao.ExecSQLScalar('SELECT STATUS FROM VENDA WHERE ID = :ID', [AIdVenda]);
  if VarIsNull(Valor) or VarIsEmpty(Valor) then
    raise ENaoEncontrado.CreateFmt('Venda %d não encontrada.', [AIdVenda]);
  Result := Valor;
end;

function TVendaService.Salvar(AIdVenda, AIdCliente: Integer; AData: TDateTime;
  const AObservacao: string; AItens: TDataSet): Integer;
var
  Total: Currency;
  Ativo: Variant;
begin
  if AIdCliente <= 0 then
    raise EValidacao.Create('Informe o cliente da venda.');
  if AItens.IsEmpty then
    raise EValidacao.Create('A venda deve ter ao menos um item.');

  Ativo := FConexao.ExecSQLScalar('SELECT ATIVO FROM CLIENTE WHERE ID = :ID', [AIdCliente]);
  if VarIsNull(Ativo) or VarIsEmpty(Ativo) then
    raise EValidacao.Create('Cliente não encontrado.');
  if (AIdVenda = 0) and not Boolean(Ativo) then
    raise ERegraNegocio.Create('Não é possível abrir venda para um cliente inativo.');

  Result := AIdVenda;
  AItens.DisableControls;
  try
    Total := 0;
    AItens.First;
    while not AItens.Eof do
    begin
      if AItens.FieldByName('QUANTIDADE').AsFloat <= 0 then
        raise EValidacao.CreateFmt('Quantidade inválida no item "%s".',
          [AItens.FieldByName('DESCRICAO').AsString]);
      Total := Total + AItens.FieldByName('VALOR_TOTAL').AsCurrency;
      AItens.Next;
    end;

    FConexao.StartTransaction;
    try
      if AIdVenda = 0 then
      begin
        Result := FConexao.ExecSQLScalar('SELECT NEXT VALUE FOR GEN_VENDA_ID FROM RDB$DATABASE');
        FConexao.ExecSQL(
          'INSERT INTO VENDA (ID, ID_CLIENTE, DATA_VENDA, OBSERVACAO, VALOR_TOTAL, STATUS) ' +
          'VALUES (:ID, :CLIENTE, :DATA, :OBS, :TOTAL, ''ABERTA'')',
          [Result, AIdCliente, AData, AObservacao, Total]);
      end
      else
      begin
        if FConexao.ExecSQL(
          'UPDATE VENDA SET ID_CLIENTE = :CLIENTE, DATA_VENDA = :DATA, OBSERVACAO = :OBS, ' +
          'VALOR_TOTAL = :TOTAL WHERE ID = :ID AND STATUS = ''ABERTA''',
          [AIdCliente, AData, AObservacao, Total, AIdVenda]) = 0 then
          raise ERegraNegocio.Create('A venda não existe mais ou não está em aberto.');
        FConexao.ExecSQL('DELETE FROM VENDA_ITEM WHERE ID_VENDA = :ID', [AIdVenda]);
      end;

      AItens.First;
      while not AItens.Eof do
      begin
        FConexao.ExecSQL(
          'INSERT INTO VENDA_ITEM (ID_VENDA, ID_PRODUTO, QUANTIDADE, VALOR_UNITARIO, VALOR_TOTAL) ' +
          'VALUES (:VENDA, :PRODUTO, :QTD, :UNITARIO, :TOTAL)',
          [Result,
           AItens.FieldByName('ID_PRODUTO').AsInteger,
           AItens.FieldByName('QUANTIDADE').AsFloat,
           AItens.FieldByName('VALOR_UNITARIO').AsCurrency,
           AItens.FieldByName('VALOR_TOTAL').AsCurrency]);
        AItens.Next;
      end;

      FConexao.Commit;
    except
      FConexao.Rollback;
      raise;
    end;
  finally
    AItens.First;
    AItens.EnableControls;
  end;
end;

procedure TVendaService.Excluir(AIdVenda: Integer);
begin
  if FConexao.ExecSQL('DELETE FROM VENDA WHERE ID = :ID AND STATUS = ''ABERTA''', [AIdVenda]) = 0 then
    raise ERegraNegocio.CreateFmt('Somente vendas em aberto podem ser excluídas (status atual: %s).',
      [StatusAtual(AIdVenda)]);
end;

procedure TVendaService.Faturar(AIdVenda: Integer);
var
  Qry: TFDQuery;
begin
  FConexao.StartTransaction;
  try
    Qry := TFDQuery.Create(nil);
    try
      Qry.Connection := FConexao;

      Qry.Open(
        'SELECT V.STATUS, C.ATIVO, C.EMAIL, C.NOME FROM VENDA V ' +
        'JOIN CLIENTE C ON C.ID = V.ID_CLIENTE WHERE V.ID = :ID', [AIdVenda]);
      if Qry.IsEmpty then
        raise ENaoEncontrado.CreateFmt('Venda %d não encontrada.', [AIdVenda]);
      if Qry.FieldByName('STATUS').AsString <> STATUS_ABERTA then
        raise ERegraNegocio.CreateFmt('Somente vendas em aberto podem ser faturadas (status atual: %s).',
          [Qry.FieldByName('STATUS').AsString]);
      if not Qry.FieldByName('ATIVO').AsBoolean then
        raise ERegraNegocio.CreateFmt('O cliente "%s" está inativo.', [Qry.FieldByName('NOME').AsString]);
      if Trim(Qry.FieldByName('EMAIL').AsString) = '' then
        raise ERegraNegocio.Create('O cliente não possui e-mail para receber a confirmação do pedido.');
      Qry.Close;

      // Baixa de estoque: o UPDATE só afeta a linha se houver saldo suficiente
      Qry.Open(
        'SELECT I.ID_PRODUTO, P.DESCRICAO, SUM(I.QUANTIDADE) AS QUANTIDADE ' +
        'FROM VENDA_ITEM I JOIN PRODUTO P ON P.ID = I.ID_PRODUTO ' +
        'WHERE I.ID_VENDA = :ID GROUP BY I.ID_PRODUTO, P.DESCRICAO', [AIdVenda]);
      if Qry.IsEmpty then
        raise ERegraNegocio.Create('A venda não possui itens.');
      while not Qry.Eof do
      begin
        if FConexao.ExecSQL(
          'UPDATE PRODUTO SET ESTOQUE = ESTOQUE - :Q1 WHERE ID = :PRODUTO AND ESTOQUE >= :Q2',
          [Qry.FieldByName('QUANTIDADE').AsFloat, Qry.FieldByName('ID_PRODUTO').AsInteger,
           Qry.FieldByName('QUANTIDADE').AsFloat]) = 0 then
          raise ERegraNegocio.CreateFmt('Estoque insuficiente para o produto "%s".',
            [Qry.FieldByName('DESCRICAO').AsString]);
        Qry.Next;
      end;
    finally
      Qry.Free;
    end;

    if FConexao.ExecSQL(
      'UPDATE VENDA SET STATUS = ''FATURADA'', DATA_FATURAMENTO = :DATA ' +
      'WHERE ID = :ID AND STATUS = ''ABERTA''', [Now, AIdVenda]) = 0 then
      raise ERegraNegocio.Create('A venda foi alterada por outro processo. Atualize a tela e tente novamente.');

    TFilaIntegracao.Enfileirar(FConexao, FILA_ENVIAR_TITULO, AIdVenda);
    FConexao.Commit;
  except
    FConexao.Rollback;
    raise;
  end;
end;

procedure TVendaService.Cancelar(AIdVenda: Integer; const AMotivo: string);
begin
  if Trim(AMotivo) = '' then
    raise EValidacao.Create('Informe o motivo do cancelamento.');
  if FConexao.ExecSQL(
    'UPDATE VENDA SET STATUS = ''CANCELADA'', DATA_CANCELAMENTO = :DATA, MOTIVO_CANCELAMENTO = :MOTIVO ' +
    'WHERE ID = :ID AND STATUS = ''ABERTA''',
    [Now, Copy(Trim(AMotivo), 1, 200), AIdVenda]) = 0 then
    raise ERegraNegocio.CreateFmt(
      'Somente vendas em aberto podem ser canceladas aqui (status atual: %s). ' +
      'Vendas faturadas são canceladas pelo ERP Financeiro.', [StatusAtual(AIdVenda)]);
end;

function TVendaService.RegistrarQuitacao(AIdVenda: Integer; ADataPagamento: TDateTime;
  AValorPago: Currency; const AFormaPagamento: string): Boolean;
var
  Qry: TFDQuery;
  Status: string;
  Total: Currency;
begin
  if AValorPago <= 0 then
    raise EValidacao.Create('valorPago deve ser maior que zero.');

  FConexao.StartTransaction;
  try
    Qry := TFDQuery.Create(nil);
    try
      Qry.Connection := FConexao;
      Qry.Open('SELECT STATUS, VALOR_TOTAL FROM VENDA WHERE ID = :ID', [AIdVenda]);
      if Qry.IsEmpty then
        raise ENaoEncontrado.CreateFmt('Venda %d não encontrada.', [AIdVenda]);
      Status := Qry.FieldByName('STATUS').AsString;
      Total := Qry.FieldByName('VALOR_TOTAL').AsCurrency;
    finally
      Qry.Free;
    end;

    if Status = STATUS_QUITADA then
    begin
      FConexao.Commit;
      Exit(False); // repetição do mesmo callback: nada a fazer
    end;
    if Status <> STATUS_FATURADA then
      raise ERegraNegocio.CreateFmt('A venda %d não pode ser quitada (status atual: %s).', [AIdVenda, Status]);
    if AValorPago < Total then
      raise ERegraNegocio.CreateFmt('Valor pago (%s) menor que o total da venda (%s).',
        [FormatFloat(',0.00', AValorPago), FormatFloat(',0.00', Total)]);

    if FConexao.ExecSQL(
      'UPDATE VENDA SET STATUS = ''QUITADA'', DATA_QUITACAO = :DATA, VALOR_PAGO = :VALOR, ' +
      'FORMA_PAGAMENTO = :FORMA WHERE ID = :ID AND STATUS = ''FATURADA''',
      [ADataPagamento, AValorPago, Copy(AFormaPagamento, 1, 30), AIdVenda]) = 0 then
      raise ERegraNegocio.Create('A venda foi alterada por outro processo. Tente novamente.');

    TFilaIntegracao.Enfileirar(FConexao, FILA_ENVIAR_EMAIL, AIdVenda);
    FConexao.Commit;
    Result := True;
  except
    FConexao.Rollback;
    raise;
  end;
end;

function TVendaService.RegistrarCancelamentoFinanceiro(AIdVenda: Integer; const AMotivo: string): Boolean;
var
  Status: string;
begin
  FConexao.StartTransaction;
  try
    Status := StatusAtual(AIdVenda);
    if Status = STATUS_CANCELADA then
    begin
      FConexao.Commit;
      Exit(False);
    end;
    if Status <> STATUS_FATURADA then
      raise ERegraNegocio.CreateFmt('A venda %d não pode ser cancelada pelo Financeiro (status atual: %s).',
        [AIdVenda, Status]);

    if FConexao.ExecSQL(
      'UPDATE VENDA SET STATUS = ''CANCELADA'', DATA_CANCELAMENTO = :DATA, MOTIVO_CANCELAMENTO = :MOTIVO ' +
      'WHERE ID = :ID AND STATUS = ''FATURADA''',
      [Now, Copy(Trim('Financeiro: ' + AMotivo), 1, 200), AIdVenda]) = 0 then
      raise ERegraNegocio.Create('A venda foi alterada por outro processo. Tente novamente.');

    // Estorno do estoque baixado no faturamento
    FConexao.ExecSQL(
      'UPDATE PRODUTO P SET ESTOQUE = ESTOQUE + ' +
      '  (SELECT SUM(I.QUANTIDADE) FROM VENDA_ITEM I WHERE I.ID_VENDA = :VENDA1 AND I.ID_PRODUTO = P.ID) ' +
      'WHERE P.ID IN (SELECT I2.ID_PRODUTO FROM VENDA_ITEM I2 WHERE I2.ID_VENDA = :VENDA2)',
      [AIdVenda, AIdVenda]);

    FConexao.Commit;
    Result := True;
  except
    FConexao.Rollback;
    raise;
  end;
end;

procedure TVendaService.ReenviarEmail(AIdVenda: Integer);
var
  Status: string;
begin
  Status := StatusAtual(AIdVenda);
  if Status <> STATUS_QUITADA then
    raise ERegraNegocio.CreateFmt('O e-mail de confirmação só é enviado para vendas quitadas (status atual: %s).',
      [Status]);
  TFilaIntegracao.Enfileirar(FConexao, FILA_ENVIAR_EMAIL, AIdVenda);
end;

end.
