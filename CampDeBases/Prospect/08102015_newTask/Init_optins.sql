DECLARE @optin NVARCHAR(255)
DECLARE @sqlCommand NVARCHAR(MAX)
DECLARE @addSqlCommand NVARCHAR(MAX)

DECLARE optin_cursor CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY 
FOR
    SELECT optin
    FROM   (
               VALUES (N'optin_newsletter_thematique_ile_de_france')
              ,(N'optin_newsletter_thematique_paris')
              ,(N'optin_newsletter_thematique_seine_et_marne')
              ,(N'optin_newsletter_thematique_yvelines')
              ,(N'optin_newsletter_thematique_essonne')
              ,(N'optin_newsletter_thematique_hauts_de_seine')
              ,(N'optin_newsletter_thematique_seine_st_denis')
              ,(N'optin_newsletter_thematique_val_de_marne')
              ,(N'optin_newsletter_thematique_val_oise')
              ,(N'optin_newsletter_thematique_oise')
           ) x(optin)

OPEN optin_cursor
FETCH NEXT FROM optin_cursor INTO @optin
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @addSqlCommand = 
        N'
IF NOT EXISTS (
       SELECT *
       FROM   sys.columns
       WHERE  OBJECT_ID     = OBJECT_ID(N''import.LPPROSP_Prospects'')
              AND NAME      = ''' + @optin +
        '''
   )
BEGIN
    ALTER TABLE import.LPPROSP_Prospects
    ADD [' + @optin + 
        '] NVARCHAR(3)
END

IF NOT EXISTS (
       SELECT *
       FROM   sys.columns
       WHERE  OBJECT_ID     = OBJECT_ID(N''rejet.LPPROSP_Prospects'')
              AND NAME      = ''' + @optin +
        '''
   )
BEGIN
    ALTER TABLE rejet.LPPROSP_Prospects
    ADD [' + @optin + 
        '] NVARCHAR(3)
END

IF NOT EXISTS (
       SELECT *
       FROM   sys.columns
       WHERE  OBJECT_ID     = OBJECT_ID(N''import.Prospects_Cumul'')
              AND NAME      = ''' + @optin +
        '''
   )
BEGIN
    ALTER TABLE import.Prospects_Cumul
    ADD [' + @optin + '] NVARCHAR(3)
END

'
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
inner join ref.Contenus rc on rc.NomContenu=@optin
inner join brut.Contacts c 
on t.email_courant=c.OriginalID 
and c.SourceID = 4
WHERE ' + @optin + ' = 1
'
    
    EXEC sp_executesql @addSqlCommand
        ,@parameters = N'@optin nvarchar(255)'
        ,@optin = @optin
    
    
    EXEC sp_executesql @sqlCommand
        ,@parameters = N'@optin nvarchar(255)'
        ,@optin = @optin
    
    PRINT @addSqlCommand
    FETCH NEXT FROM optin_cursor INTO @optin
END
CLOSE optin_cursor
DEALLOCATE optin_cursor 

