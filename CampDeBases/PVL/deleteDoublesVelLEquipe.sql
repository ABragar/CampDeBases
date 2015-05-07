DECLARE @d DATETIME = '20141002'

IF (NOT OBJECT_ID('tempdb..#prodMapping') IS NULL)
    DROP TABLE #prodMapping

select a.ProduitID AS OldProduitID, x.ProduitID AS newProduitID, x.NomProduit
INTO #prodMapping 
from ref.CatalogueProduits a INNER JOIN (select * from ref.CatalogueProduits a
											where a.OriginalID in (N'271922',N'271916')
										and a.SourceID=10) x ON a.PrixUnitaire = x.PrixUnitaire
where a.SourceID = 1 AND a.OriginalID in ( N'PREMIUM_1', N'PREMIUM_2' )

--UPDATE aa	SET aa.ProduitID = pm.newProduitID,aa.NomProduit = pm.NomProduit
SELECT * 
FROM dbo.AchatsALActe2 AS aa
INNER JOIN #prodMapping AS pm ON pm.OldProduitID = aa.ProduitID 
WHERE aa.achatDate < @d

--DELETE aa
SELECT * 
FROM dbo.AchatsALActe2 AS aa
INNER JOIN #prodMapping AS pm ON pm.OldProduitID = aa.ProduitID 
WHERE aa.achatDate > @d


----чем меняем
--select * from ref.CatalogueProduits a
--where a.OriginalID in (N'271922',N'271916')
--and a.SourceID=10

----что ищем

--select a.ProduitID AS OldProduitID, x.*
--INTO #prodMapping 
--from ref.CatalogueProduits a INNER JOIN (select * from ref.CatalogueProduits a
--											where a.OriginalID in (N'271922',N'271916')
--										and a.SourceID=10) x ON a.PrixUnitaire = x.PrixUnitaire
--where a.SourceID = 1 AND a.OriginalID in ( N'PREMIUM_1', N'PREMIUM_2' )




--SELECT cp.ProduitID
--  FROM ref.CatalogueProduits AS cp WHERE cp.SourceID = 10 AND cp.OriginalID = N'271922'

----- iProduitId=1 / sLibelle= Article Premium / dPrixUnitaire= 0.49 / sType_produit= PREMIUM_1 / sMarque= EQP
--SELECT * FROM ref.CatalogueProduits AS cp
--WHERE 


--select * from import.NEO_CatalogueProduit a
--where a.sType_produit like N'PREMIUM%' 

----(14188 row(s) affected)
----Catégorie de produit = Offre à l'acte
----SELECT * FROM ref.CategorieProduits AS cp
--SELECT * FROM ref.CatalogueProduits AS cp
--WHERE cp.SourceID = 10 AND cp.CategorieProduit = @CategoriaProd

--SELECT * FROM ref.Marques AS m
  

----SELECT * FROM ref.misc

--SELECT * FROM ref.CatalogueProduits AS cp
--WHERE cp.ProduitID = 1

----т.е. сейчас продажи ссылаются на ref.CatalogueProduits по ProduitID,
----а нам нужно по критериям обновить ProduitID, и мы подразумеваем что эта продукция лежит в таблице 
----правильно я понимаю

--SELECT * FROM ref.CatalogueProduits AS cp
--WHERE cp.SourceID = 10

--select * from ref.CatalogueProduits a
--where a.SourceID = 1 AND a.OriginalID in ( N'1', N'2' )

--select * from ref.CatalogueProduits a
--where a.SourceID = 1 AND a.OriginalID in ( N'PREMIUM_1', N'PREMIUM_2' )



--select * from ref.CatalogueProduits a
--where a.OriginalID in (N'271922',N'271916')
--and a.SourceID=10


select * from dbo.AchatsALActe a where a.SourceID=1 and cast(a.AchatDate as date)=a.AchatDate