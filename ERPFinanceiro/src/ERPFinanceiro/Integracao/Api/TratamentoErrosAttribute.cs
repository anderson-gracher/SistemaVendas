using System.Net;
using System.Net.Http;
using System.Web.Http.Filters;
using ERPFinanceiro.Dominio;
using ERPFinanceiro.Infra;

namespace ERPFinanceiro.Integracao.Api
{
    /// <summary>
    /// Converte exceções em respostas JSON {"erro": "..."}:
    /// 400 validação, 404 não encontrado, 409 regra de negócio/conflito, 500 demais.
    /// </summary>
    public class TratamentoErrosAttribute : ExceptionFilterAttribute
    {
        public override void OnException(HttpActionExecutedContext contexto)
        {
            var ex = contexto.Exception;
            HttpStatusCode codigo;
            string mensagem = ex.Message;

            if (ex is ValidacaoException)
                codigo = HttpStatusCode.BadRequest;
            else if (ex is NaoEncontradoException)
                codigo = HttpStatusCode.NotFound;
            else if (ex is RegraNegocioException)
                codigo = HttpStatusCode.Conflict;
            else
            {
                codigo = HttpStatusCode.InternalServerError;
                mensagem = "Erro interno ao processar a requisição.";
                Log.Erro("Erro na API " + contexto.Request.Method + " " + contexto.Request.RequestUri, ex);
            }

            contexto.Response = contexto.Request.CreateResponse(codigo, new { erro = mensagem });
        }
    }
}
