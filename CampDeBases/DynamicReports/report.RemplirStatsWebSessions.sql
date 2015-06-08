/************************************************************
 * Code formatted by SoftTree SQL Assistant © v7.1.246
 * Time: 08.06.2015 15:14:48
 ************************************************************/

ALTER PROC report.RemplirStatsWebSessions (@d DATE) AS
BEGIN
	--SET NOCOUNT ON;
	WITH periods AS (
	         SELECT 'J-1' AS namePeriod
	               ,etl.GetBeginOfDay(DATEADD(DAY ,-1 ,@d)) StartPeriod
	               ,etl.GetEndOfDay(DATEADD(DAY ,-1 ,@d)) EndPeriod 
	         UNION ALL
	         SELECT 'J-2'
	               ,etl.GetBeginOfDay(DATEADD(DAY ,-2 ,@d)) StartPeriod
	               ,etl.GetEndOfDay(DATEADD(DAY ,-2 ,@d)) EndPeriod
	         UNION ALL
	         SELECT 'J-3'
	               ,etl.GetBeginOfDay(DATEADD(DAY ,-3 ,@d)) StartPeriod
	               ,etl.GetEndOfDay(DATEADD(DAY ,-3 ,@d)) EndPeriod
	         UNION ALL
	         SELECT 'J-4'
	               ,etl.GetBeginOfDay(DATEADD(DAY ,-4 ,@d)) StartPeriod
	               ,etl.GetEndOfDay(DATEADD(DAY ,-4 ,@d)) EndPeriod
	         UNION ALL
	         SELECT 'J-5'
	               ,etl.GetBeginOfDay(DATEADD(DAY ,-5 ,@d)) StartPeriod
	               ,etl.GetEndOfDay(DATEADD(DAY ,-5 ,@d)) EndPeriod
	         UNION ALL
	         SELECT 'J-6'
	               ,etl.GetBeginOfDay(DATEADD(DAY ,-6 ,@d)) StartPeriod
	               ,etl.GetEndOfDay(DATEADD(DAY ,-6 ,@d)) EndPeriod
	         UNION ALL
	         SELECT 'J-7'
	               ,etl.GetBeginOfDay(DATEADD(DAY ,-7 ,@d)) StartPeriod
	               ,etl.GetEndOfDay(DATEADD(DAY ,-7 ,@d)) EndPeriod
	     ) 
	     , SessionsByPeriod AS (
	         SELECT ix.SiteID
	               ,ix.ClientID
	               ,ix.SessionID
	               ,p.namePeriod
	               ,DATEDIFF(second ,iX.SessionDebut ,iX.SessionFin) AS duration
	         FROM   import.Xiti_Sessions ix
	                INNER JOIN periods p
	                     ON  ix.SessionDebut >= p.StartPeriod
	                         AND iX.SessionDebut <= p.EndPeriod
	         WHERE  ix.LigneStatut <> 1
	     )
	     ,vsMaster AS (
	         SELECT masterId
	               ,ix.SessionID
	               ,namePeriod
	               ,duration
	         FROM   SessionsByPeriod ix
	                INNER JOIN report.StatsMasterIDsMapping m
	                     ON  ix.ClientID = m.ClientID
	                         AND ix.SiteID = m.SiteID
	     )
	     ,res AS (
	         SELECT MasterId
	               ,SessionId
	               ,namePeriod
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
	      ,N'J'
	FROM   res
	GROUP BY
	       masterId
	      ,namePeriod
	      ,Sуries
	      ,SуriesSort
END


