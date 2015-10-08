--QUERY 2 - SITES WEB - VISITES version 2
;
WITH s AS --websites 
     (
         SELECT WebSiteId
         FROM   ref.SitesWeb
     )

SELECT u.Mois
      ,SUM(web)     AS VisitesWeb
      ,SUM(Mobile)  AS VisitesMobile
      ,SUM(Multi)   AS VisitesMulti
      ,CAST(SUM(web + Mobile + Multi) AS FLOAT) / CASE COALESCE(SUM(TotalValues) ,0)
                                                       WHEN 0 THEN 1
                                                       ELSE SUM(TotalValues)
                                                  END
       Authentifies
FROM   s
       JOIN report.WebVisitesStats2 u
            ON  s.WebSiteId = u.SiteID
WHERE  u.reportId = 2
GROUP BY
       u.Mois
ORDER BY
       u.Mois
