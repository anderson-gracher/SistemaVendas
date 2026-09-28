using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;

namespace ERPFinanceiro.Integracao.Api
{
    /// <summary>Exige o header X-Api-Key em todas as rotas, exceto GET /api/health.</summary>
    public class ApiKeyHandler : DelegatingHandler
    {
        private readonly string _chave;

        public ApiKeyHandler(string chave)
        {
            _chave = chave;
        }

        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request,
            CancellationToken cancellationToken)
        {
            var caminho = request.RequestUri.AbsolutePath.TrimEnd('/');
            if (caminho.Equals("/api/health", StringComparison.OrdinalIgnoreCase))
                return base.SendAsync(request, cancellationToken);

            IEnumerable<string> valores;
            var informada = request.Headers.TryGetValues("X-Api-Key", out valores) ? valores.FirstOrDefault() : null;
            if (!string.Equals(informada, _chave, StringComparison.Ordinal))
            {
                var resposta = request.CreateResponse(HttpStatusCode.Unauthorized,
                    new { erro = "API key inválida ou ausente (header X-Api-Key)." });
                return Task.FromResult(resposta);
            }
            return base.SendAsync(request, cancellationToken);
        }
    }
}
