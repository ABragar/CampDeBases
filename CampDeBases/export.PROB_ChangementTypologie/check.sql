DROP TABLE #tmp
;WITH states as
(SELECT ct.*
      ,Code
      ,state = CASE 
            WHEN currTypologieId IS NULL THEN N'Deleted'
            WHEN prevTypologieId IS NULL AND ChangeDate = '20150805' THEN 
                 'added'
            WHEN prevTypologieId IS NULL AND ChangeDate = '20150804' THEN 
                 'no change'
            WHEN prevTypologieId <> currTypologieId THEN 
                 'change life cycle'
			ELSE 'XXX'                 
            END
               
FROM   export.PROB_ChangementTypologie ct
       INNER JOIN (
                SELECT masterId
                FROM   export.PROB_ChangementTypologie
                WHERE  ChangeDate = '20150805'
                GROUP BY
                       MasterID
            ) x
            ON  ct.MasterID = x.masterId
INNER JOIN ref.typologie ON typoId = COALESCE(currTypologieId,prevTypologieId)            
--ORDER BY
--       ct.masterID
--      ,ct.MarqueID
)
, masterIDCnt AS (SELECT COUNT(DISTINCT [state]) AS Cnt, masterID, s.MarqueID 
FROM states s
WHERE s.[state] IN ('added','Deleted')         
GROUP BY masterId,s.MarqueID
                  Having COUNT(DISTINCT [state])>1

)
,res AS (
SELECT s.* 
FROM states AS s
INNER JOIN masterIDCnt mc ON s.MasterID = mc.masterId and s.MarqueID = mc.marqueId 
WHERE s.[state] IN ('added','Deleted')
)
SELECT * 
INTO #tmp
FROM res
ORDER BY masterId, marqueId


SELECT list_code, COUNT(list_code) AS pairCount
from
(SELECT distinct MasterId
      ,MarqueID
      ,(
           SELECT Code + ',' 
           FROM   #tmp                      r2
           WHERE  r1.masterId = r2.masterId 
           and r1.marqueId = r2.marqueId
           ORDER BY r2.masterId, r2.marqueId, r2.[State]
           FOR XML PATH('')
       ) AS list_code
FROM   #tmp r1
 --ORDER BY masterId
)x
GROUP BY list_code
ORDER BY COUNT(list_code) DESC



--SELECT MasterID, marqueId
-- FROM dbo.Typologie_04082015
--except
--SELECT MasterID, marqueId 
--FROM dbo.Typologie_05082015
----(13154 row(s) affected)
----(244 row(s) affected)

--SELECT MasterID, marqueId
--FROM dbo.Typologie_05082015 
--except
--SELECT MasterID, marqueId 
--FROM dbo.Typologie_04082015
