namespace ERPFinanceiro.Dominio
{
    public static class StatusTitulo
    {
        public const string Aberto = "ABERTO";
        public const string Quitado = "QUITADO";
        public const string Cancelado = "CANCELADO";

        /// <summary>Situação derivada (não gravada): ABERTO com vencimento passado.</summary>
        public const string Vencido = "VENCIDO";

        public static string Descricao(string situacao)
        {
            switch (situacao)
            {
                case Aberto: return "A vencer";
                case Vencido: return "Vencido";
                case Quitado: return "Quitado";
                case Cancelado: return "Cancelado";
                default: return situacao;
            }
        }

        /// <summary>Ordem de exibição nos relatórios.</summary>
        public static int Ordem(string situacao)
        {
            switch (situacao)
            {
                case Vencido: return 1;
                case Aberto: return 2;
                case Quitado: return 3;
                case Cancelado: return 4;
                default: return 9;
            }
        }
    }

    public static class TipoNotificacao
    {
        public const string Quitacao = "QUITACAO";
        public const string Cancelamento = "CANCELAMENTO";
    }

    public static class StatusNotificacao
    {
        public const string Pendente = "PENDENTE";
        public const string Processado = "PROCESSADO";
        public const string Erro = "ERRO";
    }

    public static class FormasPagamento
    {
        public static readonly string[] Todas =
        {
            "PIX", "Dinheiro", "Cartão de crédito", "Cartão de débito", "Boleto", "Transferência"
        };
    }
}
