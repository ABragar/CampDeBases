 USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [import].[PublierPVL_Achats]    Script Date: 07/23/2015 13:40:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [import].[PublierPVL_Achats] @FichierTS NVARCHAR(255)
AS

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 28/10/2014
-- Description:	Alimentation de la table dbo.AchatALActe
-- a partir des fichiers DailyOrderReport de VEL : PVL_Achats
-- Modification date: 20/04/2015
-- Modified by :	Andrei BRAGAR
-- Modifications : union EQ, LP, FF
-- Modified by :	Anatoli VELITCHKO
-- Modifications : Retour en arrière concernant la Provenance :
--					On prend la Provenance telle quelle
-- Modification date: 24/06/2015
-- Modified by :	Anatoli VELITCHKO
-- Modifications : Récupération de toutes les lignes LP devenues valides à cause du ClientUserID
-- =============================================

BEGIN
	SET NOCOUNT ON
	
	-- On suppose que la table PVL_CatalogueOffres est alimentee en annule/remplace
	
	DECLARE @SourceID INT
	DECLARE @SourceID_Contact INT
	DECLARE @FilePrefix NVARCHAR(5) = NULL
	DECLARE @CusCompteTableName NVARCHAR(30)
	DECLARE @sqlCommand NVARCHAR(500)
	DECLARE @PrefixContact NVARCHAR(3) = LEFT(@FichierTS,2)+N'-'
	
	IF @FichierTS LIKE N'FF%'
	BEGIN
	    SET @CusCompteTableName = N'import.NEO_CusCompteFF'
	    SET @SourceID = 10 -- PVL
	    SET @SourceID_Contact = 1 -- Neolane
	    SET @FilePrefix = N'FF%'
	END
	
	IF @FichierTS LIKE N'EQ%'
	BEGIN
	    SET @CusCompteTableName = N'import.NEO_CusCompteEFR'		
	    SET @SourceID = 10 -- PVL
	    SET @SourceID_Contact = 1 -- Neolane
	    SET @FilePrefix = N'EQ%'
	END
	
	IF @FichierTS LIKE N'LP%'
	BEGIN
	    SET @SourceID = 10 -- PVL
	    SET @FilePrefix = N'LP%'
	END
	
	IF @FilePrefix IS NULL
	    RAISERROR('File prefix does not match any of the possible',16, 1);
	    
	IF OBJECT_ID('tempdb..#CusCompteTmp') IS NOT NULL
	    DROP TABLE #CusCompteTmp
	
	CREATE TABLE #CusCompteTmp
	(
		sIdCompte        NVARCHAR(255)
	   ,iRecipientId     NVARCHAR(18)
	   ,ActionID         NVARCHAR(8)
	   ,ImportID         INT
	   ,LigneStatut      INT
	   ,FichierTS        NVARCHAR(255)
	)	
	
	SET @sqlCommand = 
	    N'INSERT #CusCompteTmp SELECT cc.sIdCompte ,cc.iRecipientId ,cc.ActionID ,cc.ImportID ,cc.LigneStatut ,cc.FichierTS FROM '
	    + @CusCompteTableName + ' AS cc where cc.LigneStatut<>1'	          
	
	EXEC (@sqlCommand)
	
	CREATE INDEX idx01_sIdCompte ON #CusCompteTmp(sIdCompte) 
	CREATE INDEX idx02_ActionID ON #CusCompteTmp(ActionID)
	
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
	   ,PmtMode                INT NULL
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
	   ,PmtMode
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
	      , a.Provenance -- Retour en arrière effectué le 21/05/2015
	      -- case when a.Provenance like N'%oneclic%' then N'OneClick' else N'WEB' end	AS Provenance
	      ,a.IdentifiantDuCommercial      AS CommercialId
	      ,a.IdentifiantDuSalon           AS SalonId
	      ,CASE UPPER(etl.Trim(a.PaymentMethod))
	            WHEN N'OFFLINE' THEN N'Cheque'
	            ELSE NULL
	       END                            AS ModePmtHorsLigne
	      ,a.ImportID
	      ,CASE UPPER(etl.trim(a.PaymentMethod))
	            WHEN N'CREDITCARD' THEN 2 --'CB'
	            WHEN N'NOTSET' THEN 8 --'Gratuit'
	            WHEN N'OFFLINE' THEN 3 --'Cheque'
	            WHEN N'SERVICECREDITS' THEN 7 --'Jetons'
	       END                            AS PmtMode
	FROM   import.PVL_Achats                 a
	WHERE  a.FichierTS = @FichierTS
	       AND a.LigneStatut = 0
	       AND a.ProductType <> N'Service'
	       AND a.OrderStatus = N'Completed'
	

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
	
	IF @FichierTS LIKE N'LP%'
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
	    FROM   import.PVL_Achats a
	           INNER JOIN etl.VEL_Accounts b
	                ON  a.ClientUserId = b.ClientUserId
	                    AND b.Valid = 1
	/*           INNER JOIN ref.CatalogueProduits c
	                ON  a.ContentItemId = c.OriginalID
	                    AND c.SourceID = 10
	                    AND c.Appartenance = 2 */
	    WHERE  a.RejetCode & POWER(CAST(2 AS BIGINT) ,3) = POWER(CAST(2 AS BIGINT) ,3)
	     /*      AND a.ProductType <> N'Service'
	           AND a.OrderStatus = N'Completed' */
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
	    FROM   import.PVL_Achats a
	           INNER JOIN #CusCompteTmp b
	                ON  a.ClientUserId = b.sIdCompte
	    WHERE  a.RejetCode & POWER(CAST(2 AS BIGINT) ,3) = POWER(CAST(2 AS BIGINT) ,3)
	           AND a.FichierTS LIKE @FilePrefix
	END
	
	INSERT INTO #T_Recup
	  (
	    RejetCode
	   ,ImportID
	   ,FichierTS
	  )
	SELECT a.RejetCode
	      ,a.ImportID
	      ,a.FichierTS
	FROM   import.PVL_Achats a
	       INNER JOIN brut.Contacts AS b
	            ON  @PrefixContact + a.ClientUserId = b.OriginalID
	WHERE  b.SourceID = 10
	       AND a.RejetCode & POWER(CAST(2 AS BIGINT) ,3) = POWER(CAST(2 AS BIGINT) ,3)
	       AND a.FichierTS LIKE @FilePrefix
	
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
	
	
-- Revalider les lignes de import.PVL_Abonnements en RejetCode=20
-- i.e. celles qui sont invalides à cause des lignes Achats invalides 
-- mais qui ont été récupérées
		
	if object_id(N'tempdb..#T_Recup_20') is not null
		drop table #T_Recup_20
	
	create table #T_Recup_20
	(
	RejetCode bigint null
	, ImportID int null
	, FichierTS nvarchar(255) null
	)

