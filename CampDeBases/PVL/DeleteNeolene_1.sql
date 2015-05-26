USE AmauryVUC

SET DATEFORMAT ymd
--DELETE a
SELECT *
FROM   dbo.Abonnements AS a
       INNER JOIN (
                SELECT CatalogueAbosID
                FROM   ref.CatalogueAbonnements AS ca
                WHERE  ca.SourceID = 1
                       AND ca.OffreAbo IN (SELECT sLibelle
                                           FROM   import.NEO_TypeAbosQuoti a
                                           WHERE  a.sTypeAboQuoti IN (75,84,95,70,90,71,83,82,77,76,87,72,85,66,68,81,86,99))
            ) x
            ON  a.CatalogueAbosID = x.CatalogueAbosID
WHERE  a.SourceID = 1
       AND a.SouscriptionAboDate > '20141002'
