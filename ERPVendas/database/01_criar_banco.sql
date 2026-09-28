/*
 * ERP Vendas - Criação do banco de dados (Firebird 3.0)
 *
 * Uso (a pasta C:\ERP\dados precisa existir):
 *   isql -b -q -i 01_criar_banco.sql
 *
 * Ajuste caminho, usuário e senha abaixo se necessário
 * (e também em bin\ERPVendas.ini).
 */

SET SQL DIALECT 3;
SET NAMES UTF8;

CREATE DATABASE 'localhost:C:\ERP\dados\VENDAS.FDB'
  USER 'SYSDBA' PASSWORD 'masterkey'
  PAGE_SIZE 16384
  DEFAULT CHARACTER SET UTF8 COLLATION UNICODE_CI_AI;

/* ------------------------------------------------------------------ */
/* Sequences                                                          */
/* ------------------------------------------------------------------ */
CREATE SEQUENCE GEN_CLIENTE_ID;
CREATE SEQUENCE GEN_PRODUTO_ID;
CREATE SEQUENCE GEN_VENDA_ID;
CREATE SEQUENCE GEN_VENDA_ITEM_ID;
CREATE SEQUENCE GEN_INTEGRACAO_FILA_ID;

/* ------------------------------------------------------------------ */
/* Tabelas                                                            */
/* ------------------------------------------------------------------ */
CREATE TABLE CLIENTE (
  ID              INTEGER       NOT NULL,
  NOME            VARCHAR(100)  NOT NULL,
  CPF_CNPJ        VARCHAR(18)   NOT NULL,   /* gravado normalizado (sem máscara) */
  EMAIL           VARCHAR(120)  NOT NULL,   /* destino da confirmação do pedido  */
  TELEFONE        VARCHAR(20),
  CIDADE          VARCHAR(60),
  UF              CHAR(2),
  ATIVO           BOOLEAN       DEFAULT TRUE NOT NULL,
  DATA_CADASTRO   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP NOT NULL,
  CONSTRAINT PK_CLIENTE PRIMARY KEY (ID),
  CONSTRAINT UK_CLIENTE_CPF_CNPJ UNIQUE (CPF_CNPJ)
);

CREATE TABLE PRODUTO (
  ID              INTEGER       NOT NULL,
  DESCRICAO       VARCHAR(100)  NOT NULL,
  UNIDADE         VARCHAR(6)    DEFAULT 'UN' NOT NULL,
  PRECO           NUMERIC(15,2) DEFAULT 0 NOT NULL,
  ESTOQUE         NUMERIC(15,3) DEFAULT 0 NOT NULL,
  ATIVO           BOOLEAN       DEFAULT TRUE NOT NULL,
  DATA_CADASTRO   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP NOT NULL,
  CONSTRAINT PK_PRODUTO PRIMARY KEY (ID),
  CONSTRAINT CK_PRODUTO_PRECO CHECK (PRECO >= 0)
);

/*
 * Ciclo de vida da venda:
 *   ABERTA --(faturar)--> FATURADA --(quitação no Financeiro)----> QUITADA
 *     |                      \--(cancelamento no Financeiro)--> CANCELADA
 *     \--(cancelar no Vendas)--------------------------------> CANCELADA
 */
CREATE TABLE VENDA (
  ID                   INTEGER       NOT NULL,
  ID_CLIENTE           INTEGER       NOT NULL,
  DATA_VENDA           TIMESTAMP     DEFAULT CURRENT_TIMESTAMP NOT NULL,
  OBSERVACAO           VARCHAR(500),
  VALOR_TOTAL          NUMERIC(15,2) DEFAULT 0 NOT NULL,
  STATUS               VARCHAR(10)   DEFAULT 'ABERTA' NOT NULL,
  DATA_FATURAMENTO     TIMESTAMP,
  DATA_QUITACAO        TIMESTAMP,
  VALOR_PAGO           NUMERIC(15,2),
  FORMA_PAGAMENTO      VARCHAR(30),
  DATA_CANCELAMENTO    TIMESTAMP,
  MOTIVO_CANCELAMENTO  VARCHAR(200),
  EMAIL_ENVIADO        BOOLEAN       DEFAULT FALSE NOT NULL,
  DATA_EMAIL           TIMESTAMP,
  CONSTRAINT PK_VENDA PRIMARY KEY (ID),
  CONSTRAINT FK_VENDA_CLIENTE FOREIGN KEY (ID_CLIENTE) REFERENCES CLIENTE (ID),
  CONSTRAINT CK_VENDA_STATUS CHECK (STATUS IN ('ABERTA', 'FATURADA', 'QUITADA', 'CANCELADA'))
);

