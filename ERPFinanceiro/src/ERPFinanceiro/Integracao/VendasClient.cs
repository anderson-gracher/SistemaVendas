using System;
using System.Globalization;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using ERPFinanceiro.Configuracao;
using ERPFinanceiro.Dominio;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace ERPFinanceiro.Integracao
{
    /// <summary>ERP Vendas fora do ar ou erro transitório (5xx, 408, 429, timeout): tentar de novo.</summary>
    public class VendasIndisponivelException : Exception
    {
        public VendasIndisponivelException(string mensagem, Exception interna = null) : base(mensagem, interna) { }
    }

    /// <summary>ERP Vendas recusou a notificação (4xx): repetir não resolve.</summary>
    public class VendasRejeitouException : FalhaDefinitivaException
    {
        public VendasRejeitouException(string mensagem) : base(mensagem) { }
    }

    /// <summary>
    /// Cliente REST do ERP Vendas (servidor Indy no módulo Delphi).
    ///   POST {Vendas.Url}/api/vendas/{id}/quitacao      {dataPagamento, valorPago, formaPagamento}
    ///   POST {Vendas.Url}/api/vendas/{id}/cancelamento  {motivo}
    /// O Vendas é idempotente: repetir a mesma notificação devolve 200.
    /// </summary>
    public class VendasClient
    {
        private static readonly Lazy<HttpClient> Http = new Lazy<HttpClient>(CriarHttpClient);

        private static HttpClient CriarHttpClient()
        {
            var http = new HttpClient { Timeout = TimeSpan.FromMilliseconds(Config.VendasTimeoutMs) };
            http.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
            http.DefaultRequestHeaders.Add("X-Api-Key", Config.VendasApiKey);
            http.DefaultRequestHeaders.ExpectContinue = false; // o Indy não precisa do "100-continue"
            return http;
        }

        public void NotificarQuitacao(int idVenda, DateTime dataPagamento, decimal valorPago, string formaPagamento)
        {
            var corpo = new JObject
            {
                ["dataPagamento"] = new DateTimeOffset(DateTime.SpecifyKind(dataPagamento, DateTimeKind.Local))
                    .ToString("yyyy-MM-dd'T'HH:mm:sszzz", CultureInfo.InvariantCulture),
                ["valorPago"] = valorPago,
                ["formaPagamento"] = formaPagamento ?? string.Empty
            };
            Enviar(string.Format("api/vendas/{0}/quitacao", idVenda), corpo);
        }

        public void NotificarCancelamento(int idVenda, string motivo)
        {
            var corpo = new JObject { ["motivo"] = motivo ?? string.Empty };
            Enviar(string.Format("api/vendas/{0}/cancelamento", idVenda), corpo);
        }

        private static void Enviar(string rota, JObject corpo)
        {
            var url = Config.VendasUrl.TrimEnd('/') + "/" + rota;
            HttpResponseMessage resposta;
            try
            {
                using (var conteudo = new StringContent(corpo.ToString(Formatting.None), Encoding.UTF8, "application/json"))
                    resposta = Http.Value.PostAsync(url, conteudo).GetAwaiter().GetResult();
            }
            catch (Exception ex)
            {
                throw new VendasIndisponivelException(string.Format(
                    "Não foi possível comunicar com o ERP Vendas ({0}): {1}", url, ex.GetBaseException().Message), ex);
            }

            using (resposta)
            {
                var codigo = (int)resposta.StatusCode;
                var texto = resposta.Content.ReadAsStringAsync().GetAwaiter().GetResult();
                if (resposta.IsSuccessStatusCode)
                    return;
                if (codigo >= 400 && codigo < 500 && codigo != 408 && codigo != 429)
                    throw new VendasRejeitouException(string.Format("ERP Vendas recusou (HTTP {0}): {1}", codigo, texto));
                throw new VendasIndisponivelException(string.Format("ERP Vendas respondeu HTTP {0}: {1}", codigo, texto));
            }
        }
    }
}
