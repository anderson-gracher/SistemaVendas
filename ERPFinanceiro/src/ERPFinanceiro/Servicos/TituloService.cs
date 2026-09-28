using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Data.Entity.Infrastructure;
using System.Linq;
using ERPFinanceiro.Dados;
using ERPFinanceiro.Dominio;
using ERPFinanceiro.Infra;

namespace ERPFinanceiro.Servicos
{
    /// <summary>
    /// Regras de negócio dos títulos. Usado pela tela e pela API (mesmas regras).
    /// Cada operação abre o seu próprio contexto: seguro em múltiplas threads.
    /// </summary>
    public class TituloService
    {
        private readonly Func<FinanceiroContext> _criarContexto;

        public TituloService() : this(() => new FinanceiroContext()) { }

        public TituloService(Func<FinanceiroContext> criarContexto)
        {
            _criarContexto = criarContexto;
        }

        // ------------------------------------------------------------------
        // Registro (chamado pelo ERP Vendas via POST /api/titulos)
        // ------------------------------------------------------------------

        /// <summary>
        /// Cria o título da venda. Idempotente por idVenda: se já existir com o mesmo
        /// valor, devolve o existente (Criado = false); com valor diferente, 409.
        /// </summary>
        public ResultadoRegistro Registrar(TituloEntradaDto dto)
        {
            Validar(dto);

            using (var ctx = _criarContexto())
            {
                var existente = ctx.Titulos.AsNoTracking().FirstOrDefault(t => t.IdVenda == dto.IdVenda);
                if (existente != null)
                    return Conferir(existente, dto);

                var titulo = new Titulo
                {
                    IdVenda = dto.IdVenda,
                    ClienteNome = dto.ClienteNome.Trim(),
                    ClienteDocumento = Documento.Normalizar(dto.ClienteDocumento),
                    ClienteEmail = string.IsNullOrWhiteSpace(dto.ClienteEmail) ? null : dto.ClienteEmail.Trim(),
                    Valor = Math.Round(dto.Valor, 2),
                    DataEmissao = dto.DataEmissao,
                    DataVencimento = dto.DataVencimento,
                    DataRecebimento = DateTime.Now,
                    Status = StatusTitulo.Aberto
                };
                ctx.Titulos.Add(titulo);

                try
                {
                    ctx.SaveChanges();
                }
                catch (DbUpdateException)
                {
                    // Duas requisições simultâneas para a mesma venda: a outra venceu (UK_TITULO_VENDA)
                    using (var ctx2 = _criarContexto())
                        existente = ctx2.Titulos.AsNoTracking().FirstOrDefault(t => t.IdVenda == dto.IdVenda);
                    if (existente == null)
                        throw;
                    return Conferir(existente, dto);
                }

                Log.Info(string.Format("Título da venda {0} registrado: {1:C} para {2}.",
                    titulo.IdVenda, titulo.Valor, titulo.ClienteNome));
                Eventos.NotificarTituloAlterado(titulo.IdVenda);
                return new ResultadoRegistro(titulo, true);
            }
        }

        private static ResultadoRegistro Conferir(Titulo existente, TituloEntradaDto dto)
        {
            if (existente.Valor != Math.Round(dto.Valor, 2))
                throw new RegraNegocioException(string.Format(
                    "Já existe título para a venda {0} com valor diferente ({1:N2} x {2:N2}).",
                    dto.IdVenda, existente.Valor, dto.Valor));
            return new ResultadoRegistro(existente, false);
        }

