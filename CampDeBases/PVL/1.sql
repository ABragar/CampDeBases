DECLARE @FichierTS NVARCHAR(255)
SET @FichierTS = N'FF_DailyOrder-14032015.csv'
DECLARE @F2 NVARCHAR(255)
SET @F2 = N'FF_Subscriptions-14032015.csv'

declare @SourceID int
declare @SourceID_Contact int

SELECT * FROM import.PVL_Achats AS pa
WHERE pa.FichierTS = @FichierTS
AND pa.ProductType = N'Service'
--(15 row(s) affected)

SELECT * FROM import.PVL_Abonnements
WHERE FichierTS = @F2