--prepare the data
DECLARE @d DATE = '20150627'

TRUNCATE TABLE report.StatsWebSessions;
TRUNCATE TABLE report.StatsVolumetrieSessions;
	
--EXEC report.RemplirMasterIDsMapping; --
-- for Durée des sessions report
EXEC report.RemplirStatsWebSessionsByPeriod @d, N'J' 
EXEC report.RemplirStatsWebSessionsByPeriod @d, N'S'
EXEC report.RemplirStatsWebSessionsByPeriod @d, N'M'

-- for Volumétrie des sessions
exec report.RemplirStatsVolumetrieSessionsByPeriod @d, N'J'; 

--for reports Fréquence des sessions, Profondeur des sessions
exec report.RemplirStatsVolumetrieSessionsByPeriod @d, N'M'

--SELECT * FROM report.StatsWebSessions
SELECT * FROM report.StatsVolumetrieSessions