CREATE TABLE VENDA_ITEM (
  ID              INTEGER       NOT NULL,
  ID_VENDA        INTEGER       NOT NULL,
  ID_PRODUTO      INTEGER       NOT NULL,
  QUANTIDADE      NUMERIC(15,3) NOT NULL,
  VALOR_UNITARIO  NUMERIC(15,2) NOT NULL,
  VALOR_TOTAL     NUMERIC(15,2) NOT NULL,
  CONSTRAINT PK_VENDA_ITEM PRIMARY KEY (ID),
  CONSTRAINT FK_VENDA_ITEM_VENDA FOREIGN KEY (ID_VENDA) REFERENCES VENDA (ID) ON DELETE CASCADE,
  CONSTRAINT FK_VENDA_ITEM_PRODUTO FOREIGN KEY (ID_PRODUTO) REFERENCES PRODUTO (ID),
  CONSTRAINT CK_VENDA_ITEM_QTD CHECK (QUANTIDADE > 0),
  CONSTRAINT CK_VENDA_ITEM_VALOR CHECK (VALOR_UNITARIO >= 0)
);

/*
 * Outbox de integração: toda comunicação de saída (título para o Financeiro,
 * e-mail de confirmação) é gravada aqui na MESMA transação da regra de negócio
 * e processada em segundo plano com retentativas (backoff exponencial).
 */
CREATE TABLE INTEGRACAO_FILA (
  ID                   INTEGER       NOT NULL,
  TIPO                 VARCHAR(30)   NOT NULL,   /* ENVIAR_TITULO | ENVIAR_EMAIL */
  ID_VENDA             INTEGER       NOT NULL,
  STATUS               VARCHAR(12)   DEFAULT 'PENDENTE' NOT NULL,
  TENTATIVAS           INTEGER       DEFAULT 0 NOT NULL,
  ULTIMO_ERRO          VARCHAR(1000),
  DATA_CRIACAO         TIMESTAMP     DEFAULT CURRENT_TIMESTAMP NOT NULL,
  PROXIMA_TENTATIVA    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP NOT NULL,
  DATA_PROCESSAMENTO   TIMESTAMP,
  CONSTRAINT PK_INTEGRACAO_FILA PRIMARY KEY (ID),
  CONSTRAINT FK_FILA_VENDA FOREIGN KEY (ID_VENDA) REFERENCES VENDA (ID) ON DELETE CASCADE,
  CONSTRAINT CK_FILA_STATUS CHECK (STATUS IN ('PENDENTE', 'PROCESSADO', 'ERRO'))
);

/* ------------------------------------------------------------------ */
/* Índices                                                            */
/* ------------------------------------------------------------------ */
CREATE INDEX IX_VENDA_STATUS ON VENDA (STATUS);
CREATE INDEX IX_VENDA_DATA ON VENDA (DATA_VENDA);
CREATE INDEX IX_FILA_PENDENTE ON INTEGRACAO_FILA (STATUS, PROXIMA_TENTATIVA);

/* ------------------------------------------------------------------ */
/* Triggers de chave primária                                         */
/* ------------------------------------------------------------------ */
SET TERM ^ ;

CREATE TRIGGER TBI_CLIENTE FOR CLIENTE ACTIVE BEFORE INSERT POSITION 0 AS
BEGIN
  IF (NEW.ID IS NULL) THEN NEW.ID = NEXT VALUE FOR GEN_CLIENTE_ID;
END^

CREATE TRIGGER TBI_PRODUTO FOR PRODUTO ACTIVE BEFORE INSERT POSITION 0 AS
BEGIN
  IF (NEW.ID IS NULL) THEN NEW.ID = NEXT VALUE FOR GEN_PRODUTO_ID;
END^

CREATE TRIGGER TBI_VENDA FOR VENDA ACTIVE BEFORE INSERT POSITION 0 AS
BEGIN
  IF (NEW.ID IS NULL) THEN NEW.ID = NEXT VALUE FOR GEN_VENDA_ID;
END^

CREATE TRIGGER TBI_VENDA_ITEM FOR VENDA_ITEM ACTIVE BEFORE INSERT POSITION 0 AS
BEGIN
  IF (NEW.ID IS NULL) THEN NEW.ID = NEXT VALUE FOR GEN_VENDA_ITEM_ID;
END^

CREATE TRIGGER TBI_INTEGRACAO_FILA FOR INTEGRACAO_FILA ACTIVE BEFORE INSERT POSITION 0 AS
BEGIN
  IF (NEW.ID IS NULL) THEN NEW.ID = NEXT VALUE FOR GEN_INTEGRACAO_FILA_ID;
END^

SET TERM ; ^

COMMIT;
