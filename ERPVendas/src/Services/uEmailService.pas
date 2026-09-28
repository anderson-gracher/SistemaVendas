unit uEmailService;

/// Envio de e-mail (HTML + anexo) via Indy.

interface

type
  TEmailService = class
  public
    class procedure Enviar(const ADestinatario, ANomeDestinatario, AAssunto, ACorpoHtml: string;
      const AAnexo: string = '');
  end;

implementation

uses
  System.SysUtils, IdSMTP, IdMessage, IdText, IdAttachmentFile, IdSSLOpenSSL,
  IdExplicitTLSClientServerBase, IdEMailAddress, uConfig, uLog;

class procedure TEmailService.Enviar(const ADestinatario, ANomeDestinatario, AAssunto,
  ACorpoHtml, AAnexo: string);
var
  Cfg: TConfig;
  Smtp: TIdSMTP;
  Msg: TIdMessage;
  SSL: TIdSSLIOHandlerSocketOpenSSL;
  Texto: TIdText;
  Anexo: TIdAttachmentFile;
  Destino: TIdEMailAddressItem;
begin
  Cfg := TConfig.Instancia;
  Smtp := TIdSMTP.Create(nil);
  Msg := TIdMessage.Create(nil);
  try
    Smtp.Host := Cfg.SmtpHost;
    Smtp.Port := Cfg.SmtpPorta;
    Smtp.ConnectTimeout := 15000;
    Smtp.ReadTimeout := 30000;
    if Cfg.SmtpUsuario <> '' then
    begin
      Smtp.AuthType := satDefault;
      Smtp.Username := Cfg.SmtpUsuario;
      Smtp.Password := Cfg.SmtpSenha;
    end
    else
      Smtp.AuthType := satNone;

    if Cfg.SmtpTLS > 0 then
    begin
      SSL := TIdSSLIOHandlerSocketOpenSSL.Create(Smtp);
      SSL.SSLOptions.Method := sslvTLSv1_2;
      SSL.SSLOptions.SSLVersions := [sslvTLSv1_2];
      SSL.SSLOptions.Mode := sslmClient;
      Smtp.IOHandler := SSL;
      if Cfg.SmtpTLS = 1 then
        Smtp.UseTLS := utUseImplicitTLS
      else
        Smtp.UseTLS := utUseExplicitTLS;
    end;

    Msg.From.Address := Cfg.SmtpRemetente;
    Msg.From.Name := Cfg.SmtpRemetenteNome;
    Destino := Msg.Recipients.Add;
    Destino.Address := ADestinatario;
    Destino.Name := ANomeDestinatario;
    Msg.Subject := AAssunto;
    Msg.CharSet := 'utf-8';
    Msg.Encoding := meMIME;
    Msg.ContentType := 'multipart/mixed';

    Texto := TIdText.Create(Msg.MessageParts, nil);
    Texto.ContentType := 'text/html';
    Texto.CharSet := 'utf-8';
    Texto.ContentTransfer := 'quoted-printable';
    Texto.Body.Text := ACorpoHtml;

    if (AAnexo <> '') and FileExists(AAnexo) then
    begin
      Anexo := TIdAttachmentFile.Create(Msg.MessageParts, AAnexo);
      Anexo.ContentType := 'application/pdf';
    end;

    Smtp.Connect;
    try
      Smtp.Send(Msg);
    finally
      if Smtp.Connected then
        Smtp.Disconnect;
    end;
    Log('E-mail "%s" enviado para %s.', [AAssunto, ADestinatario]);
  finally
    Msg.Free;
    Smtp.Free;
  end;
end;

end.
