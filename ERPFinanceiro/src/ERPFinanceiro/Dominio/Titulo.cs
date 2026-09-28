using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ERPFinanceiro.Dominio
{
    /// <summary>Título a receber gerado a partir de uma venda faturada no ERP Vendas.</summary>
    [Table("TITULO")]
    public class Titulo
    {
        [Key, Column("ID"), DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Column("ID_VENDA")]
        public int IdVenda { get; set; }

        [Column("CLIENTE_NOME"), Required, StringLength(100)]
        public string ClienteNome { get; set; }

        [Column("CLIENTE_DOCUMENTO"), Required, StringLength(18)]
        public string ClienteDocumento { get; set; }

        [Column("CLIENTE_EMAIL"), StringLength(120)]
        public string ClienteEmail { get; set; }

        [Column("VALOR")]
        public decimal Valor { get; set; }

        [Column("DATA_EMISSAO")]
        public DateTime DataEmissao { get; set; }

        [Column("DATA_VENCIMENTO")]
        public DateTime DataVencimento { get; set; }

        [Column("DATA_RECEBIMENTO")]
        public DateTime DataRecebimento { get; set; }

        /// <summary>
        /// Token de concorrência: o UPDATE gerado pelo EF inclui "AND STATUS = original",
        /// tornando as transições (quitar/cancelar) atômicas.
        /// </summary>
        [Column("STATUS"), Required, StringLength(10), ConcurrencyCheck]
        public string Status { get; set; }

        [Column("DATA_PAGAMENTO")]
        public DateTime? DataPagamento { get; set; }

        [Column("VALOR_PAGO")]
        public decimal? ValorPago { get; set; }

        [Column("FORMA_PAGAMENTO"), StringLength(30)]
        public string FormaPagamento { get; set; }

        [Column("DATA_CANCELAMENTO")]
        public DateTime? DataCancelamento { get; set; }

        [Column("MOTIVO_CANCELAMENTO"), StringLength(200)]
        public string MotivoCancelamento { get; set; }

        // ---------- Propriedades calculadas (não mapeadas) ----------

        [NotMapped]
        public bool Vencido => Status == StatusTitulo.Aberto && DataVencimento.Date < DateTime.Today;

        /// <summary>Status considerando o vencimento: ABERTO, VENCIDO, QUITADO ou CANCELADO.</summary>
        [NotMapped]
        public string Situacao => Vencido ? StatusTitulo.Vencido : Status;

        [NotMapped]
        public string SituacaoDescricao => StatusTitulo.Descricao(Situacao);

        [NotMapped]
        public string ClienteDocumentoFormatado => Documento.Formatar(ClienteDocumento);

        [NotMapped]
        public int DiasAtraso => Vencido ? (DateTime.Today - DataVencimento.Date).Days : 0;

        [NotMapped]
        public bool PodeQuitar => Status == StatusTitulo.Aberto;

        [NotMapped]
        public bool PodeCancelar => Status == StatusTitulo.Aberto;
    }
}
