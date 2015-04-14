USE [AmauryVUC]
GO

/****** Object:  UserDefinedFunction [etl].[TRIM]    Script Date: 14.04.2015 17:45:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION etl.GetContenuID
(
	@MarqueID        INT
   ,@TypeContenuName     NVARCHAR(MAX)
)
RETURNS INT

BEGIN
	DECLARE @result INT
	DECLARE @TypeContenuId INT
	SET @TypeContenuId = (
	        SELECT CodeValN
	        FROM   ref.Misc a
	        WHERE  a.TypeRef = N'TYPECTNU'
	               AND Valeur = @TypeContenuName
	    )
	
	SET @result = (
	        SELECT ContenuId
	        FROM   ref.Contenus a
	        WHERE  a.MarqueID = @MarqueID
	               AND a.TypeContenu = @TypeContenuId
	    )
	
	RETURN @result
END

GO


