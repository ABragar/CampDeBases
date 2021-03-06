﻿ALTER PROCEDURE etl.SupprDoublonsConsent
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
	OUTPUT 3, DELETED.ConsentementID INTO export.ActionID_ATOS_ConsentEmails(ActionID, ConsentementID)
	FROM   dbo.ConsentementsEmail c
	       INNER JOIN doubles d
	            ON  c.ConsentementID = d.ConsentementID
END


