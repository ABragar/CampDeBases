@echo on

set rwork=D:\Projects\Camp de bases\Projects\PVL
rem cd "%rwork%\ImportData"

for %%A in (
26032015
) do (
echo Traitement de %%A commence
time /t
echo %%A
call VEL_FF.bat %%A
if %ERRORLEVEL% NEQ 0 goto finerr
)
goto finnorm
:finerr
echo Programme termine en erreur
time /t
exit /b
:finnorm
pause