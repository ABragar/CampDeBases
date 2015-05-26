/************************************************************
 * Code formatted by SoftTree SQL Assistant © v7.1.246
 * Time: 26.05.2015 14:29:54
 ************************************************************/

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
	
	IF @FullTableName IN (N'import.Prospects_Cumul' ,N'import.SSO_Cumul')
	BEGIN
	    --SSO_Cumul
	    RETURN
	END

	IF @FullTableName IN (N'import.LPPROSP_Prospects' ,N'Import.LPSSO_SSO')
	BEGIN
	    --SSO 
	    EXEC sp_SaveStatisticSSO @FullTableName
	END
	ELSE
	IF EXISTS(
	       -- TIMESTAMP 
	       SELECT Column_Name
	       FROM   information_schema.columns
	       WHERE  table_schema        = @SchemaName
	              AND table_name      = @TableName
	              AND Column_Name     = N'TIMESTAMP'
	   )
	BEGIN
	    EXEC sp_SaveStatisticTimestamp @FullTableName
	END
	ELSE
	BEGIN
	    IF EXISTS(
	           --with FichierTS
	           SELECT Column_Name
	           FROM   information_schema.columns
	           WHERE  table_schema        = @SchemaName
	                  AND table_name      = @TableName
	                  AND Column_Name     = N'FichierTS'
	       )
	    BEGIN
	        IF EXISTS(
	               --with ActionID
	               SELECT Column_Name
	               FROM   information_schema.columns
	               WHERE  table_schema       = @SchemaName
	                      AND table_name     = @TableName
	                      AND Column_Name = N'ActionID'
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
	    ELSE
	    	PRINT @TableName + N' not processing!!!'
	END
END

