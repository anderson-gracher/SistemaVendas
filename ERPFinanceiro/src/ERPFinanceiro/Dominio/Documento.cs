using System.Linq;

namespace ERPFinanceiro.Dominio
{
    /// <summary>Formatação de CPF/CNPJ (inclui o CNPJ alfanumérico).</summary>
    public static class Documento
    {
        public static string Normalizar(string valor) =>
            new string((valor ?? string.Empty).ToUpperInvariant().Where(char.IsLetterOrDigit).ToArray());

        public static string Formatar(string valor)
        {
            var d = Normalizar(valor);
            if (d.Length == 11)
                return string.Format("{0}.{1}.{2}-{3}", d.Substring(0, 3), d.Substring(3, 3), d.Substring(6, 3), d.Substring(9, 2));
            if (d.Length == 14)
                return string.Format("{0}.{1}.{2}/{3}-{4}", d.Substring(0, 2), d.Substring(2, 3), d.Substring(5, 3),
                    d.Substring(8, 4), d.Substring(12, 2));
            return valor;
        }
    }
}
