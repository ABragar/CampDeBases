@echo off

rem Tables VEL du Parisien
rem 1 argument : 1 - date (repertoire)
setlocal

set rwork=D:\Projects\Camp de bases\Projects\PVL
set rbat=%rwork%\batVUC
set rlog=%rbat%\log\VEL
set rsql=%rbat%\sql\VEL
set rbcp=%rwork%\data\Ventes en ligne\VEL Le Parisien
set rfilebcp=%rbcp%\VEL-FF-%1
set rfmt=%rwork%\fmt\PVL
set rbase=AmauryVUC


for %%D in (
CatalogueDesOffres
Account
DailyOrder
Subscriptions
)  do (

if not %%D==Remb echo Bcp in %1 %%D commence
if not %%D==Remb time /t
echo 
if %%D==CatalogueDesOffres bcp %rbase%.import.PVL_CatalogueOffres in "%rfilebcp%\FF_%%D-%1.csv" -f "%rfmt%\PVL_CatalogueOffres.fmt" -e "%rlog%\%%D-%1.err" -T -F2 -S .\FRENCH -m10000 > "%rlog%\bcp_%%D-%1.log"
if %%D==Account bcp %rbase%.import.PVL_Utilisateur in "%rfilebcp%\FF_%%D-%1.csv" -f "%rfmt%\PVL_Utilisateur.fmt" -e "%rlog%\%%D-%1.err" -T -F2 -S .\FRENCH -m10000 > "%rlog%\bcp_%%D-%1.log"
if %%D==DailyOrder bcp %rbase%.import.PVL_Achats in "%rfilebcp%\FF_Order-%1.csv" -f "%rfmt%\PVL_Achats.fmt" -e "%rlog%\%%D-%1.err" -T -F2 -S .\FRENCH -m10000 > "%rlog%\bcp_%%D-%1.log"
if %%D==Subscriptions bcp %rbase%.import.PVL_Abonnements in "%rfilebcp%\FF_%%D-%1.csv" -f "%rfmt%\PVL_Abonnements.fmt" -e "%rlog%\%%D-%1.err" -T -F2 -S .\FRENCH -m10000 > "%rlog%\bcp_%%D-%1.log"
if %ERRORLEVEL% NEQ 0 goto finerr

echo use %rbase% > "%rsql%\rejeterPVL_%%D.sql"
echo go >> "%rsql%\rejeterPVL_%%D.sql"
if %%D==CatalogueDesOffres echo exec import.rejeterPVL_CatalogueOffres N'FF_%%D-%1.csv' >> "%rsql%\rejeterPVL_%%D.sql"
if %%D==Account echo exec import.rejeterPVL_Utilisateur_LP N'FF_%%D-%1.csv' >> "%rsql%\rejeterPVL_%%D.sql"
if %%D==DailyOrder echo exec import.rejeterPVL_Achats_LP N'FF_%%D-%1.csv' >> "%rsql%\rejeterPVL_%%D.sql"
if %%D==Subscriptions echo exec import.rejeterPVL_Abonnements_LP N'FF_%%D-%1.csv' >> "%rsql%\rejeterPVL_%%D.sql"
echo go >> "%rsql%\rejeterPVL_FF_%%D.sql"

if not %%D==Remb echo Rejet %%D-%1 
if not %%D==Remb time /t

sqlcmd -S .\FRENCH -i "%rsql%\rejeterPVL_%%D.sql" -o "%rlog%\rejeterPVL_%%D-%1.log"
if %ERRORLEVEL% NEQ 0 goto finerr

echo use %rbase% > "%rsql%\publierPVL_%%D.sql"
echo go >> "%rsql%\publierPVL_%%D.sql"
if %%D==CatalogueDesOffres echo exec import.PublierPVL_CatalogueOffres_LP N'FF_%%D-%1.csv' >> "%rsql%\publierPVL_%%D.sql"
if %%D==Account echo exec import.PublierPVL_Utilisateur_LP N'FF_%%D-%1.csv' >> "%rsql%\publierPVL_%%D.sql"
if %%D==DailyOrder echo exec import.PublierPVL_Achats_LP N'FF_%%D-%1.csv' >> "%rsql%\publierPVL_%%D.sql"
if %%D==Subscriptions echo exec import.PublierPVL_Abonnements_LP N'FF_%%D-%1.csv' >> "%rsql%\publierPVL_%%D.sql"
if %%D==Remb echo exec import.PublierPVL_Achats_Remb_LP N'FF_%%D-%1.csv' >> "%rsql%\publierPVL_%%D.sql"
echo go >> "%rsql%\publierPVL_%%D.sql"

rem echo Publication %%D-%1 
rem time /t

rem sqlcmd -S BO1 -i "%rsql%\publierPVL_%%D.sql" -o "%rlog%\publierPVL_%%D-%1.log"
rem if %ERRORLEVEL% NEQ 0 goto finerr
)

goto finnorm
:finerr
echo Traitement de %1 termine en erreur
:finnorm
echo Traitement de %1 termine avec succes
endlocal
rem Tables PVL
pause



