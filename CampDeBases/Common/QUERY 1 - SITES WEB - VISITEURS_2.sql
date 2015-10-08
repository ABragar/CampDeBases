-- QUERY 1 - SITES WEB - VISITEURS version №2
;
WITH s AS --websites
     (
         SELECT WebSiteId
         FROM   ref.SitesWeb
     )
     , r AS (
         --visites
         SELECT a.MasterID
               ,a.CodeOS
               ,a.DateVisite
         FROM   etl.VisitesWeb a --TABLESAMPLE(1 PERCENT) REPEATABLE(205)
                INNER JOIN s
                     ON  a.SiteID = s.WebSiteID
     )
     ,p AS (
         --last year
         SELECT m.Mois
               ,a.MasterID
               ,a.CodeOS
               ,a.DateVisite
         FROM   r AS a
                INNER JOIN AmauryVUC.report.DouzeDerniersMois m
                     ON  a.DateVisite >= m.Mois
                         AND a.DateVisite < m.FinMois
     )
     , w AS (
         -- Is mobile
         SELECT a.Mois
               ,a.MasterID
               ,CASE 
                     WHEN b.RefID IS NULL THEN 0
                     ELSE 1
                END  AS IsMobile
         FROM   p    AS a
                LEFT JOIN AmauryVUC.ref.Misc b
                     ON  a.CodeOS = b.RefID
                         AND b.TypeRef IN (N'OSMOBILE' ,N'OSTABLETTE')
         GROUP BY
                a.Mois
               ,a.MasterID
               ,CASE 
                     WHEN b.RefID IS NULL THEN 0
                     ELSE 1
                END
     ),
     v AS(
         --multi
         SELECT Mois
               ,MasterID
               ,IsMobile
               ,COUNT(MasterID) OVER(PARTITION BY Mois ,MasterId) AS 
                multi
         FROM   w
     ),
     x AS
     (
         SELECT DISTINCT
                mois
               ,masterId
               ,CASE 
                     WHEN multi = 2 THEN N'VisiteursMulti'
                     WHEN multi = 1
         AND isMobile = 1 THEN N'VisiteursMobile' WHEN multi = 1
         AND isMobile = 0 THEN N'VisiteursWeb' END AS kind
             FROM v
     )

SELECT Mois
      ,VisiteursWeb
      ,VisiteursMobile
      ,VisiteursMulti
FROM   (
           SELECT m.mois
                 ,masterID
                 ,kind
           FROM   AmauryVUC.report.DouzeDerniersMois m
                  LEFT JOIN x
                       ON  m.Mois = x.Mois
       ) xxx 
       PIVOT(
           COUNT(MasterID)
           FOR kind IN ([VisiteursWeb] ,[VisiteursMobile] ,[VisiteursMulti])
       ) AS pvt
ORDER BY
       Mois 
