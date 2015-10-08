--QUERY 2 - SITES WEB - VISITES version 2
;
WITH s AS --websites 
     (
         SELECT WebSiteId
         FROM   ref.SitesWeb
     )
     , r AS (
         --visites by websites
         SELECT a.MasterID
               ,a.CodeOS
               ,a.DateVisite
               ,a.VisiteID
         FROM   AmauryVUC.etl.VisitesWeb a --TABLESAMPLE(1 PERCENT) REPEATABLE(666)
                INNER JOIN s
                     ON  a.SiteID = s.WebSiteID
     )
     
     , p AS (
         --last year
         SELECT m.Mois
               ,a.MasterID
               ,a.CodeOS
               ,a.DateVisite
               ,a.VisiteID
         FROM   r AS a
                INNER JOIN AmauryVUC.report.DouzeDerniersMois m
                     ON  a.DateVisite >= m.Mois
                         AND a.DateVisite < m.FinMois
     )
     
     , q AS (
         --xiti sites
         SELECT a.SiteID
               ,CAST(a.Visites AS INT) AS Visites
               ,CONVERT(DATETIME ,LEFT(RIGHT(a.FichierTS ,12) ,8) ,112) AS TS
         FROM   AmauryVUC.import.Xiti_Sites a
                INNER JOIN s
                     ON  a.SiteID = s.WebSiteID
     )
     
     , u AS (
         --xiti sites last year
         SELECT m.Mois
               ,SUM(a.Visites)  AS TotalVisites
         FROM   q               AS a
                INNER JOIN AmauryVUC.report.DouzeDerniersMois m
                     ON  a.TS >= m.Mois
                         AND a.TS < m.FinMois
         GROUP BY
                m.Mois
     )
     , w AS (
         -- Is mobile
         SELECT a.Mois
               ,a.MasterID
               ,COUNT(DISTINCT a.VisiteID) AS NombreVisite
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
         SELECT *
               ,COUNT(MasterID) OVER(PARTITION BY mois ,MasterId) AS 
                multi
         FROM   w
     )
     ,x AS
     (
         SELECT mois
               ,masterId
               ,NombreVisite
               ,CASE 
                     WHEN multi = 2 THEN N'VisitesMulti'
                     WHEN multi = 1
         AND isMobile = 1 THEN N'VisitesMobile' WHEN multi = 1
         AND isMobile = 0 THEN N'VisitesWeb' END AS kind
             FROM v
     )
     ,z AS (
         SELECT Mois
               ,VisitesWeb
               ,VisitesMobile
               ,VisitesMulti
         FROM   (
                    SELECT m.mois
                          ,NombreVisite
                          ,kind
                    FROM   AmauryVUC.report.DouzeDerniersMois m
                           LEFT JOIN x
                                ON  m.Mois = x.Mois
                ) xxx 
                PIVOT(
                    SUM(NombreVisite)
                    FOR kind IN ([VisitesWeb] ,[VisitesMobile] ,[VisitesMulti])
                ) AS pvt
     )

SELECT z.Mois,VisitesWeb,VisitesMobile,VisitesMulti
      ,(
           CAST(VisitesWeb + VisitesMobile + VisitesMulti AS FLOAT) / CASE 
                                                                           COALESCE(u.TotalVisites ,0)
                                                                           WHEN 
                                                                                0 THEN 
                                                                                1
                                                                           ELSE 
                                                                                COALESCE(u.TotalVisites , 0)
                                                                      END
       ) AS Authentifies
FROM   z
       LEFT JOIN u
            ON  z.mois = u.Mois
ORDER BY
       z.Mois
    
