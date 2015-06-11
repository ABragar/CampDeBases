USE AmauryVUC
GO
ALTER PROC report.RemplirStatsWebSessionsByPeriod (@d DATE ,@period NVARCHAR(1)) 
AS
BEGIN
	--SET NOCOUNT ON;
	
	SET NOCOUNT ON;
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
	   ,duration int
	)
	
	INSERT INTO #SessionsByPeriod
	  (
	    SiteID
	   ,ClientID
	   ,SessionID
	   ,namePeriod
	   ,duration
	  )
	SELECT ix.SiteID
	      ,ix.ClientID
	      ,ix.SessionID
	      ,p.namePeriod
	      ,DATEDIFF(second ,iX.SessionDebut ,iX.SessionFin) AS duration
	FROM   #periods p
	       LEFT JOIN import.Xiti_Sessions ix
	            ON  ix.SessionDebut >= p.StartPeriod
	                AND iX.SessionDebut <= p.EndPeriod
	WHERE  ix.LigneStatut <> 1
	
	CREATE INDEX ix_SiteID_ClientID ON #SessionsByPeriod (SiteID,ClientID)	
	
	--WITH periods AS (
	--         SELECT *
	--         FROM   report.GetPeriodsList(@d ,@period)
	--     ) 
	--     , SessionsByPeriod AS (
	--         SELECT ix.SiteID
	--               ,ix.ClientID
	--               ,ix.SessionID
	--               ,p.namePeriod
	--               ,DATEDIFF(second ,iX.SessionDebut ,iX.SessionFin) AS duration
	--         FROM   import.Xiti_Sessions ix
	--                INNER JOIN periods p
	--                     ON  ix.SessionDebut >= p.StartPeriod
	--                         AND iX.SessionDebut <= p.EndPeriod
	--         WHERE  ix.LigneStatut <> 1
	--     )
	     ;with vsMaster AS (
	         SELECT masterId
	               ,ix.SessionID
	               ,namePeriod
	               ,duration
	               ,Appartenance
	         FROM   #SessionsByPeriod ix
	                INNER JOIN report.StatsMasterIDsMapping m
	                     ON  ix.ClientID = m.ClientID
	                         AND ix.SiteID = m.SiteID
	                INNER JOIN ref.SitesWeb AS sw
	                     ON  m.SiteID = sw.WebSiteID
	     )
	     ,res AS (
	         SELECT MasterId
	               ,SessionId
	               ,namePeriod
	               ,Appartenance
	               ,Sуries = CASE 
	                              WHEN duration < 60 THEN N'< 1 mn'
	                              WHEN duration >= 60
	         AND duration < 300 THEN N'1 a 5 mn'
	             WHEN duration >= 300
	         AND duration < 600 THEN N'6 a 10 mn'
	             WHEN duration >= 600
	         AND duration < 1800 THEN N'10 a 30 mn'
	             WHEN duration >= 1800 THEN N'> 30 mn'
	             END
	        ,SуriesSort = CASE 
	                           WHEN duration < 60 THEN 1
	                           WHEN duration >= 60
	         AND duration < 300 THEN 2
	             WHEN duration >= 300
	         AND duration < 600 THEN 3
	             WHEN duration >= 600
	         AND duration < 1800 THEN 4
	             WHEN duration >= 1800 THEN 5
	             END 
	             
	             FROM vsMaster
	     )
	
	INSERT INTO report.StatsWebSessions
	SELECT masterId
	      ,COUNT(SessionId)
	      ,namePeriod
	      ,Sуries
	      ,SуriesSort
	      ,@period
	      ,Appartenance
	FROM   res
	GROUP BY
	       masterId
	      ,namePeriod
	      ,Sуries
	      ,SуriesSort
	      ,Appartenance
END


