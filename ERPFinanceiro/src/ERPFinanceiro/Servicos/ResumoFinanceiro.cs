using System.Collections.Generic;
using System.Linq;
using ERPFinanceiro.Dominio;

namespace ERPFinanceiro.Servicos
{
    /// <summary>Totais por situação de um conjunto de títulos (cards da tela, relatório, API).</summary>
    public class ResumoFinanceiro
    {
        public int QtdAVencer { get; set; }
        public decimal ValorAVencer { get; set; }
        public int QtdVencido { get; set; }
        public decimal ValorVencido { get; set; }
        public int QtdQuitado { get; set; }
        public decimal ValorQuitado { get; set; }
        public decimal ValorRecebido { get; set; }
        public int QtdCancelado { get; set; }
        public decimal ValorCancelado { get; set; }

        public int QtdEmAberto => QtdAVencer + QtdVencido;
        public decimal ValorEmAberto => ValorAVencer + ValorVencido;
        public int QtdTotal => QtdEmAberto + QtdQuitado + QtdCancelado;
        /// <summary>Total faturado (exclui cancelados).</summary>
        public decimal ValorFaturado => ValorEmAberto + ValorQuitado;

        public static ResumoFinanceiro Calcular(IEnumerable<Titulo> titulos)
        {
            var lista = titulos.ToList();
            var aVencer = lista.Where(t => t.Situacao == StatusTitulo.Aberto).ToList();
            var vencidos = lista.Where(t => t.Situacao == StatusTitulo.Vencido).ToList();
            var quitados = lista.Where(t => t.Situacao == StatusTitulo.Quitado).ToList();
            var cancelados = lista.Where(t => t.Situacao == StatusTitulo.Cancelado).ToList();
            return new ResumoFinanceiro
            {
                QtdAVencer = aVencer.Count,
                ValorAVencer = aVencer.Sum(t => t.Valor),
                QtdVencido = vencidos.Count,
                ValorVencido = vencidos.Sum(t => t.Valor),
                QtdQuitado = quitados.Count,
                ValorQuitado = quitados.Sum(t => t.Valor),
                ValorRecebido = quitados.Sum(t => t.ValorPago ?? 0m),
                QtdCancelado = cancelados.Count,
                ValorCancelado = cancelados.Sum(t => t.Valor)
            };
        }
    }
}
