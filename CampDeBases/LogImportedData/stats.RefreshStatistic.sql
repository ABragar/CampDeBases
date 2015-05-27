USE AmauryVUC
go
Create PROC stats.RefreshStatistic AS
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

END

