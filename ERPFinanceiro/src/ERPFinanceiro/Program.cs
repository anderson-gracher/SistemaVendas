using System;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Threading;
using System.Windows.Forms;
using ERPFinanceiro.Configuracao;
using ERPFinanceiro.Dados;
using ERPFinanceiro.Dominio;
using ERPFinanceiro.Infra;
using ERPFinanceiro.Integracao;
using ERPFinanceiro.Integracao.Api;
using ERPFinanceiro.Telas;

namespace ERPFinanceiro
{
    internal static class Program
    {
        [STAThread]
        private static void Main()
        {
            var cultura = new CultureInfo("pt-BR");
            CultureInfo.DefaultThreadCurrentCulture = cultura;
            CultureInfo.DefaultThreadCurrentUICulture = cultura;
            Thread.CurrentThread.CurrentCulture = cultura;
            Thread.CurrentThread.CurrentUICulture = cultura;

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.SetUnhandledExceptionMode(UnhandledExceptionMode.CatchException);
            Application.ThreadException += (s, e) => TratarErro(e.Exception);
            AppDomain.CurrentDomain.UnhandledException += (s, e) =>
                Log.Erro("Exceção não tratada", e.ExceptionObject as Exception);
            ServicePointManager.Expect100Continue = false;

            Log.Info("==== ERP Financeiro iniciando ====");

            // 1) Banco de dados (obrigatório)
            try
            {
                using (var ctx = new FinanceiroContext())
                    ctx.Titulos.Take(1).ToList();
            }
            catch (Exception ex)
            {
                Log.Erro("Falha ao conectar no banco", ex);
                Ui.Erro(null, "Não foi possível conectar ao banco de dados FINANCEIRO.FDB." + Environment.NewLine +
                              Environment.NewLine + ex.GetBaseException().Message + Environment.NewLine + Environment.NewLine +
                              "Verifique a connection string \"FinanceiroDb\" no arquivo ERPFinanceiro.exe.config.");
                return;
            }

            // 2) API REST (o sistema funciona sem ela, mas não recebe títulos do Vendas)
            IDisposable api = null;
            try
            {
                api = ServidorApi.Iniciar(Config.ApiUrl);
            }
            catch (Exception ex)
            {
                Log.Erro("Falha ao iniciar a API em " + Config.ApiUrl, ex);
                Ui.Avisar(null, string.Format(
                    "Não foi possível iniciar a API em {0}:{1}{2}{1}{1}" +
                    "O sistema continuará funcionando, mas não receberá títulos do ERP Vendas.{1}" +
                    "Verifique se a porta está livre. Para URLs diferentes de localhost, reserve-a com:{1}" +
                    "netsh http add urlacl url=http://+:9001/ user=Todos",
                    Config.ApiUrl, Environment.NewLine, ex.GetBaseException().Message));
            }

            // 3) Envio das notificações ao ERP Vendas + tela principal
            try
            {
                using (var processador = new ProcessadorNotificacoes())
                {
                    processador.Iniciar();
                    Application.Run(new FrmPrincipal(api != null ? Config.ApiUrl : null));
                }
            }
            finally
            {
                api?.Dispose();
                Log.Info("==== ERP Financeiro encerrado ====");
            }
        }

        private static void TratarErro(Exception ex)
        {
            var dono = Form.ActiveForm;
            if (ex is ValidacaoException || ex is RegraNegocioException || ex is NaoEncontradoException)
            {
                Ui.Avisar(dono, ex.Message);
                return;
            }
            Log.Erro("Erro não tratado na interface", ex);
            Ui.Erro(dono, "Ocorreu um erro inesperado:" + Environment.NewLine + Environment.NewLine +
                          ex.GetBaseException().Message);
        }
    }
}
