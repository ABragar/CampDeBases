USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [import].[PublierPVL_Achats_Remb]    Script Date: 22.04.2015 10:21:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [import].[PublierPVL_Achats_Remb] @FichierTS NVARCHAR(255)
AS

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 28/11/2014
-- Description:	Remboursements des achats dans dbo.AchatALActe
-- et des abonnements dans dbo.Abonnements
-- a partir des fichiers DailyOrderReport de VEL : PVL_Achats 
-- ou OrderStatus=Refunded
-- Modification date: 22/04/2015
-- Modified by :	Andrei BRAGAR
-- Modifications : union EQ, LP, FF to 1 script
-- =============================================

BEGIN
	SET NOCOUNT ON
	
	DECLARE @FilePrefix NVARCHAR(5) = NULL
	DECLARE @CusCompteTableName NVARCHAR(30)
	DECLARE @sqlCommand NVARCHAR(500)
	
	DECLARE @OrderStatus NVARCHAR(8) = N'Refunded'
	DECLARE @Description NVARCHAR(25) = N'Refund Amount on Order:%' 
	DECLARE @Joincondition NVARCHAR(255)
	
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
	
	CREATE INDEX idx01_sIdCompte ON #CusCompteTmp(sIdCompte) 
	CREATE INDEX idx02_ActionID ON #CusCompteTmp(ActionID)
	
	
	
	IF OBJECT_ID(N'tempdb..#T_Refunds') IS NOT NULL
	    DROP TABLE #T_Refunds
	
	CREATE TABLE #T_Refunds
	(
		OrderID_Refund         NVARCHAR(18) NULL
	   ,AccountID              NVARCHAR(18) NULL
	   ,ClientUserId           NVARCHAR(18) NULL
	   ,Description_Refund     NVARCHAR(255) NULL
	   ,OrderID_Abo            NVARCHAR(18) NULL
	   ,GrossAmount            DECIMAL(10 ,2) NULL
	   ,AchatID                INT NULL
	   ,AbonnementID           INT NULL
	   ,ImportID               INT NULL
	)
	
	INSERT #T_Refunds
	  (
	    OrderID_Refund
	   ,AccountID
	   ,ClientUserId
	   ,Description_Refund
	   ,GrossAmount
	   ,ImportID
	  )
	SELECT a.OrderID
	      ,a.AccountID
	      ,a.ClientUserId
	      ,a.Description
	      ,CAST(a.GrossAmount AS DECIMAL(10 ,2)) AS GrossAmount
	      ,a.ImportID
	FROM   import.PVL_Achats a
	WHERE  a.FichierTS = @FichierTS
	       AND a.LigneStatut = 0
	       AND a.OrderStatus = @OrderStatus
	       AND a.Description LIKE @Description
	
	-- Recuperer les lignes rejetees a cause de ClientUserId absent de CusCompteEFR (EQ) ou CusCompteFF (FF)
	-- ou e-mail non trouvé dans LPSSO ou brut.Emails (LP)
	-- mais dont la situation a été régularisée depuis
	
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
	    SET @Joincondition = 
	        N' INNER JOIN etl.VEL_Accounts b ON a.ClientUserId = b.ClientUserId '
	ELSE
	    SET @Joincondition = 
	        N' INNER JOIN #CusCompteTmp b ON  a.ClientUserId = b.sIdCompte '
	
	DECLARE @sql NVARCHAR(500) = 
	        N'INSERT #T_Recup
	      (
	        RejetCode
	       ,ImportID
	       ,FichierTS
	      )
	    SELECT a.RejetCode
	          ,a.ImportID
	          ,a.FichierTS
	    FROM   import.PVL_Achats a
				' + @Joincondition +
	        ' WHERE  a.RejetCode & POWER(CAST(2 AS BIGINT) ,3) = POWER(CAST(2 AS BIGINT) ,3)
	           AND a.OrderStatus = @OrderStatus AND a.Description LIKE @Description'
	
	DECLARE @param NVARCHAR(100) = 
	        N'@OrderStatus NVARCHAR(8), @Description NVARCHAR(25)'
	
	EXECUTE sp_executesql @sql
	       ,@Param
	       ,@OrderStatus = @OrderStatus
	       ,@Description = @Description
	
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
	
	
	INSERT #T_Refunds
	  (
	    OrderID_Refund
	   ,AccountID
	   ,ClientUserId
	   ,Description_Refund
	   ,GrossAmount
	   ,ImportID
	  )
	SELECT a.OrderID
	      ,a.AccountID
	      ,a.ClientUserId
	      ,a.Description
	      ,CAST(a.GrossAmount AS DECIMAL(10 ,2)) AS GrossAmount
	      ,a.ImportID
	FROM   import.PVL_Achats a
	       INNER JOIN #T_Recup b
	            ON  a.ImportID = b.ImportID
	WHERE  a.LigneStatut = 0
	       AND a.OrderStatus = @OrderStatus
	       AND a.Description LIKE @Description
	
	
	UPDATE a
	SET    OrderID_Abo = LTRIM(
	           SUBSTRING(
	               a.Description_Refund
	              ,CHARINDEX(N':' ,a.Description_Refund ,1) + 1
	              ,CASE 
	                    WHEN CHARINDEX(N'(' ,a.Description_Refund ,1) >
	                         CHARINDEX(N':' ,a.Description_Refund ,1) THEN 
	                         CHARINDEX(N'(' ,a.Description_Refund ,1) -CHARINDEX(N':' ,a.Description_Refund ,1)
	                         -1
	                    ELSE 18
	               END
	           )
	       )
	FROM   #T_Refunds a
	
	UPDATE a
	SET    AchatID = b.AchatID
	FROM   #T_Refunds a
	       INNER JOIN dbo.AchatsALActe b
	            ON  a.OrderID_Abo = b.OrderID
	
	UPDATE a
	SET    AbonnementID = b.AbonnementID
	FROM   #T_Refunds a
	       INNER JOIN dbo.Abonnements b
	            ON  a.OrderID_Abo = b.OrderID
	
	UPDATE a
	SET    MontantAchat = a.MontantAchat -b.GrossAmount
	      ,StatutAchat = 2 -- Refunded
	      ,ModifieTop = 1
	FROM   dbo.AchatsALActe a
	       INNER JOIN #T_Refunds b
	            ON  a.AchatID = b.AchatID
	
	UPDATE a
	SET    MontantAbo = a.MontantAbo -b.GrossAmount
	      ,ModifieTop = 1
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Refunds b
	            ON  a.AbonnementID = b.AbonnementID
	
	UPDATE a
	SET    LigneStatut = 99
	FROM   import.PVL_Achats a
	       INNER JOIN #T_Refunds b
	            ON  a.ImportID = b.ImportID
	WHERE  (b.AbonnementID IS NOT NULL OR b.AchatID IS NOT NULL)
	       AND a.LigneStatut = 0
	
	IF OBJECT_ID(N'tempdb..#T_Recup') IS NOT NULL
	    DROP TABLE #T_Recup
	
	IF OBJECT_ID(N'tempdb..#T_Refunds') IS NOT NULL
	    DROP TABLE #T_Refunds
	
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
	    set @S=N'EXECUTE [QTSDQF].[dbo].[RejetsStats] ''95940C81-C7A7-4BD9-A523-445A343A9605'', ''PVL_Achats'', N'''+@FTS+N''' ; '
	    
	    IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_Achats'))
	    	execute (@S) 
	    
	    FETCH c_fts INTO @FTS
	END
	
	CLOSE c_fts
	DEALLOCATE c_fts
	
	IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_Achats'))
		EXECUTE [QTSDQF].[dbo].[RejetsStats] '95940C81-C7A7-4BD9-A523-445A343A9605', 'PVL_Achats', @FichierTS
END
