DECLARE TableNamesCursor CURSOR  
FOR
               SELECT NAME
               FROM   sys.objects  AS o
               WHERE  o.type_desc = N'USER_TABLE'
                      AND o.SCHEMA_ID = SCHEMA_ID(N'export')
                      AND o.name LIKE N'ActionID_ATOS%' 

DECLARE @ObjName NVARCHAR(255)

OPEN TableNamesCursor

FETCH NEXT FROM TableNamesCursor
INTO @ObjName
WHILE @@FETCH_STATUS = 0
BEGIN
    exec export.atosDeleteDoubles @ObjName
    
    FETCH NEXT FROM TableNamesCursor
    INTO @ObjName
END 
CLOSE TableNamesCursor
DEALLOCATE TableNamesCursor	