        private static void Validar(TituloEntradaDto dto)
        {
            if (dto == null)
                throw new ValidacaoException("Corpo da requisição ausente ou inválido.");
            if (dto.IdVenda <= 0)
                throw new ValidacaoException("idVenda é obrigatório.");
            if (string.IsNullOrWhiteSpace(dto.ClienteNome))
                throw new ValidacaoException("clienteNome é obrigatório.");
            if (dto.ClienteNome.Trim().Length > 100)
                throw new ValidacaoException("clienteNome deve ter no máximo 100 caracteres.");
            var documento = Documento.Normalizar(dto.ClienteDocumento);
            if (documento.Length != 11 && documento.Length != 14)
                throw new ValidacaoException("clienteDocumento deve ser um CPF (11) ou CNPJ (14).");
            if (dto.Valor <= 0)
                throw new ValidacaoException("valor deve ser maior que zero.");
            if (dto.DataEmissao == default(DateTime))
                throw new ValidacaoException("dataEmissao é obrigatória.");
            if (dto.DataVencimento == default(DateTime))
                throw new ValidacaoException("dataVencimento é obrigatória.");
            if (dto.DataVencimento.Date < dto.DataEmissao.Date)
                throw new ValidacaoException("dataVencimento não pode ser anterior à dataEmissao.");
        }

        // ------------------------------------------------------------------
        // Quitação e cancelamento (tela ou API)
        // ------------------------------------------------------------------

        /// <summary>
        /// ABERTO -> QUITADO e enfileira a notificação ao Vendas (mesma transação).
        /// Retorna false se o título já estava quitado (idempotente).
        /// </summary>
        public bool Quitar(int idVenda, DateTime dataPagamento, decimal valorPago, string formaPagamento)
        {
            if (valorPago <= 0)
                throw new ValidacaoException("O valor pago deve ser maior que zero.");
            if (dataPagamento.Date > DateTime.Today)
                throw new ValidacaoException("A data de pagamento não pode ser futura.");
            if (string.IsNullOrWhiteSpace(formaPagamento))
                throw new ValidacaoException("Informe a forma de pagamento.");

            using (var ctx = _criarContexto())
            {
                var titulo = Obter(ctx, idVenda);
                if (titulo.Status == StatusTitulo.Quitado)
                    return false;
                if (titulo.Status != StatusTitulo.Aberto)
                    throw new RegraNegocioException(string.Format(
                        "O título da venda {0} não pode ser quitado (situação: {1}).", idVenda,
                        titulo.SituacaoDescricao));
                if (valorPago < titulo.Valor)
                    throw new RegraNegocioException(string.Format(
                        "Valor pago ({0:N2}) menor que o valor do título ({1:N2}). Pagamento parcial não é suportado.",
                        valorPago, titulo.Valor));
                if (dataPagamento.Date < titulo.DataEmissao.Date)
                    throw new ValidacaoException("A data de pagamento não pode ser anterior à emissão do título.");

                titulo.Status = StatusTitulo.Quitado;
                titulo.DataPagamento = dataPagamento;
                titulo.ValorPago = Math.Round(valorPago, 2);
                titulo.FormaPagamento = Truncar(formaPagamento.Trim(), 30);
                ctx.Notificacoes.Add(NotificacaoVendas.Nova(titulo, TipoNotificacao.Quitacao));
                Salvar(ctx);
            }

            Log.Info(string.Format("Título da venda {0} quitado: {1:C} ({2}).", idVenda, valorPago, formaPagamento));
            Eventos.NotificarTituloAlterado(idVenda);
            Eventos.NotificarNotificacaoEnfileirada();
            return true;
        }

        /// <summary>
        /// ABERTO -> CANCELADO e enfileira a notificação ao Vendas (estorna o estoque lá).
        /// Retorna false se o título já estava cancelado (idempotente).
        /// </summary>
        public bool Cancelar(int idVenda, string motivo)
        {
            if (string.IsNullOrWhiteSpace(motivo))
                throw new ValidacaoException("Informe o motivo do cancelamento.");

            using (var ctx = _criarContexto())
            {
                var titulo = Obter(ctx, idVenda);
                if (titulo.Status == StatusTitulo.Cancelado)
                    return false;
                if (titulo.Status != StatusTitulo.Aberto)
                    throw new RegraNegocioException(string.Format(
                        "O título da venda {0} não pode ser cancelado (situação: {1}).", idVenda,
                        titulo.SituacaoDescricao));

                titulo.Status = StatusTitulo.Cancelado;
                titulo.DataCancelamento = DateTime.Now;
                titulo.MotivoCancelamento = Truncar(motivo.Trim(), 200);
                ctx.Notificacoes.Add(NotificacaoVendas.Nova(titulo, TipoNotificacao.Cancelamento));
                Salvar(ctx);
            }

            Log.Info(string.Format("Título da venda {0} cancelado: {1}", idVenda, motivo));
            Eventos.NotificarTituloAlterado(idVenda);
            Eventos.NotificarNotificacaoEnfileirada();
            return true;
        }

