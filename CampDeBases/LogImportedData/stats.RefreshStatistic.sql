USE AmauryVUC
go
ALTER PROC stats.RefreshStatistic AS
BEGIN
DECLARE TableNamesCursor CURSOR  
FOR
    SELECT OBJECT_ID
    FROM   (
               SELECT NAME
                      ,OBJECT_ID
                     ,N'import'    AS schemaName
               FROM   sys.objects  AS o
               WHERE  o.type_desc = N'USER_TABLE'
                      AND o.SCHEMA_ID = SCHEMA_ID(N'import') 
               --UNION ALL
               --SELECT NAME
               --       ,OBJECT_ID
               --      ,N'rejet'
               --FROM   sys.objects AS o
               --WHERE  o.type_desc = N'USER_TABLE'
               --       AND o.SCHEMA_ID = SCHEMA_ID(N'rejet')
           ) i
    ORDER BY
           NAME
          ,schemaName  

DECLARE @ObjID Int

OPEN TableNamesCursor

FETCH NEXT FROM TableNamesCursor
INTO @ObjID
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC stats.selectProcessingMethod @ObjID
    
    FETCH NEXT FROM TableNamesCursor
    INTO @ObjID
END 
CLOSE TableNamesCursor
DEALLOCATE TableNamesCursor

--update TimeStamp
UPDATE i
SET    i.TIMESTAMPDATE = COALESCE(
           [CDBDataQuality].[dbo].[RexGroupAsDatetime](
               i.FichierTS
              ,N'(0[1-9]|1[0-9]|2[0-9]|3[01])(0[1-9]|1[012])[0-9]{4}'
              ,'0'
              ,'ddMMyyyy'
              ,NULL
           )
          ,[CDBDataQuality].[dbo].[RexGroupAsDatetime](
               i.FichierTS
              ,N'[0-9]{4}-(0[1-9]|1[012])-(0[1-9]|1[0-9]|2[0-9]|3[01])'
              ,'0'
              ,'yyyy-MM-dd'
              ,NULL
           )
          ,[CDBDataQuality].[dbo].[RexGroupAsDatetime](
               i.FichierTS
              ,N'[0-9]{4}(0[1-9]|1[012])(0[1-9]|1[0-9]|2[0-9]|3[01])'
              ,'0'
              ,'yyyyMMdd'
              ,NULL
           )
          ,[CDBDataQuality].[dbo].[RexGroupAsDatetime](
               i.FichierTS
              ,N'(0[1-9]|1[0-9]|2[0-9]|3[01])-(0[1-9]|1[012])-[0-9]{4}'
              ,'0'
              ,'dd-MM-yyyy'
              ,NULL
           )
       )
FROM   [STATS].[ImportDataStatistic] i	

END

