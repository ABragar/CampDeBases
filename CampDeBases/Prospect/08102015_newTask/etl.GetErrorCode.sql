USE [AmauryVUC]
GO

/****** Object:  UserDefinedFunction [etl].[GetErrorCode]    Script Date: 13.10.2015 21:38:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [etl].[GetErrorCode]
(
	@fullTableName     NVARCHAR(255)
   ,@columnName         NVARCHAR(255)
)
RETURNS BIGINT
AS

BEGIN
	DECLARE @result BIGINT   	
	DECLARE @shemaName NVARCHAR(255)
	SET @shemaName = OBJECT_SCHEMA_NAME(OBJECT_ID(@fullTableName));
	
	DECLARE @TableName NVARCHAR(255)
	SELECT @TableName = OBJECT_NAME(OBJECT_ID(@fullTableName))

	DECLARE @columnPos INT
	SELECT @columnPos = ordinal_position -1
	FROM   information_schema.columns
	WHERE  TABLE_SCHEMA        = @ShemaName
	       AND TABLE_NAME      = @TableName
	       AND COLUMN_NAME     = @columnName
	
	
	RETURN POWER(CAST(2 AS BIGINT) ,@columnPos)
END

GO


