ALTER PROC report.RemplirMasterIDsMapping AS
BEGIN
	--SET NOCOUNT ON;
	TRUNCATE TABLE report.StatsMasterIDsMapping
	
	SELECT clientId
	      ,SiteID
	      ,sw.Marque 
	       INTO                        #clientIDs
	FROM   (
	           SELECT clientId
	                 ,SiteID
	           FROM   import.Xiti_Sessions
	           WHERE  LigneStatut <> 1
	           GROUP BY
	                  clientId
	                 ,SiteID
	       ) x
	       INNER JOIN ref.SitesWeb  AS sw
	            ON  x.SiteID = sw.WebSiteID
	
	INSERT INTO report.StatsMasterIDsMapping
	  (
	    MasterID
	   ,ClientID
	   ,SiteID
	   ,MarqueId
	  )
	SELECT bc.masterId
	      ,ClientID
	      ,SiteId
	      ,Marque
	FROM   #clientIDs c
	       INNER JOIN import.LPSSO_SSO I
	            ON  ClientID = I.id_SSO
	       INNER JOIN brut.Contacts bc
	            ON  I.email_origine = bc.OriginalID
	                AND bc.SourceID = 2
	WHERE  c.Marque IN (2 ,6)
	GROUP BY
	       bc.MasterID
	      ,ClientID
	      ,SiteId
	      ,Marque
	
	UNION ALL
	SELECT bc.masterId
	      ,ClientID
	      ,SiteId
	      ,Marque
	FROM   #clientIDs c
	       INNER JOIN import.NEO_CusCompteEFR I
	            ON  c.ClientID = I.sIdCompte
	       INNER JOIN brut.Contacts bC
	            ON  I.iRecipientId = bC.OriginalID
	                AND bC.SourceID = 1
	WHERE  c.Marque = 7
	GROUP BY
	       bc.MasterID
	      ,ClientID
	      ,SiteId
	      ,Marque
	
	UNION ALL
	SELECT bc.masterId
	      ,ClientID
	      ,SiteId
	      ,Marque
	FROM   #clientIDs c
	       INNER JOIN import.NEO_CusCompteFF I
	            ON  c.ClientID = I.sIdCompte
	       INNER JOIN brut.Contacts bC
	            ON  I.iRecipientId = bC.OriginalID
	                AND bC.SourceID = 1
	WHERE  c.Marque = 3
	GROUP BY
	       bc.MasterID
	      ,ClientID
	      ,SiteId
	      ,Marque
	
	DROP TABLE #clientIDs
END