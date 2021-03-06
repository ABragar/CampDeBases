﻿--Durée des sessions

DECLARE @p NVARCHAR(1) = N'J';
--N'S'            
--N'M'            

;WITH s AS (
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

SELECT SUM(SessionsCount)
      ,Period
      ,Sуries
      ,r.Marque
FROM   report.StatsWebSessions r
       INNER JOIN t
            ON  t.MasterID = r.MasterID
WHERE r.PeriodType=@p
GROUP BY
       Period
      ,Sуries
      ,SуriesSort
      ,r.Marque
      --,r.Appartenance
ORDER BY Period, SуriesSort
