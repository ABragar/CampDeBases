ALTER PROC report.RemplirStatsWebSessionsWeek (@d DATE) AS
BEGIN
	SET NOCOUNT ON;
--	DECLARE @d DATE = '20140908';
	
	WITH num(n) AS(
	         SELECT 0 
	         UNION ALL
	         SELECT n + 1
	         FROM   num
	         WHERE  n < 11
	     )
	     ,dat AS (
	         SELECT n
	         FROM   num
	     )
	     ,periods AS (
	         SELECT 'S-' + CAST(n AS NVARCHAR) AS namePeriod
	               ,DATEADD(DAY ,-6 ,etl.GetEndOfWeek(DATEADD(week ,-n ,@d))) 
	                StartPeriod
	               ,etl.GetEndOfDay(etl.GetEndOfWeek(DATEADD(week ,-n ,CAST(@d AS DATETIME)))) 
	                EndPeriod
	         FROM   dat
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
	        ,SyriesSort = CASE 
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
	      ,SyriesSort
	      ,N'S'
	FROM   res
	GROUP BY
	       masterId
	      ,namePeriod
	      ,Sуries
	      ,SyriesSort
END


