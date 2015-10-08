 -- QUERY 3 - SITES WEB - PAGES VUES
;
WITH s AS --websites 
     (
         SELECT WebSiteId
         FROM   ref.SitesWeb
     )
SELECT u.Mois
      ,Sum(web) as PagesVuesWeb
      ,Sum(Mobile) as PagesVuesMobile
      ,Sum(Multi) as PagesVuesMulti
      ,CAST(SUM(web+Mobile+Multi) AS FLOAT) / CASE COALESCE(Sum(TotalValues),0)
	                  WHEN 0 THEN 1
	                  ELSE Sum(TotalValues)
	             END
           Authentifies
FROM   s
       JOIN report.WebVisitesStats2 u
            ON  s.WebSiteId = u.SiteID
WHERE u.reportId = 3            
GROUP BY u.Mois
ORDER BY
       u.Mois
    
