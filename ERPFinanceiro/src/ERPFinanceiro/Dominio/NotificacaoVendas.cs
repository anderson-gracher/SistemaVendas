using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ERPFinanceiro.Dominio
{
    /// <summary>Item da outbox: aviso de quitação/cancelamento a ser enviado ao ERP Vendas.</summary>
    [Table("NOTIFICACAO_FILA")]
    public class NotificacaoVendas
    {
        [Key, Column("ID"), DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Column("ID_TITULO")]
        public int IdTitulo { get; set; }

        [Column("ID_VENDA")]
        public int IdVenda { get; set; }

        [Column("TIPO"), Required, StringLength(20)]
        public string Tipo { get; set; }

        [Column("STATUS"), Required, StringLength(12)]
        public string Status { get; set; }

        [Column("TENTATIVAS")]
        public int Tentativas { get; set; }

        [Column("ULTIMO_ERRO"), StringLength(1000)]
        public string UltimoErro { get; set; }

        [Column("DATA_CRIACAO")]
        public DateTime DataCriacao { get; set; }

        [Column("PROXIMA_TENTATIVA")]
        public DateTime ProximaTentativa { get; set; }

        [Column("DATA_PROCESSAMENTO")]
        public DateTime? DataProcessamento { get; set; }

        public static NotificacaoVendas Nova(Titulo titulo, string tipo)
        {
            var agora = DateTime.Now;
            return new NotificacaoVendas
            {
                IdTitulo = titulo.Id,
                IdVenda = titulo.IdVenda,
                Tipo = tipo,
                Status = StatusNotificacao.Pendente,
                Tentativas = 0,
                DataCriacao = agora,
                ProximaTentativa = agora
            };
        }
    }
}
