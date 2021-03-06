ALTER PROC export.atosDeleteDoubles @TableName NVARCHAR(255) AS

BEGIN
	DECLARE @FullTableName NVARCHAR(255) = N'export.' + @TableName
	DECLARE @FildList NVARCHAR(255) = N''
	DECLARE @Condition NVARCHAR(255) = N''
	DECLARE @TableNameTimestamp NVARCHAR(255) =  @FullTableName+N'_' +(SELECT Replace(REPLACE(Convert(NVARCHAR(19),GETDATE(),126),'-',''),':',''))
	DECLARE TableColumnCursor CURSOR  
	FOR
	    SELECT Column_name
	    FROM   INFORMATION_SCHEMA.[COLUMNS] AS c
	    WHERE  c.TABLE_NAME = @TableName AND c.TABLE_SCHEMA = N'export'
	
	DECLARE @FieldName NVARCHAR(255)
	
	OPEN TableColumnCursor
	
	FETCH NEXT FROM TableColumnCursor
	INTO @FieldName
	WHILE @@FETCH_STATUS = 0
	BEGIN
	    IF @FieldName <> N'ActionID'
	    BEGIN
	        IF @FildList <> N''
	            SET @FildList = @FildList + ',';
	        SET @FildList = @FildList + @FieldName
	        
	        IF @Condition <> N''
	            SET @Condition = @Condition + ' and ';
	        SET @Condition = @Condition + N'X1.' + @FieldName + N'=X2.' + @FieldName
	    END
	    
	    FETCH NEXT FROM TableColumnCursor
	    INTO @FieldName
	END 
	CLOSE TableColumnCursor
	DEALLOCATE TableColumnCursor
	
	DECLARE @SqlCommand NVARCHAR(MAX)
	
	SET @SqlCommand = 
	    N'
DECLARE @D DATETIME = GETDATE()
SELECT Replace(REPLACE(Convert(NVARCHAR(19),@D,126),''-'',''''),'':'','''')	    
	    
SELECT * 
INTO '+@TableNameTimestamp+'
FROM '+@FullTableName+'

SELECT DISTINCT * 
INTO #distinct
FROM '+@FullTableName+'

TRUNCATE TABLE '+@FullTableName+'

INSERT INTO '+@FullTableName+'
SELECT * FROM #distinct AS t
	    
SELECT DISTINCT *
       INTO     #varians
FROM   (
           SELECT COUNT(*) OVER(PARTITION BY ' + @FildList + 
	    ') N
                 ,*
           FROM   ' + @FullTableName + 
	    '
       )        x
WHERE  N <> 1
ORDER BY ActionID

SELECT ' + @FildList + 
	    '
      ,Actions
       INTO #Groups
FROM   (
           SELECT ' + @FildList + 
	    '
                 ,(
                      SELECT ActionID + ''''
                      FROM   #varians X2
                      WHERE  ' + @Condition + 
	    ' FOR XML PATH('''')
                  ) AS Actions
           FROM   #varians X1
           GROUP BY ' + @FildList + '
       ) xxx
GROUP BY ' + @FildList + 
	    '
      ,Actions
ORDER BY
       Actions

UPDATE g
SET    actions = CASE 
                      WHEN actions LIKE(''12'') THEN 1
                      WHEN actions LIKE(''1%3'') THEN 0
                      WHEN actions LIKE(''23'') THEN 3
                      ELSE actions
                 END
FROM   #Groups G

--SELECT *
DELETE X1
FROM   ' + @FullTableName + 
	    ' X1
       INNER JOIN #Groups X2
            ON  ' + @Condition + 
	    '
WHERE  X2.Actions = 0

--SELECT *
DELETE X1
FROM   ' + @FullTableName + 
	    ' X1
       INNER JOIN #Groups X2
            ON  ' + @Condition + 
	    '
WHERE  X1.actionID <> X2.actions

DROP TABLE #varians
DROP TABLE #Groups
DROP TABLE #distinct
'
	--select @SqlCommand
	
	EXECUTE sp_executesql @SqlCommand
END
