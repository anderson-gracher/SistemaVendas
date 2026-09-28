# ERP Financeiro (módulo C#)

Módulo financeiro do teste técnico. Ele recebe do **ERP Vendas** (Delphi) os títulos das vendas faturadas e oferece:

- **Quitação e cancelamento** de títulos. O resultado volta automaticamente ao ERP Vendas.
- **Consulta de informações financeiras**, com cards de resumo, filtros e situação de vencimento.
- **Relatório financeiro das vendas** em FastReport, agrupado por situação.

Stack: C# / .NET Framework 4.8, WinForms, DevExpress, Entity Framework 6, Firebird 3.0, FastReport .NET

---

## 1. Integração com o ERP Vendas

```
 ERP VENDAS (Delphi, porta 9000)                   ERP FINANCEIRO (C#, porta 9001)
 ───────────────────────────────                   ───────────────────────────────
 Faturar ──► POST /api/titulos ───────────────────► cria título ABERTO (idempotente)

                                                    Usuário quita/cancela na tela
                                                      └► título + NOTIFICACAO_FILA
                                                         (mesma transação)
 venda QUITADA ◄── POST /api/vendas/{id}/quitacao ◄──── processador da fila
   └► PDF + e-mail                                      (retentativas com backoff)
 venda CANCELADA ◄─ POST /api/vendas/{id}/cancelamento ◄┘
   └► estorno de estoque
```

Situações do título:

| Situação | Como surge |
|---|---|
| ABERTO | Título criado quando o ERP Vendas envia a venda faturada |
| VENCIDO | Calculada, não é gravada: título ABERTO com vencimento anterior a hoje |
| QUITADO | Quitação feita na tela ou via API |
| CANCELADO | Cancelamento feito na tela ou via API |

Quitar e cancelar só são permitidos a partir de ABERTO (inclusive quando vencido).

### Decisões técnicas

- **Decisões técnicas** 
  - Quitar ou cancelar grava o título e a notificação ao Vendas em uma única transação
  - Se o Vendas estiver fora do ar, nada se perde: uma thread reenvia com backoff exponencial de 1, 2, 4, 8 e 16 minutos, até no máximo 30 minutos. 
  - Rejeições HTTP 4xx vão direto para `ERRO`, permitindo reprocessamento na tela de Notificações
- **Idempotência.**
  - `POST /api/titulos` com um `idVenda` já existente e o mesmo valor devolve `200` com o título existente. Com valor diferente devolve `409`.
  - O índice único `UK_TITULO_VENDA` cobre o caso de duas requisições simultâneas.
  - Quitar ou cancelar duas vezes também não tem efeito colateral.
- **Concorrência.** 
  - `STATUS` é token de concorrência no EF (`[ConcurrencyCheck]`), então o UPDATE só é aplicado se o status não mudou desde a leitura. 
  - Tela e API usam o mesmo `TituloService`.
- **Threads.** 
  - A API (Web API sobre HttpListener) e a fila abrem um `DbContext` por operação. 
  - A tela recebe avisos por eventos e atualiza a grade via `BeginInvoke`.
- **Regras de quitação.**
  - Não há pagamento parcial. Valor maior que o título (juros ou multa) é permitido, com confirmação na tela.
  - A data de pagamento não pode ser futura nem anterior à emissão.
  - A forma de pagamento é obrigatória.

---

## 2. Estrutura

