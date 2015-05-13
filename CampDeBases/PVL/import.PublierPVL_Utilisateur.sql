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

-- =============================================

BEGIN
	SET NOCOUNT ON
	DECLARE @ContenuID INT
	DECLARE @SourceID INT
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
	    SET @MarqueID = 7 -- en attendant la mise en place des noms des fichiers, on met d'office marque l'Equipe
	END
	
	IF @FichierTS LIKE N'LP%'
	BEGIN
	    SET @FilePrefix = N'LP%'
	    SET @MarqueID = 6 -- en attendant la mise en place des noms des fichiers, on met d'office marque Le Parisien
	END
	--TypeContenu?
	SET @ContenuID = etl.GetContenuID(@MarqueID ,N'Commercial')
	
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
	
	SET DATEFORMAT dmy
	
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
	    
	    -- Pour le reste, on passe par brut.Emails de differentes sources
	    IF OBJECT_ID(N'tempdb..#T_BrutSourceID') IS NOT NULL
	        DROP TABLE #T_BrutSourceID
	    
	    CREATE TABLE #T_BrutSourceID
	    (
	    	ProfilID         INT NULL
	       ,EmailAddress     NVARCHAR(255) NULL
	       ,SourceID         INT NULL
	    )
	    
	    -- SourceID = 2 : LP SSO
	    
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
	                ON  a.EmailAddress = b.Email
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
	    
	    
	    -- SourceID = 4 : LP Prospects
	    
	    TRUNCATE TABLE #T_BrutSourceID
	    
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
	                ON  a.EmailAddress = b.Email
	           INNER JOIN brut.Contacts c
	                ON  b.ProfilID = c.ProfilID
	                    AND c.SourceID = 4
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
	    
	    -- SourceID = 3 : SDVP (DCS)
	    
	    TRUNCATE TABLE #T_BrutSourceID
	    
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
	                ON  a.EmailAddress = b.Email
	           INNER JOIN brut.Contacts c
	                ON  b.ProfilID = c.ProfilID
	                    AND c.SourceID = 3
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
	    
	    -- SourceID = 1 : Neolane
	    -- (il ne doit pas y en avoir, en theorie)
	    
	    TRUNCATE TABLE #T_BrutSourceID
	    
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
	                ON  a.EmailAddress = b.Email
	           INNER JOIN brut.Contacts c
	                ON  b.ProfilID = c.ProfilID
	                    AND c.SourceID = 1
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
	
	IF OBJECT_ID(N'tempdb..#T_Recup') IS NOT NULL
	    DROP TABLE #T_Recup
	
	IF OBJECT_ID(N'tempdb..#T_ConsEmail') IS NOT NULL
	    DROP TABLE #T_ConsEmail
	
	IF OBJECT_ID(N'tempdb..#T_Trouver_ProfilID') IS NOT NULL
	    DROP TABLE #T_Trouver_ProfilID
	
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
	    --set @S=N'EXECUTE [QTSDQF].[dbo].[RejetsStats] ''95940C81-C7A7-4BD9-A523-445A343A9605'', ''PVL_Utilisateur'', N'''+@FTS+N''' ; '
	    
	    --IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_Utilisateur'))
	    --	execute (@S) 
	    
	    FETCH c_fts INTO @FTS
	END
	
	CLOSE c_fts
	DEALLOCATE c_fts
	
	
	/********** AUTOCALCULATE REJECTSTATS **********/
	--IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_Utilisateur'))
	--	EXECUTE [QTSDQF].[dbo].[RejetsStats] '95940C81-C7A7-4BD9-A523-445A343A9605', 'PVL_Utilisateur', @FichierTS
END
