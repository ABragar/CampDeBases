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
--       INTO            #prodMapping
FROM   ref.CatalogueProduits a
       INNER JOIN ( 
                SELECT a.ProduitID, a.NomProduit, a.PrixUnitaire
                FROM   ref.CatalogueProduits a
                WHERE  a.OriginalID IN (N'271922' ,N'271916')
                       AND a.SourceID = 10
            ) x
            ON  a.PrixUnitaire = x.PrixUnitaire
WHERE  a.SourceID = 1
       AND a.OriginalID IN (N'PREMIUM_1' ,N'PREMIUM_2')

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
