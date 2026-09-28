# ERP Vendas (módulo Delphi)

Módulo de vendas do teste técnico: 
- Cadastro de clientes, produtos e vendas
- Relatório de confirmação de pedido
- Integração REST com o ERP Financeiro

O relatório é enviado automaticamente por e-mail depois que o Financeiro confirma a quitação.

Stack: Delphi 12/13 (compatível com 10.3), VCL, FireDAC, Firebird 3.0, DevExpress VCL, ReportBuilder e Indy.

---

## 1. Visão geral da integração

```
 ERP VENDAS (Delphi)                                     ERP FINANCEIRO (C#)
 ────────────────────                                    ───────────────────
 Faturar venda ──► INTEGRACAO_FILA ──► POST /api/titulos ─────► cria título (mesma transação)   (outbox + retry)   (porta 9001)
                                                                   │ quitação /
 Servidor Indy (porta 9000) ◄──── POST /api/vendas/{id}/quitacao ──┘ cancelamento
   └─► venda QUITADA ──► fila ENVIAR_EMAIL ──► PDF (ReportBuilder) + e-mail (Indy)
```

Ciclo de vida da venda:

| De | Para | Quem dispara | Efeitos |
|---|---|---|---|
| — | ABERTA | Tela de vendas | Venda pode ser editada ou excluída |
| ABERTA | FATURADA | Botão **Faturar** | Baixa o estoque e enfileira o envio do título ao Financeiro |
| ABERTA | CANCELADA | Botão **Cancelar venda** | Motivo obrigatório (a venda ainda não foi para o Financeiro) |
| FATURADA | QUITADA | Callback do Financeiro | Enfileira o e-mail com o PDF do pedido |
| FATURADA | CANCELADA | Callback do Financeiro | Estorna o estoque |

### Decisões técnicas

