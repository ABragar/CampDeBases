SET DATEFORMAT ymd

IF OBJECT_ID('tempdb..#mapping') IS NOT NULL
    DROP TABLE #mapping

--create sTypeAboQuoti Mpp ServiceID mapping

SELECT OldsTypeAboQuoti
      ,MppServiceID
      ,NULL AS newCatalogAbosID
       INTO #mapping
FROM   (
           VALUES (38 ,11740)
          ,(44 ,11740)
          ,(12 ,11720)
          ,(4 ,11749)
          ,(58 ,11787)
          ,(60 ,11787)
          ,(11 ,11719)
          ,(13 ,11721)
          ,(32 ,11735)
          ,(56 ,11756)
          ,(35 ,11738)
          ,(31 ,11734)
          ,(29 ,11732)
       )x(OldsTypeAboQuoti ,MppServiceID)
       
-- add CatalogueAbosID for Mpp ServiceID
UPDATE m
SET    newCatalogAbosID = ca.CatalogueAbosID
FROM   #mapping m
       INNER JOIN ref.CatalogueAbonnements AS ca
            ON  CAST(m.MppServiceID AS NVARCHAR) = ca.OriginalID
	
IF OBJECT_ID('tempdb..#CatalogIdMapping') IS NOT NULL
    DROP TABLE #CatalogIdMapping

SELECT CatalogueAbosId
      ,NewCatalogAbosId
       INTO                         #CatalogIdMapping
FROM   ref.CatalogueAbonnements  AS ca
       INNER JOIN import.NEO_TypeAbosQuoti a
            ON  ca.OffreAbo = a.sLibelle
       INNER JOIN #mapping m
            ON  a.sTypeAboQuoti = m.OldsTypeAboQuoti
GROUP BY
       CatalogueAbosId
      ,NewCatalogAbosId


SELECT *
       --UPDATE a
       --SET a.CatalogueAbosID = x.NewCatalogAbosId
       --,a.DebutAboDate = a.SouscriptionAboDate
FROM   Abonnements AS a
       INNER JOIN #CatalogIdMapping x
            ON  a.CatalogueAbosID = x.CatalogueAbosId
WHERE  a.SourceID = 1
       AND a.SouscriptionAboDate < '20141002'


SELECT *
       --DELETE a
FROM   Abonnements AS a
       INNER JOIN #CatalogIdMapping x
            ON  a.CatalogueAbosID = x.CatalogueAbosId
WHERE  a.SourceID = 1
       AND a.SouscriptionAboDate >= '20141002'
          