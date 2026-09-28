using System;
using System.Web.Http;

namespace ERPFinanceiro.Integracao.Api
{
    public class HealthController : ApiController
    {
        [HttpGet, Route("api/health")]
        public IHttpActionResult Get()
        {
            return Ok(new { status = "ok", servico = "ERP Financeiro", dataHora = DateTime.Now });
        }
    }
}
