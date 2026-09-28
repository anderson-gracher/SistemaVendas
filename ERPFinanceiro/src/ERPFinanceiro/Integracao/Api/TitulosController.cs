using System;
using System.Linq;
using System.Web.Http;
using ERPFinanceiro.Dominio;
using ERPFinanceiro.Servicos;

namespace ERPFinanceiro.Integracao.Api
{
    /// <summary>
    /// Endpoints de títulos:
    ///   POST /api/titulos                        (ERP Vendas envia a venda faturada; idempotente)
    ///   GET  /api/titulos?situacao=&amp;de=&amp;ate=&amp;cliente=
    ///   GET  /api/titulos/{idVenda}
    ///   POST /api/titulos/{idVenda}/quitacao     {dataPagamento, valorPago, formaPagamento}
    ///   POST /api/titulos/{idVenda}/cancelamento {motivo}
    ///   GET  /api/resumo?de=&amp;ate=&amp;cliente=
    /// </summary>
    [RoutePrefix("api")]
    public class TitulosController : ApiController
    {
        private readonly TituloService _servico = new TituloService();

        [HttpPost, Route("titulos")]
        public IHttpActionResult Criar([FromBody] TituloEntradaDto dto)
        {
            var resultado = _servico.Registrar(dto);
            var corpo = TituloDto.De(resultado.Titulo);
            if (resultado.Criado)
                return Created("api/titulos/" + resultado.Titulo.IdVenda, corpo);
            return Ok(corpo); // já existia: idempotente
        }

        [HttpGet, Route("titulos")]
        public IHttpActionResult Listar(string situacao = null, DateTime? de = null, DateTime? ate = null,
            string cliente = null)
        {
            var filtro = new FiltroTitulos { Situacao = situacao, EmissaoDe = de, EmissaoAte = ate, Cliente = cliente };
            return Ok(_servico.Consultar(filtro).Select(TituloDto.De).ToList());
        }

        [HttpGet, Route("titulos/{idVenda:int}")]
        public IHttpActionResult Obter(int idVenda)
        {
            return Ok(TituloDto.De(_servico.ObterPorVenda(idVenda)));
        }

        [HttpPost, Route("titulos/{idVenda:int}/quitacao")]
        public IHttpActionResult Quitar(int idVenda, [FromBody] QuitacaoDto dto)
        {
            if (dto == null)
                throw new ValidacaoException("Corpo da requisição ausente ou inválido.");
            var alterou = _servico.Quitar(idVenda, dto.DataPagamento ?? DateTime.Now, dto.ValorPago, dto.FormaPagamento);
            return Ok(new
            {
                titulo = TituloDto.De(_servico.ObterPorVenda(idVenda)),
                mensagem = alterou
                    ? "Quitação registrada. O ERP Vendas será notificado."
                    : "O título já estava quitado (requisição repetida)."
            });
        }

        [HttpPost, Route("titulos/{idVenda:int}/cancelamento")]
        public IHttpActionResult Cancelar(int idVenda, [FromBody] CancelamentoDto dto)
        {
            var alterou = _servico.Cancelar(idVenda, dto?.Motivo);
            return Ok(new
            {
                titulo = TituloDto.De(_servico.ObterPorVenda(idVenda)),
                mensagem = alterou
                    ? "Cancelamento registrado. O ERP Vendas será notificado."
                    : "O título já estava cancelado (requisição repetida)."
            });
        }

        [HttpGet, Route("resumo")]
        public IHttpActionResult Resumo(DateTime? de = null, DateTime? ate = null, string cliente = null)
        {
            var filtro = new FiltroTitulos { EmissaoDe = de, EmissaoAte = ate, Cliente = cliente };
            return Ok(ResumoFinanceiro.Calcular(_servico.Consultar(filtro)));
        }
    }
}
