CREATE PROCEDURE etl.SupprDoublonsConsent
AS
BEGIN
	SET NOCOUNT ON
	;
	WITH doubles AS (
	         SELECT ConsentementID
	         FROM   (
	                    SELECT ConsentementID
	                          ,ROW_NUMBER() OVER(
	                               PARTITION BY Email
	                              ,ContenuID
	                              ,MasterID 
	                               ORDER BY ConsentementDate DESC
	                              ,valeur ASC
	                           ) N
	                    FROM   dbo.ConsentementsEmail
	                ) x
	         WHERE  N > 1
	     )
	
	DELETE c
	FROM   dbo.ConsentementsEmail c
	       INNER JOIN doubles d
	            ON  c.ConsentementID = d.ConsentementID
END


