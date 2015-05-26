SET DATEFORMAT ymd

IF OBJECT_ID('tempdb..#mapping') IS NOT NULL
    DROP TABLE #mapping

--create sTypeAboQuoti Mpp ServiceID mapping

SELECT OldsTypeAboQuoti
      ,MppServiceID
      ,NULL AS newCatalogAbosID
       INTO #mapping
FROM   (
           VALUES (28 ,11750)
          ,(45 ,11748)
          ,(19 ,11724)
          ,(17 ,11722)
          ,(33 ,11736)
          ,(57 ,11762)
          ,(25 ,11729)
          ,(43 ,11742)
          ,(50 ,11743)
          ,(18 ,11723)
          ,(24 ,11727)
          ,(48 ,11747)
          ,(26 ,11729)
          ,(37 ,11729)
          ,(21 ,11725)
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

IF OBJECT_ID('tempdb..#AbosMapping') IS NOT NULL
    DROP TABLE #AbosMapping
    
SELECT * 
       INTO     #AbosMapping
FROM   (
           SELECT -- COUNT(a.CatalogueAbosID) OVER(PARTITION BY a.profilid ,a.CatalogueAbosID) AS
                  --       C
                  --      ,RANK() OVER(
                  --           PARTITION BY a.profilid
                  --          ,a.CatalogueAbosID ORDER BY a.SouscriptionAboDate
                  --       )                       AS N
                  a.AbonnementID
                 ,a2.AbonnementID         AS VEL_AbonnementID
                 ,a.ProfilID
                 ,a.CatalogueAbosID
                 ,a2.CatalogueAbosID         VEL_CatalogueAbosID
                 ,a.SouscriptionAboDate
                 ,a.DebutAboDate
                 ,a.FinAboDate
                 ,a2.SouscriptionAboDate     VEL_SouscriptionAboDate
                 ,a2.DebutAboDate            VEL_DebutAboDate
                 ,a2.FinAboDate              VEL_FinAboDate
                 ,DATEDIFF(DAY ,a.FinAboDate ,a2.SouscriptionAboDate) AS diff
                 ,a.MontantAbo
           FROM   Abonnements             AS a
                  INNER JOIN #CatalogIdMapping AS m
                       ON  a.CatalogueAbosID = m.CatalogueAbosID
                  INNER JOIN Abonnements a2
                       ON  a2.CatalogueAbosID = m.newCatalogAbosID
                           AND a.ProfilID = a2.ProfilID
           WHERE  a.SourceID = 1
                  AND a2.SourceID = 10
                  AND a.SouscriptionAboDate < '20141002'
                  AND a2.FinAboDate > a.finabodate
       )        x
ORDER BY
       ProfilID
      ,CatalogueAbosID 

--extraire les donnees afin de regarder les cas
SELECT N'question?'
      ,*
FROM   #AbosMapping
WHERE  diff > 32
ORDER BY
       ProfilID
      ,CatalogueAbosID
 
SELECT N'Update VEL'
      ,* 
       --UPDATE a
       --SET
       --a.SouscriptionAboDate = m.SouscriptionAboDate,
       --a.DebutAboDate = a.SouscriptionAboDate,
       --a.MontantAbo = a.MontantAbo + m.MontantAbo
FROM   #AbosMapping m
       INNER JOIN Abonnements AS a
            ON  a.AbonnementID = m.VEL_AbonnementID
WHERE  diff <= 32

--delete neolene
SELECT N'Delete Neolene'
      ,*
       --DELETE a
FROM   #AbosMapping m
       INNER JOIN dbo.Abonnements AS a
            ON  a.AbonnementID = m.AbonnementID
WHERE  diff <= 32

--3-b
SELECT N'3-b'
      ,*
       --DELETE a
FROM   Abonnements AS a
       INNER JOIN #CatalogIdMapping x
            ON  a.CatalogueAbosID = x.CatalogueAbosId
WHERE  a.SourceID = 1
       AND a.SouscriptionAboDate >= '20141002'

DROP TABLE #mapping
DROP TABLE #AbosMapping
DROP TABLE #CatalogIdMapping