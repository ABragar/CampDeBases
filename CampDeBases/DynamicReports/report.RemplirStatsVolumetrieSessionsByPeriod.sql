USE AmauryVUC
GO
ALTER PROC report.RemplirStatsVolumetrieSessionsByPeriod (@d DATE ,@period NVARCHAR(1)) 
AS
BEGIN

--SET NOCOUNT ON;
	IF OBJECT_ID('tempdb..#periods') IS NOT NULL
	    DROP TABLE #periods
	
	CREATE TABLE #periods
	(
		namePeriod      NVARCHAR(255)
	   ,StartPeriod     DATETIME
	   ,EndPeriod       DATETIME
	)
	INSERT INTO #periods
	  (
	    namePeriod
	   ,StartPeriod
	   ,EndPeriod
	  )
	SELECT *
	FROM   report.GetPeriodsList(@d ,@period)
	
	IF OBJECT_ID('tempdb..#SessionsByPeriod') IS NOT NULL
	    DROP TABLE #SessionsByPeriod
	
	CREATE TABLE #SessionsByPeriod
	(
		SiteID         Int
	   ,MasterID       Int
	   ,SessionID      int
	   ,namePeriod     NVARCHAR(255)
	   ,PagesNb      INT
	   ,PagesPremiumNb INT
	)
	
	INSERT INTO #SessionsByPeriod
	  (
	    SiteID
	   ,MasterID
	   ,SessionID
	   ,namePeriod
	   ,PagesNb
	   ,PagesPremiumNb
	  )
	SELECT ix.SiteID
	      ,ix.MasterID
	      ,ix.VisiteId
	      ,p.namePeriod
	      ,ix.PagesNb
	      ,ix.PagesPremiumNb
	FROM   #periods p
	       LEFT JOIN etl.VisitesWeb ix
	            ON  ix.DateVisite >= p.StartPeriod
	                AND iX.DateVisite <= p.EndPeriod
	
	CREATE INDEX ix_SiteID_ClientID ON #SessionsByPeriod(SiteID ,MasterID)
	
	;
	WITH vsMaster AS (
	         SELECT masterId
	               ,ix.SessionID
	               ,namePeriod
	               ,Appartenance
	               ,ix.SiteID
	               ,ix.PagesNb,
	               ix.PagesPremiumNb
	         FROM   #SessionsByPeriod ix
	                INNER JOIN ref.SitesWeb AS sw
	                     ON  ix.SiteID = sw.WebSiteID
	     )
	     ,v1 AS (
	         --Le Parisien.fr
	         SELECT COUNT(SessionID)      AS SessionsCount
	               ,SUM(PagesNb-PagesPremiumNb)        AS PagesVues
	               ,masterId
	               ,namePeriod
	               ,'Le Parisien.fr'      AS Category
	               ,N'Pour Le Parisien'   AS Gr
	               ,sw.Marque
	               ,sw.Appartenance
	         FROM   vsMaster m
	                INNER JOIN ref.SitesWeb AS sw
	                     ON  sw.WebSiteID = SiteID
	         WHERE  sw.WebSiteID = 40086
	         GROUP BY
	                namePeriod
	               ,masterId
	               ,sw.Marque
	               ,sw.Appartenance
	     )
	     ,v2 AS (
	         --premium
	         SELECT COUNT(*)              AS SessionsCount
	               ,SUM(PagesPremiumNb)        AS PagesVues
	               ,m.masterId
	               ,m.namePeriod
	               ,'Premium'             AS Category
	               ,N'Pour Le Parisien'   AS Gr
	               ,sw.Marque
	               ,sw.Appartenance
	         FROM   vsMaster m
	                INNER JOIN ref.SitesWeb AS sw
	                     ON  sw.WebSiteID = SiteID
	         WHERE  sw.WebSiteID = 40086 AND PagesPremiumNb > 0
	         GROUP BY
	                m.namePeriod
	               ,m.masterId
	               ,sw.Marque
	               ,sw.Appartenance
	     )
	     ,v3 AS (
	         --L’Equipe
	         SELECT COUNT(SessionID)    AS SessionsCount
	               ,SUM(PagesNb-PagesPremiumNb)      AS PagesVues
	               ,m.masterId
	               ,namePeriod
	               ,'Marque L’Equipe'   AS Category
	               ,N'Pour L’Equipe'    AS Gr
	               ,sw.Marque
	               ,sw.Appartenance
	         FROM   vsMaster m
	                INNER JOIN ref.SitesWeb AS sw
	                     ON  sw.WebSiteID = SiteID
	         WHERE  sw.Marque = 7
	         GROUP BY
	                namePeriod
	               ,m.masterId
	               ,sw.Marque
	               ,sw.Appartenance
	     )
	     ,v4 AS (
	         --L’Equipe
	         SELECT COUNT(SessionID)   AS SessionsCount
	               ,SUM(PagesNb-PagesPremiumNb)     AS PagesVues
	               ,m.masterId
	               ,namePeriod
	               ,'Marque France Football' AS Category
	               ,N'Pour L’Equipe'   AS Gr
	               ,sw.Marque
	               ,sw.Appartenance
	         FROM   vsMaster m
	                INNER JOIN ref.SitesWeb AS sw
	                     ON  sw.WebSiteID = SiteID
	         WHERE  sw.Marque = 3
	         GROUP BY
	                namePeriod
	               ,m.masterId
	               ,sw.Marque
	               ,sw.Appartenance
	     )
	     ,v5 AS (
	         --Marques L’Equipe
	         SELECT COUNT(SessionID)     AS SessionsCount
	               ,SUM(PagesNb-PagesPremiumNb)       AS PagesVues
	               ,m.masterId
	               ,namePeriod
	               ,'Editeur L’Equipe'   AS Category
	               ,N'Pour L’Equipe'     AS Gr
	               ,sw.Marque
	               ,sw.Appartenance
	         FROM   vsMaster m
	                INNER JOIN ref.SitesWeb AS sw
	                     ON  sw.WebSiteID = SiteID
	         WHERE  sw.Appartenance = 1
	         GROUP BY
	                namePeriod
	               ,m.masterId
	               ,sw.Marque
	               ,sw.Appartenance
	     )
	     ,res AS (
	         SELECT *
	         FROM   v1
	         UNION ALL
	         SELECT *
	         FROM   v2
	         UNION ALL
	         SELECT *
	         FROM   v3
	         UNION ALL
	         SELECT *
	         FROM   v4
	         UNION ALL
	         SELECT *
	         FROM   v5
	     )
	
	INSERT INTO report.StatsVolumetrieSessions
	  (
	    MasterID
	   ,SessionsCount
	   ,Period
	   ,periodType
	   ,Category
	   ,Gr
	   ,Marque
	   ,Appartenance
	   ,PagesVues
	  )
	SELECT masterId
	      ,SessionsCount
	      ,namePeriod
	      ,@period
	      ,Category
	      ,Gr
	      ,Marque
	      ,Appartenance
	      ,PagesVues
	FROM   res
	UNION ALL
	SELECT masterId
	      ,Sum(SessionsCount)
	      ,namePeriod
	      ,@period
	      ,N'Group'
	      ,'Pour Le Groupe'
	      ,0
	      ,0
	      ,Sum(PagesVues)
	FROM   res
	GROUP BY masterID,namePeriod 
	;
	
	DROP TABLE #periods
	DROP TABLE #SessionsByPeriod
END
  