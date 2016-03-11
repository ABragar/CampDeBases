DECLARE @optin NVARCHAR(255)
DECLARE @contenuId int
DECLARE @sqlCommand NVARCHAR(MAX)
DECLARE @addSqlCommand NVARCHAR(MAX)

DECLARE optin_cursor CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY 
FOR
    SELECT optin,contenuId
    FROM   (
               VALUES (N'optin_newsletter_thematique_ile_de_france',59)
              ,(N'optin_newsletter_thematique_paris',60)
              ,(N'optin_newsletter_thematique_seine_et_marne',61)
              ,(N'optin_newsletter_thematique_yvelines',62)
              ,(N'optin_newsletter_thematique_essonne',63)
              ,(N'optin_newsletter_thematique_hauts_de_seine',64)
              ,(N'optin_newsletter_thematique_seine_st_denis',65)
              ,(N'optin_newsletter_thematique_val_de_marne',66)
              ,(N'optin_newsletter_thematique_val_oise',67)
              ,(N'optin_newsletter_thematique_oise',68)
              ,(N'optin_newsletter_thematique_medias_people',69)
              ,(N'optin_newsletter_thematique_tv',70)
             ,(N'optin_newsletter_thematique_environnement',71)
           ) x(optin,contenuId)

OPEN optin_cursor
FETCH NEXT FROM optin_cursor INTO @optin, @contenuId
WHILE @@FETCH_STATUS = 0
BEGIN
    --init value
    SET @sqlCommand = 
        'insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select
c.ProfilID
,c.ProfilID
, LEFT(t.email_courant,128)
,rc.ContenuID --,58
,1 as Valeur
,coalesce(date_souscr_nl_thematique,getdate()) as ConsentementDate
from import.LPPROSP_Prospects t
inner join ref.Contenus rc on rc.ContenuID=@contenuId
inner join brut.Contacts c 
on t.email_courant=c.OriginalID 
and c.SourceID = 4
WHERE ' + @optin + ' = 1
'
	PRINT @sqlCommand
    EXEC sp_executesql @sqlCommand
        ,@parameters = N'@optin nvarchar(255), @contenuId int'
        ,@optin = @optin
    	,@contenuId = @contenuId

    FETCH NEXT FROM optin_cursor INTO @optin, @contenuId
END
CLOSE optin_cursor
DEALLOCATE optin_cursor 

