using System.Web.Http;
using ERPFinanceiro.Configuracao;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;
using Owin;

namespace ERPFinanceiro.Integracao.Api
{
    /// <summary>Configuração OWIN / Web API 2 (self-host dentro do executável).</summary>
    public class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            var config = new HttpConfiguration();
            config.MapHttpAttributeRoutes();

            // Somente JSON, camelCase, datas ISO 8601 com o fuso local ("2026-09-22T10:30:00-03:00")
            config.Formatters.Remove(config.Formatters.XmlFormatter);
            var json = config.Formatters.JsonFormatter.SerializerSettings;
            json.ContractResolver = new CamelCasePropertyNamesContractResolver();
            json.DateTimeZoneHandling = DateTimeZoneHandling.Local;
            json.NullValueHandling = NullValueHandling.Include;

            config.MessageHandlers.Add(new ApiKeyHandler(Config.ApiKey));
            config.Filters.Add(new TratamentoErrosAttribute());
            config.IncludeErrorDetailPolicy = IncludeErrorDetailPolicy.Never;

            config.EnsureInitialized();
            app.UseWebApi(config);
        }
    }
}
