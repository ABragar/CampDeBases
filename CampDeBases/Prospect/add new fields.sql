DECLARE @optin NVARCHAR(255)
DECLARE @contenuId int
DECLARE @sqlCommand NVARCHAR(MAX)
DECLARE @addSqlCommand NVARCHAR(MAX)

DECLARE optin_cursor CURSOR LOCAL STATIC READ_ONLY FORWARD_ONLY 
FOR
    SELECT optin,contenuId
    FROM   (
               VALUES (N'optin_newsletter_thematique_ile_de_france',58)
              ,(N'optin_newsletter_thematique_paris',59)
              ,(N'optin_newsletter_thematique_seine_et_marne',60)
              ,(N'optin_newsletter_thematique_yvelines',61)
              ,(N'optin_newsletter_thematique_essonne',62)
              ,(N'optin_newsletter_thematique_hauts_de_seine',63)
              ,(N'optin_newsletter_thematique_seine_st_denis',64)
              ,(N'optin_newsletter_thematique_val_de_marne',65)
              ,(N'optin_newsletter_thematique_val_oise',66)
              ,(N'optin_newsletter_thematique_oise',67)
              ,(N'optin_newsletter_thematique_medias_people',68)
              ,(N'optin_newsletter_thematique_tv',69)
             ,(N'optin_newsletter_thematique_environnement',70)
           ) x(optin,contenuId)

OPEN optin_cursor
FETCH NEXT FROM optin_cursor INTO @optin, @contenuId
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
    EXEC sp_executesql @addSqlCommand
        ,@parameters = N'@optin nvarchar(255)'
        ,@optin = @optin
    
   FETCH NEXT FROM optin_cursor INTO @optin, @contenuId
END
CLOSE optin_cursor
DEALLOCATE optin_cursor 

