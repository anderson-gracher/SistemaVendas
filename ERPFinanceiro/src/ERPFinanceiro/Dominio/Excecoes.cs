using System;

namespace ERPFinanceiro.Dominio
{
    /// <summary>Dado inválido (HTTP 400).</summary>
    public class ValidacaoException : Exception
    {
        public ValidacaoException(string mensagem) : base(mensagem) { }
    }

    /// <summary>Operação não permitida no estado atual ou dados conflitantes (HTTP 409).</summary>
    public class RegraNegocioException : Exception
    {
        public RegraNegocioException(string mensagem) : base(mensagem) { }
    }

    /// <summary>Registro inexistente (HTTP 404).</summary>
    public class NaoEncontradoException : Exception
    {
        public NaoEncontradoException(string mensagem) : base(mensagem) { }
    }

    /// <summary>Falha de integração que não adianta repetir (a notificação vai para ERRO).</summary>
    public class FalhaDefinitivaException : Exception
    {
        public FalhaDefinitivaException(string mensagem, Exception interna = null) : base(mensagem, interna) { }
    }
}
