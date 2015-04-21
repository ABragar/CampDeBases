USE AmauryVUC
GO

IF OBJECT_ID(N'ref.V_Marques' ,'V') IS NOT NULL
    DROP VIEW ref.V_Marques
GO

CREATE VIEW ref.V_Marques AS
	SELECT *
	FROM   ref.Misc AS m
	WHERE  m.TypeRef = N'MARQUE'
