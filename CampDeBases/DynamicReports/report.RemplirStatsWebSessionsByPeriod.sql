USE AmauryVUC
GO
ALTER PROC report.RemplirStatsWebSessionsByPeriod (@d DATE ,@period NVARCHAR(1)) 
AS
BEGIN
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
		SiteID         Int
	   ,MasterID       Int
	   ,SessionID      int
	   ,namePeriod     NVARCHAR(255)
	   ,duration int
	)
	
	INSERT INTO #SessionsByPeriod
	  (
	    SiteID
	   ,MasterID
	   ,SessionID
	   ,namePeriod
	   ,duration
	  )

	SELECT ix.SiteID
	      ,ix.MasterID
	      ,ix.VisiteId
	      ,p.namePeriod
	      ,DATEDIFF(second ,iX.DateVisite ,iX.FinVisite) AS duration
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
	               ,duration
	               ,sw.Marque
	               ,Appartenance
	         FROM   #SessionsByPeriod ix
	                INNER JOIN ref.SitesWeb AS sw
	                     ON  ix.SiteID = sw.WebSiteID
	     )
	     ,res AS (
	         SELECT MasterId
	               ,SessionId
	               ,namePeriod
	               ,Marque
	               ,Appartenance
	               ,Sуries = CASE 
	                              WHEN duration < 60 THEN N'< 1 mn'
	                              WHEN duration >= 60
	         AND duration < 360 THEN N'1 a 5 mn'
	             WHEN duration >= 360
	         AND duration < 660 THEN N'6 a 10 mn'
	             WHEN duration >= 660
	         AND duration < 1860 THEN N'10 a 30 mn'
	             WHEN duration >= 1860 THEN N'> 30 mn'
	             END
	        ,SуriesSort = CASE 
	                           WHEN duration < 60 THEN 1
	                           WHEN duration >= 60
	         AND duration < 360 THEN 2
	             WHEN duration >= 360
	         AND duration < 660 THEN 3
	             WHEN duration >= 660
	         AND duration < 1860 THEN 4
	             WHEN duration >= 1860 THEN 5
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
	      ,Marque
	      ,Appartenance
	      
	FROM   res
	GROUP BY
	       masterId
	      ,namePeriod
	      ,Sуries
	      ,SуriesSort
	      ,Marque
	      ,Appartenance
END


