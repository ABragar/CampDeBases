-- QUERY 3 - SITES WEB - PAGES VUES
;
WITH s AS --websites 
     (
         SELECT WebSiteId
         FROM   ref.SitesWeb
     )
     , r AS (
         --visites by websites
         SELECT a.MasterID
               ,a.DateVisite
               ,IsMobile = CASE 
                                WHEN a.NbPagesVues - a.NbPagesVuesMobile > 0 THEN 
                                     1
                                ELSE 0
                           END
               ,a.MultiOS
               ,a.NbPagesVues
               ,a.NbPagesVuesMobile
         FROM   AmauryVUC.dbo.JourneesWeb a
                INNER JOIN s
                     ON  a.SiteID = s.WebSiteID
     )
     
     , p AS (
         --last year
         SELECT m.Mois
               ,a.MasterID
               ,IsMobile
               ,a.MultiOS
               ,a.NbPagesVues
               ,a.NbPagesVuesMobile
               ,a.DateVisite
         FROM   AmauryVUC.report.DouzeDerniersMois m
                LEFT JOIN r AS a
                     ON  a.DateVisite >= m.Mois
                         AND a.DateVisite < m.FinMois
     )
     
     , q AS (
         SELECT a.SiteID
               ,CAST(COALESCE(a.PagesVues ,0) AS BIGINT) AS PagesVues
               ,CONVERT(DATETIME ,LEFT(RIGHT(a.FichierTS ,12) ,8) ,112) AS TS
         FROM   AmauryVUC.import.Xiti_Sites a
                INNER JOIN s
                     ON  a.SiteID = s.WebSiteID
     )
     , u AS (
         SELECT m.Mois
               ,SUM(a.PagesVues)  AS TotalPagesVues
         FROM   q                 AS a
                INNER JOIN AmauryVUC.report.DouzeDerniersMois m
                     ON  a.TS >= m.Mois
                         AND a.TS < m.FinMois
         GROUP BY
                m.Mois
     )
     ,x AS
     (
         SELECT mois
               ,masterId
               ,NombreVisite = CASE 
                                    WHEN MultiOS = 1
         AND isMobile = 1 THEN NbPagesVuesMobile ELSE NbPagesVues END
        ,CASE 
              WHEN MultiOS = 2 THEN N'PagesVuesMulti'
              WHEN MultiOS = 1
         AND isMobile = 1 THEN N'PagesVuesMobile' WHEN MultiOS = 1
         AND isMobile = 0 THEN N'PagesVuesWeb' END AS kind
             FROM p
     )
     
     ,z AS (
         SELECT Mois
               ,ISNULL(PagesVuesWeb ,0)     AS PagesVuesWeb
               ,ISNULL(PagesVuesMobile ,0)  AS PagesVuesMobile
               ,ISNULL(PagesVuesMulti ,0)   AS PagesVuesMulti
         FROM   (
                    SELECT m.mois
                          ,NombreVisite AS NombreVisite
                          ,kind
                    FROM   AmauryVUC.report.DouzeDerniersMois m
                           LEFT JOIN x
                                ON  m.Mois = x.Mois
                ) xxx 
                PIVOT(
                    SUM(NombreVisite)
                    FOR kind IN ([PagesVuesWeb] ,[PagesVuesMobile] ,[PagesVuesMulti])
                )                         AS pvt
     )
SELECT z.Mois
      ,PagesVuesWeb
      ,PagesVuesMobile
      ,PagesVuesMulti
      ,(
           CAST((PagesVuesWeb + PagesVuesMobile + PagesVuesMulti) AS FLOAT)
            / CASE 
                                                                           COALESCE(u.TotalPagesVues ,0)
                                                                           WHEN 
                                                                                0 THEN 
                                                                                1
                                                                           ELSE 
                                                                                COALESCE(u.TotalPagesVues , 0)
                                                                      END
       ) AS Authentifies
FROM   z
       LEFT JOIN u
            ON  z.mois = u.Mois
ORDER BY
       z.Mois
    
