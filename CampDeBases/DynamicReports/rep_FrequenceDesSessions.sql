--FREQUENCE DES SESSIONS
DECLARE @p NVARCHAR(1) = N'M';
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

SELECT round(cast(SUM(SessionsCount) AS FLOAT)/COUNT(r.masterID),3) , Period, Category
FROM   report.StatsVolumetrieSessions r
       INNER JOIN t
            ON  t.MasterID = r.MasterID
WHERE r.PeriodType=@p            
GROUP BY
       Period,Category
ORDER BY Period
