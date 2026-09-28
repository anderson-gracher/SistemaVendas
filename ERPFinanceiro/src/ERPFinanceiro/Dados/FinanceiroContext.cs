using System.Data.Entity;
using System.Data.Entity.ModelConfiguration.Conventions;
using ERPFinanceiro.Dominio;

namespace ERPFinanceiro.Dados
{
    /// <summary>
    /// Contexto EF6 sobre o FINANCEIRO.FDB (Firebird 3). O banco é criado pelo script
    /// database\01_criar_banco.sql; o EF não cria nem migra o schema (initializer nulo).
    /// Um contexto por operação: seguro para uso em threads (API e fila).
    /// </summary>
    public class FinanceiroContext : DbContext
    {
        static FinanceiroContext()
        {
            Database.SetInitializer<FinanceiroContext>(null);
        }

        public FinanceiroContext() : base("name=FinanceiroDb")
        {
            Configuration.LazyLoadingEnabled = false;
            Configuration.ProxyCreationEnabled = false;
        }

        public DbSet<Titulo> Titulos { get; set; }

        public DbSet<NotificacaoVendas> Notificacoes { get; set; }

        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            modelBuilder.Conventions.Remove<PluralizingTableNameConvention>();
            modelBuilder.Properties<decimal>().Configure(c => c.HasPrecision(15, 2));
            base.OnModelCreating(modelBuilder);
        }
    }
}
