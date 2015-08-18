WITH doubles AS (
         SELECT ConsentementID
         FROM   (
                    SELECT ConsentementID
                          ,ROW_NUMBER() OVER(
                               PARTITION BY Email
                              , ContenuID 
							  , MasterID 
								ORDER BY ConsentementDate DESC
                              ,valeur ASC
                           ) N
                    FROM   dbo.ConsentementsEmail
                ) x
         WHERE  N > 1
     )
--DELETE c
SELECT *
FROM   dbo.ConsentementsEmail c
       INNER JOIN doubles d
            ON  c.ConsentementID = d.ConsentementID

;WITH doubles AS (
         SELECT MasterID
         FROM   (
                    SELECT COUNT(*) AS N
                          ,a.MasterID
                          ,a.Email
                          ,a.ContenuID
                    FROM   dbo.ConsentementsEmail a
                    GROUP BY
                           a.MasterID
                          ,a.Email
                          ,a.ContenuID
                ) AS r1
         WHERE  r1.N > 1
     )
, OrderedD AS
(
         SELECT ConsentementID
         FROM   (
                    SELECT ConsentementID
                          ,ROW_NUMBER() OVER(
                               PARTITION BY c.MasterID
                              ,c.Email
                              ,c.ContenuID ORDER BY ConsentementDate DESC
                              ,c.valeur ASC
                           ) N
                    FROM   dbo.ConsentementsEmail c
                    INNER JOIN doubles ON c.MasterID = doubles.MasterID
                ) x
         WHERE  N > 1
)
SELECT *
FROM   dbo.ConsentementsEmail c
       INNER JOIN OrderedD d
            ON  c.ConsentementID = d.ConsentementID

;WITH doubles AS (
         SELECT MasterID
         FROM   (
                    SELECT masterID
                          ,ROW_NUMBER() OVER(
                               PARTITION BY Email
                              , ContenuID 
							  , MasterID 
								ORDER BY [ConsentementID]
                           ) N
                    FROM   dbo.ConsentementsEmail
                ) x
         WHERE  N > 1
)
,ordered AS 
(
        SELECT ConsentementID
         FROM   (
                    SELECT ConsentementID
                          ,ROW_NUMBER() OVER(
                               PARTITION BY c.MasterID
                              ,c.Email
                              ,c.ContenuID ORDER BY ConsentementDate DESC
                              ,c.valeur ASC
                           ) N
                    FROM   dbo.ConsentementsEmail c
                    INNER JOIN doubles ON c.MasterID = doubles.MasterID
                ) x
         WHERE  N > 1
	)
--DELETE c
SELECT *
FROM   dbo.ConsentementsEmail c
       INNER JOIN ordered d
            ON  c.ConsentementID = d.[ConsentementID]