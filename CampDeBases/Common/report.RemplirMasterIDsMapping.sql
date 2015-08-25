/****** Object:  StoredProcedure [report].[RemplirMasterIDsMapping]    Script Date: 19/08/2015 16:23:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [report].[RemplirMasterIDsMapping] AS
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
	       INNER JOIN import.SSO_Cumul I
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
	       INNER JOIN (
	                SELECT RANK() OVER(
	                           PARTITION BY sIdCompte ORDER BY ActionID 
	                           DESC
	                          ,ImportID DESC
	                       ) AS N
	                      ,sIdCompte
	                      ,iRecipientId
	                FROM   import.NEO_CusCompteEFR
	                WHERE  LigneStatut <> 1
	            ) I
	            ON  c.ClientID = I.sIdCompte
	       INNER JOIN brut.Contacts bC
	            ON  I.iRecipientId = bC.OriginalID
	                AND bC.SourceID = 1
	WHERE  I.N = 1
	       AND c.Marque = 7
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
	       INNER JOIN (
	                SELECT RANK() OVER(
	                           PARTITION BY sIdCompte ORDER BY ActionID 
	                           DESC
	                          ,ImportID DESC
	                       ) AS N
	                      ,sIdCompte
	                      ,iRecipientId
	                FROM   import.NEO_CusCompteFF
	                WHERE  LigneStatut <> 1
	            ) I
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
GO