```
ERPFinanceiro/
├── ERPFinanceiro.sln
├── database/
│   ├── 01_criar_banco.sql       cria FINANCEIRO.FDB (TITULO, NOTIFICACAO_FILA)
│   └── criar_banco.bat
├── bin/                         saída da compilação (ERPFinanceiro.exe + .config)
└── src/ERPFinanceiro/
    ├── ERPFinanceiro.csproj     SDK-style, net48
    ├── App.config               conexão, URLs, chaves de API, EF/Firebird
    ├── Program.cs               inicialização (banco, API, fila, tela)
    ├── Configuracao/            Config (appSettings)
    ├── Infra/                   Log, Eventos
    ├── Dominio/                 Titulo, NotificacaoVendas, status, exceções
    ├── Dados/                   FinanceiroContext (EF6)
    ├── Servicos/                TituloService (regras), NotificacaoService, ResumoFinanceiro, DTOs
    ├── Integracao/
    │   ├── Api/                 Startup OWIN, TitulosController, HealthController,
    │   │                        ApiKeyHandler, TratamentoErrosAttribute
    │   ├── VendasClient.cs      cliente REST do ERP Vendas
    │   └── ProcessadorNotificacoes.cs
    ├── Relatorios/              RelatorioFinanceiro (FastReport, montado em código)
    └── Telas/                   FrmPrincipal, FrmQuitacao, FrmCancelamento, FrmFila
```

---

## 3. Pré-requisitos

- **Visual Studio 2022** 
  - com o .NetFramework 4.8 instalado
- **Firebird 3.0**. 
  - O acesso usa o `FirebirdSql.Data.FirebirdClient`, 100% gerenciado, sem precisar de `fbclient.dll`.
- **DevExpress WinForms** instalado.
  - O projeto referencia o pacote NuGet `DevExpress.Win.Grid` (versão `24.1.*`).
  - O instalador da DevExpress registra a fonte offline *"DevExpress 24.x Local"*.
  - Se a sua versão for outra, ajuste `<DevExpressVersion>` no `.csproj`.
- **FastReport .NET** (licença ou trial) instalado.
  - O projeto referencia `FastReport.dll` pela propriedade `<FastReportDir>` do `.csproj`.
  - Padrão: `C:\Program Files (x86)\FastReports\FastReport .NET\Framework 4.0\`.
- Os demais pacotes vêm do nuget.org: EntityFramework 6.4.4, EntityFramework.Firebird, FirebirdSql.Data.FirebirdClient e Microsoft.AspNet.WebApi.OwinSelfHost.

---

## 4. Como executar

1. **Banco:** execute `database\criar_banco.bat`. 
 - Ele cria `C:\ERP\dados\FINANCEIRO.FDB` com usuário `SYSDBA` e senha `masterkey`.
2. **Configuração:** 
 - `src\ERPFinanceiro\App.config`.

   | Chave | Padrão | Uso |
   |---|---|---|
   | `FinanceiroDb` (connection string) | localhost:3050, `C:\ERP\dados\FINANCEIRO.FDB` | Banco do Financeiro |
   | `Api.Url` / `Api.Key` | `http://localhost:9001` / `financeiro-chave-dev` | API que recebe os títulos |
   | `Vendas.Url` / `Vendas.ApiKey` | `http://localhost:9000` / `vendas-chave-dev` | Callbacks para o ERP Vendas |
   | `Fila.IntervaloSegundos` / `Fila.MaxTentativas` | 15 / 10 | Reenvio das notificações |
   | `Empresa.Nome` | Minha Empresa Ltda | Cabeçalho do relatório |

   Com `localhost` a API não exige administrador. Para aceitar conexões de outras máquinas, use `http://+:9001`, reserve a URL uma vez com `netsh http add urlacl url=http://+:9001/ user=Todos` e libere a porta no firewall.
