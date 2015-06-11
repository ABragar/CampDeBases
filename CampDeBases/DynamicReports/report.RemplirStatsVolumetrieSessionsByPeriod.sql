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
		SiteID         NVARCHAR(18)
	   ,ClientID       NVARCHAR(18)
	   ,SessionID      NVARCHAR(255)
	   ,namePeriod     NVARCHAR(255)
	   ,PagesVues      INT
	)
	
	INSERT INTO #SessionsByPeriod
	  (
	    SiteID
	   ,ClientID
	   ,SessionID
	   ,namePeriod
	   ,PagesVues
	  )
	SELECT ix.SiteID
	      ,ix.ClientID
	      ,ix.SessionID
	      ,p.namePeriod
	      ,ix.PagesVues
	FROM   #periods p
	       LEFT JOIN import.Xiti_Sessions ix
	            ON  ix.SessionDebut >= p.StartPeriod
	                AND iX.SessionDebut <= p.EndPeriod
	WHERE  ix.LigneStatut <> 1
	
	CREATE INDEX ix_SiteID_ClientID ON #SessionsByPeriod(SiteID ,ClientID)
	
	;
	WITH vsMaster AS (
	         SELECT masterId
	               ,ix.SessionID
	               ,namePeriod
	               ,Appartenance
	               ,ix.SiteID
	               ,ix.PagesVues
	         FROM   #SessionsByPeriod ix
	                INNER JOIN report.StatsMasterIDsMapping m
	                     ON  ix.ClientID = m.ClientID
	                         AND ix.SiteID = m.SiteID
	                INNER JOIN ref.SitesWeb AS sw
	                     ON  m.SiteID = sw.WebSiteID
	     )
	     ,v1 AS (
	         --Le Parisien.fr
	         SELECT COUNT(SessionID)      AS SessionsCount
	               ,SUM(PagesVues)        AS PagesVues
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
	               ,SUM(PagesVues)        AS PagesVues
	               ,m.masterId
	               ,m.namePeriod
	               ,'Premium'             AS Category
	               ,N'Pour Le Parisien'   AS Gr
	               ,sw.Marque
	               ,sw.Appartenance
	         FROM   vsMaster m
	                INNER JOIN ref.SitesWeb AS sw
	                     ON  sw.WebSiteID = SiteID
	                INNER JOIN dbo.SessionsPremium AS sp
	                     ON  m.masterID = sp.MasterID
	                INNER JOIN #periods p
	                     ON  sp.DateVisite BETWEEN p.StartPeriod AND p.EndPeriod
	         WHERE  sw.WebSiteID = 40086
	         GROUP BY
	                m.namePeriod
	               ,m.masterId
	               ,sw.Marque
	               ,sw.Appartenance
	     )
	     ,v3 AS (
	         --L’Equipe
	         SELECT COUNT(SessionID)    AS SessionsCount
	               ,SUM(PagesVues)      AS PagesVues
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
	               ,SUM(PagesVues)     AS PagesVues
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
	               ,SUM(PagesVues)       AS PagesVues
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
	FROM   res;
	
	DROP TABLE #periods
	DROP TABLE #SessionsByPeriod
END
  