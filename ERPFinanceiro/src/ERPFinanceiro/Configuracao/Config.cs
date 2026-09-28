using System.Configuration;

namespace ERPFinanceiro.Configuracao
{
    /// <summary>Configurações lidas do ERPFinanceiro.exe.config (App.config).</summary>
    public static class Config
    {
        public static string ApiUrl => Ler("Api.Url", "http://localhost:9001");
        public static string ApiKey => Ler("Api.Key", "financeiro-chave-dev");

        public static string VendasUrl => Ler("Vendas.Url", "http://localhost:9000");
        public static string VendasApiKey => Ler("Vendas.ApiKey", "vendas-chave-dev");
        public static int VendasTimeoutMs => LerInteiro("Vendas.TimeoutMs", 10000);

        public static int FilaIntervaloSegundos => LerInteiro("Fila.IntervaloSegundos", 15);
        public static int FilaMaxTentativas => LerInteiro("Fila.MaxTentativas", 10);

        public static string EmpresaNome => Ler("Empresa.Nome", "Minha Empresa Ltda");

        private static string Ler(string chave, string padrao)
        {
            var valor = ConfigurationManager.AppSettings[chave];
            return string.IsNullOrWhiteSpace(valor) ? padrao : valor.Trim();
        }

        private static int LerInteiro(string chave, int padrao)
        {
            int valor;
            return int.TryParse(ConfigurationManager.AppSettings[chave], out valor) && valor > 0 ? valor : padrao;
        }
    }
}