        // ------------------------------------------------------------------
        // Consultas
        // ------------------------------------------------------------------

        public Titulo ObterPorVenda(int idVenda)
        {
            using (var ctx = _criarContexto())
            {
                var titulo = ctx.Titulos.AsNoTracking().FirstOrDefault(t => t.IdVenda == idVenda);
                if (titulo == null)
                    throw new NaoEncontradoException(string.Format("Título da venda {0} não encontrado.", idVenda));
                return titulo;
            }
        }

        public List<Titulo> Consultar(FiltroTitulos filtro)
        {
            filtro = filtro ?? new FiltroTitulos();
            using (var ctx = _criarContexto())
            {
                IQueryable<Titulo> consulta = ctx.Titulos.AsNoTracking();

                if (filtro.EmissaoDe.HasValue)
                {
                    var de = filtro.EmissaoDe.Value.Date;
                    consulta = consulta.Where(t => t.DataEmissao >= de);
                }
                if (filtro.EmissaoAte.HasValue)
                {
                    var ate = filtro.EmissaoAte.Value.Date.AddDays(1);
                    consulta = consulta.Where(t => t.DataEmissao < ate);
                }

                var hoje = DateTime.Today;
                switch ((filtro.Situacao ?? string.Empty).Trim().ToUpperInvariant())
                {
                    case FiltroTitulos.EmAberto: // a vencer + vencidos
                        consulta = consulta.Where(t => t.Status == StatusTitulo.Aberto);
                        break;
                    case StatusTitulo.Aberto: // a vencer
                        consulta = consulta.Where(t => t.Status == StatusTitulo.Aberto && t.DataVencimento >= hoje);
                        break;
                    case StatusTitulo.Vencido:
                        consulta = consulta.Where(t => t.Status == StatusTitulo.Aberto && t.DataVencimento < hoje);
                        break;
                    case StatusTitulo.Quitado:
                        consulta = consulta.Where(t => t.Status == StatusTitulo.Quitado);
                        break;
                    case StatusTitulo.Cancelado:
                        consulta = consulta.Where(t => t.Status == StatusTitulo.Cancelado);
                        break;
                }

                if (!string.IsNullOrWhiteSpace(filtro.Cliente))
                {
                    var texto = filtro.Cliente.Trim();
                    var documento = Documento.Normalizar(texto);
                    consulta = documento.Length > 0 && documento.All(char.IsDigit)
                        ? consulta.Where(t => t.ClienteDocumento.Contains(documento) || t.ClienteNome.Contains(texto))
                        : consulta.Where(t => t.ClienteNome.Contains(texto));
                }

                return consulta.OrderByDescending(t => t.DataEmissao).ThenByDescending(t => t.IdVenda).ToList();
            }
        }

        // ------------------------------------------------------------------

        private static Titulo Obter(FinanceiroContext ctx, int idVenda)
        {
            var titulo = ctx.Titulos.FirstOrDefault(t => t.IdVenda == idVenda);
            if (titulo == null)
                throw new NaoEncontradoException(string.Format("Título da venda {0} não encontrado.", idVenda));
            return titulo;
        }

        private static void Salvar(FinanceiroContext ctx)
        {
            try
            {
                ctx.SaveChanges(); // título + notificação na mesma transação
            }
            catch (DbUpdateConcurrencyException)
            {
                throw new RegraNegocioException(
                    "O título foi alterado por outro usuário/processo. Atualize a consulta e tente novamente.");
            }
        }

        private static string Truncar(string texto, int tamanho) =>
            texto.Length <= tamanho ? texto : texto.Substring(0, tamanho);
    }
}
