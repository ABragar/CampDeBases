USE [AmauryVUC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [etl].GetPhoneType
(
	@phone NVARCHAR(MAX)
)
RETURNS INT

BEGIN
	DECLARE @trimPhone NVARCHAR(MAX)
	SET @trimPhone = REPLACE(@phone, N' ', N'')
	
	RETURN 
	CASE 
	     WHEN (
	              LEN(@trimPhone) = 9
	              AND LEFT(@trimPhone, 1) IN (N'6', N'7')
	          ) 
	          OR (
	              LEN(@trimPhone) = 10
	              AND LEFT(@trimPhone, 2) IN (N'06', N'07')
	          ) THEN 4
	     ELSE 3
	END
END
