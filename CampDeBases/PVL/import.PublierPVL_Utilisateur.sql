USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [import].[PublierPVL_Utilisateur]    Script Date: 29.04.2015 17:39:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [import].[PublierPVL_Utilisateur] @FichierTS NVARCHAR(255)
AS
-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 24/10/2014
-- Description:	Alimentation des tables : 
--								
--								brut.ConsentementsEmail 
-- a partir des fichiers AccountReport de VEL : PVL_Utilisateur
-- Modification date: 18/11/2014
-- Modifications : n'alimenter que brut.ConsentementsEmail
-- Modification date: 15/12/2014
-- Modifications : Recuperation des lignes invalides a cause de ClientUserID
-- Modified by :	Andrei BRAGAR
-- Modification date: 08/05/2015
-- Modifications : join with PublierPVL_Utilisateur_EQ,LP,FF
-- Modified by :	Andrei BRAGAR
-- Modification date: 15/07/2015
-- Modifications : public contacts with SourceID = 10
-- =============================================

BEGIN
	SET NOCOUNT ON
	SET DATEFORMAT dmy
	DECLARE @ContenuID INT
	DECLARE @MarqueID INT
	DECLARE @CusCompteTableName NVARCHAR(255)
	DECLARE @FilePrefix NVARCHAR(255)
	DECLARE @sqlCommand NVARCHAR(500)
	
	IF @FichierTS LIKE N'FF%'
	BEGIN
	    SET @CusCompteTableName = N'import.NEO_CusCompteFF'
	    SET @FilePrefix = N'FF%'
	    SET @MarqueID = 3
	END
	
	IF @FichierTS LIKE N'EQP%'
	BEGIN
	    SET @CusCompteTableName = N'import.NEO_CusCompteEFR'		
	    SET @FilePrefix = N'EQP%'
	    SET @MarqueID = 7 -- l'Equipe
	END
	
	IF @FichierTS LIKE N'LP%'
	BEGIN
	    SET @FilePrefix = N'LP%'
	    SET @MarqueID = 6 -- Le Parisien
	END
	
	--TypeContenu
	SET @ContenuID = etl.GetContenuID(@MarqueID ,N'Marque')
	
	IF @FilePrefix IS NULL
	    RAISERROR('File prefix does not match any of the possible' ,16 ,1);
	
	CREATE TABLE #CusCompteTmp
	(
		sIdCompte        NVARCHAR(255)
	   ,iRecipientId     NVARCHAR(18)
	   ,ActionID         INT
	   ,ImportID         INT
	   ,LigneStatut      INT
	   ,FichierTS        NVARCHAR(255)
	)	
	
	IF @FilePrefix <> N'LP%'
	BEGIN
	    SET @sqlCommand = 
	        N'INSERT #CusCompteTmp SELECT cc.sIdCompte ,cc.iRecipientId ,CAST(cc.ActionID AS INT) as ActionID ,cc.ImportID ,cc.LigneStatut ,cc.FichierTS FROM '
	        + @CusCompteTableName + ' AS cc where cc.LigneStatut<>1'	          
	    
	    EXEC (@sqlCommand)
	    
	    CREATE INDEX idx01_sIdCompte ON #CusCompteTmp(sIdCompte) 
	    CREATE INDEX idx02_ActionID ON #CusCompteTmp(ActionID)
	END
	
	CREATE TABLE #T_Trouver_ProfilID
	(
		ProfilID                   INT NULL
	   ,EmailAddress               NVARCHAR(255) NULL
	   ,ClientUserId               NVARCHAR(16) NULL
	   ,iRecipientId               NVARCHAR(16) NULL
	   ,NoMarketingInformation     NVARCHAR(16) NULL
	   ,AccountStatus              NVARCHAR(20) NULL
	   ,CreateDate                 DATETIME NULL
	   ,LastUpdated                DATETIME NULL
	   ,ImportID                   INT NULL
	)
	
	INSERT #T_Trouver_ProfilID
	  (
	    EmailAddress
	   ,ClientUserId
	   ,AccountStatus
	   ,NoMarketingInformation
	   ,CreateDate
	   ,LastUpdated
	   ,ImportID
	  )
	SELECT a.EmailAddress
	      ,a.ClientUserId
	      ,a.AccountStatus
	      ,COALESCE(a.NoMarketingInformation ,N'False')
	      ,CAST(a.CreateDate AS DATETIME)
	      ,CAST(a.LastUpdated AS DATETIME)
	      ,a.ImportID
	FROM   import.PVL_Utilisateur a
	WHERE  a.FichierTS = @FichierTS
	       AND a.LigneStatut = 0

	       
	-- Recuperer les lignes rejetees a cause de ClientUserId absent de CusCompteEFR
	-- mais dont le sIdCompte est arrive depuis dans CusCompteEFR
	
	-- La table #T_FTS servira au recalcul des statistiques 
	
	IF OBJECT_ID(N'tempdb..#T_FTS') IS NOT NULL
	    DROP TABLE #T_FTS
	
	CREATE TABLE #T_FTS
	(
		FichierTS NVARCHAR(255) NULL
	)
	
	IF OBJECT_ID(N'tempdb..#T_Recup') IS NOT NULL
	    DROP TABLE #T_Recup
	
	CREATE TABLE #T_Recup
	(
		RejetCode     BIGINT NOT NULL
	   ,ImportID      INT NOT NULL
	   ,FichierTS     NVARCHAR(255) NULL
	)
	
	IF @FilePrefix = N'LP%'
	BEGIN
	    INSERT #T_Recup
	      (
	        RejetCode
	       ,ImportID
	       ,FichierTS
	      )
	    SELECT DISTINCT a.RejetCode
	          ,a.ImportID
	          ,a.FichierTS
	    FROM   import.PVL_Utilisateur a
	           INNER JOIN import.SSO_Cumul b
	                ON  a.EmailAddress = b.email_courant
	    WHERE  a.RejetCode & POWER(CAST(2 AS BIGINT) ,2) = POWER(CAST(2 AS BIGINT) ,2)
	    
	    INSERT #T_Recup
	      (
	        RejetCode
	       ,ImportID
	       ,FichierTS
	      )
	    SELECT DISTINCT a.RejetCode
	          ,a.ImportID
	          ,a.FichierTS
	    FROM   import.PVL_Utilisateur a
	           INNER JOIN brut.Emails b
	                ON  a.EmailAddress = b.Email
	    WHERE  a.RejetCode & POWER(CAST(2 AS BIGINT) ,2) = POWER(CAST(2 AS BIGINT) ,2)
	    
	    UPDATE a
	    SET    RejetCode = a.RejetCode -POWER(CAST(2 AS BIGINT) ,2)
	    FROM   #T_Recup a
	END
	ELSE
	    --EQ, FF
	BEGIN
	    INSERT #T_Recup
	      (
	        RejetCode
	       ,ImportID
	       ,FichierTS
	      )
	    SELECT a.RejetCode
	          ,a.ImportID
	          ,a.FichierTS
	    FROM   import.PVL_Utilisateur a
	           INNER JOIN #CusCompteTmp b
	                ON  a.ClientUserId = b.sIdCompte
	    WHERE  a.RejetCode & POWER(CAST(2 AS BIGINT) ,42) = POWER(CAST(2 AS BIGINT) ,42)
	    
	    UPDATE a
	    SET    RejetCode = a.RejetCode -POWER(CAST(2 AS BIGINT) ,42)
	    FROM   #T_Recup a
	END
	
	UPDATE a
	SET    RejetCode = b.RejetCode
	FROM   import.PVL_Utilisateur a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	
	UPDATE a
	SET    LigneStatut = 0
	FROM   import.PVL_Utilisateur a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	WHERE  b.RejetCode = 0
	
	UPDATE a
	SET    RejetCode = b.RejetCode
	FROM   rejet.PVL_Utilisateur a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	
	INSERT #T_FTS
	  (
	    FichierTS
	  )
	SELECT DISTINCT FichierTS
	FROM   #T_Recup
	
	DELETE a
	FROM   #T_Recup a
	WHERE  a.RejetCode <> 0
	
	DELETE a
	FROM   rejet.PVL_Utilisateur a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	
	INSERT #T_Trouver_ProfilID
	  (
	    EmailAddress
	   ,ClientUserId
	   ,AccountStatus
	   ,NoMarketingInformation
	   ,CreateDate
	   ,LastUpdated
	   ,ImportID
	  )
	SELECT a.EmailAddress
	      ,a.ClientUserId
	      ,a.AccountStatus
	      ,a.NoMarketingInformation
	      ,CAST(a.CreateDate AS DATETIME)
	      ,CAST(a.LastUpdated AS DATETIME)
	      ,a.ImportID
	FROM   import.PVL_Utilisateur a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	WHERE  a.LigneStatut = 0
	       --AND ISDATE(a.LastUpdated) = 1
	       --AND ISDATE(a.CreateDate) = 1

	IF @FilePrefix = N'LP%'--LP
	BEGIN
	    -- Trouver le ProfilID
	    
	    -- On retrouve le ProfilID dans brut.Contacts en passant par import.SSO_Cumul
	    -- ainsi on retrouve la plupart des ProfilID
	    UPDATE a
	    SET    ProfilID = c.ProfilID
	    FROM   #T_Trouver_ProfilID a
	           INNER JOIN import.SSO_Cumul b
	                ON  a.EmailAddress = b.email_courant
	           INNER JOIN brut.Contacts c
	                ON  b.email_origine = c.OriginalID
	                    AND c.SourceID = 2 
	    
	    -- Pour le reste, on passe par brut.Emails de SourceID=2
	    IF OBJECT_ID(N'tempdb..#T_BrutSourceID') IS NOT NULL
	        DROP TABLE #T_BrutSourceID
	    
	    CREATE TABLE #T_BrutSourceID
	    (
	    	ProfilID         INT NULL
	       ,EmailAddress     NVARCHAR(255) NULL
	       ,SourceID         INT NULL
	    )
	    
	    ---- SourceID = 2 : LP SSO
	    
	    INSERT #T_BrutSourceID
	      (
	        ProfilID
	       ,EmailAddress
	       ,SourceID
	      )
	    SELECT c.ProfilID
	          ,a.EmailAddress
	          ,c.SourceID
	    FROM   #T_Trouver_ProfilID a
	           INNER JOIN brut.Emails b
	                ON  a.EmailAddress = b.ValeurOrigine
	           INNER JOIN brut.Contacts c
	                ON  b.ProfilID = c.ProfilID
	                    AND c.SourceID = 2
	    WHERE  a.ProfilID IS NULL
	    
	    UPDATE a
	    SET    ProfilID = r1.ProfilID
	    FROM   #T_Trouver_ProfilID a
	           INNER JOIN brut.Emails b
	                ON  a.EmailAddress = b.Email
	           INNER JOIN (
	                    SELECT RANK() OVER(PARTITION BY c.EmailAddress ORDER BY c.ProfilID ASC) AS 
	                           N1
	                          ,c.ProfilID
	                    FROM   #T_BrutSourceID c
	                ) AS r1
	                ON  b.ProfilID = r1.ProfilID
	    WHERE  a.ProfilID IS NULL
	           AND r1.N1 = 1
	END
	
	IF @FilePrefix <> N'LP%'
	BEGIN
	    UPDATE a
	    SET    iRecipientId = r1.iRecipientId
	    FROM   #T_Trouver_ProfilID a
	           INNER JOIN (
	                    SELECT RANK() OVER(
	                               PARTITION BY b.sIdCompte ORDER BY b.ActionID 
	                               DESC
	                              ,b.ImportID DESC
	                           ) AS N1
	                          ,b.sIdCompte
	                          ,b.iRecipientId
	                    FROM   #CusCompteTmp b
	                ) AS r1
	                ON  a.ClientUserId = r1.sIdCompte
	    WHERE  r1.N1 = 1
	    
	    UPDATE a
	    SET    ProfilID = b.ProfilID
	    FROM   #T_Trouver_ProfilID a
	           INNER JOIN brut.Contacts b
	                ON  a.iRecipientId = b.OriginalID
	                    AND b.SourceID = 1
	END
	
	-- find by SourceID = 10
	UPDATE a
	SET    ProfilID = c.ProfilID
	FROM   #T_Trouver_ProfilID a
	       INNER JOIN brut.Contacts c
	            ON  a.ClientUserId = c.OriginalID
	                AND c.SourceID = 10
	                AND a.ProfilID IS NULL
	
       
	
	-- Create with SourceID=10 those contacts which had not been found neither with SourceID=1 or 2, nor with 10.
	-- We take all the files with the current prefix, excepting that of today, 
	-- as we expect account data (Neolane or SSO) arrive by tomorrow.
	
	DECLARE @SourceID INT = 10
	IF OBJECT_ID('tempdb..#T_Contacts') IS NOT NULL
	    DROP TABLE #T_Contacts
	
	DECLARE @rejeteCode BIGINT = CASE 
	                                  WHEN @FilePrefix = N'LP%' THEN POWER(CAST(2 AS BIGINT) ,2) --LP
	                                  ELSE POWER(CAST(2 AS BIGINT) ,42) --EQ,FF
	                             END
	
	CREATE TABLE #T_Contacts
	(
		ProfilID             INT NULL
	   ,OriginalID           NVARCHAR(255) NULL
	   ,Origine              NVARCHAR(255) NULL
	   ,SourceID             INT NULL
	   ,Civilite             NVARCHAR(255)
	   ,Prenom               NVARCHAR(255)
	   ,Nom                  NVARCHAR(255)
	   ,Genre                TINYINT
	   ,NaissanceDate        DATETIME
	   ,CreationDate         DATETIME
	   ,ModificationDate     DATETIME
	   ,FichierSource        NVARCHAR(255)
	   ,ImportID             NVARCHAR(255)
	    --Domiciliations
	   ,ComplementNom        NVARCHAR(80)
	   ,Adr1                 NVARCHAR(80)
	   ,Adr2                 NVARCHAR(80)
	   ,Adr3                 NVARCHAR(80)
	   ,Adr4                 NVARCHAR(80)
	   ,CodePostal           NVARCHAR(32)
	   ,Ville                NVARCHAR(80)
	   ,Region               NVARCHAR(80)
	   ,Pays                 NVARCHAR(80)
	    --E-Mails
	   ,email                NVARCHAR(128)
	    --telephones
	   ,TelFixe              NVARCHAR(20)
	   ,TelMobile            NVARCHAR(20)
	)
	
	INSERT #T_Contacts
	SELECT NULL                       AS ProfilID
	      ,pu.ClientUserId
	      ,etl.TRIM(pu.ClientUserId)  AS OriginalID
	      ,@SourceID                  AS SourceID
	      ,c.CodeValN                 AS Civilite
	      ,Prenom = CASE etl.Trim(FirstName)
	                     WHEN N'-' THEN NULL
	                     ELSE etl.Trim(FirstName)
	                END
	      ,Nom = CASE etl.Trim(Surname)
	                  WHEN N'-' THEN NULL
	                  ELSE etl.Trim(Surname)
	             END
	      ,Genre = CASE 
	                    WHEN pu.Title IN (N'2' ,N'3') /* Madame, Mademoiselle */ THEN 
	                         1
	                    WHEN pu.Title = N'1' /* Monsieur */ THEN 0
	                    ELSE NULL
	               END
	      ,CASE 
	            WHEN CAST(pu.DateOfBirth AS DATE) = CAST(N'01/01/1970' AS DATE) THEN 
	                 NULL
	            ELSE CAST(pu.DateOfBirth AS DATETIME)
	       END AS NaissanceDate
	      ,COALESCE(CAST(pu.CreateDate AS DATETIME) ,GETDATE()) AS CreationDate
	      ,COALESCE(CAST(pu.LastUpdated AS DATETIME) ,GETDATE()) AS 
	       ModificationDate
	      ,pu.FichierTS AS FichierSource
	      ,pu.ImportID
	       --Domiciliations
	      ,ComplementNom = LEFT(HomeHouseName ,80)
	      , Adr1 = NULL
	      ,Adr2 = CASE 
	                   WHEN ISNUMERIC(LEFT(pu.HomeFlatNumber ,1)) = 0 AND pu.HomeCountry 
	                        = 'France' THEN LEFT(etl.Trim(pu.HomeFlatNumber) ,80)
	              END
	      ,Adr3 = LEFT(
	           CASE 
	                WHEN ISNUMERIC(LEFT(pu.HomeFlatNumber ,1)) = 1 THEN etl.trim(pu.HomeFlatNumber)
	                ELSE ''
	           END + ' ' + etl.trim(pu.HomeStreet)
	          ,80
	       )
	      ,Adr4 = LEFT(
	           CASE 
	                WHEN ISNUMERIC(LEFT(pu.HomeFlatNumber ,1)) = 0
	           AND pu.HomeCountry <> 'France' THEN LEFT(etl.Trim(pu.HomeFlatNumber) ,80) 
	               ELSE '' END + ' ' + etl.trim(pu.HomeDistrict)
	          ,80
	       )
	      ,CodePostal = LEFT(pu.HomePostCode ,32)
	      ,Ville = LEFT(pu.HomeTownCity ,80)
	      ,Region = LEFT(pu.HomeCounty ,80)
	      ,Pays = case when etl.TRIM(pu.HomeCountry)=N'N/A' THEN NULL ELSE LEFT(pu.HomeCountry,80) END
	       --e-mail
	      ,email = LEFT(pu.EmailAddress ,128)
	       --telephones
	      ,TelFixe = etl.trim(LEFT(pu.HomePhoneNumber ,20))
	      ,TelMobile = etl.trim(LEFT(pu.MobilePhoneNumber ,20))
	FROM   import.PVL_Utilisateur AS pu
	       LEFT JOIN ref.Misc c
	            ON  c.CodeValN = CASE 
	                                  WHEN ISNUMERIC(pu.Title) = 1 THEN CAST(pu.Title AS INT)
	                                  ELSE NULL
	                             END
	                AND c.TypeRef = N'CIVILITE'
	WHERE  pu.FichierTS <> @FichierTS --exclude current day
	       AND pu.FichierTS LIKE @FilePrefix --	File prefix
	       AND pu.LigneStatut = 1
	       AND pu.RejetCode = @rejeteCode
	
	UPDATE pu
	SET    pu.RejetCode = 0
	      ,pu.LigneStatut = 99
	FROM   import.PVL_Utilisateur AS pu
	       INNER JOIN #T_Contacts c
	            ON  pu.ImportID = c.ImportID
	            
	DELETE pu
	FROM   rejet.PVL_Utilisateur pu
	       INNER JOIN #T_Contacts c
	            ON  pu.ImportID = c.ImportID

	INSERT INTO #T_FTS
	  (
	    FichierTS
	  )
	SELECT x.FichierSource  AS FichierTS
	FROM   (
	           SELECT c.FichierSource
	           FROM   #T_Contacts c
	           GROUP BY
	                  c.FichierSource
	       ) x
	       LEFT JOIN #T_FTS f
	            ON  x.FichierSource = f.FichierTS
	WHERE  f.FichierTS IS      NULL 
		             	             
	
	CREATE INDEX idx01_OriginalID ON #T_Contacts(OriginalID)
	
	UPDATE tc
	SET    tc.ProFilID = bc.ProfilID
	FROM   #T_Contacts tc
	       INNER JOIN brut.Contacts bc
	            ON  tc.OriginalID = bc.OriginalID
	WHERE  bc.SourceID = @SourceID
	
	--IF OBJECT_ID('tempdb..#ExistingContacts') IS NOT NULL
	--    DROP TABLE #ExistingContacts
	
	--CREATE TABLE #ExistingContacts
	--(
	--	ProfilID       INT NULL
	--   ,OriginalID     NVARCHAR(255) NULL
	--)
	
	---- fill existing profileId by sourceId
	--INSERT #ExistingContacts
	--  (
	--    ProfilID
	--   ,OriginalID
	--  )
	--SELECT b.ProfilID
	--      ,b.OriginalID
	--FROM   brut.Contacts b
	--       INNER JOIN #T_Contacts a
	--            ON  a.OriginalID = b.OriginalID
	--WHERE  b.SourceID = @SourceID
	
	--CREATE INDEX idx01_OriginalID ON #ExistingContacts(OriginalID)
	
	--UPDATE a
	--SET    ProfilID = b.ProfilID
	--FROM   #T_Contacts a
	--       INNER JOIN #ExistingContacts b
	--            ON  a.OriginalID = b.OriginalID
	
	
	-- insert new contacts
	INSERT INTO brut.Contacts
	  (
	    OriginalID
	   ,Origine
	   ,SourceID
	   ,Civilite
	   ,Prenom
	   ,Nom
	   ,Genre
	   ,NaissanceDate
	   ,CreationDate
	   ,ModificationDate
	   ,FichierSource
	  )
	SELECT OriginalID
	      ,Origine
	      ,SourceID
	      ,Civilite
	      ,Prenom
	      ,Nom
	      ,Genre
	      ,NaissanceDate
	      ,CreationDate
	      ,ModificationDate
	      ,FichierSource
	FROM   #T_Contacts
	WHERE  ProfilID IS NULL
	
	--update existing contacts
	UPDATE a
	SET    Origine = b.Origine
	      ,Civilite = b.Civilite
	      ,Prenom = b.Prenom
	      ,Nom = b.Nom
	      ,Genre = b.Genre
	      ,NaissanceDate = b.NaissanceDate
	      ,CreationDate = b.CreationDate
	      ,ModificationDate = b.ModificationDate
	      ,ModifieTop = 1
	FROM   brut.Contacts a
	       INNER JOIN #T_Contacts b
	            ON  a.ProfilID = b.ProfilID
	
	UPDATE t
	SET    t.ProfilID = c.ProfilID
	FROM   #T_Contacts t
	       INNER JOIN brut.Contacts AS c
	            ON  t.OriginalID = c.OriginalID
	WHERE  c.SourceID = @SourceID
	       AND t.ProfilID IS NULL 
	-- end brut.contacts
	
	-- update ProfilID for brut.ConsentementsEmail
	INSERT #T_Trouver_ProfilID
	  (
	    EmailAddress
	   ,ClientUserId
	   ,AccountStatus
	   ,NoMarketingInformation
	   ,CreateDate
	   ,LastUpdated
	   ,ImportID
	  )
	SELECT a.EmailAddress
	      ,a.ClientUserId
	      ,a.AccountStatus
	      ,a.NoMarketingInformation
	      ,CAST(a.CreateDate AS DATETIME)
	      ,CAST(a.LastUpdated AS DATETIME)
	      ,a.ImportID
	FROM   import.PVL_Utilisateur a
	       INNER JOIN #T_Contacts c
	            ON  a.ImportID = c.ImportID
	       LEFT JOIN #T_Trouver_ProfilID AS x
	            ON  x.ClientUserId = c.OriginalID
	WHERE  x.ClientUserId IS NULL
	
	UPDATE x
	SET    x.ProfilID = tc.ProfilID
	FROM   #T_Trouver_ProfilID AS x
	       INNER JOIN #T_Contacts tc
	            ON  x.ClientUserId = tc.OriginalID
	WHERE  x.ProfilID IS NULL
	
	--	/* update Domiciliations*/
	INSERT brut.Domiciliations
	  (
	    ProfilID
	   ,TypeAdr
	   ,ComplementNom
	   ,Adr1
	   ,Adr2
	   ,Adr3
	   ,Adr4
	   ,CodePostal
	   ,Ville
	   ,Region
	   ,Pays
	   ,CreationDate
	   ,ModificationDate
	   ,ValeurOrigine
	  )
	SELECT t.ProfilID
	      ,NULL
	      ,t.ComplementNom
	      ,t.Adr1
	      ,t.Adr2
	      ,t.Adr3
	      ,t.Adr4
	      ,t.CodePostal
	      ,t.Ville
	      ,t.Region
	      ,t.Pays
	      ,t.CreationDate
	      ,t.ModificationDate
	      ,CAST(COALESCE(t.ComplementNom ,N'') AS NVARCHAR(255))
	       + CAST(COALESCE(t.Adr1 ,N'') AS NVARCHAR(255)) 
	       + CAST(COALESCE(t.Adr2 ,N'') AS NVARCHAR(255)) 
	       + CAST(COALESCE(t.Adr3 ,N'')AS NVARCHAR(255)) 
	       + CAST(COALESCE(t.Adr4 ,N'')AS NVARCHAR(255)) 
	       + CAST(COALESCE(t.CodePostal ,N'')AS NVARCHAR(255)) 
	       + CAST(COALESCE(t.Ville ,N'') AS NVARCHAR(255))
	       + CAST(COALESCE(t.Region ,N'') AS NVARCHAR(255))
	       + CAST(COALESCE(t.Pays ,N'') AS NVARCHAR(255)) AS ValeurOrigine
	FROM   #T_Contacts t
	       LEFT JOIN brut.Domiciliations AS d
	            ON  t.ProfilID = d.ProfilID
	                AND d.ValeurOrigine = CAST(COALESCE(t.ComplementNom ,N'') AS NVARCHAR(255))
	                    + CAST(COALESCE(t.Adr1 ,N'') AS NVARCHAR(255)) 
	                    + CAST(COALESCE(t.Adr2 ,N'') AS NVARCHAR(255)) 
	                    + CAST(COALESCE(t.Adr3 ,N'')AS NVARCHAR(255)) 
	                    + CAST(COALESCE(t.Adr4 ,N'')AS NVARCHAR(255)) 
	                    + CAST(COALESCE(t.CodePostal ,N'')AS NVARCHAR(255)) 
	                    + CAST(COALESCE(t.Ville ,N'') AS NVARCHAR(255))
	                    + CAST(COALESCE(t.Region ,N'') AS NVARCHAR(255))
	                    + CAST(COALESCE(t.Pays ,N'') AS NVARCHAR(255))
	WHERE  (
	           CAST(COALESCE(t.ComplementNom ,N'') AS NVARCHAR(255))
	           + CAST(COALESCE(t.Adr1 ,N'') AS NVARCHAR(255)) 
	           + CAST(COALESCE(t.Adr2 ,N'') AS NVARCHAR(255)) 
	           + CAST(COALESCE(t.Adr3 ,N'')AS NVARCHAR(255)) 
	           + CAST(COALESCE(t.Adr4 ,N'')AS NVARCHAR(255)) 
	           + CAST(COALESCE(t.CodePostal ,N'')AS NVARCHAR(255)) 
	           + CAST(COALESCE(t.Ville ,N'') AS NVARCHAR(255))
	           + CAST(COALESCE(t.Region ,N'') AS NVARCHAR(255))
	           + CAST(COALESCE(t.Pays ,N'') AS NVARCHAR(255))
	       ) <> N''
	       AND t.ProfilID IS NOT NULL
	       AND d.ProfilID IS NULL
	--	/* end Domiciliations*/
	
	
	/* update emails*/
	INSERT brut.Emails
	  (
	    Email
	   ,ProfilID
	   ,ValeurOrigine
	   ,CreationDate
	   ,ModificationDate
	  )
	SELECT t.Email
	      ,t.ProfilID
	      ,t.Email
	      ,t.CreationDate
	      ,t.ModificationDate
	FROM   #T_Contacts t
	       LEFT JOIN [brut].[Emails] em
	            ON  t.ProfilID = em.ProfilID
	                AND t.Email = em.Email
	WHERE  em.ProfilID IS NULL
	       AND COALESCE(t.[Email] ,N'') <> N'' 
	/* end update emails*/
	
	/* update telephones*/
	IF OBJECT_ID('tempdb..#telephones') IS NOT NULL
	    DROP TABLE #telephones
	
	SELECT DISTINCT * INTO     #telephones
	FROM   (
	           SELECT c.ProfilID
	                 ,c.CreationDate
	                 ,c.ModificationDate
	                 ,c.TelFixe    AS PhoneNumber
	                 ,0            AS StopFlag
	                 ,3            AS PhoneType
	           FROM   #T_Contacts     c
	           WHERE  TelFixe IS NOT NULL
	           UNION
	           SELECT c.ProfilID
	                 ,c.CreationDate
	                 ,c.ModificationDate
	                 ,c.TelMobile
	                 ,0
	                 ,4
	           FROM   #T_Contacts c
	           WHERE  TelMobile IS NOT NULL
	       )                   x
	
	INSERT brut.Telephones
	  (
	    ProfilID
	   ,LigneType
	   ,NumeroTelephone
	   ,CreationDate
	   ,ModificationDate
	   ,StopTel
	  )
	SELECT t.ProfilID
	      ,t.PhoneType
	      ,t.PhoneNumber
	      ,t.CreationDate
	      ,t.ModificationDate
	      ,t.StopFlag
	FROM   #telephones t
	       LEFT JOIN [brut].[Telephones] bt
	            ON  bt.ProfilID = t.ProfilID
	                AND RIGHT(REPLACE(bt.NumeroTelephone ,N' ' ,N'') ,9) = RIGHT(REPLACE(t.PhoneNumber ,N' ' ,N'') ,9)
	WHERE  bt.ProfilID IS NULL
	       AND COALESCE(t.PhoneNumber ,N'') <> N'' 
	/* end update telephones*/
	
	DELETE b
	FROM   #T_Trouver_ProfilID a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	WHERE  a.ProfilID IS NULL
	
	DELETE #T_Trouver_ProfilID
	WHERE  ProfilID IS NULL
	
	UPDATE b
	SET    IDclientVEL = a.ClientUserId
	      ,StatutCompteVEL = (
	           CASE a.AccountStatus
	                WHEN N'Activated' THEN 1
	                WHEN N'Closed' THEN 2
	                WHEN N'Suspended' THEN 3
	           END
	       ) 
	       -- rajouter les deux autres statuts ("inactif", "mauvais payeur") quand ils seront connus
	FROM   #T_Trouver_ProfilID a
	       INNER JOIN brut.Contacts b
	            ON  a.ProfilID = b.ProfilID
	                AND b.SourceID = 1
	
	-- LienAvecMarque : StatutCompteVEL int
	
	-- brut.ConsentementsEmail
	
	IF OBJECT_ID(N'tempdb..#T_ConsEmail') IS NOT NULL
	    DROP TABLE #T_ConsEmail
	
	CREATE TABLE #T_ConsEmail
	(
		ProfilID             INT NOT NULL
	   ,MasterID             INT NULL
	   ,Email                NVARCHAR(255) NOT NULL
	   ,ContenuID            INT NULL
	   ,Valeur               INT NULL
	   ,ConsentementDate     DATETIME NULL
	)
	INSERT #T_ConsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT DISTINCT
	       a.ProfilID
	      ,a.ProfilID
	      ,a.EmailAddress
	      ,@ContenuID           AS ContenuID
	      ,CASE 
	            WHEN a.NoMarketingInformation = N'False' THEN 1
	            ELSE -1
	       END                  AS Valeur
	      ,COALESCE(a.CreateDate ,a.LastUpdated ,GETDATE()) AS ConsentementDate
	FROM   #T_Trouver_ProfilID     a
	WHERE  a.ProfilID IS NOT NULL
	       AND COALESCE(a.EmailAddress ,N'') <> N''
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT DISTINCT 
	       a.ProfilID
	      ,a.MasterID
	      ,a.Email
	      ,a.ContenuID
	      ,a.Valeur
	      ,a.ConsentementDate
	FROM   #T_ConsEmail a
	       LEFT OUTER JOIN brut.ConsentementsEmail b
	            ON  a.ProfilID = b.ProfilID
	                AND a.Email = b.Email
	                AND a.ContenuID = b.ContenuID
	                AND (a.Valeur = b.Valeur OR b.Valeur = -4)
	WHERE  a.ProfilID IS NOT NULL
	       AND b.ProfilID IS NULL
	
	
	-- dbo.LienAvecMarques
	
	UPDATE import.PVL_Utilisateur
	SET    LigneStatut = 99
	WHERE  FichierTS = @FichierTS
	       AND LigneStatut = 0
	
	UPDATE a
	SET    LigneStatut = 99
	FROM   import.PVL_Utilisateur a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	WHERE  a.LigneStatut = 0
	
	IF @FilePrefix = N'LP%'
	    EXEC etl.RemplirVEL_Accounts @FichierTS
	
	IF OBJECT_ID(N'tempdb..#T_Recup') IS NOT NULL
	    DROP TABLE #T_Recup
	
	IF OBJECT_ID(N'tempdb..#T_ConsEmail') IS NOT NULL
	    DROP TABLE #T_ConsEmail
	
	IF OBJECT_ID(N'tempdb..#T_Trouver_ProfilID') IS NOT NULL
	    DROP TABLE #T_Trouver_ProfilID
	
	IF OBJECT_ID(N'tempdb..#CusCompteTmp') IS NOT NULL
	    DROP TABLE #CusCompteTmp
	
	IF OBJECT_ID(N'tempdb..#T_Contacts') IS NOT NULL
	    DROP TABLE #T_Contacts
	
	
	DECLARE @FTS NVARCHAR(255)
	DECLARE @S NVARCHAR(1000)
	
	DECLARE c_fts CURSOR  
	FOR
	    SELECT FichierTS
	    FROM   #T_FTS
	
	OPEN c_fts
	
	FETCH c_fts INTO @FTS
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
	    SET @S = 
	        N'EXECUTE [QTSDQF].[dbo].[RejetsStats] ''95940C81-C7A7-4BD9-A523-445A343A9605'', ''PVL_Utilisateur'', N'''
	        + @FTS + N''' ; '
	    
	    IF (
	           EXISTS(
	               SELECT NULL
	               FROM   sys.tables t
	                      INNER JOIN sys.[schemas] s
	                           ON  s.SCHEMA_ID = t.SCHEMA_ID
	               WHERE  s.name = 'import'
	                      AND t.Name = 'PVL_Utilisateur'
	           )
	       )
	        EXECUTE (@S) 
	    
	    FETCH c_fts INTO @FTS
	END
	
	CLOSE c_fts
	DEALLOCATE c_fts
	
	
	/********** AUTOCALCULATE REJECTSTATS **********/
	IF (
	       EXISTS(
	           SELECT NULL
	           FROM   sys.tables t
	                  INNER JOIN sys.[schemas] s
	                       ON  s.SCHEMA_ID = t.SCHEMA_ID
	           WHERE  s.name = 'import'
	                  AND t.Name = 'PVL_Utilisateur'
	       )
	   )
	    EXECUTE [QTSDQF].[dbo].[RejetsStats] 
	            '95940C81-C7A7-4BD9-A523-445A343A9605'
	           ,'PVL_Utilisateur'
	           ,@FichierTS
END
    
