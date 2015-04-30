USE AmauryVUC
GO

IF OBJECT_ID(N'ref.V_Typologies' ,'V') IS NOT NULL
    DROP VIEW ref.V_Typologies
GO

CREATE VIEW ref.V_Typologies AS
	SELECT *
	FROM   ref.Misc AS m
	WHERE  m.TypeRef = N'TYPOLOGIE'