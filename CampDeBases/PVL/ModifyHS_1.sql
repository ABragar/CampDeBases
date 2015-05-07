--part1	HS_1
SET DATEFORMAT ymd
DECLARE @d DATETIME = '20141002'

IF (NOT OBJECT_ID('tempdb..#prodMapping') IS NULL)
    DROP TABLE #prodMapping

CREATE TABLE #prodMapping(
	ProduitID INT
	,NewNomProduit NVARCHAR(255) 	
)

INSERT INTO #prodMapping (ProduitID,NewNomProduit)
SELECT ProduitID AS ProduitID, N'Hors-Série France Football' AS NewNomProduit
FROM ref.CatalogueProduits cp
WHERE cp.ProduitID in (1184, 52308)
--cp.OriginalID = N'HS_1' OR cp.CategorieProduit = N'HS_1'

UPDATE cp  
SET
	NomProduit = t.NewNomProduit,
	CategorieProduit = N'Offre à l''acte',
	Marque = 3
FROM ref.CatalogueProduits cp INNER JOIN #prodMapping t ON cp.ProduitID = t.ProduitID

--UPDATE aa	SET aa.NomProduit = pm.NewNomProduit
SELECT *
FROM   dbo.AchatsALActe2        AS aa 
       INNER JOIN #prodMapping  AS pm
            ON  pm.ProduitID = aa.ProduitID
WHERE  aa.achatDate < @d AND aa.MontantAchat = 3.59

--DELETE aa
SELECT *
FROM   dbo.AchatsALActe2        AS aa
       INNER JOIN #prodMapping  AS pm
            ON  pm.ProduitID = aa.ProduitID
WHERE  aa.achatDate >= @d AND aa.MontantAchat = 3.59

DROP TABLE #prodMapping


