program ERPVendas;

uses
  Vcl.Forms,
  uConfig in 'Core\uConfig.pas',
  uLog in 'Core\uLog.pas',
  uExcecoes in 'Core\uExcecoes.pas',
  uValidacoes in 'Core\uValidacoes.pas',
  uEventos in 'Core\uEventos.pas',
  uUtilsDB in 'Core\uUtilsDB.pas',
  uConexao in 'Data\uConexao.pas',
  uFilaIntegracao in 'Services\uFilaIntegracao.pas',
  uVendaService in 'Services\uVendaService.pas',
  uEmailService in 'Services\uEmailService.pas',
  uRelatorioPedido in 'Reports\uRelatorioPedido.pas',
  uFinanceiroClient in 'Integration\uFinanceiroClient.pas',
  uProcessadorFila in 'Integration\uProcessadorFila.pas',
  uServidorIntegracao in 'Integration\uServidorIntegracao.pas',
  uFrmCadastroBase in 'Views\uFrmCadastroBase.pas' {frmCadastroBase},
  uFrmClientes in 'Views\uFrmClientes.pas' {frmClientes},
  uFrmProdutos in 'Views\uFrmProdutos.pas' {frmProdutos},
  uFrmVendaEdit in 'Views\uFrmVendaEdit.pas' {frmVendaEdit},
  uFrmVendas in 'Views\uFrmVendas.pas' {frmVendas},
  uFrmFila in 'Views\uFrmFila.pas' {frmFila},
  uFrmPrincipal in 'Views\uFrmPrincipal.pas' {frmPrincipal};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := DebugHook <> 0;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'ERP Vendas';
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.Run;
end.
