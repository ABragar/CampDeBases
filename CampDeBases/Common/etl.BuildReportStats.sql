ALTER PROCEDURE report.RemplirReportWebStats
AS
BEGIN
	TRUNCATE TABLE report.WebVisitesStats2
	
	IF OBJECT_ID('tempdb..#xiti') IS NOT NULL
	    DROP TABLE #xiti;
	WITH xiti AS (
	         --xiti sites
	         SELECT a.SiteID
	               ,CAST(a.Visites AS INT) AS Visites
	               ,CAST(COALESCE(a.PagesVues ,0) AS BIGINT) AS PagesVues
	               ,CONVERT(DATETIME ,LEFT(RIGHT(a.FichierTS ,12) ,8) ,112) AS 
	                TS
	         FROM   AmauryVUC.import.Xiti_Sites a
	     )
	--xiti sites last year
	SELECT m.Mois
	      ,SUM(a.Visites)    AS TotalVisites
	      ,SUM(a.PagesVues)  AS TotalPagesVues
	       INTO #xiti
	FROM   xiti              AS a
	       INNER JOIN AmauryVUC.report.DouzeDerniersMois m
	            ON  a.TS >= m.Mois
	                AND a.TS < m.FinMois
	GROUP BY
	       m.Mois
	--visites          --last year
	IF OBJECT_ID('tempdb..#VisitesLastYear') IS NOT NULL
	    DROP TABLE #VisitesLastYear
	
	SELECT m.Mois
	      ,a.SiteID
	      ,a.MasterID
	      ,IsMobile = CASE 
	                       WHEN SUM(a.NbVisites - a.NbVisitesMobile) = 0 THEN 1
	                       ELSE 0
	                  END
	      ,MAX(CASE WHEN a.MultiOS = 1 THEN 1 ELSE 0 END) AS MultiOS
	      ,SUM(a.NbVisites)          AS NbVisites
	      ,SUM(a.NbVisitesMobile)    AS NbVisitesMobile
	      ,SUM(a.NbPagesVues)        AS NbPagesVues
	      ,SUM(a.NbPagesVuesMobile)  AS NbPagesVuesMobile
	      ,kind = CAST('' AS NVARCHAR(6))
	      ,NombreVisite = 0
	      ,Pages = 0 
	       
	       INTO                         #VisitesLastYear
	FROM   AmauryVUC.report.DouzeDerniersMois m
	       LEFT JOIN AmauryVUC.dbo.JourneesWeb a
	            ON  a.DateVisite >= m.Mois
	                AND a.DateVisite < m.FinMois
	GROUP BY
	       m.Mois
	      ,a.SiteID
	      ,a.MasterID
	
	UPDATE x
	SET    x.kind = CASE 
	                     WHEN multiOS = 1 THEN N'Multi'
	                     WHEN multiOS = 0 AND isMobile = 1 THEN N'Mobile'
	                     WHEN multiOS = 0 AND isMobile = 0 THEN N'Web'
	                END
	      ,NombreVisite = CASE 
	                           WHEN MultiOS = 0 AND isMobile = 1 THEN 
	                                NbVisitesMobile
	                           ELSE NbVisites
	                      END
	      ,Pages = CASE 
	                    WHEN MultiOS = 0
	                         AND isMobile = 1 THEN NbPagesVuesMobile
	                    ELSE NbPagesVues
	               END
	FROM   #VisitesLastYear x                    
	
	IF OBJECT_ID('tempdb..#VisitesLastYearGroup') IS NOT NULL
	    DROP TABLE #VisitesLastYearGroup
	
	
	SELECT Mois
	      ,SiteID
	      ,MasterID
	      ,IsMobile
	      ,MultiOS
	      ,SUM(NBVisites)        AS NBVisites
	      ,SUM(NbVisitesMobile)  AS NbVisitesMobile
	      ,SUM(NombreVisite)     AS NombreVisite
	      ,SUM(Pages)            AS Pages
	      ,kind
	       INTO                     #VisitesLastYearGroup
	FROM   #VisitesLastYear
	GROUP BY
	       Mois
	      ,SiteID
	      ,MasterID
	      ,MultiOS
	      ,IsMobile
	      ,Kind
	--report 1
	INSERT INTO report.WebVisitesStats2
	  (
	    reportId
	   ,SiteID
	   ,Mois
	   ,Web
	   ,Mobile
	   ,Multi
	  )
	SELECT 1
	      ,SiteID
	      ,Mois
	      ,Web
	      ,Mobile
	      ,Multi
	FROM   (
	           SELECT mois
	                 ,SiteID
	                 ,masterID
	                 ,kind
	           FROM   #VisitesLastYearGroup
	       ) xxx 
	       PIVOT(COUNT(MasterID) FOR kind IN ([Web] ,[Mobile] ,[Multi])) AS pvt
	ORDER BY
	       Mois 
	
	--report 2
	;
	WITH z AS 
	     (
	         SELECT Mois
	               ,SiteID
	               ,ISNULL(Web ,0)     AS VisitesWeb
	               ,ISNULL(Mobile ,0)  AS VisitesMobile
	               ,ISNULL(Multi ,0)   AS VisitesMulti
	         FROM   (
	                    SELECT mois
	                          ,SiteID
	                          ,NombreVisite AS NombreVisite
	                          ,kind
	                    FROM   #VisitesLastYearGroup x
	                ) xxx 
	                PIVOT(SUM(NombreVisite) FOR kind IN ([Web] ,[Mobile] ,[Multi])) AS 
	                pvt
	     )
	
	INSERT INTO report.WebVisitesStats2
	  (
	    reportId
	   ,SiteID
	   ,Mois
	   ,Web
	   ,Mobile
	   ,Multi
	   ,TotalValues
	  )
	SELECT 2
	      ,SiteID
	      ,z.Mois
	      ,VisitesWeb
	      ,VisitesMobile
	      ,VisitesMulti
	      ,u.TotalVisites
	FROM   z
	       LEFT JOIN #xiti u
	            ON  z.mois = u.Mois
	ORDER BY
	       z.Mois
	
	--report 3
	--
	;
	WITH z AS (
	         SELECT Mois
	               ,SiteID
	               ,ISNULL(Web ,0)     AS PagesVuesWeb
	               ,ISNULL(Mobile ,0)  AS PagesVuesMobile
	               ,ISNULL(Multi ,0)   AS PagesVuesMulti
	         FROM   (
	                    SELECT mois
	                          ,SiteID
	                          ,Pages AS Pages
	                          ,kind
	                    FROM   #VisitesLastYearGroup x
	                ) xxx 
	                PIVOT(SUM(Pages) FOR kind IN ([Web] ,[Mobile] ,[Multi])) AS 
	                pvt
	     )
	
	INSERT INTO report.WebVisitesStats2
	  (
	    reportId
	   ,SiteID
	   ,Mois
	   ,Web
	   ,Mobile
	   ,Multi
	   ,TotalValues
	  )
	SELECT 3
	      ,SiteID
	      ,z.Mois
	      ,PagesVuesWeb
	      ,PagesVuesMobile
	      ,PagesVuesMulti
	      ,u.TotalPagesVues
	FROM   z
	       LEFT JOIN #xiti u
	            ON  z.mois = u.Mois
	ORDER BY
	       z.Mois
END             