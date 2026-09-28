using System;
using ERPFinanceiro.Infra;
using Microsoft.Owin.Hosting;

namespace ERPFinanceiro.Integracao.Api
{
    /// <summary>Sobe/derruba a API REST (HttpListener via OWIN).</summary>
    public static class ServidorApi
    {
        /// <param name="url">
        /// Ex.: http://localhost:9001 (não exige administrador). Para aceitar conexões de
        /// outras máquinas use http://+:9001 e reserve a URL uma vez:
        /// netsh http add urlacl url=http://+:9001/ user=Todos
        /// </param>
        public static IDisposable Iniciar(string url)
        {
            var servidor = WebApp.Start(url, app => new Startup().Configuration(app));
            Log.Info("API do Financeiro ouvindo em " + url);
            return servidor;
        }
    }
}
