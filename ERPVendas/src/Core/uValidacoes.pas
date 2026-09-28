unit uValidacoes;

interface

function SomenteDigitos(const ATexto: string): string;
function NormalizarDocumento(const ATexto: string): string;
function CPFValido(const ACPF: string): Boolean;
function CNPJValido(const ACNPJ: string): Boolean;
function DocumentoValido(const ADocumento: string): Boolean;
function FormatarDocumento(const ADocumento: string): string;
function EmailValido(const AEmail: string): Boolean;

implementation

uses
  System.SysUtils, System.RegularExpressions;

function SomenteDigitos(const ATexto: string): string;
var
  C: Char;
begin
  Result := '';
  for C in ATexto do
    if CharInSet(C, ['0'..'9']) then
      Result := Result + C;
end;

function NormalizarDocumento(const ATexto: string): string;
var
  C: Char;
begin
  Result := '';
  for C in UpperCase(ATexto) do
    if CharInSet(C, ['0'..'9', 'A'..'Z']) then
      Result := Result + C;
end;

function ValorCaractere(const ATexto: string; AIndice: Integer): Integer;
begin
  Result := Ord(ATexto[AIndice]) - Ord('0');
end;

function TodosIguais(const ATexto: string): Boolean;
begin
  Result := ATexto = StringOfChar(ATexto[1], Length(ATexto));
end;

function CPFValido(const ACPF: string): Boolean;
var
  D: string;
  I, Soma, Dv: Integer;
begin
  Result := False;
  D := SomenteDigitos(ACPF);
  if (Length(D) <> 11) or TodosIguais(D) then
    Exit;

  Soma := 0;
  for I := 1 to 9 do
    Inc(Soma, ValorCaractere(D, I) * (11 - I));
  Dv := 11 - (Soma mod 11);
  if Dv >= 10 then
    Dv := 0;
  if Dv <> ValorCaractere(D, 10) then
    Exit;

  Soma := 0;
  for I := 1 to 10 do
    Inc(Soma, ValorCaractere(D, I) * (12 - I));
  Dv := 11 - (Soma mod 11);
  if Dv >= 10 then
    Dv := 0;
  Result := Dv = ValorCaractere(D, 11);
end;

function CNPJValido(const ACNPJ: string): Boolean;
const
  PESOS1: array[1..12] of Integer = (5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2);
  PESOS2: array[1..13] of Integer = (6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2);
var
  D: string;
  I, Soma, Resto, Dv: Integer;
begin
  Result := False;
  D := NormalizarDocumento(ACNPJ);
  if (Length(D) <> 14) or TodosIguais(D) then
    Exit;
  // Os dígitos verificadores são sempre numéricos
  if not (CharInSet(D[13], ['0'..'9']) and CharInSet(D[14], ['0'..'9'])) then
    Exit;

  Soma := 0;
  for I := 1 to 12 do
    Inc(Soma, ValorCaractere(D, I) * PESOS1[I]);
  Resto := Soma mod 11;
  if Resto < 2 then Dv := 0 else Dv := 11 - Resto;
  if Dv <> ValorCaractere(D, 13) then
    Exit;

  Soma := 0;
  for I := 1 to 13 do
    Inc(Soma, ValorCaractere(D, I) * PESOS2[I]);
  Resto := Soma mod 11;
  if Resto < 2 then Dv := 0 else Dv := 11 - Resto;
  Result := Dv = ValorCaractere(D, 14);
end;

function DocumentoValido(const ADocumento: string): Boolean;
var
  D: string;
begin
  D := NormalizarDocumento(ADocumento);
  case Length(D) of
    11: Result := CPFValido(D);
    14: Result := CNPJValido(D);
  else
    Result := False;
  end;
end;

function FormatarDocumento(const ADocumento: string): string;
var
  D: string;
begin
  D := NormalizarDocumento(ADocumento);
  case Length(D) of
    11: Result := Copy(D, 1, 3) + '.' + Copy(D, 4, 3) + '.' + Copy(D, 7, 3) + '-' + Copy(D, 10, 2);
    14: Result := Copy(D, 1, 2) + '.' + Copy(D, 3, 3) + '.' + Copy(D, 6, 3) + '/' +
      Copy(D, 9, 4) + '-' + Copy(D, 13, 2);
  else
    Result := ADocumento;
  end;
end;

function EmailValido(const AEmail: string): Boolean;
begin
  Result := TRegEx.IsMatch(Trim(AEmail), '^[^@\s]+@[^@\s]+\.[^@\s]+$');
end;

end.
