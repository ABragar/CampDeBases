USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [import].[PublierPVL_Utilisateur_EQ]    Script Date: 29.04.2015 17:40:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [import].[PublierPVL_Utilisateur_EQ] @FichierTS NVARCHAR(255)
AS

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 24/10/2014
-- Description:	Alimentation des tables : 
--								
--								brut.ConsentementsEmail 
-- a partir des fichiers AccountReport de VEL : PVL_Utilisateur de l'Equipe
-- Modification date: 18/11/2014
-- Modifications : n'alimenter que brut.ConsentementsEmail
-- Modification date: 15/12/2014
-- Modifications : Recuperation des lignes invalides a cause de ClientUserID
-- =============================================

BEGIN
	SET NOCOUNT ON
	
	DECLARE @SourceID INT
	
	SET @SourceID = 10 -- PVL
	
	DECLARE @Marque INT
	
	SELECT @Marque = (
	           CASE 
	                WHEN @FichierTS LIKE N'%EQ%' THEN 7
	                WHEN @FichierTS LIKE N'%LP%' THEN 6
	           END
	       )
	
	SELECT @Marque = 7 -- en attendant la mise en place des noms des fichiers, on met d'office marque l'Equipe 
	
	CREATE TABLE #T_Trouver_ProfilID
	(
		ProfileID                  INT NULL
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
	       INNER JOIN import.NEO_CusCompteEFR b
	            ON  a.ClientUserId = b.sIdCompte
	WHERE  a.RejetCode & POWER(CAST(2 AS BIGINT) ,42) = POWER(CAST(2 AS BIGINT) ,42)
	       AND b.LigneStatut <> 1
	
	UPDATE a
	SET    RejetCode = a.RejetCode -POWER(CAST(2 AS BIGINT) ,42)
	FROM   #T_Recup a
	
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
	
	IF @Marque = 7
	BEGIN
	    UPDATE a
	    SET    iRecipientId = r1.iRecipientId
	    FROM   #T_Trouver_ProfilID a
	           INNER JOIN (
	                    SELECT RANK() OVER(
	                               PARTITION BY b.sIdCompte ORDER BY CAST(b.ActionID AS INT) 
	                               DESC
	                              ,b.ImportID DESC
	                           ) AS N1
	                          ,b.sIdCompte
	                          ,b.iRecipientId
	                    FROM   import.NEO_CusCompteEFR b
	                    WHERE  b.LigneStatut <> 1
	                ) AS r1
	                ON  a.ClientUserId = r1.sIdCompte
	    WHERE  r1.N1 = 1
	    
	    UPDATE a
	    SET    ProfileID = b.ProfilID
	    FROM   #T_Trouver_ProfilID a
	           INNER JOIN brut.Contacts b
	                ON  a.iRecipientId = b.OriginalID
	                    AND b.SourceID = 1
	END
	
	DELETE b
	FROM   #T_Trouver_ProfilID a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	WHERE  a.ProfileID IS NULL
	
	DELETE #T_Trouver_ProfilID
	WHERE  ProfileID IS NULL
	
	UPDATE b
	SET    IDclientVEL = a.ClientUserId
	      ,StatutCompteVEL = (
	           CASE a.AccountStatus
	                WHEN N'Activated' THEN 1
	                WHEN N'Closed' THEN 2
	           END
	       ) 
	       -- rajouter les deux autres statuts ("inactif", "mauvais payeur") quand ils seront connus
	FROM   #T_Trouver_ProfilID a
	       INNER JOIN brut.Contacts b
	            ON  a.ProfileID = b.ProfilID
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
	
	DECLARE @ContenuID INT
	
	SELECT @ContenuID = (CASE @Marque WHEN 7 THEN 50 WHEN 6 THEN 51 END)
	
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
	       a.ProfileID
	      ,a.ProfileID
	      ,a.EmailAddress
	      ,@ContenuID           AS ContenuID
	      ,CASE 
	            WHEN a.NoMarketingInformation = N'False' THEN 1
	            ELSE -1
	       END                  AS Valeur
	      ,COALESCE(a.CreateDate ,a.LastUpdated ,GETDATE()) AS ConsentementDate
	FROM   #T_Trouver_ProfilID     a
	WHERE  a.ProfileID IS NOT NULL
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
