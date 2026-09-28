@echo off
setlocal
rem ------------------------------------------------------------------
rem  Cria o banco FINANCEIRO.FDB.
rem  Ajuste o caminho do isql conforme a sua instalacao do Firebird 3.0
rem ------------------------------------------------------------------
set ISQL=C:\Program Files\Firebird\Firebird_3_0\isql.exe

if not exist "%ISQL%" (
  echo isql nao encontrado em "%ISQL%". Edite este arquivo.
  goto fim
)
if not exist "C:\ERP\dados" mkdir "C:\ERP\dados"

"%ISQL%" -b -q -i "%~dp001_criar_banco.sql"
if errorlevel 1 goto erro

echo.
echo Banco criado com sucesso: C:\ERP\dados\FINANCEIRO.FDB
goto fim

:erro
echo.
echo Falha ao criar o banco. Verifique as mensagens acima.

:fim
pause
