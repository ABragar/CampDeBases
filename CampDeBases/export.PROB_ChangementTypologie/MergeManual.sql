IF OBJECT_ID('tempdb..#NewData' ,'U') IS NOT NULL
    DROP TABLE #NewData
 GO
  
 DECLARE @curDate DATE = '20150805'
 
 --TRUNCATE TABLE export.PROB_ChangementTypologie
 --select * from export.PROB_ChangementTypologie 
 
 SELECT * 
 INTO #NewData
 FROM dbo.Typologie_05082015
 --(9603700 row(s) affected)
 
--no matches in source table. Clear curr typologie for this rows.  (420 row(s) affected)
--SELECT *
UPDATE t
	SET    t.PrevTypologieID = t.CurrTypologieID
	      ,t.CurrTypologieID = NULL
	      ,ChangeDate = GETDATE()
FROM export.PROB_ChangementTypologie t
LEFT JOIN #NewData n 
             ON  t.MasterID = n.MasterID
                 AND t.MarqueID = n.MarqueID
WHERE n.MasterID IS NULL
 
 
 
 --delete not changed rows
 
 
 -- full matches
 delete n
 --SELECT *
 FROM   #NewData n
        INNER JOIN export.PROB_ChangementTypologie t
             ON  t.MasterID = n.MasterID
                 AND t.MarqueID = n.MarqueID
                 AND t.CurrTypologieID = n.TypologieID
--(9572846 row(s) affected)		                 

SELECT * FROM #NewData --(30854 row(s) affected)
----------------------------------------------------------------------------------
-- no matches in target table. Add --(15912 row(s) affected)
IF OBJECT_ID('tempdb..#added' ,'U') IS NOT NULL
    DROP TABLE #added
 GO

SELECT n.*
INTO #added
FROM #NewData n
LEFT JOIN export.PROB_ChangementTypologie t 
             ON  t.MasterID = n.MasterID
                 AND t.MarqueID = n.MarqueID
WHERE t.MasterID IS NULL		                 

DELETE n
FROM #NewData n
INNER JOIN
#added a ON a.MasterID = n.MasterID AND a.MarqueID = n.MarqueID AND a.TypologieID = n.TypologieID
-----------------------------------------------------------------------------------------------------
SELECT * FROM #NewData	 --(14942 row(s) affected) осталось

-----------------------------------------------------------------------------------------------------
--update life cycle	 (12477 row(s) affected) 
IF OBJECT_ID('tempdb..#UpdateLifeCycle' ,'U') IS NOT NULL
    DROP TABLE #UpdateLifeCycle
 GO
SELECT n.*
INTO #UpdateLifeCycle
FROM #NewData n
INNER JOIN  
export.PROB_ChangementTypologie t
             ON  t.MasterID = n.MasterID
                 AND t.MarqueID = n.MarqueID
		INNER JOIN etl.V_TypologiesByGroup tg ON n.TypologieID = tg.TypologieID
WHERE
	t.CurrTypologieID <> n.TypologieID
	AND tg.groupId = TypoGR1

SELECT * FROM #UpdateLifeCycle

DELETE n
FROM #NewData n
INNER JOIN  
	#UpdateLifeCycle u ON n.LigneID = u.LigneID  

UPDATE t
SET    t.PrevTypologieID = t.CurrTypologieID
	      ,t.CurrTypologieID = n.TypologieID
	      ,ChangeDate = GETDATE()
FROM #UpdateLifeCycle n
INNER JOIN  
export.PROB_ChangementTypologie t
             ON  t.MasterID = n.MasterID
                 AND t.MarqueID = n.MarqueID
		INNER JOIN etl.V_TypologiesByGroup tg ON n.TypologieID = tg.TypologieID
WHERE
	t.CurrTypologieID <> n.TypologieID
	AND tg.groupId = TypoGR1
---------------------------------------------------------------------------------------
SELECT n.*, t.*, Count(*) OVER (PARTITION BY TypoGr1 ORDER BY Typogr1) N 
FROM #NewData n	--(2465 row(s) affected)
JOIN etl.V_TypologieTransitions  tt ON n.TypologieID = tt.IdTo
JOIN export.PROB_ChangementTypologie t
 ON n.masterId = t.MasterID AND n.marqueID = t.MarqueID AND t.CurrTypologieID = tt.idfrom 
ORDER BY t.MasterID

SELECT * FROM etl.V_TypologiesByGroup	

SELECT * FROM export.PROB_ChangementTypologie
	                           