3. **Compilação:** abra `ERPFinanceiro.sln` e faça *Build*. O executável vai para `bin\`. Ao editar `App.config`, recompile, ou edite direto o `bin\ERPFinanceiro.exe.config`.
4. **Execução:** rode `bin\ERPFinanceiro.exe`. A barra de status mostra o banco, a API e a fila de notificações.

### Roteiro de teste integrado (com o ERP Vendas)

1. Inicie o smtp4dev, o **ERP Financeiro** e o **ERP Vendas**.
2. No Vendas, fature uma venda. Em poucos segundos o título aparece no Financeiro, e o card "A vencer" é atualizado.
3. No Financeiro, selecione o título e clique em **Quitar**; a data, o valor e a forma vêm sugeridos. Confirme.
4. A notificação é enviada ao Vendas. A venda fica QUITADA, o PDF é gerado e o e-mail chega no smtp4dev.
5. Para testar o cancelamento, fature outra venda e clique em **Cancelar** no Financeiro. A venda é cancelada no Vendas e o estoque é estornado.
6. Para testar a resiliência, feche o Vendas e quite um título. A notificação fica PENDENTE com o erro e a próxima tentativa. Ao abrir o Vendas de novo, ela é entregue sozinha; o botão **Processar agora** antecipa o envio.

### Testes da API sem o ERP Vendas (curl)

```bash
curl http://localhost:9001/api/health

curl -X POST http://localhost:9001/api/titulos -H "Content-Type: application/json" -H "X-Api-Key: financeiro-chave-dev" ^
  -d "{\"idVenda\":501,\"clienteNome\":\"Maria Aparecida Souza\",\"clienteDocumento\":\"52998224725\",\"clienteEmail\":\"maria@exemplo.com.br\",\"valor\":150.00,\"dataEmissao\":\"2026-09-22T10:00:00-03:00\",\"dataVencimento\":\"2026-10-22T00:00:00-03:00\"}"

curl "http://localhost:9001/api/titulos?situacao=EM_ABERTO" -H "X-Api-Key: financeiro-chave-dev"
curl "http://localhost:9001/api/resumo?de=2026-09-01&ate=2026-09-30" -H "X-Api-Key: financeiro-chave-dev"
```

- Repetir o POST devolve `200`; com outro valor, `409`.
- Sem a chave, a resposta é `401`.
- Uma quitação feita para uma venda que não existe no Vendas vai para `ERRO` na fila, porque o Vendas responde `404`.

---

## 5. Contrato da API

Base: `http://localhost:9001`. Todas as rotas, exceto `/api/health`, exigem o header `X-Api-Key`. As respostas são JSON em camelCase; as datas seguem o ISO 8601 com fuso (`2026-09-22T10:30:00-03:00`).

| Método e rota | Corpo | Resposta |
|---|---|---|
| `GET /api/health` | — | `200 {status, servico, dataHora}` |
| `POST /api/titulos` | `{idVenda, clienteNome, clienteDocumento, clienteEmail, valor, dataEmissao, dataVencimento}` | `201` criado, `200` já existia, `409` valor divergente |
| `GET /api/titulos?situacao=&de=&ate=&cliente=` | — | `200 [titulo]` |
| `GET /api/titulos/{idVenda}` | — | `200 titulo` ou `404` |
| `POST /api/titulos/{idVenda}/quitacao` | `{dataPagamento?, valorPago, formaPagamento}` | `200 {titulo, mensagem}` |
| `POST /api/titulos/{idVenda}/cancelamento` | `{motivo}` | `200 {titulo, mensagem}` |
| `GET /api/resumo?de=&ate=&cliente=` | — | `200 {qtdAVencer, valorAVencer, qtdVencido, valorVencido, valorRecebido, ...}` |

Valores aceitos em `situacao`: `EM_ABERTO`, `ABERTO` (a vencer), `VENCIDO`, `QUITADO` ou `CANCELADO`.

Erros vêm no formato `{"erro": "mensagem"}`:

| Código | Situação |
|---|---|
| 400 | Dados inválidos |
| 401 | Chave de API inválida ou ausente |
| 404 | Título não encontrado |
| 409 | Transição não permitida ou conflito |
| 500 | Erro interno |

Callbacks enviados ao ERP Vendas (contrato do módulo Delphi):

| Método e rota | Corpo |
|---|---|
| `POST {Vendas.Url}/api/vendas/{id}/quitacao` | `{dataPagamento, valorPago, formaPagamento}` |
| `POST {Vendas.Url}/api/vendas/{id}/cancelamento` | `{motivo}` |

---