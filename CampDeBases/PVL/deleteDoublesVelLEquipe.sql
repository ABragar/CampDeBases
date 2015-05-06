DECLARE @d DATETIME = '20141002'
DECLARE @CategoriaProd NVARCHAR(30)  = N'Offre à l''acte'
DECLARE @NameProd NVARCHAR(30) = N'1 article L''Équipe Premium'

SELECT * FROM dbo.AchatsALActe2 AS aa
INNER JOIN ref.CatalogueProduits AS cp ON cp.ProduitID = aa.ProduitID AND cp.NomProduit = @NameProd AND cp.SourceID = 10 AND cp.CategorieProduit = @CategoriaProd
WHERE aa.achatDate < @d

--(14188 row(s) affected)
--Catégorie de produit = Offre à l'acte
--SELECT * FROM ref.CategorieProduits AS cp
SELECT * FROM ref.CatalogueProduits AS cp
WHERE cp.SourceID = 10 AND cp.CategorieProduit = @CategoriaProd

SELECT * FROM ref.Marques AS m
  

--SELECT * FROM ref.misc

SELECT * FROM ref.CatalogueProduits AS cp
WHERE cp.ProduitID = 1