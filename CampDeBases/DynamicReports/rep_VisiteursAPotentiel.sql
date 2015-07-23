--VISITEURS A POTENTIEL
DECLARE @p NVARCHAR(1) = N'J';;
WITH s AS (
         SELECT MasterID
         FROM   dbo.Contacts
     ),
     filter AS (
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
     ,serie1 AS (
         SELECT f.MasterId
               ,'Abonnes numeriques'   AS Serie
         FROM   filter                 AS f
                INNER JOIN Typologie t
                     ON  f.MasterID = t.MasterID
                INNER JOIN (
                         SELECT CodeVAlN
                         FROM   ref.Misc AS m
                         WHERE  m.TypeRef = 'TYPOLOGIE'
                                AND (
                                        m.Valeur LIKE 'CSNGN%'
                                        OR m.Valeur LIKE 'CSNGA%'
                                        OR m.Valeur LIKE 'CSNGE%'
                                        OR m.Valeur LIKE 'CSNPN%'
                                        OR m.Valeur LIKE 'CSNPA%'
                                        OR m.Valeur LIKE 'CSNPE%'
                                        OR m.Valeur LIKE 'BSNGN%'
                                        OR m.Valeur LIKE 'BSNGA%'
                                        OR m.Valeur LIKE 'BSNGE%'
                                        OR m.Valeur LIKE 'BSNPN%'
                                        OR m.Valeur LIKE 'BSNPA%'
                                        OR m.Valeur LIKE 'BSNPE%'
                                        OR m.Valeur LIKE 'TSNGN%'
                                        OR m.Valeur LIKE 'TSNGA%'
                                        OR m.Valeur LIKE 'TSNGE%'
                                        OR m.Valeur LIKE 'TSNPN%'
                                        OR m.Valeur LIKE 'TSNPA%'
                                    )
                     ) i
                     ON  i.CodeVAlN = t.TypologieID
     )
     ,serie3 AS (
         SELECT f.MasterId
               ,'Autres contacts'   AS Serie
         FROM   filter f
                LEFT JOIN serie1 s
                     ON  f.masterId = s.masterId
         WHERE  s.masterId IS          NULL
     )
     ,visitorsNumeric AS (
         SELECT r.masterId
               ,Serie
               ,Period
         FROM   report.StatsWebSessions r
                INNER JOIN serie1 s
                     ON  r.MasterID = s.masterID
         WHERE  r.periodType = @p
     )
     ,visitorsNonNumeric AS (
         SELECT r.masterId
               ,Serie
               ,Period
         FROM   report.StatsWebSessions r
                INNER JOIN serie3 s
                     ON  r.MasterID = s.masterID
         WHERE  r.periodType = @p
     )
     ,AllAbonentsNewsletter AS (
         SELECT cm.masterID
         FROM   dbo.ConsentementsEmail cm
                INNER JOIN ref.Contenus AS c
                     ON  cm.ContenuID = c.ContenuID
                INNER JOIN Typologie t
                     ON  cm.MasterID = t.MasterID
                INNER JOIN (
                         SELECT CodeVAlN
                         FROM   ref.Misc AS m
                         WHERE  m.TypeRef = 'TYPOLOGIE'
                                AND (m.Valeur LIKE 'OEN%' OR m.Valeur LIKE 'OEA%')
                     ) i
                     ON  i.CodeVAlN = t.TypologieID
         WHERE  cm.Valeur = 1
                AND c.TypeContenu = 1
     )
     ,AbonentsNewsletterNumeric AS
     (
         SELECT vn.masterID
               ,Serie
               ,Period
         FROM   AllAbonentsNewsletter a
                INNER JOIN visitorsNumeric vn
                     ON  a.masterId = vn.masterID
     )
     ,AbonentsNewsletterNonNumeric AS
     (
         SELECT vn.masterID
               ,Serie
               ,Period
         FROM   AllAbonentsNewsletter a
                INNER JOIN visitorsNonNumeric vn
                     ON  a.masterId = vn.masterID
     )
     ,res AS (
         SELECT COUNT(MasterID)  AS Visitors
               ,0                AS AbonentsNewsletter
               ,Serie
               ,Period
         FROM   visitorsNumeric
         GROUP BY
                Serie
               ,Period
         
         UNION ALL
         
         SELECT COUNT(MasterID)  AS Visitors
               ,0                AS AbonentsNewsletter
               ,Serie
               ,Period
         FROM   visitorsNonNumeric
         GROUP BY
                Serie
               ,Period
         
         UNION ALL
         
         SELECT 0
               ,COUNT(MasterID) AS AbonentsNewsletter
               ,Serie
               ,Period
         FROM   AbonentsNewsletterNumeric
         GROUP BY
                Serie
               ,Period
         
         UNION ALL
         
         SELECT 0
               ,COUNT(MasterID) AS AbonentsNewsletter
               ,Serie
               ,Period
         FROM   AbonentsNewsletterNonNumeric
         GROUP BY
                Serie
               ,Period
     )

SELECT CAST(SUM(AbonentsNewsletter) AS FLOAT) / SUM(Visitors) AS value
      ,Serie
      ,Period
FROM   res
GROUP BY
       Serie
      ,Period



	
					 