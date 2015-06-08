USE AmauryVUC

DECLARE @d DATE = '20140908'

TRUNCATE TABLE report.StatsWebSessions;
	
EXEC report.RemplirMasterIDsMapping;

EXEC report.RemplirStatsWebSessions @d; 

EXEC report.RemplirStatsWebSessionsWeek @d;

EXEC report.RemplirStatsWebSessionsMonth @d;

WITH s AS (
         SELECT MasterID
         FROM   dbo.Contacts
     ),
     t AS (
         SELECT s.masterId
         FROM   s 
                --INNER JOIN Typologie t ON  s.MasterID = t.MasterID
                --INNER JOIN (
                --         SELECT CodeVAlN
                --         FROM   ref.Misc AS m
                --         WHERE  m.TypeRef = 'TYPOLOGIE'
                --                AND m.Valeur LIKE '%VIE%'
                --     ) i
                --     ON  i.CodeVAlN = t.TypologieID
     )

SELECT COUNT(SessionsCount)
      ,Period
      ,Sуries
FROM   report.StatsWebSessions r
       INNER JOIN t
            ON  t.MasterID = r.MasterID
WHERE --r.PeriodType=N'J'
--r.PeriodType=N'S'            
r.PeriodType=N'J'            

GROUP BY
       Period
      ,Sуries
      ,SуriesSort
ORDER BY Period, SуriesSort
--SELECT * FROM report.StatsWebSessions	 ORDER BY PeriodType, Period, SуriesSort