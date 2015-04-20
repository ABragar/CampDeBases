USE AmauryVUC
GO

IF OBJECT_ID(N'etl.PayModes' ,'V') IS NOT NULL
    DROP VIEW etl.PayModes
GO

CREATE VIEW etl.PayModes AS
	SELECT *
	FROM   ref.Misc AS m
	WHERE  m.TypeRef = N'PAYMODE'
