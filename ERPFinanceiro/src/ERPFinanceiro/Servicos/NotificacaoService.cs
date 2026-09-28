using System;
using System.Collections.Generic;
using System.Linq;
using ERPFinanceiro.Dados;
using ERPFinanceiro.Dominio;
using ERPFinanceiro.Infra;

namespace ERPFinanceiro.Servicos
{
    /// <summary>Consulta e manutenção da fila de notificações ao ERP Vendas.</summary>
    public class NotificacaoService
    {
        public List<NotificacaoVendas> Listar(int maximo = 500)
        {
            using (var ctx = new FinanceiroContext())
                return ctx.Notificacoes.AsNoTracking().OrderByDescending(n => n.Id).Take(maximo).ToList();
        }

        public int ContarPorStatus(string status)
        {
            using (var ctx = new FinanceiroContext())
                return ctx.Notificacoes.Count(n => n.Status == status);
        }

        /// <summary>Devolve os itens com ERRO para a fila (zera as tentativas).</summary>
        public int ReprocessarErros()
        {
            int quantidade;
            using (var ctx = new FinanceiroContext())
            {
                var erros = ctx.Notificacoes.Where(n => n.Status == StatusNotificacao.Erro).ToList();
                var agora = DateTime.Now;
                foreach (var n in erros)
                {
                    n.Status = StatusNotificacao.Pendente;
                    n.Tentativas = 0;
                    n.ProximaTentativa = agora;
                }
                ctx.SaveChanges();
                quantidade = erros.Count;
            }
            if (quantidade > 0)
            {
                Log.Info(string.Format("{0} notificação(ões) com erro devolvidas para a fila.", quantidade));
                Eventos.NotificarNotificacaoEnfileirada();
                Eventos.NotificarFilaAlterada();
            }
            return quantidade;
        }
    }
}
