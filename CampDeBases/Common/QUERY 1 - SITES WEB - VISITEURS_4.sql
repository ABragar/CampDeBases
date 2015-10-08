-- QUERY 1 - SITES WEB - VISITEURS version №2
; 
WITH s AS --websites 
     (
         SELECT WebSiteId
         FROM   ref.SitesWeb
     )

SELECT u.Mois
      ,SUM(web)     AS VisiteursWeb
      ,SUM(Mobile)  AS VisiteursMobile
      ,SUM(Multi)   AS VisiteursMulti
FROM   s
       JOIN report.WebVisitesStats2 u
            ON  s.WebSiteId = u.SiteID
WHERE  u.reportId = 1
GROUP BY
       u.Mois
ORDER BY
       u.Mois

