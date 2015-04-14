USE [AmauryVUC]
GO

/****** Object:  UserDefinedFunction [etl].[TRIM]    Script Date: 14.04.2015 17:45:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION etl.GetMarqueID(@markName NVARCHAR(MAX))
RETURNS int
BEGIN
 
DECLARE @result int
	set @result = (SELECT
       	m.CodeValN
       FROM
       	ref.Misc AS m
       WHERE m.TypeRef = N'MARQUE'
       AND m.Valeur = @markName) 
RETURN @result
END

GO


