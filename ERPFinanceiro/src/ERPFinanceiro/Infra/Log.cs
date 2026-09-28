using System;
using System.IO;
using System.Text;
using System.Threading;

namespace ERPFinanceiro.Infra
{
    /// <summary>Log em arquivo, thread-safe: &lt;exe&gt;\logs\ERPFinanceiro_aaaammdd.log</summary>
    public static class Log
    {
        private static readonly object Trava = new object();

        public static void Info(string mensagem) => Gravar("INFO", mensagem);

        public static void Erro(string mensagem, Exception ex = null) =>
            Gravar("ERRO", ex == null ? mensagem : mensagem + ": " + ex);

        private static void Gravar(string nivel, string mensagem)
        {
            try
            {
                var pasta = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "logs");
                var arquivo = Path.Combine(pasta, "ERPFinanceiro_" + DateTime.Now.ToString("yyyyMMdd") + ".log");
                var linha = string.Format("{0:HH:mm:ss.fff} [{1,3}] {2} {3}{4}", DateTime.Now,
                    Thread.CurrentThread.ManagedThreadId, nivel, mensagem, Environment.NewLine);
                lock (Trava)
                {
                    Directory.CreateDirectory(pasta);
                    File.AppendAllText(arquivo, linha, new UTF8Encoding(false));
                }
            }
            catch
            {
                // o log nunca pode derrubar a aplicação
            }
        }
    }
}