insert #T_Recup_20
(
RejetCode
, ImportID
, FichierTS
)
select  i.RejetCode
, i.ImportID
, i.FichierTS
from #T_Recup a inner join import.PVL_Abonnements i on a.ImportID=i.ImportID
inner join import.PVL_Achats b on i.ServiceId=b.ServiceId
								and i.ClientUserID=b.ClientUserId
								and 
								cast(i.SubscriptionLastUpdated as datetime) 
									between dateadd(minute,-10,cast(b.OrderDate as datetime))
										and dateadd(minute,10,cast(b.OrderDate as datetime))
								and b.LigneStatut<>1
								and b.ProductType=N'Service'
								and b.OrderStatus<>N'Refunded'
where i.SubscriptionStatusID=N'2' -- Active Subscription
and i.RejetCode & 20 = 20
and b.RejetCode=0
and i.FichierTS like @FilePrefix
and b.FichierTS like @FilePrefix

	UPDATE a
	SET    RejetCode = a.RejetCode - 20
	FROM   #T_Recup_20 a

	UPDATE a
	SET    RejetCode = b.RejetCode
	FROM   import.PVL_Abonnements a
	       INNER JOIN #T_Recup_20 b
	            ON  a.ImportID = b.ImportID
	
	UPDATE a
	SET    LigneStatut = 0
	FROM   import.PVL_Abonnements a
	       INNER JOIN #T_Recup_20 b
	            ON  a.ImportID = b.ImportID
	WHERE  b.RejetCode = 0
	
	UPDATE a
	SET    RejetCode = b.RejetCode
	FROM   rejet.PVL_Abonnements a
	       INNER JOIN #T_Recup_20 b
	            ON  a.ImportID = b.ImportID
	
	if object_id(N'tempdb..#T_FTS_ABO') is not null
		drop table #T_FTS_ABO
	
	create table #T_FTS_ABO (FichierTS nvarchar(255) null)
	
	
	INSERT #T_FTS_ABO
	  (
	    FichierTS
	  )
	SELECT DISTINCT FichierTS
	FROM   #T_Recup_20
	
	DELETE a
	FROM   #T_Recup_20 a
	WHERE  a.RejetCode <> 0
	
	DELETE a
	FROM   rejet.PVL_Abonnements a
	       INNER JOIN #T_Recup_20 b
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
	   ,PmtMode
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
	      , a.Provenance -- Retour en arrière effectué le 21/05/2015
	      -- case when a.Provenance like N'%oneclic%' then N'OneClick' else N'WEB' end	AS Provenance
	      ,a.IdentifiantDuCommercial      AS CommercialId
	      ,a.IdentifiantDuSalon           AS SalonId
	      ,CASE UPPER(etl.Trim(a.PaymentMethod))
	            WHEN N'OFFLINE' THEN N'Cheque'
	            ELSE NULL
	       END                            AS ModePmtHorsLigne
	      ,a.ImportID
	      ,CASE UPPER(etl.trim(a.PaymentMethod))
	            WHEN N'CREDITCARD' THEN 2 --'CB'
	            WHEN N'NOTSET' THEN 8 --'Gratuit'
	            WHEN N'OFFLINE' THEN 3 --'Cheque'
	            WHEN N'SERVICECREDITS' THEN 7 --'Jetons'
	       END                            AS PmtMode
	FROM   import.PVL_Achats a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	WHERE  a.LigneStatut = 0
	       AND a.ProductType <> N'Service'
	       AND a.OrderStatus = N'Completed'
	
	
	IF @FichierTS LIKE N'LP%'
	BEGIN
	    UPDATE a
	    SET    EmailAddress = b.EmailAddress
	    FROM   #T_Achats a
	           INNER JOIN etl.VEL_Accounts b
	                ON  a.ClientUserId = b.ClientUserId
	                    AND b.Valid = 1
	END
	
	UPDATE a
	SET    ProduitID = b.ProduitID
	      ,Marque = b.Marque
	      ,NomProduit = b.NomProduit
	FROM   #T_Achats a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.OriginalID = b.OriginalID
	                AND b.SourceID = @SourceID
	
	
	IF @FichierTS NOT LIKE N'LP%'
	BEGIN
	    UPDATE a
	    SET    iRecipientId = r1.iRecipientId
	    FROM   #T_Achats a
	           INNER JOIN (
	                    SELECT RANK() OVER(
	                               PARTITION BY b.sIdCompte ORDER BY CAST(b.ActionID AS INT) 
	                               DESC
	                              ,b.ImportID DESC
	                           ) AS N1
	                          ,b.sIdCompte
	                          ,b.iRecipientId
	                    FROM   #CusCompteTmp b
	                    ) AS r1
	                ON  a.ClientUserId = r1.sIdCompte
	    WHERE  r1.N1 = 1
	END
	
	IF @FichierTS LIKE N'LP%'
	BEGIN
	    UPDATE a
	    SET    ProfilID = b.ProfilID
	    FROM   #T_Achats a
	           INNER JOIN etl.VEL_Accounts b
	                ON  a.ClientUserId = b.ClientUserId
	                    AND b.Valid = 1
	END
	ELSE
	BEGIN
	    UPDATE a
	    SET    ProfilID = b.ProfilID
	    FROM   #T_Achats a
	           INNER JOIN brut.Contacts b
	                ON  a.iRecipientID = b.OriginalID
	                    AND b.SourceID = @SourceID_Contact
	END
	
	UPDATE a
	    SET    ProfilID = b.ProfilID
	    FROM   #T_Achats a
	           INNER JOIN brut.Contacts b
	                ON @PrefixContact + a.ClientUserID = b.OriginalID
	                    AND b.SourceID = 10
	
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
	   ,PmtMode
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
	      ,a.PmtMode
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
	    SET @S = 
	        N'EXECUTE [QTSDQF].[dbo].[RejetsStats] ''95940C81-C7A7-4BD9-A523-445A343A9605'', ''PVL_Achats'', N'''
	        + @FTS + N''' ; '
	    
	    IF (
	           EXISTS(
	               SELECT NULL
	               FROM   sys.tables t
	                      INNER JOIN sys.[schemas] s
	                           ON  s.SCHEMA_ID = t.SCHEMA_ID
	               WHERE  s.name = 'import'
	                      AND t.Name = 'PVL_Achats'
	           )
	       )
	        EXECUTE (@S) 
	    
	    FETCH c_fts INTO @FTS
	END
	
	CLOSE c_fts
	DEALLOCATE c_fts
	
	DECLARE c_fts_abo CURSOR  
	FOR
	    SELECT FichierTS
	    FROM   #T_FTS_ABO
	
	OPEN c_fts_abo
	
	FETCH c_fts_abo INTO @FTS
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
	    SET @S = 
	        N'EXECUTE [QTSDQF].[dbo].[RejetsStats] ''95940C81-C7A7-4BD9-A523-445A343A9605'', ''PVL_Abonnements'', N'''
	        + @FTS + N''' ; '
	    
	    IF (
	           EXISTS(
	               SELECT NULL
	               FROM   sys.tables t
	                      INNER JOIN sys.[schemas] s
	                           ON  s.SCHEMA_ID = t.SCHEMA_ID
	               WHERE  s.name = 'import'
	                      AND t.Name = 'PVL_Abonnements'
	           )
	       )
	        EXECUTE (@S) 
	    
	    FETCH c_fts_abo INTO @FTS
	END
	
	CLOSE c_fts_abo
	DEALLOCATE c_fts_abo
	
	
	/********** AUTOCALCULATE REJECTSTATS **********/
		IF (
		       EXISTS(
		           SELECT NULL
		           FROM   sys.tables t
		                  INNER JOIN sys.[schemas] s
		                       ON  s.SCHEMA_ID = t.SCHEMA_ID
		           WHERE  s.name = 'import'
		                  AND t.Name = 'PVL_Achats'
		       )
		   )
		    EXECUTE [QTSDQF].[dbo].[RejetsStats]
		            '95940C81-C7A7-4BD9-A523-445A343A9605'
		           ,'PVL_Achats'
		           ,@FichierTS
END

