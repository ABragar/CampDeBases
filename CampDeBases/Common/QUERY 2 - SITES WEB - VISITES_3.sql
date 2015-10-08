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
               ,a.DateVisite
               ,IsMobile = CASE WHEN a.NbVisites - a.NbVisitesMobile > 0 THEN 1 ELSE 0 END
			   ,a.MultiOS
			   ,a.NbVisites
			   ,a.NbVisitesMobile
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
			   ,a.NbVisites
			   ,a.NbVisitesMobile
               ,a.DateVisite
          FROM AmauryVUC.report.DouzeDerniersMois m LEFT JOIN r AS a
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
     ,x AS
     (
         SELECT mois
               ,masterId
               ,NombreVisite = CASE WHEN MultiOS = 1 AND isMobile = 1 THEN NbVisitesMobile ELSE NbVisites END
               ,CASE 
                     WHEN MultiOS = 2 THEN N'VisitesMulti'
                     WHEN MultiOS = 1
         AND isMobile = 1 THEN N'VisitesMobile' WHEN MultiOS = 1
         AND isMobile = 0 THEN N'VisitesWeb' END AS kind
             FROM p
     )
     ,z AS (
         SELECT Mois
               ,isnull(VisitesWeb,0) AS VisitesWeb
               ,isnull(VisitesMobile,0)	AS VisitesMobile 
               ,isnull(VisitesMulti,0) as VisitesMulti
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
    
