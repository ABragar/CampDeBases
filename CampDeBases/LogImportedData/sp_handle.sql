USE AmauryVUC
GO

ALTER PROC sp_handle @ObjId INT
AS
BEGIN
	DECLARE @SchemaName        NVARCHAR(50)
	       ,@TableName         NVARCHAR(50)
	       ,@FullTableName     NVARCHAR(100)
	
	SET @TableName = OBJECT_NAME(@ObjId)
	SET @SchemaName = OBJECT_SCHEMA_NAME(@ObjId)
	SET @FullTableName = @SchemaName + '.' + @TableName 
	
	
	IF NOT EXISTS(
	       -- NO FichierTS 
	       SELECT Column_Name
	       FROM   information_schema.columns
	       WHERE  table_schema        = @SchemaName
	              AND table_name      = @TableName
	              AND Column_Name     = N'FichierTS'
	   )
	BEGIN
	    EXEC sp_SaveStatisticNoFichierTS @FullTableName
	END
	ELSE
	BEGIN
	    IF EXISTS(
	           --with ActionID
	           SELECT Column_Name
	           FROM   information_schema.columns
	           WHERE  table_schema        = @SchemaName
	                  AND table_name      = @TableName
	                  AND Column_Name     = N'ActionID'
	       )
	    BEGIN
	        EXEC sp_SaveStatisticWithActionID @FullTableName
	    END
	    ELSE
	        --without ActionID
	    BEGIN
	        EXEC sp_SaveStatisticNoActionID @FullTableName
	    END
	END
END

