--EXEC etl.BuildJourneesWeb 1
-- QUERY 1 - SITES WEB - VISITEURS version №2
--select * from report.DouzeDerniersMois
;
WITH s AS --websites
     (
         SELECT WebSiteId
         FROM   ref.SitesWeb
         WHERE WebSiteID = 40086
     )
     , r AS (
         --visites
         SELECT a.MasterID
               ,a.DateVisite
               ,IsMobile = CASE WHEN a.NbVisites - a.NbVisitesMobile = 0 THEN 1 ELSE 0 END
			   ,a.MultiOS
         FROM   AmauryVUC.dbo.JourneesWeb a 
                INNER JOIN s
                     ON  a.SiteID = s.WebSiteID
     )
     ,p AS (
         --last year
         SELECT m.Mois
               ,a.MasterID
               ,a.DateVisite
               ,IsMobile
               ,MultiOS
         FROM AmauryVUC.report.DouzeDerniersMois m LEFT JOIN r AS a
                     ON  a.DateVisite >= m.Mois
                         AND a.DateVisite < m.FinMois
         WHERE m.Mois = '20150801'
     )
     ,x AS
     (
         SELECT distinct
                mois
               ,masterId
               ,CASE 
                     WHEN multiOS = 1 THEN N'VisiteursMulti'
                     WHEN multiOS = 0 AND isMobile = 1 THEN N'VisiteursMobile' 
                     WHEN multiOS = 0 AND isMobile = 0 THEN N'VisiteursWeb' END AS kind
             FROM p
     )
SELECT Mois
      ,VisiteursWeb
      ,VisiteursMobile
      ,VisiteursMulti
FROM   (
           SELECT x.mois
                 ,masterID
                 ,kind
           FROM  x 
       ) xxx 
       PIVOT(
           COUNT(MasterID)
           FOR kind IN ([VisiteursWeb] ,[VisiteursMobile] ,[VisiteursMulti])
       ) AS pvt
ORDER BY
       Mois 
