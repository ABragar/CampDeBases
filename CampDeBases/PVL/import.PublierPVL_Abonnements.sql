/************************************************************
 * Code formatted by SoftTree SQL Assistant © v7.1.246
 * Time: 23.04.2015 13:28:41
 ************************************************************/

USE [AmauryVUC]

GO
/****** Object:  StoredProcedure [import].[PublierPVL_Abonnements]    Script Date: 22.04.2015 17:42:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [import].[PublierPVL_Abonnements] @FichierTS NVARCHAR(255)
AS

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 29/10/2014
-- Description:	Alimentation de la table dbo.Abonnements
-- a partir des fichiers DailyOrderReport de VEL : PVL_Abonnements
-- Modification date: 15/12/2014
-- Modifications : Recuperation des lignes invalides a cause de ClientUserID
-- Modification date: 22/04/2015
-- Modifications : Ancien mode en attendant OrderID dans les Subscriptions
-- Modified by :	Andrei BRAGAR
-- Modification date: 22/04/2015
-- Modifications : Union with EQ, FF
-- =============================================

BEGIN
	SET NOCOUNT ON
	
	-- On suppose que la table PVL_CatalogueOffres est alimentee en annule/remplace
	
	DECLARE @SourceID INT
	DECLARE @SourceID_Contact INT
	SET @SourceID = 10 -- PVL
	SET @SourceID_Contact = 1 -- Neolane, car on ne cree pas de contacts PVL specifiques : on transcode vers Neolane
	
	
	DECLARE @FilePrefix NVARCHAR(5) = NULL
	DECLARE @CusCompteTableName NVARCHAR(30)
	DECLARE @sqlCommand NVARCHAR(500)
	
	IF @FichierTS LIKE N'FF%'
	BEGIN
	    SET @CusCompteTableName = N'import.NEO_CusCompteFF'
	    SET @FilePrefix = N'FF%'
	END
	
	IF @FichierTS LIKE N'EQP%'
	BEGIN
	    SET @CusCompteTableName = N'import.NEO_CusCompteEFR'		
	    SET @FilePrefix = N'EQP%'
	END
	
	IF @FichierTS LIKE N'LP%'
	BEGIN
	    SET @FilePrefix = N'LP%'
	END
	
	IF @FilePrefix IS NULL
	    RAISERROR('File prefix does not match any of the possible' ,16 ,1);
	
	IF OBJECT_ID('tempdb..#CusCompteTmp') IS NOT NULL
	    DROP TABLE #CusCompteTmp
	
	CREATE TABLE #CusCompteTmp
	(
		sIdCompte        NVARCHAR(255)
	   ,iRecipientId     NVARCHAR(18)
	   ,ActionID         INT
	   ,ImportID         INT
	   ,LigneStatut      INT
	   ,FichierTS        NVARCHAR(255)
	)	
	
	SET @sqlCommand = 
	    N'INSERT #CusCompteTmp SELECT cc.sIdCompte ,cc.iRecipientId ,CAST(cc.ActionID AS INT) as ActionID ,cc.ImportID ,cc.LigneStatut ,cc.FichierTS FROM '
	    + @CusCompteTableName + ' AS cc where cc.LigneStatut<>1'	          
	
	EXEC (@sqlCommand)
	
	-- Alimentation de dbo.Abonnements
	
	IF OBJECT_ID('tempdb..#T_Abos') IS NOT NULL
	    DROP TABLE #T_Abos
	
	CREATE TABLE #T_Abos
	(
		ProfilID                 INT NULL
	   ,SourceID                 INT NULL
	   ,Marque                   INT NULL
	   ,ClientUserID             NVARCHAR(18) NULL
	   ,iRecipientID             NVARCHAR(18) NULL
	   ,OriginalID               NVARCHAR(255) NULL -- Code produit d'origine
	   ,CatalogueAbosID          INT NULL -- Reference de produit dans le catalogue
	   ,NomAbo                   NVARCHAR(255) NULL -- Libelle du catalogue
	   ,OrderDate                DATETIME NULL
	   ,ServiceID                NVARCHAR(18) NULL
	   ,SouscriptionAboDate      DATETIME NULL
	   ,DebutAboDate             DATETIME NULL
	   ,FinAboDate               DATETIME NULL
	   ,ExAboSouscrNb            INT NOT NULL DEFAULT(0)
	   ,RemiseAbo                DECIMAL(10 ,2) NULL
	   ,MontantAbo               DECIMAL(10 ,2) NULL
	   ,Devise                   NVARCHAR(16) NULL
	   ,Recurrent                BIT NULL
	   ,SubscriptionStatus       NVARCHAR(255) NULL
	   ,SubscriptionStatusID     INT NULL
	   ,ServiceGroup             NVARCHAR(255) NULL
	   ,IsTrial                  BIT NULL
	    -- les champs suivants seront alimentes a partir de la table Orders
	   ,OrderID                  NVARCHAR(16) NULL
	   ,ProductDescription       NVARCHAR(255) NULL
	   ,MethodePaiement          NVARCHAR(24) NULL
	   ,CodePromo                NVARCHAR(24) NULL
	   ,Provenance               NVARCHAR(255) NULL
	   ,CommercialId             NVARCHAR(255) NULL
	   ,SalonId                  NVARCHAR(255) NULL
	   ,ModePmtHorsLigne         NVARCHAR(255) NULL
	   ,ImportID                 INT NULL
	   ,Reprise                  BIT NOT NULL DEFAULT(0)
	)
	
	SET DATEFORMAT dmy
	
	INSERT #T_Abos
	  (
	    ProfilID
	   ,SourceID
	   ,Marque
	   ,ClientUserID
	   ,OriginalID
	   ,CatalogueAbosID
	   ,NomAbo
	   ,OrderDate
	   ,ServiceID
	   ,SouscriptionAboDate
	   ,DebutAboDate
	   ,FinAboDate
	   ,ExAboSouscrNb
	   ,RemiseAbo
	   ,MontantAbo
	   ,Devise
	   ,Recurrent
	   ,SubscriptionStatus
	   ,SubscriptionStatusID
	   ,ServiceGroup
	   ,IsTrial
	   ,ImportID
	  )
	SELECT NULL                    AS ProfilID
	      ,@SourceID
	      ,NULL                    AS Marque
	      ,a.ClientUserID
	      ,a.ServiceId             AS OriginalID
	      ,NULL                    AS CatalogueAbosID
	      ,NULL                    AS NomAbo
	      ,CAST(a.SubscriptionLastUpdated AS DATETIME) AS OrderDate
	      ,a.ServiceID
	      ,CAST(a.SubscriptionCreated AS DATETIME) AS SouscriptionAboDate
	      ,CAST(a.SubscriptionLastUpdated AS DATETIME) AS DebutAboDate
	      ,a.ServiceExpiry         AS FinAboDate
	      ,1                       AS ExAboSouscrNb
	      ,0                       AS RemiseAbo
	      ,a.ExplicitPrice         AS MontantAbo
	      ,a.ExplicitCurrency      AS Devise
	      ,NULL                    AS Recurrent
	      ,a.SubscriptionStatus
	      ,CAST(a.SubscriptionStatusID AS INT) AS SubscriptionStatusID
	      ,a.ServiceGroup
	      ,CASE 
	            WHEN a.IsTrial = N'True' THEN 1
	            ELSE 0
	       END
	      ,a.ImportID
	FROM   import.PVL_Abonnements     a
	WHERE  a.FichierTS = @FichierTS
	       AND a.LigneStatut = 0
	       AND a.SubscriptionStatusID = N'2' -- Active Subscription
	
	-- Recuperer les lignes rejetees a cause de ClientUserId absent de CusCompteEFR
	-- mais dont le sIdCompte est arrive depuis dans CusCompteEFR
	
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
	    SELECT RejetCode
	          ,ImportID
	          ,FichierTS
	    FROM   import.PVL_Abonnements a
	           INNER JOIN etl.VEL_Accounts b
	                ON  a.ClientUserId = b.ClientUserId
	                    AND b.Valid = 1
	           INNER JOIN ref.CatalogueAbonnements c
	                ON  a.ServiceID = c.OriginalID
	                    AND c.SourceID = 10
	                    AND c.Appartenance = 2
	    WHERE  a.RejetCode & POWER(CAST(2 AS BIGINT) ,14) = POWER(CAST(2 AS BIGINT) ,14)
	           AND a.SubscriptionStatusID = N'2' -- Active Subscription
	END
	ELSE
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
	    FROM   import.PVL_Abonnements a
	           INNER JOIN #CusCompteTmp b
	                ON  a.ClientUserId = b.sIdCompte
	    WHERE  a.RejetCode & POWER(CAST(2 AS BIGINT) ,14) = POWER(CAST(2 AS BIGINT) ,14)
	END
	
	UPDATE a
	SET    RejetCode = a.RejetCode -POWER(CAST(2 AS BIGINT) ,14)
	FROM   #T_Recup a
	
	UPDATE a
	SET    RejetCode = b.RejetCode
	FROM   import.PVL_Abonnements a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	
	IF @FilePrefix = N'LP%'
	BEGIN
	    UPDATE a
	    SET    RejetCode = b.RejetCode
	    FROM   rejet.PVL_Abonnements a
	           INNER JOIN #T_Recup b
	                ON  a.ImportID = b.ImportID
	END	
	
	UPDATE a
	SET    LigneStatut = 0
	FROM   import.PVL_Abonnements a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	WHERE  b.RejetCode = 0
	
	UPDATE a
	SET    RejetCode = b.RejetCode
	FROM   rejet.PVL_Abonnements a
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
	FROM   rejet.PVL_Abonnements a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	
	INSERT #T_Abos
	  (
	    ProfilID
	   ,SourceID
	   ,Marque
	   ,ClientUserID
	   ,OriginalID
	   ,CatalogueAbosID
	   ,NomAbo
	   ,OrderDate
	   ,ServiceID
	   ,SouscriptionAboDate
	   ,DebutAboDate
	   ,FinAboDate
	   ,ExAboSouscrNb
	   ,RemiseAbo
	   ,MontantAbo
	   ,Devise
	   ,Recurrent
	   ,SubscriptionStatus
	   ,SubscriptionStatusID
	   ,ServiceGroup
	   ,IsTrial
	   ,ImportID
	  )
	SELECT NULL                AS ProfilID
	      ,@SourceID
	      ,NULL                AS Marque
	      ,a.ClientUserID
	      ,a.ServiceId         AS OriginalID
	      ,NULL                AS CatalogueAbosID
	      ,NULL                AS NomAbo
	      ,CAST(a.SubscriptionLastUpdated AS DATETIME) AS OrderDate
	      ,a.ServiceID
	      ,CAST(a.SubscriptionCreated AS DATETIME) AS SouscriptionAboDate
	      ,CAST(a.SubscriptionLastUpdated AS DATETIME) AS DebutAboDate
	      ,a.ServiceExpiry     AS FinAboDate
	      ,1                   AS ExAboSouscrNb
	      ,0                   AS RemiseAbo
	      ,a.ExplicitPrice     AS MontantAbo
	      ,a.ExplicitCurrency  AS Devise
	      ,NULL                AS Recurrent
	      ,a.SubscriptionStatus
	      ,CAST(a.SubscriptionStatusID AS INT) AS SubscriptionStatusID
	      ,a.ServiceGroup
	      ,CASE 
	            WHEN a.IsTrial = N'True' THEN 1
	            ELSE 0
	       END
	      ,a.ImportID
	FROM   import.PVL_Abonnements a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	WHERE  a.LigneStatut = 0
	       AND a.SubscriptionStatusID = N'2' -- Active Subscription
	
	
	UPDATE a
	SET    OrderID = b.OrderID
	FROM   #T_Abos a
	       INNER JOIN import.PVL_Achats b
	            ON  a.ServiceId = b.ServiceID
	                AND a.ClientUserID = b.ClientUserId
	                AND a.OrderDate BETWEEN DATEADD(minute ,-10 ,CAST(b.OrderDate AS DATETIME)) 
	                    AND DATEADD(minute ,10 ,CAST(b.OrderDate AS DATETIME))
	WHERE  b.LigneStatut <> 1
	       AND b.ProductType = N'Service'
	       AND b.OrderStatus <> N'Refunded'
	
	
	-- On ne prend pas de lignes qui n'ont pas de correspondance dans Orders, i.e. qui n'ont pas d'OrderID
	
	DELETE a
	FROM   #T_Abos a
	WHERE  a.OrderID IS NULL
	
	UPDATE a
	SET    ProductDescription = b.Description
	      ,MontantAbo = CAST(b.GrossAmount AS FLOAT)
	      ,MethodePaiement = b.PaymentMethod
	      ,CodePromo = b.ActivationCode
	      ,Provenance = b.Provenance
	      ,CommercialId = b.IdentifiantDuCommercial
	      ,SalonId = b.IdentifiantDuSalon
	      ,ModePmtHorsLigne = b.DetailModePaiementHorsLigne
	FROM   #T_Abos a
	       INNER JOIN import.PVL_Achats b
	            ON  a.OrderID = b.OrderID
	
	IF @FilePrefix = N'LP%'
	   -- Trouver le ProfilID
	   
	   -- SPECIFIQUE AU PARISIEN
	   
	   -- On retrouve le ProfilID dans brut.Contacts en passant par import.SSO_Cumul
	   -- ainsi on retrouve la plupart des ProfilID
	   -- Ensuite, par brut.Emails, dans l'ordre : LP SSO et Prospects, SDVP, Neolane
	BEGIN
	    UPDATE a
	    SET    ProfilID = b.ProfilID
	    FROM   #T_Abos a
	           INNER JOIN etl.VEL_Accounts b
	                ON  a.ClientUserID = b.ClientUserId
	END
	ELSE
	BEGIN
	    UPDATE a
	    SET    iRecipientId = r1.iRecipientId
	    FROM   #T_Abos a
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
	    FROM   #T_Abos a
	           INNER JOIN brut.Contacts b
	                ON  a.iRecipientID = b.OriginalID
	                    AND b.SourceID = @SourceID_Contact
	    
	    DELETE b
	    FROM   #T_Abos a
	           INNER JOIN #T_Recup b
	                ON  a.ImportID = b.ImportID
	    WHERE  a.ProfilID IS NULL
	END
	DELETE #T_Abos
	WHERE  ProfilID IS NULL
	
	UPDATE a
	SET    CatalogueAbosID = b.CatalogueAbosID
	      ,NomAbo = b.OffreAbo
	      ,Marque = b.Marque
	      ,Recurrent = b.Recurrent
	FROM   #T_Abos a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.OriginalID = b.OriginalID
	                AND a.SourceID = b.SourceID
	
	DELETE b
	FROM   #T_Abos a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	WHERE  a.CatalogueAbosID IS NULL
	
	DELETE #T_Abos
	WHERE  CatalogueAbosID IS NULL
	
	-- ici, les abonnements doivent se cumuler, plusieurs lignes du meme client et meme titre en une ligne.

	INSERT brut.Contrats_Abos
	  (
	    ProfilID
	   ,SourceID
	   ,CatalogueAbosID
	   ,SouscriptionAboDate
	   ,DebutAboDate
	   ,FinAboDate
	   ,MontantAbo
	   ,ExAboSouscrNb
	   ,Devise
	   ,Recurrent
	   ,ClientUserId
	   ,ServiceGroup
	   ,IsTrial
	   ,OrderID
	   ,ProductDescription
	   ,MethodePaiement
	   ,CodePromo
	   ,Provenance
	   ,CommercialId
	   ,SalonId
	   ,ModePmtHorsLigne
	   ,SubscriptionStatusID
	  )
	SELECT ProfilID
	      ,SourceID
	      ,CatalogueAbosID
	      ,SouscriptionAboDate
	      ,DebutAboDate
	      ,FinAboDate
	      ,MontantAbo
	      ,ExAboSouscrNb
	      ,Devise
	      ,Recurrent
	      ,ClientUserId
	      ,ServiceGroup
	      ,IsTrial
	      ,OrderID
	      ,ProductDescription
	      ,MethodePaiement
	      ,CodePromo
	      ,Provenance
	      ,CommercialId
	      ,SalonId
	      ,ModePmtHorsLigne
	      ,SubscriptionStatusID
	FROM   #T_Abos
	
	
	IF OBJECT_ID('tempdb..#T_Brut_Abos') IS NOT NULL
	    DROP TABLE #T_Brut_Abos
	
	CREATE TABLE #T_Brut_Abos
	(
		ContratID                INT NOT NULL
	   ,MasterAboID              INT NULL -- = AbonnementID de abo.Abonnements
	   ,ProfilID                 INT NOT NULL
	   ,SourceID                 INT NULL
	   ,CatalogueAbosID          INT NULL
	   ,SouscriptionAboDate      DATETIME NULL
	   ,DebutAboDate             DATETIME NULL
	   ,FinAboDate               DATETIME NULL
	   ,MontantAbo               DECIMAL(10 ,2)
	   ,ExAboSouscrNb            INT NULL
	   ,Devise                   NVARCHAR(16) NULL
	   ,Recurrent                BIT NULL
	   ,ContratID_Regroup        INT NULL
	   ,ClientUserId             NVARCHAR(18) NULL
	   ,ServiceGroup             NVARCHAR(255) NULL
	   ,IsTrial                  BIT NULL
	   ,OrderID                  NVARCHAR(16) NULL
	   ,ProductDescription       NVARCHAR(255) NULL
	   ,MethodePaiement          NVARCHAR(24) NULL
	   ,CodePromo                NVARCHAR(24) NULL
	   ,Provenance               NVARCHAR(255) NULL
	   ,CommercialId             NVARCHAR(255) NULL
	   ,SalonId                  NVARCHAR(255) NULL
	   ,ModePmtHorsLigne         NVARCHAR(255) NULL
	   ,SubscriptionStatusID     INT NULL
	)
	
	INSERT #T_Brut_Abos
	  (
	    ContratID
	   ,MasterAboID
	   ,ProfilID
	   ,SourceID
	   ,CatalogueAbosID
	   ,SouscriptionAboDate
	   ,DebutAboDate
	   ,FinAboDate
	   ,MontantAbo
	   ,ExAboSouscrNb
	   ,Devise
	   ,Recurrent
	   ,ClientUserId
	   ,ServiceGroup
	   ,IsTrial
	   ,OrderID
	   ,ProductDescription
	   ,MethodePaiement
	   ,CodePromo
	   ,Provenance
	   ,CommercialId
	   ,SalonId
	   ,ModePmtHorsLigne
	   ,SubscriptionStatusID
	  )
	SELECT a.ContratID
	      ,a.MasterAboID
	      ,a.ProfilID
	      ,a.SourceID
	      ,a.CatalogueAbosID
	      ,a.SouscriptionAboDate
	      ,a.DebutAboDate
	      ,a.FinAboDate
	      ,a.MontantAbo
	      ,a.ExAboSouscrNb
	      ,a.Devise
	      ,a.Recurrent
	      ,a.ClientUserId
	      ,a.ServiceGroup
	      ,a.IsTrial
	      ,OrderID
	      ,ProductDescription
	      ,MethodePaiement
	      ,CodePromo
	      ,Provenance
	      ,CommercialId
	      ,SalonId
	      ,ModePmtHorsLigne
	      ,SubscriptionStatusID
	FROM   brut.Contrats_Abos a
	WHERE  a.ModifieTop = 1 -- Les lignes qui viennent d'etre inserees
	       AND a.SourceID = @SourceID -- PVL
	       AND a.Recurrent = 1
	
	CREATE INDEX ind_01_T_Brut_Abos ON #T_Brut_Abos(ProfilID ,CatalogueAbosID)
	
	INSERT #T_Brut_Abos
	  (
	    ContratID
	   ,MasterAboID
	   ,ProfilID
	   ,SourceID
	   ,CatalogueAbosID
	   ,SouscriptionAboDate
	   ,DebutAboDate
	   ,FinAboDate
	   ,MontantAbo
	   ,ExAboSouscrNb
	   ,Devise
	   ,Recurrent
	   ,ClientUserId
	   ,ServiceGroup
	   ,IsTrial
	   ,OrderID
	   ,ProductDescription
	   ,MethodePaiement
	   ,CodePromo
	   ,Provenance
	   ,CommercialId
	   ,SalonId
	   ,ModePmtHorsLigne
	   ,SubscriptionStatusID
	  )
	SELECT a.ContratID
	      ,a.MasterAboID
	      ,a.ProfilID
	      ,a.SourceID
	      ,a.CatalogueAbosID
	      ,a.SouscriptionAboDate
	      ,a.DebutAboDate
	      ,a.FinAboDate
	      ,a.MontantAbo
	      ,a.ExAboSouscrNb
	      ,a.Devise
	      ,a.Recurrent
	      ,a.ClientUserId
	      ,a.ServiceGroup
	      ,a.IsTrial
	      ,a.OrderID
	      ,a.ProductDescription
	      ,a.MethodePaiement
	      ,a.CodePromo
	      ,a.Provenance
	      ,a.CommercialId
	      ,a.SalonId
	      ,a.ModePmtHorsLigne
	      ,a.SubscriptionStatusID
	FROM   brut.Contrats_Abos a
	       INNER JOIN #T_Brut_Abos b
	            ON  a.ProfilID = b.ProfilID
	                AND a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.ModifieTop = 0 -- Les lignes anciennes du meme profil, abonnements recurrents
	       AND a.SourceID = @SourceID -- PVL
	       AND a.Recurrent = 1
	
	CREATE TABLE #T_Abo_Fusion
	(
		N1                    INT NULL
	   ,ContratID             INT NULL
	   ,ProfilID              INT NULL
	   ,CatalogueAbosID       INT NULL
	   ,DebutAboDate          DATETIME NULL
	   ,FinAboDate            DATETIME NULL
	   ,DatePrevFin           DATETIME NULL
	   ,Ddiff                 INT NULL
	   ,ContratID_Regroup     INT NULL
	)
	
	INSERT #T_Abo_Fusion
	  (
	    N1
	   ,ContratID
	   ,ProfilID
	   ,CatalogueAbosID
	   ,DebutAboDate
	   ,FinAboDate
	  )
	SELECT RANK() OVER(
	           PARTITION BY ProfilID
	          ,CatalogueAbosID ORDER BY SouscriptionAboDate ASC
	          ,DebutAboDate ASC
	          ,NEWID()
	       ) AS N1
	      ,ContratID
	      ,ProfilID
	      ,CatalogueAbosID
	      ,DebutAboDate
	      ,FinAboDate
	FROM   #T_Brut_Abos
	
	UPDATE a
	SET    DatePrevFin = b.FinAboDate
	FROM   #T_Abo_Fusion a
	       LEFT OUTER JOIN #T_Abo_Fusion b
	            ON  a.ProfilID = b.ProfilID
	                AND a.CatalogueAbosID = b.CatalogueAbosID
	                AND b.N1 = a.N1 -1
	
	UPDATE #T_Abo_Fusion
	SET    ContratID_Regroup = ContratID
	WHERE  DatePrevFin IS NULL
	       AND ContratID_Regroup IS NULL 
	
	UPDATE #T_Abo_Fusion
	SET    Ddiff = DATEDIFF(DAY ,DatePrevFin ,DebutAboDate)
	WHERE  DatePrevFin IS NOT NULL
	
	UPDATE #T_Abo_Fusion
	SET    ContratID_Regroup = ContratID
	WHERE  Ddiff > 181
	       AND ContratID_Regroup IS NULL
	
	DECLARE @R AS INT
	
	SELECT @R = 1
	
	WHILE (@R > 0)
	BEGIN
	    UPDATE a
	    SET    ContratID_Regroup = b.ContratID_Regroup
	    FROM   #T_Abo_Fusion a
	           INNER JOIN #T_Abo_Fusion b
	                ON  a.ProfilID = b.ProfilID
	                    AND a.CatalogueAbosID = b.CatalogueAbosID
	                    AND b.N1 = a.N1 -1
	    WHERE  a.ContratID_Regroup IS NULL
	           AND a.DDiff <= 181 -- Intervalle ne doit pas etre superieur a 6 mois pour qu'on considere l'abonnement non interrompu
	           AND b.ContratID_Regroup IS NOT NULL
	    
	    SELECT @R = @@ROWCOUNT
	END
	
	UPDATE a
	SET    ContratID_Regroup = b.ContratID_Regroup
	FROM   #T_Brut_Abos a
	       INNER JOIN #T_Abo_Fusion b
	            ON  a.ContratID = b.ContratID
	
	IF OBJECT_ID('tempdb..#T_Abos_MinMax') IS NOT NULL
	    DROP TABLE #T_Abos_MinMax
	
	CREATE TABLE #T_Abos_MinMax
	(
		ProfilID              INT NULL
	   ,CatalogueAbosID       INT NULL
	   ,ContratID_Regroup     INT NULL
	   ,ContratID_Min         INT NULL
	   ,DebutAboDate_Min      DATETIME NULL
	   ,DebutAboDate_Max      DATETIME NULL
	   ,MontantAbo_Sum        DECIMAL(10 ,2) NULL
	)
	
	INSERT #T_Abos_MinMax
	  (
	    ProfilID
	   ,CatalogueAbosID
	   ,ContratID_Regroup
	   ,ContratID_Min
	   ,DebutAboDate_Min
	   ,DebutAboDate_Max
	   ,MontantAbo_Sum
	  )
	SELECT a.ProfilID
	      ,a.CatalogueAbosID
	      ,ContratID_Regroup
	      ,MIN(a.ContratID)     AS ContratID_Min
	      ,MIN(a.DebutAboDate)  AS DebutAboDate_Min
	      ,MAX(a.DebutAboDate)  AS DebutAboDate_Max
	      ,SUM(a.MontantAbo)    AS MontantAbo_Sum
	FROM   #T_Brut_Abos            a
	GROUP BY
	       a.ProfilID
	      ,a.CatalogueAbosID
	      ,a.ContratID_Regroup
	
	CREATE INDEX ind_01_T_Abos_MinMax ON #T_Abos_MinMax(ProfilID ,CatalogueAbosID)
	
	
	UPDATE a
	SET    MasterAboID = b.ContratID_Min
	FROM   #T_Brut_Abos a
	       INNER JOIN #T_Abos_MinMax b
	            ON  a.ContratID_Regroup = b.ContratID_Regroup
	                AND a.ProfilID = b.ProfilID
	                AND a.CatalogueAbosID = b.CatalogueAbosID
	
	IF OBJECT_ID('tempdb..#T_Abos_Agreg') IS NOT NULL
	    DROP TABLE #T_Abos_Agreg
	
	CREATE TABLE #T_Abos_Agreg
	(
		MasterAboID              INT NULL -- = AbonnementID de abo.Abonnements
	   ,ProfilID                 INT NOT NULL
	   ,MasterID                 INT NULL
	   ,SourceID                 INT NULL
	   ,Marque                   INT NULL
	   ,CatalogueAbosID          INT NULL
	   ,SouscriptionAboDate      DATETIME NULL
	   ,DebutAboDate             DATETIME NULL
	   ,FinAboDate               DATETIME NULL
	   ,MontantAbo               DECIMAL(10 ,2)
	   ,ExAboSouscrNb            INT NULL
	   ,Devise                   NVARCHAR(16) NULL
	   ,Recurrent                BIT NULL
	   ,ContratID_Regroup        INT NULL
	   ,ClientUserId             NVARCHAR(18) NULL
	   ,ServiceGroup             NVARCHAR(255) NULL
	   ,IsTrial                  BIT NULL
	   ,OrderID                  NVARCHAR(16) NULL
	   ,ProductDescription       NVARCHAR(255) NULL
	   ,MethodePaiement          NVARCHAR(24) NULL
	   ,CodePromo                NVARCHAR(24) NULL
	   ,Provenance               NVARCHAR(255) NULL
	   ,CommercialId             NVARCHAR(255) NULL
	   ,SalonId                  NVARCHAR(255) NULL
	   ,ModePmtHorsLigne         NVARCHAR(255) NULL
	   ,SubscriptionStatusID     INT NULL
	)
	
	INSERT #T_Abos_Agreg
	  (
	    MasterAboID
	   ,ProfilID
	   ,SourceID
	   ,CatalogueAbosID
	   ,SouscriptionAboDate
	   ,DebutAboDate
	   ,FinAboDate
	   ,MontantAbo
	   ,ExAboSouscrNb
	   ,Devise
	   ,Recurrent
	   ,ContratID_Regroup
	   ,ClientUserId
	   ,ServiceGroup
	   ,IsTrial
	   ,OrderID
	   ,ProductDescription
	   ,MethodePaiement
	   ,CodePromo
	   ,Provenance
	   ,CommercialId
	   ,SalonId
	   ,ModePmtHorsLigne
	   ,SubscriptionStatusID
	  )
	SELECT DISTINCT
	       b.ContratID_Min AS MasterAboID
	      ,a.ProfilID
	      ,a.SourceID
	      ,a.CatalogueAbosID
	      ,a.SouscriptionAboDate
	      ,a.DebutAboDate
	      ,a.FinAboDate
	      ,b.MontantAbo_Sum
	      ,a.ExAboSouscrNb
	      ,a.Devise
	      ,a.Recurrent
	      ,a.ContratID_Regroup
	      ,a.ClientUserId
	      ,a.ServiceGroup
	      ,a.IsTrial
	      ,a.OrderID
	      ,a.ProductDescription
	      ,a.MethodePaiement
	      ,a.CodePromo
	      ,a.Provenance
	      ,a.CommercialId
	      ,a.SalonId
	      ,a.ModePmtHorsLigne
	      ,a.SubscriptionStatusID
	FROM   #T_Brut_Abos a
	       INNER JOIN #T_Abos_MinMax b
	            ON  a.ProfilID = b.ProfilID
	                AND a.CatalogueAbosID = b.CatalogueAbosID
	                AND a.DebutAboDate = b.DebutAboDate_Max
	                AND a.ContratID_Regroup = b.ContratID_Regroup
	
	-- Mettre a jour les informations avec la derniere valeur renseignee et non celle de la derniere ligne dans le temps
	
	-- le valeurs sont : SubscriptionStatusID
	
	-- ProductDescription
	-- MethodePaiement
	-- CodePromo
	-- Provenance
	-- CommercialId
	-- SalonId
	-- ModePmtHorsLigne
	
	UPDATE a
	SET    ProductDescription = b.ProductDescription
	FROM   #T_Abos_Agreg a
	       INNER JOIN (
	                SELECT a.ProfilID
	                      ,a.CatalogueAbosID
	                      ,a.ContratID_Regroup
	                      ,a.ProductDescription
	                      ,RANK() OVER(
	                           PARTITION BY a.ProfilID
	                          ,a.CatalogueAbosID
	                          ,a.ContratID_Regroup ORDER BY a.DebutAboDate DESC
	                       )             AS N1
	                FROM   #T_Brut_Abos     a
	                WHERE  a.ProductDescription IS NOT NULL
	            ) AS b
	            ON  a.ProfilID = b.ProfilID
	                AND a.CatalogueAbosID = b.CatalogueAbosID
	                AND a.MasterAboID = b.ContratID_Regroup
	WHERE  b.N1 = 1
	
	UPDATE a
	SET    MethodePaiement = b.MethodePaiement
	FROM   #T_Abos_Agreg a
	       INNER JOIN (
	                SELECT a.ProfilID
	                      ,a.CatalogueAbosID
	                      ,a.ContratID_Regroup
	                      ,a.MethodePaiement
	                      ,RANK() OVER(
	                           PARTITION BY a.ProfilID
	                          ,a.CatalogueAbosID
	                          ,a.ContratID_Regroup ORDER BY a.DebutAboDate DESC
	                       )             AS N1
	                FROM   #T_Brut_Abos     a
	                WHERE  a.MethodePaiement IS NOT NULL
	            ) AS b
	            ON  a.ProfilID = b.ProfilID
	                AND a.CatalogueAbosID = b.CatalogueAbosID
	                AND a.MasterAboID = b.ContratID_Regroup
	WHERE  b.N1 = 1
	
	UPDATE a
	SET    CodePromo = b.CodePromo
	FROM   #T_Abos_Agreg a
	       INNER JOIN (
	                SELECT a.ProfilID
	                      ,a.CatalogueAbosID
	                      ,a.ContratID_Regroup
	                      ,a.CodePromo
	                      ,RANK() OVER(
	                           PARTITION BY a.ProfilID
	                          ,a.CatalogueAbosID
	                          ,a.ContratID_Regroup ORDER BY a.DebutAboDate DESC
	                       )             AS N1
	                FROM   #T_Brut_Abos     a
	                WHERE  a.CodePromo IS NOT NULL
	            ) AS b
	            ON  a.ProfilID = b.ProfilID
	                AND a.CatalogueAbosID = b.CatalogueAbosID
	                AND a.MasterAboID = b.ContratID_Regroup
	WHERE  b.N1 = 1
	
	UPDATE a
	SET    Provenance = b.Provenance
	FROM   #T_Abos_Agreg a
	       INNER JOIN (
	                SELECT a.ProfilID
	                      ,a.CatalogueAbosID
	                      ,a.ContratID_Regroup
	                      ,a.Provenance
	                      ,RANK() OVER(
	                           PARTITION BY a.ProfilID
	                          ,a.CatalogueAbosID
	                          ,a.ContratID_Regroup ORDER BY a.DebutAboDate DESC
	                       )             AS N1
	                FROM   #T_Brut_Abos     a
	                WHERE  a.Provenance IS NOT NULL
	            ) AS b
	            ON  a.ProfilID = b.ProfilID
	                AND a.CatalogueAbosID = b.CatalogueAbosID
	                AND a.MasterAboID = b.ContratID_Regroup
	WHERE  b.N1 = 1
	
	UPDATE a
	SET    CommercialId = b.CommercialId
	FROM   #T_Abos_Agreg a
	       INNER JOIN (
	                SELECT a.ProfilID
	                      ,a.CatalogueAbosID
	                      ,a.ContratID_Regroup
	                      ,a.CommercialId
	                      ,RANK() OVER(
	                           PARTITION BY a.ProfilID
	                          ,a.CatalogueAbosID
	                          ,a.ContratID_Regroup ORDER BY a.DebutAboDate DESC
	                       )             AS N1
	                FROM   #T_Brut_Abos     a
	                WHERE  a.CommercialId IS NOT NULL
	            ) AS b
	            ON  a.ProfilID = b.ProfilID
	                AND a.CatalogueAbosID = b.CatalogueAbosID
	                AND a.MasterAboID = b.ContratID_Regroup
	WHERE  b.N1 = 1
	
	UPDATE a
	SET    SalonId = b.SalonId
	FROM   #T_Abos_Agreg a
	       INNER JOIN (
	                SELECT a.ProfilID
	                      ,a.CatalogueAbosID
	                      ,a.ContratID_Regroup
	                      ,a.SalonId
	                      ,RANK() OVER(
	                           PARTITION BY a.ProfilID
	                          ,a.CatalogueAbosID
	                          ,a.ContratID_Regroup ORDER BY a.DebutAboDate DESC
	                       )             AS N1
	                FROM   #T_Brut_Abos     a
	                WHERE  a.SalonId IS NOT NULL
	            ) AS b
	            ON  a.ProfilID = b.ProfilID
	                AND a.CatalogueAbosID = b.CatalogueAbosID
	                AND a.MasterAboID = b.ContratID_Regroup
	WHERE  b.N1 = 1
	
	UPDATE a
	SET    ModePmtHorsLigne = b.ModePmtHorsLigne
	FROM   #T_Abos_Agreg a
	       INNER JOIN (
	                SELECT a.ProfilID
	                      ,a.CatalogueAbosID
	                      ,a.ContratID_Regroup
	                      ,a.ModePmtHorsLigne
	                      ,RANK() OVER(
	                           PARTITION BY a.ProfilID
	                          ,a.CatalogueAbosID
	                          ,a.ContratID_Regroup ORDER BY a.DebutAboDate DESC
	                       )             AS N1
	                FROM   #T_Brut_Abos     a
	                WHERE  a.ModePmtHorsLigne IS NOT NULL
	            ) AS b
	            ON  a.ProfilID = b.ProfilID
	                AND a.CatalogueAbosID = b.CatalogueAbosID
	                AND a.MasterAboID = b.ContratID_Regroup
	WHERE  b.N1 = 1
	
	-- Eliminer les doublons eventuels dans #T_Abos_Agreg
	-- Les doublons sont possibles si deux lignes ont la meme date de debut
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN (
	                SELECT RANK() OVER(
	                           PARTITION BY MasterAboID
	                          ,DebutAboDate ORDER BY COALESCE(b.FinAboDate ,N'01-01-2078') 
	                           DESC
	                          ,NEWID()
	                       ) AS N1
	                      ,b.MasterAboID
	                      ,b.DebutAboDate
	                      ,COALESCE(b.FinAboDate ,N'01-01-2078') AS FinAboDate
	                FROM   #T_Abos_Agreg b
	            ) AS r1
	            ON  a.MasterAboID = r1.MasterAboID
	                AND CAST(a.DebutAboDate AS DATE) = CAST(r1.DebutAboDate AS DATE) -- on elimine ceux qui commencent le meme jour, et pas seulement a la seconde pres
	                AND COALESCE(a.FinAboDate ,N'01-01-2078') = r1.FinAboDate
	WHERE  N1 > 1
	

	UPDATE a
	SET    DebutAboDate = b.DebutAboDate
	      ,SouscriptionAboDate = b.SouscriptionAboDate
	FROM   #T_Abos_Agreg a
	       INNER JOIN #T_Brut_Abos b
	            ON  a.ProfilID = b.ProfilID
	                AND a.CatalogueAbosID = b.CatalogueAbosID
	       INNER JOIN #T_Abos_MinMax c
	            ON  b.ProfilID = c.ProfilID
	                AND b.CatalogueAbosID = c.CatalogueAbosID
	                AND b.DebutAboDate = c.DebutAboDate_Min
	                AND a.ContratID_Regroup = c.ContratID_Regroup
	
	
	IF OBJECT_ID('tempdb..#T_Abos_MinMax') IS NOT NULL
	    DROP TABLE #T_Abos_MinMax
	
	-- Propager MasterAboID dans brut :
	
	UPDATE a
	SET    MasterAboID = b.MasterAboID
	FROM   brut.Contrats_Abos a
	       INNER JOIN #T_Brut_Abos b
	            ON  a.ContratID = b.ContratID
	WHERE  a.ModifieTop = 1
	
	IF OBJECT_ID('tempdb..#T_Brut_Abos') IS NOT NULL
	    DROP TABLE #T_Brut_Abos
	
	UPDATE a
	SET    MasterAboID = a.ContratID
	FROM   brut.Contrats_Abos a
	WHERE  a.MasterAboID IS NULL
	       AND a.ModifieTop = 1
	       AND SourceID = @SourceID 
	
	-- Inserer dans #T_Abos_Agreg les lignes des abonnements non-recurrents
	
	INSERT #T_Abos_Agreg
	  (
	    MasterAboID
	   ,ProfilID
	   ,SourceID
	   ,CatalogueAbosID
	   ,SouscriptionAboDate
	   ,DebutAboDate
	   ,FinAboDate
	   ,MontantAbo
	   ,ExAboSouscrNb
	   ,Devise
	   ,Recurrent
	   ,ContratID_Regroup
	   ,ClientUserId
	   ,ServiceGroup
	   ,IsTrial
	   ,OrderID
	   ,ProductDescription
	   ,MethodePaiement
	   ,CodePromo
	   ,Provenance
	   ,CommercialId
	   ,SalonId
	   ,ModePmtHorsLigne
	   ,SubscriptionStatusID
	  )
	SELECT a.ContratID
	      ,a.ProfilID
	      ,a.SourceID
	      ,a.CatalogueAbosID
	      ,a.SouscriptionAboDate
	      ,a.DebutAboDate
	      ,a.FinAboDate
	      ,a.MontantAbo
	      ,a.ExAboSouscrNb
	      ,a.Devise
	      ,a.Recurrent
	      ,a.ContratID         AS ContratID_Regroup
	      ,a.ClientUserId
	      ,a.ServiceGroup
	      ,a.IsTrial
	      ,a.OrderID
	      ,a.ProductDescription
	      ,a.MethodePaiement
	      ,a.CodePromo
	      ,CASE 
	            WHEN a.Provenance IS NOT NULL AND a.SalonId IS NOT NULL THEN a.Provenance 
	                 + N' - ' + a.SalonId
	            ELSE COALESCE(a.Provenance ,a.SalonId)
	       END                 AS Provenance
	      ,a.CommercialId
	      ,a.SalonId
	      ,a.ModePmtHorsLigne
	      ,a.SubscriptionStatusID
	FROM   brut.Contrats_Abos     a
	WHERE  ModifieTop = 1 -- Les lignes qui viennent d'etre inserees
	       AND SourceID = @SourceID -- Neolane
	       AND a.Recurrent = 0 -- Abonnements non-recurrents
	
	-- Renseigner la marque
	
	UPDATE a
	SET    Marque = b.Marque
	FROM   #T_Abos_Agreg a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	
	CREATE INDEX ind_03_T_Abonnements_Agreg ON #T_Abos_Agreg(MasterAboID)
	
	UPDATE #T_Abos_Agreg
	SET    MasterID = ProfilID
	WHERE  MasterID IS NULL
	
	-- Renseigner = metrre a jour le SubscriptionStatusID avec le statut dernier en date qui peut ne pas etre "Active Subscription"
	
	IF OBJECT_ID(N'tempdb..#T_AboStatut') IS NOT NULL
	    DROP TABLE #T_AboStatut
	
	CREATE TABLE #T_AboStatut
	(
		SubscriptionId              NVARCHAR(16) NULL
	   ,ServiceID                   NVARCHAR(16) NULL
	   ,SubscriptionCreated         DATETIME NULL
	   ,SubscriptionLastUpdated     DATETIME NULL
	   ,SubscriptionStatusID        INT NULL
	   ,SubscriptionStatus          NVARCHAR(255) NULL
	   ,AccountId                   NVARCHAR(16) NULL
	   ,ClientUserId                NVARCHAR(16) NULL
	   ,ServiceExpiry               DATETIME NULL
	   ,UKI                         NVARCHAR(255) NULL
	)
	
	INSERT #T_AboStatut
	  (
	    SubscriptionId
	   ,ServiceID
	   ,SubscriptionCreated
	   ,SubscriptionLastUpdated
	   ,SubscriptionStatusID
	   ,SubscriptionStatus
	   ,AccountId
	   ,ClientUserId
	   ,ServiceExpiry
	   ,UKI
	  )
	SELECT a.SubscriptionId
	      ,a.ServiceID
	      ,CAST(a.SubscriptionCreated AS DATETIME) AS SubscriptionCreated
	      ,CAST(a.SubscriptionLastUpdated AS DATETIME) AS 
	       SubscriptionLastUpdated
	      ,CAST(a.SubscriptionStatusID AS INT) AS SubscriptionStatusID
	      ,a.SubscriptionStatus
	      ,a.AccountId
	      ,a.ClientUserId
	      ,CAST(a.ServiceExpiry AS DATETIME) AS ServiceExpiry
	      ,a.UKI
	FROM   import.PVL_Abonnements a
	WHERE  a.LigneStatut <> 1
	
	IF OBJECT_ID(N'tempdb..#T_AboDernierStatut') IS NOT NULL
	    DROP TABLE #T_AboDernierStatut
	
	CREATE TABLE #T_AboDernierStatut
	(
		SubscriptionId              NVARCHAR(16) NULL
	   ,ServiceID                   NVARCHAR(16) NULL
	   ,SubscriptionCreated         DATETIME NULL
	   ,SubscriptionLastUpdated     DATETIME NULL
	   ,SubscriptionStatusID        INT NULL
	   ,SubscriptionStatus          NVARCHAR(255) NULL
	   ,AccountId                   NVARCHAR(16) NULL
	   ,ClientUserId                NVARCHAR(16) NULL
	   ,ServiceExpiry               DATETIME NULL
	   ,iRecipientId                NVARCHAR(18) NULL
	   ,ProfilID                    INT NULL
	   ,CatalogueAbosID             INT NULL
	   ,EmailAddress                NVARCHAR(255) NULL
	)
	
	SET DATEFORMAT dmy
	
	INSERT #T_AboDernierStatut
	  (
	    SubscriptionId
	   ,ServiceID
	   ,SubscriptionCreated
	   ,SubscriptionLastUpdated
	   ,SubscriptionStatusID
	   ,SubscriptionStatus
	   ,AccountId
	   ,ClientUserId
	   ,ServiceExpiry
	   ,EmailAddress
	  )
	SELECT a.SubscriptionId
	      ,a.ServiceID
	      ,a.SubscriptionCreated
	      ,a.SubscriptionLastUpdated
	      ,a.SubscriptionStatusID
	      ,a.SubscriptionStatus
	      ,a.AccountId
	      ,a.ClientUserId
	      ,a.ServiceExpiry
	      ,a.UKI
	FROM   #T_AboStatut a
	       INNER JOIN (
	                SELECT RANK() OVER(
	                           PARTITION BY a.SubscriptionId ORDER BY a.SubscriptionLastUpdated 
	                           DESC
	                       )             AS N1
	                      ,SubscriptionId
	                      ,SubscriptionLastUpdated
	                FROM   #T_AboStatut     a
	            ) AS r1
	            ON  a.SubscriptionId = r1.SubscriptionId
	                AND a.SubscriptionLastUpdated = r1.SubscriptionLastUpdated
	                AND r1.N1 = 1
	
	IF OBJECT_ID(N'tempdb..#T_AboStatut') IS NOT NULL
	    DROP TABLE #T_AboStatut
	
	IF @FilePrefix = N'LP%'
	BEGIN
	    UPDATE a
	    SET    ProfilID = b.ProfilID
	    FROM   #T_AboDernierStatut a
	           INNER JOIN etl.VEL_Accounts b
	                ON  a.ClientUserId = b.ClientUserId
	END
	ELSE
	BEGIN
	    UPDATE a
	    SET    iRecipientId = r1.iRecipientId
	    FROM   #T_AboDernierStatut a
	           INNER JOIN (
	                    SELECT RANK() OVER(
	                               PARTITION BY b.sIdCompte ORDER BY b.ActionID 
	                               DESC
	                              ,b.ImportID DESC
	                           ) AS N1
	                          ,b.sIdCompte
	                          ,b.iRecipientId
	                    FROM   #CusCompteTmp b
	                    WHERE  b.LigneStatut <> 1
	                ) AS r1
	                ON  a.ClientUserId = r1.sIdCompte
	    WHERE  r1.N1 = 1
	    
	    
	    UPDATE a
	    SET    ProfilID = b.ProfilID
	    FROM   #T_AboDernierStatut a
	           INNER JOIN brut.Contacts b
	                ON  a.iRecipientID = b.OriginalID
	                    AND b.SourceID = @SourceID_Contact
	END	
	DELETE #T_AboDernierStatut
	WHERE  ProfilID IS NULL
	
	UPDATE a
	SET    CatalogueAbosID = b.CatalogueAbosID
	FROM   #T_AboDernierStatut a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.ServiceID = b.OriginalID
	                AND b.SourceID = @SourceID
	
	DELETE #T_AboDernierStatut
	WHERE  CatalogueAbosID IS NULL
	
	CREATE INDEX idx01_T_AboDernierStatut ON #T_AboDernierStatut(ProfilID)
	CREATE INDEX idx02_T_AboDernierStatut ON #T_AboDernierStatut(CatalogueAbosID)
	CREATE INDEX idx03_T_AboDernierStatut ON #T_AboDernierStatut(SubscriptionCreated)
	
	UPDATE a
	SET    SubscriptionStatusID = b.SubscriptionStatusID
	      ,FinAboDate = (
	           CASE 
	                WHEN a.FinAboDate < b.ServiceExpiry THEN a.FinAboDate
	                ELSE b.ServiceExpiry
	           END
	       )
	FROM   #T_Abos_Agreg a
	       INNER JOIN #T_AboDernierStatut b
	            ON  a.ProfilID = b.ProfilID
	                AND a.CatalogueAbosID = b.CatalogueAbosID
	                AND a.SouscriptionAboDate = b.SubscriptionCreated
	WHERE  a.SubscriptionStatusID <> b.SubscriptionStatusID
	
	-- Stocker les lignes dans etl.Abos_Agreg_PVL
	-- en attendant que la procedure etl.InsertAbonnements_Agreg les deverse dans dbo.Abonnements
	
	DELETE a -- on supprime les lignes que l'on va remplacer
	FROM   etl.Abos_Agreg_PVL a
	       INNER JOIN #T_Abos_Agreg b
	            ON  a.MasterAboID = b.MasterAboID
	
	INSERT etl.Abos_Agreg_PVL
	  (
	    MasterAboID
	   ,ProfilID
	   ,MasterID
	   ,SourceID
	   ,Marque
	   ,CatalogueAbosID
	   ,SouscriptionAboDate
	   ,DebutAboDate
	   ,FinAboDate
	   ,MontantAbo
	   ,ExAboSouscrNb
	   ,Devise
	   ,Recurrent
	   ,ContratID_Regroup
	   ,ClientUserId
	   ,ServiceGroup
	   ,IsTrial
	   ,OrderID
	   ,AboDescription
	   ,MethodePaiement
	   ,CodePromo
	   ,Provenance
	   ,CommercialId
	   ,SalonId
	   ,ModePmtHorsLigne
	   ,SubscriptionStatusID
	  )
	SELECT MasterAboID
	      ,ProfilID
	      ,MasterID
	      ,SourceID
	      ,Marque
	      ,CatalogueAbosID
	      ,SouscriptionAboDate
	      ,DebutAboDate
	      ,FinAboDate
	      ,MontantAbo
	      ,ExAboSouscrNb
	      ,Devise
	      ,Recurrent
	      ,ContratID_Regroup
	      ,ClientUserId
	      ,ServiceGroup
	      ,IsTrial
	      ,OrderID
	      ,ProductDescription
	      ,MethodePaiement
	      ,CodePromo
	      ,Provenance
	      ,CommercialId
	      ,SalonId
	      ,ModePmtHorsLigne
	      ,SubscriptionStatusID
	FROM   #T_Abos_Agreg
	
	UPDATE brut.Contrats_Abos
	SET    ModifieTop = 0
	WHERE  ModifieTop = 1 -- Alimentations successives sans build ; normalement, cela doit etre fait par la procedure FinTraitement
	
	UPDATE a
	SET    LigneStatut = 99
	FROM   import.PVL_Abonnements a
	WHERE  a.FichierTS = @FichierTS
	       AND a.LigneStatut = 0
	       AND a.SubscriptionStatusID = N'2' 
		
	UPDATE a
	SET    LigneStatut = 99
	FROM   import.PVL_Abonnements a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	WHERE  a.LigneStatut = 0
	       AND a.SubscriptionStatusID = N'2'
	                                    	
	UPDATE a
	SET    LigneStatut = 99
	FROM   import.PVL_Achats a
	       INNER JOIN #T_Abos_Agreg b
	            ON  a.OrderID = b.OrderID
	WHERE  a.LigneStatut = 0
	       AND a.ProductType = N'Service'
	       AND a.OrderStatus <> N'Refunded'
	
	IF OBJECT_ID(N'tempdb..#T_Recup') IS NOT NULL
	    DROP TABLE #T_Recup
	
	IF OBJECT_ID(N'tempdb..#T_Abos_Agreg') IS NOT NULL
	    DROP TABLE #T_Abos_Agreg
	
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
	    set @S=N'EXECUTE [QTSDQF].[dbo].[RejetsStats] ''95940C81-C7A7-4BD9-A523-445A343A9605'', ''PVL_Abonnements'', N'''+@FTS+N''' ; '
	    
	    IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_Abonnements'))
	    	execute (@S) 
	    
	    FETCH c_fts INTO @FTS
	END
	
	CLOSE c_fts
	DEALLOCATE c_fts
	
	
	/********** AUTOCALCULATE REJECTSTATS **********/
	IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_Abonnements'))
	EXECUTE [QTSDQF].[dbo].[RejetsStats] '95940C81-C7A7-4BD9-A523-445A343A9605', 'PVL_Abonnements', @FichierTS
END
