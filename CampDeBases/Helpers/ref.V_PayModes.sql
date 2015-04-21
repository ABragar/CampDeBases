USE AmauryVUC
GO

IF OBJECT_ID(N'ref.V_PayModes' ,'V') IS NOT NULL
    DROP VIEW ref.V_PayModes
GO

CREATE VIEW ref.V_PayModes AS
	SELECT *
	FROM   ref.Misc AS m
	WHERE  m.TypeRef = N'PAYMODE'
