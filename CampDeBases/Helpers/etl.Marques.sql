USE AmauryVUC
GO

IF OBJECT_ID(N'etl.Marques' ,'V') IS NOT NULL
    DROP VIEW etl.Marques
GO

CREATE VIEW etl.Marques AS
	SELECT *
	FROM   ref.Misc AS m
	WHERE  m.TypeRef = N'MARQUE'
