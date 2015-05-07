--part2	HS_2
SET DATEFORMAT ymd
DECLARE @d DATETIME = '20141002'

IF (NOT OBJECT_ID('tempdb..#prodMapping') IS NULL)
    DROP TABLE #prodMapping

CREATE TABLE #prodMapping(
	OldProduitID INT
	,newProduitID INT
	,NomProduit NVARCHAR(255) 	
)

INSERT INTO #prodMapping
SELECT a.ProduitID  AS OldProduitID
      ,x.ProduitID  AS newProduitID
      ,x.NomProduit
FROM   ref.CatalogueProduits a
       INNER JOIN ( 
                SELECT a.ProduitID, a.NomProduit, a.PrixUnitaire
                FROM   ref.CatalogueProduits a
                WHERE  a.ProduitID =N'52652'
            ) x
            ON  a.PrixUnitaire = x.PrixUnitaire
WHERE a.OriginalID = N'HS_2' OR a.CategorieProduit = N'HS_2'

--UPDATE aa	SET aa.ProduitID = pm.newProduitID,aa.NomProduit = pm.NomProduit
SELECT *
FROM   dbo.AchatsALActe2        AS aa 
       INNER JOIN #prodMapping  AS pm
            ON  pm.OldProduitID = aa.ProduitID
WHERE  aa.achatDate < @d

--DELETE aa
SELECT *
FROM   dbo.AchatsALActe2        AS aa
       INNER JOIN #prodMapping  AS pm
            ON  pm.OldProduitID = aa.ProduitID
WHERE  aa.achatDate >= @d

DROP TABLE #prodMapping