**Decisões de Design**
- A mudança de status e a mensagem de integração são gravadas na mesma transação. 
- Se o Financeiro estiver fora do ar, nada se perde: uma thread reprocessa com *backoff* exponencial (1, 2, 4, 8, 16 min, até 30 min). 
- Erros definitivos (codigos  vão direto para `ERRO`, e esses itens podem ser reprocessados na tela **Fila de integração**.
**Idempotência nos dois sentidos.** 
O Vendas aceita o mesmo callback várias vezes sem efeito colateral (quitar uma venda já quitada devolve 200). Do lado do Financeiro, espera-se idempotência por `idVenda` no `POST /api/titulos`.
**Transições atômicas** 
- Toda mudança de status é feita com `UPDATE ... WHERE STATUS = <esperado>` e conferência das linhas afetadas. 
- Assim não há corrida entre a tela e o callback, e a baixa de estoque nunca deixa saldo negativo (`WHERE ESTOQUE >= :QTD`).
**Threads.** 
- O servidor HTTP e a fila usam conexões próprias, vindas do pool do FireDAC. 
- O ReportBuilder, que é VCL, gera o PDF na thread principal via `Synchronize`. 
- As telas são avisadas das mudanças por `TThread.Queue` e atualizam a grade sozinhas.
**Validações.** 
- CPF e CNPJ com dígito verificador, incluindo o **CNPJ alfanumérico** emitido desde julho de 2026;
- Também são validados e-mail e UF;
- As regras de negócio ficam em `TVendaService` e não nas telas.
**Banco de Dados**
- Utilizado o banco de dados Firebird 3.0 com os scripts de criação em database

---

## 2. Estrutura

```
ERPVendas/
├── database/
│   ├── 01_criar_banco.sql        cria VENDAS.FDB (tabelas, sequences, triggers, índices)
│   ├── 02_dados_exemplo.sql      4 clientes, 7 produtos, 1 venda aberta
│   └── criar_banco.bat           executa os dois scripts com o isql
├── bin/
│   └── ERPVendas.ini             configuração (o .exe deve ser gerado aqui)
└── src/
    ├── ERPVendas.dpr
    ├── Core/          uConfig, uLog, uExcecoes, uValidacoes, uEventos, uUtilsDB
    ├── Data/          uConexao (FireDAC + pool)
    ├── Services/      uVendaService (regras), uFilaIntegracao (outbox), uEmailService
    ├── Reports/       uRelatorioPedido (ReportBuilder, tela e PDF)
    ├── Integration/   uFinanceiroClient (REST), uProcessadorFila (thread), uServidorIntegracao (Indy)
    └── Views/         Principal, CadastroBase (herança visual), Clientes, Produtos,
                       Vendas, VendaEdit, Fila
```

---

## 3. Pré-requisitos

- **Delphi 12 ou 13** (também deve compilar no 10.3). Banco de dados aceito somente local
- **DevExpress VCL** Para acesso aos componentes VCL do Dev Express
- **ReportBuilder**, PDF nativo.
- **Firebird 3.0** instalado e em execução (servidor e `fbclient.dll`).
- Para testar o e-mail, um SMTP de testes: **smtp4dev** (recomendado) ou Mailtrap. OBS: Se for usar TLS no SMTP: DLLs do OpenSSL 1.0.2 (`libeay32.dll` e `ssleay32.dll`) ao lado do executável.

## 4. Como executar

### 4.1 Banco de dados

1. Ajuste o caminho do `isql.exe` em `database\criar_banco.bat`, se necessário.
2. Execute `criar_banco.bat`. Ele cria `C:\ERP\dados\VENDAS.FDB` com usuário `SYSDBA` e senha `masterkey`.

Para usar outro caminho ou outras credenciais, altere os dois `.sql` e o `ERPVendas.ini`.

### 4.2 Configuração

Edite `bin\ERPVendas.ini`:

| Seção | Chaves principais |
|---|---|
| `[Banco]` | Servidor, Porta, Caminho, Usuario, Senha, VendorLib (caminho da `fbclient.dll`, opcional) |
| `[Servidor]` | Porta dos callbacks (9000) e ApiKey exigida do Financeiro |
| `[Financeiro]` | Url da API (http://localhost:9001), ApiKey, TimeoutMs, DiasVencimento |
| `[Smtp]` | Host, Porta, Usuario, Senha, TLS (0 = nenhum, 1 = implícito, 2 = STARTTLS), Remetente |
| `[Fila]` | IntervaloSegundos, MaxTentativas |
| `[Geral]` | EmpresaNome (aparece no relatório) e PastaPedidos (onde os PDFs ficam salvos) |

Se o `.ini` não existir, ele é criado com esses valores padrão.

### 4.3 Compilação

1. Abra `src\ERPVendas.dpr`. O IDE cria o `.dproj` e o `.res`.
2. Em *Project > Options > Building > Delphi Compiler*, defina **Output directory** como `..\bin`.
3. Abra cada form uma vez no IDE e salve. O IDE completa as units do DevExpress e do ReportBuilder que a sua versão exigir.
4. Compile com *Build*.

### 4.4 Roteiro de teste

1. Inicie o **smtp4dev**. A interface web fica em http://localhost:5000 e o SMTP na porta 25.
2. Execute `bin\ERPVendas.exe`. A barra de status mostra o banco, a porta 9000 e a fila.
3. Em **Vendas**, crie uma venda (ou use a de número 1) e clique em **Faturar**.
   - Sem o Financeiro no ar, o item fica `PENDENTE` na **Fila de integração**, com o erro e a próxima tentativa.
4. Simule a quitação feita pelo Financeiro com curl:

```bash
curl -X POST http://localhost:9000/api/vendas/1/quitacao ^
  -H "Content-Type: application/json" -H "X-Api-Key: vendas-chave-dev" ^
  -d "{\"dataPagamento\":\"2026-09-22T10:30:00-03:00\",\"valorPago\":4479.70,\"formaPagamento\":\"PIX\"}"
```

5. A venda passa a `QUITADA` e a grade se atualiza sozinha. O PDF é gravado em `bin\pedidos\Pedido_000001.pdf` e o e-mail aparece no smtp4dev com o anexo.
6. Outros testes úteis:
   - Repetir o mesmo curl deve devolver 200 com "já estava quitada".
   - Omitir a API key deve devolver 401.
   - Usar uma venda inexistente deve devolver 404.
   - Enviar um `valorPago` menor que o total deve devolver 409.

Cancelamento pelo Financeiro (a venda precisa estar `FATURADA`):

```bash
curl -X POST http://localhost:9000/api/vendas/2/cancelamento ^
  -H "Content-Type: application/json" -H "X-Api-Key: vendas-chave-dev" ^
  -d "{\"motivo\":\"Cliente desistiu\"}"
```

Os logs ficam em `bin\logs\ERPVendas_aaaammdd.log`.

---

## 5. Contrato da API (referência para o ERP Financeiro)

### 5.1 Vendas → Financeiro

`POST {Financeiro.Url}/api/titulos`, com o header `X-Api-Key: {Financeiro.ApiKey}`.

```json
{
  "idVenda": 15,
  "clienteNome": "Maria Aparecida Souza",
  "clienteDocumento": "52998224725",
  "clienteEmail": "maria.souza@exemplo.com.br",
  "valor": 4479.70,
  "dataEmissao": "2026-09-22T14:05:31.000-03:00",
  "dataVencimento": "2026-10-22T00:00:00.000-03:00"
}
```

Respostas esperadas:

- `201` quando o título é criado.
- `200` quando o título já existia para o mesmo `idVenda` (idempotência).
- `4xx` quando os dados são inválidos. Nesse caso o item vai para `ERRO` e não é repetido.
- `5xx` ou timeout fazem o Vendas tentar de novo.

### 5.2 Financeiro → Vendas

Base: `http://{host}:{Servidor.Porta}`. Todas as rotas, exceto `/api/health`, exigem o header `X-Api-Key: {Servidor.ApiKey}`.

| Método e rota | Corpo | Sucesso |
|---|---|---|
| `GET /api/health` | — | `200 {"status":"ok"}` |
| `GET /api/vendas/{id}` | — | `200 {idVenda, status, valorTotal, dataVenda, cliente, emailEnviado}` |
| `POST /api/vendas/{id}/quitacao` | `{dataPagamento, valorPago, formaPagamento}` | `200 {idVenda, status:"QUITADA", mensagem}` |
| `POST /api/vendas/{id}/cancelamento` | `{motivo}` | `200 {idVenda, status:"CANCELADA", mensagem}` |

Erros vêm no formato `{"erro": "mensagem"}`:

| Código | Situação |
|---|---|
| 400 | JSON ou campo inválido |
| 401 | API key inválida ou ausente |
| 404 | Venda inexistente |
| 409 | Transição não permitida (por exemplo, quitar uma venda cancelada, ou valor pago menor que o total) |
| 500 | Erro interno |

As datas seguem o ISO 8601. `dataPagamento` é opcional: se não for enviada, vale a data e hora atuais.

