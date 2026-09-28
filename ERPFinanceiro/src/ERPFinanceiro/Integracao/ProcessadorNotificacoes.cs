using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using ERPFinanceiro.Configuracao;
using ERPFinanceiro.Dados;
using ERPFinanceiro.Dominio;
using ERPFinanceiro.Infra;

namespace ERPFinanceiro.Integracao
{
    /// <summary>
    /// Thread que envia a outbox (NOTIFICACAO_FILA) ao ERP Vendas.
    /// Falhas transitórias: backoff exponencial (1, 2, 4, 8, 16, máx. 30 min) até
    /// Fila.MaxTentativas; falhas definitivas (4xx) vão direto para ERRO.
    /// Acorda imediatamente quando uma nova notificação é enfileirada.
    /// </summary>
    public sealed class ProcessadorNotificacoes : IDisposable
    {
        private readonly AutoResetEvent _sinal = new AutoResetEvent(false);
        private readonly VendasClient _vendas = new VendasClient();
        private readonly Thread _thread;
        private volatile bool _parar;

        public ProcessadorNotificacoes()
        {
            _thread = new Thread(Executar) { IsBackground = true, Name = "ProcessadorNotificacoes" };
            Eventos.NotificacaoEnfileirada += Sinalizar;
        }

        public void Iniciar() => _thread.Start();

        public void Sinalizar() => _sinal.Set();

        public void Dispose()
        {
            Eventos.NotificacaoEnfileirada -= Sinalizar;
            _parar = true;
            _sinal.Set();
            if (_thread.IsAlive)
                _thread.Join(TimeSpan.FromSeconds(15));
            _sinal.Dispose();
        }

        private void Executar()
        {
            var intervalo = TimeSpan.FromSeconds(Config.FilaIntervaloSegundos);
            while (!_parar)
            {
                try
                {
                    ProcessarPendentes();
                }
                catch (Exception ex)
                {
                    Log.Erro("Processador de notificações", ex);
                }
                if (!_parar)
                    _sinal.WaitOne(intervalo);
            }
        }

        private void ProcessarPendentes()
        {
            List<NotificacaoVendas> pendentes;
            using (var ctx = new FinanceiroContext())
            {
                var agora = DateTime.Now;
                pendentes = ctx.Notificacoes.AsNoTracking()
                    .Where(n => n.Status == StatusNotificacao.Pendente && n.ProximaTentativa <= agora)
                    .OrderBy(n => n.Id)
                    .Take(20)
                    .ToList();
            }

            foreach (var notificacao in pendentes)
            {
                if (_parar)
                    break;
                Processar(notificacao);
            }
        }

        private void Processar(NotificacaoVendas notificacao)
        {
            try
            {
                Titulo titulo;
                using (var ctx = new FinanceiroContext())
                    titulo = ctx.Titulos.AsNoTracking().FirstOrDefault(t => t.Id == notificacao.IdTitulo);
                if (titulo == null)
                    throw new FalhaDefinitivaException("Título não encontrado.");

                if (notificacao.Tipo == TipoNotificacao.Quitacao)
                {
                    if (!titulo.DataPagamento.HasValue || !titulo.ValorPago.HasValue)
                        throw new FalhaDefinitivaException("Título sem dados de pagamento.");
                    _vendas.NotificarQuitacao(titulo.IdVenda, titulo.DataPagamento.Value, titulo.ValorPago.Value,
                        titulo.FormaPagamento);
                }
                else if (notificacao.Tipo == TipoNotificacao.Cancelamento)
                    _vendas.NotificarCancelamento(titulo.IdVenda, titulo.MotivoCancelamento);
                else
                    throw new FalhaDefinitivaException("Tipo de notificação desconhecido: " + notificacao.Tipo);

                Atualizar(notificacao.Id, StatusNotificacao.Processado, notificacao.Tentativas + 1, null, null);
                Log.Info(string.Format("Notificação #{0} ({1}, venda {2}) entregue ao ERP Vendas.",
                    notificacao.Id, notificacao.Tipo, notificacao.IdVenda));
            }
            catch (Exception ex)
            {
                var tentativa = notificacao.Tentativas + 1;
                var definitiva = ex is FalhaDefinitivaException || tentativa >= Config.FilaMaxTentativas;
                var esperaSegundos = Math.Min(60 * (1 << Math.Min(tentativa - 1, 5)), 1800);
                var status = definitiva ? StatusNotificacao.Erro : StatusNotificacao.Pendente;
                Log.Erro(string.Format("Notificação #{0} ({1}, venda {2}) falhou [tentativa {3}, {4}]: {5}",
                    notificacao.Id, notificacao.Tipo, notificacao.IdVenda, tentativa, status, ex.Message));
                try
                {
                    Atualizar(notificacao.Id, status, tentativa, ex.Message, DateTime.Now.AddSeconds(esperaSegundos));
                }
                catch (Exception ex2)
                {
                    Log.Erro("Não foi possível registrar a falha da notificação #" + notificacao.Id, ex2);
                }
            }
            Eventos.NotificarFilaAlterada();
        }

        private static void Atualizar(int id, string status, int tentativas, string erro, DateTime? proxima)
        {
            using (var ctx = new FinanceiroContext())
            {
                var n = ctx.Notificacoes.Find(id);
                if (n == null)
                    return;
                n.Status = status;
                n.Tentativas = tentativas;
                n.UltimoErro = erro == null ? null : (erro.Length > 1000 ? erro.Substring(0, 1000) : erro);
                if (status == StatusNotificacao.Processado)
                    n.DataProcessamento = DateTime.Now;
                if (proxima.HasValue)
                    n.ProximaTentativa = proxima.Value;
                ctx.SaveChanges();
            }
        }
    }
}
