using System;

namespace ERPFinanceiro.Infra
{
    /// <summary>
    /// Avisos entre camadas (publish/subscribe). Podem ser disparados de qualquer thread:
    /// quem assina é responsável por voltar à thread da UI (BeginInvoke).
    /// </summary>
    public static class Eventos
    {
        /// <summary>Título criado, quitado ou cancelado (parâmetro: idVenda).</summary>
        public static event Action<int> TituloAlterado;

        /// <summary>Nova notificação ao Vendas colocada na fila (acorda o processador).</summary>
        public static event Action NotificacaoEnfileirada;

        /// <summary>Uma notificação foi processada ou falhou (atualiza telas/status).</summary>
        public static event Action FilaAlterada;

        public static void NotificarTituloAlterado(int idVenda) => Disparar(() => TituloAlterado?.Invoke(idVenda));

        public static void NotificarNotificacaoEnfileirada() => Disparar(() => NotificacaoEnfileirada?.Invoke());

        public static void NotificarFilaAlterada() => Disparar(() => FilaAlterada?.Invoke());

        private static void Disparar(Action acao)
        {
            try
            {
                acao();
            }
            catch (Exception ex)
            {
                Log.Erro("Falha em assinante de evento", ex);
            }
        }
    }
}
