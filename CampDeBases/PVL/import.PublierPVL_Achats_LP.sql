USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [import].[PublierPVL_Achats_LP]    Script Date: 21.04.2015 9:54:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [import].[PublierPVL_Achats_LP] @FichierTS NVARCHAR(255)
AS

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 30/03/2015
-- Description:	Alimentation de la table dbo.AchatALActe
-- a partir des fichiers DailyOrderReport de VEL : PVL_Achats du Parisien
-- Modification date: 30/03/2015
-- Modifications : Recuperation des lignes invalides a cause de l'adresse e-mail
--					que l'on recupere 
-- =============================================

BEGIN
	SET NOCOUNT ON
	
	-- On suppose que la table PVL_CatalogueOffres est alimentee en annule/remplace
	
	DECLARE @SourceID INT
	
	SET @SourceID = 10 -- PVL
	
	IF OBJECT_ID('tempdb..#T_Achats') IS NOT NULL
	    DROP TABLE #T_Achats
	
	CREATE TABLE #T_Achats
	(
		ProfilID               INT NULL
	   ,ClientUserID           NVARCHAR(18) NULL
	   ,OriginalID             NVARCHAR(255) NULL -- Code produit d'origine
	   ,ProduitID              INT NULL -- Reference de produit dans le catalogue
	   ,SourceID               INT NULL
	   ,Marque                 INT NULL
	   ,NomProduit             NVARCHAR(255) NULL
	   ,AchatDate              DATETIME NULL
	   ,ExProdNb               INT NULL
	   ,Reduction              DECIMAL(10 ,2) NULL
	   ,MontantAchat           DECIMAL(10 ,2) NULL
	   ,OrderID                INT NULL
	   ,ProductDescription     NVARCHAR(255) NULL
	   ,MethodePaiement        NVARCHAR(24) NULL
	   ,CodePromo              NVARCHAR(24) NULL
	   ,Provenance             NVARCHAR(255) NULL
	   ,CommercialId           NVARCHAR(255) NULL
	   ,SalonId                NVARCHAR(255) NULL
	   ,ModePmtHorsLigne       NVARCHAR(255) NULL
	   ,iRecipientId           NVARCHAR(18) NULL
	   ,ImportID               INT NULL
	   ,EmailAddress           NVARCHAR(255) NULL
	)
	
	SET DATEFORMAT dmy
	
	INSERT #T_Achats
	  (
	    ProfilID
	   ,ClientUserID
	   ,OriginalID
	   ,ProduitID
	   ,SourceID
	   ,Marque
	   ,NomProduit
	   ,AchatDate
	   ,ExProdNb
	   ,Reduction
	   ,MontantAchat
	   ,OrderID
	   ,ProductDescription
	   ,MethodePaiement
	   ,CodePromo
	   ,Provenance
	   ,CommercialId
	   ,SalonId
	   ,ModePmtHorsLigne
	   ,ImportID
	  )
	SELECT NULL                           AS ProfilID
	      ,a.ClientUserId
	      ,a.ContentItemId
	      ,NULL                           AS ProduitID
	      ,@SourceID
	      ,NULL                           AS Marque
	      ,NULL                           AS NomProduit
	      ,CAST(a.OrderDate AS DATETIME)  AS AchatDate
	      ,1                              AS ExProdNb
	      ,0                              AS Reduction
	      ,a.GrossAmount                  AS MontantAchat
	      ,a.OrderID
	      ,a.Description
	      ,a.PaymentMethod
	      ,a.ActivationCode               AS CodePromo
	      ,a.Provenance
	      ,a.IdentifiantDuCommercial      AS CommercialId
	      ,a.IdentifiantDuSalon           AS SalonId
	      ,a.DetailModePaiementHorsLigne  AS ModePmtHorsLigne
	      ,a.ImportID
	FROM   import.PVL_Achats                 a
	WHERE  a.FichierTS = @FichierTS
	       AND a.LigneStatut = 0
	       AND a.ProductType <> N'Service'
	       AND a.OrderStatus = N'Completed'
	
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
	
	-- SPECIFIQUE AU PARISIEN
	-- On passe par import.PVL_Utilisateur, puisqu'il n'y a pas d'adresse e-mail dans import.PVL_Achats
	INSERT #T_Recup
	  (
	    RejetCode
	   ,ImportID
	   ,FichierTS
	  )
	SELECT a.RejetCode
	      ,a.ImportID
	      ,a.FichierTS
	FROM   import.PVL_Achats a
	       INNER JOIN etl.VEL_Accounts b
	            ON  a.ClientUserId = b.ClientUserId
	                AND b.Valid = 1
	       INNER JOIN ref.CatalogueProduits c
	            ON  a.ContentItemId = c.OriginalID
	                AND c.SourceID = 10
	                AND c.Appartenance = 2
	WHERE  a.RejetCode & POWER(CAST(2 AS BIGINT) ,3) = POWER(CAST(2 AS BIGINT) ,3)
	       AND a.ProductType <> N'Service'
	       AND a.OrderStatus = N'Completed'
	
	UPDATE a
	SET    RejetCode = a.RejetCode -POWER(CAST(2 AS BIGINT) ,3)
	FROM   #T_Recup a
	
	UPDATE a
	SET    RejetCode = b.RejetCode
	FROM   import.PVL_Achats a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	
	UPDATE a
	SET    LigneStatut = 0
	FROM   import.PVL_Achats a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	WHERE  b.RejetCode = 0
	
	UPDATE a
	SET    RejetCode = b.RejetCode
	FROM   rejet.PVL_Achats a
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
	FROM   rejet.PVL_Achats a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	
	INSERT #T_Achats
	  (
	    ProfilID
	   ,ClientUserID
	   ,OriginalID
	   ,ProduitID
	   ,SourceID
	   ,Marque
	   ,NomProduit
	   ,AchatDate
	   ,ExProdNb
	   ,Reduction
	   ,MontantAchat
	   ,OrderID
	   ,ProductDescription
	   ,MethodePaiement
	   ,CodePromo
	   ,Provenance
	   ,CommercialId
	   ,SalonId
	   ,ModePmtHorsLigne
	   ,ImportID
	  )
	SELECT NULL                           AS ProfilID
	      ,a.ClientUserId
	      ,a.ContentItemId
	      ,NULL                           AS ProduitID
	      ,@SourceID
	      ,NULL                           AS Marque
	      ,NULL                           AS NomProduit
	      ,CAST(a.OrderDate AS DATETIME)  AS AchatDate
	      ,1                              AS ExProdNb
	      ,0                              AS Reduction
	      ,a.GrossAmount                  AS MontantAchat
	      ,a.OrderID
	      ,a.Description
	      ,a.PaymentMethod
	      ,a.ActivationCode               AS CodePromo
	      ,a.Provenance
	      ,a.IdentifiantDuCommercial      AS CommercialId
	      ,a.IdentifiantDuSalon           AS SalonId
	      ,a.DetailModePaiementHorsLigne  AS ModePmtHorsLigne
	      ,a.ImportID
	FROM   import.PVL_Achats a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	WHERE  a.LigneStatut = 0
	       AND a.ProductType <> N'Service'
	       AND a.OrderStatus = N'Completed'
	
	UPDATE a
	SET    EmailAddress = b.EmailAddress
	FROM   #T_Achats a
	       INNER JOIN etl.VEL_Accounts b
	            ON  a.ClientUserId = b.ClientUserId
	                AND b.Valid = 1
	
	UPDATE a
	SET    ProduitID = b.ProduitID
	      ,Marque = b.Marque
	      ,NomProduit = b.NomProduit
	FROM   #T_Achats a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.OriginalID = b.OriginalID
	                AND b.SourceID = @SourceID
	
	-- SPECIFIQUE AU PARISIEN
	-- Trouver le ProfilID
	
	-- On retrouve le ProfilID dans brut.Contacts en passant par import.SSO_Cumul
	-- ainsi on retrouve la plupart des ProfilID
	
	UPDATE a
	SET    ProfilID = b.ProfilID
	FROM   #T_Achats a
	       INNER JOIN etl.VEL_Accounts b
	            ON  a.ClientUserId = b.ClientUserId
	                AND b.Valid = 1
	
	DELETE b
	FROM   #T_Achats a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	WHERE  a.ProfilID IS NULL
	
	DELETE a
	FROM   #T_Achats a
	WHERE  a.ProfilID IS NULL
	
	INSERT dbo.AchatsALActe
	  (
	    ProfilID
	   ,MasterID
	   ,ProduitID
	   ,SourceID
	   ,Marque
	   ,NomProduit
	   ,AchatDate
	   ,ExProdNb
	   ,Reduction
	   ,MontantAchat
	   ,OrderID
	   ,ClientUserId
	   ,ProductDescription
	   ,MethodePaiement
	   ,CodePromo
	   ,Provenance
	   ,CommercialId
	   ,SalonId
	   ,ModePmtHorsLigne
	   ,StatutAchat
	   ,Appartenance
	  )
	SELECT a.ProfilID
	      ,a.ProfilID         AS MasterID
	      ,a.ProduitID
	      ,a.SourceID
	      ,a.Marque
	      ,a.NomProduit
	      ,a.AchatDate
	      ,a.ExProdNb
	      ,a.Reduction
	      ,a.MontantAchat
	      ,a.OrderID
	      ,a.ClientUserID
	      ,a.ProductDescription
	      ,a.MethodePaiement
	      ,a.CodePromo
	      ,a.Provenance
	      ,a.CommercialId
	      ,a.SalonId
	      ,a.ModePmtHorsLigne
	      ,1                  AS StatutAchat -- Completed
	      ,c.Appartenance
	FROM   #T_Achats a
	       INNER JOIN ref.Misc c
	            ON  a.Marque = c.CodeValN
	                AND c.TypeRef = N'MARQUE'
	       LEFT OUTER JOIN dbo.AchatsALActe b
	            ON  a.ProfilID = b.ProfilID
	                AND a.ProduitID = b.ProduitID
	                AND a.AchatDate = b.AchatDate
	WHERE  a.ProfilID IS NOT NULL
	       AND b.ProfilID IS     NULL
	
	UPDATE a
	SET    LigneStatut = 99
	FROM   import.PVL_Achats a
	       INNER JOIN #T_Achats b
	            ON  a.ImportID = b.ImportID
	WHERE  a.FichierTS = @FichierTS
	       AND a.LigneStatut = 0
	       AND a.ProductType <> N'Service'
	       AND a.OrderStatus = N'Completed'
	
	UPDATE a
	SET    LigneStatut = 99
	FROM   import.PVL_Achats a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	WHERE  a.LigneStatut = 0
	       AND a.ProductType <> N'Service'
	       AND a.OrderStatus = N'Completed'
	
	
	IF OBJECT_ID('tempdb..#T_Achats') IS NOT NULL
	    DROP TABLE #T_Achats
	
	IF OBJECT_ID(N'tempdb..#T_Recup') IS NOT NULL
	    DROP TABLE #T_Recup
	
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
	    --set @S=N'EXECUTE [QTSDQF].[dbo].[RejetsStats] ''95940C81-C7A7-4BD9-A523-445A343A9605'', ''PVL_Achats'', N'''+@FTS+N''' ; '
	    
	    --IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_Achats'))
	    --	execute (@S) 
	    
	    FETCH c_fts INTO @FTS
	END
	
	CLOSE c_fts
	DEALLOCATE c_fts
	
	
	/********** AUTOCALCULATE REJECTSTATS **********/
	--IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_Achats'))
	--	EXECUTE [QTSDQF].[dbo].[RejetsStats] '95940C81-C7A7-4BD9-A523-445A343A9605', 'PVL_Achats', @FichierTS
END
