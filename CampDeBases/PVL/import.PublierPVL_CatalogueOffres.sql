USE [AmauryVUC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [import].[PublierPVL_CatalogueOffres] @FichierTS NVARCHAR(255)
AS

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 21/10/2014
-- Description:	Alimentation de la table ref.CatalogueProduits et ref.CatalogueAbonnements
-- a partir des fichiers CatalogueOffres de VEL : PVL_CatalogueOffres
-- Modification date: 22/04/2015
-- Modified by :	Andrei BRAGAR
-- Modifications : union EQ, FF, LP
-- =============================================

BEGIN
	SET NOCOUNT ON
	DECLARE @SourceID INT
	SET @SourceID = 10 -- PVL
	
	DECLARE @MarqueId INT
	DECLARE @TitrePressValue NVARCHAR(255) 
	
	-- On suppose que la table PVL_CatalogueOffres est alimentee en annule/remplace
	DECLARE @FilePrefix NVARCHAR(5) = NULL
	
	IF @FichierTS LIKE N'FF%'
	BEGIN
		SET @FilePrefix = N'FF'
	    SET @MarqueId = etl.GetMarqueID(N'France Football')
	    SET @TitrePressValue = N'France Football'
	END
	
	IF @FichierTS LIKE N'EQP%'
	BEGIN
		SET @FilePrefix = N'EQP'
	    SET @MarqueId = etl.GetMarqueID(N'L''Équipe')
	    SET @TitrePressValue = N'L''Équipe Numérique'
	END
	
	IF @FichierTS LIKE N'LP%'
	BEGIN
	    SET @FilePrefix = N'LP'
	    SET @MarqueId = NULL
	END
	
	IF @FilePrefix IS NULL
	    RAISERROR('File prefix does not match any of the possible' ,16 ,1);
	
	-- 1) Alimentation de ref.CatalogueProduits
	
	IF OBJECT_ID(N'#T_CatProduits') IS NOT NULL
	    DROP TABLE #T_CatProduits
	
	CREATE TABLE #T_CatProduits
	(
		OriginalID           NVARCHAR(255) NULL
	   ,SourceID             INT NULL
	   ,PrixUnitaire         DECIMAL(10 ,4) NULL
	   ,Devise               NVARCHAR(16) NULL
	   ,NomProduit           NVARCHAR(255) NULL
	   ,CategorieProduit     NVARCHAR(255) NULL
	   ,Marque               INT NULL
	)
	
	INSERT #T_CatProduits
	  (
	    OriginalID
	   ,SourceID
	   ,PrixUnitaire
	   ,Devise
	   ,NomProduit
	   ,CategorieProduit
	   ,Marque
	  )
	SELECT a.IdentifiantOffre  AS OriginalID
	      ,@SourceID
	      ,CAST(a.PrixOffre AS DECIMAL(10 ,4)) AS PrixUnitaire
	      ,N'EUR'              AS Devise
	      ,a.NomOffre          AS NomProduit
	      ,a.TypeProduit       AS CategorieProduit
	      ,CASE 
	            WHEN @FilePrefix <> N'LP' THEN @MarqueId --EQ, FF
	            ELSE CASE --LP
	                      WHEN (
	                               a.NomOffre LIKE N'%AEF%'
	                               OR a.NomOffre LIKE 
	                                  N'%Aujourd''hui en France%'
	                           ) THEN 2
	                      ELSE 6
	                 END
	       END AS Marque
	FROM   import.PVL_CatalogueOffres a
	WHERE  a.FichierTS = @FichierTS
	       AND a.LigneStatut = 0
	       AND a.TypeOffre <> N'Abonnements'
	
	UPDATE a
	SET    PrixUnitaire = 0.00
	FROM   #T_CatProduits a
	WHERE  a.PrixUnitaire IS NULL
	
	UPDATE b
	SET    PrixUnitaire = a.PrixUnitaire
	      ,Devise = a.Devise
	      ,NomProduit = a.NomProduit
	      ,CategorieProduit = a.CategorieProduit
	      ,Marque = a.Marque
	FROM   #T_CatProduits a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.OriginalID = b.OriginalID
	                AND a.SourceID = b.SourceID
	
	INSERT ref.CatalogueProduits
	  (
	    OriginalID
	   ,SourceID
	   ,PrixUnitaire
	   ,Devise
	   ,NomProduit
	   ,CategorieProduit
	   ,Marque
	  )
	SELECT a.OriginalID
	      ,a.SourceID
	      ,a.PrixUnitaire
	      ,a.Devise
	      ,a.NomProduit
	      ,a.CategorieProduit
	      ,a.Marque
	FROM   #T_CatProduits a
	       LEFT OUTER JOIN ref.CatalogueProduits b
	            ON  a.OriginalID = b.OriginalID
	                AND a.SourceID = b.SourceID
	WHERE  a.OriginalID IS NOT NULL
	       AND b.OriginalID IS NULL
	
	IF OBJECT_ID(N'#T_CatProduits') IS NOT NULL
	    DROP TABLE #T_CatProduits
	
	-- 2) Alimentation de ref.CatalogueAbonnements
	
	IF OBJECT_ID(N'#T_CatAbos') IS NOT NULL
	    DROP TABLE #T_CatAbos
	
	CREATE TABLE #T_CatAbos
	(
		OriginalID      NVARCHAR(255) NULL
	   ,SourceID        INT NULL
	   ,MontantAbo      DECIMAL(10 ,2) NULL
	   ,PrixInitial     DECIMAL(10 ,2) NULL
	   ,TitreID         INT NULL
	   ,OffreAbo        NVARCHAR(255) NULL
	   ,SupportAbo      INT NULL
	   ,Marque          INT NULL
	   ,Recurrent       BIT NOT NULL DEFAULT(0)
	   ,isCouple        BIT NOT NULL DEFAULT(0)
	)
	
	INSERT #T_CatAbos
	  (
	    OriginalID
	   ,SourceID
	   ,MontantAbo
	   ,PrixInitial
	   ,OffreAbo
	   ,Marque
	   ,TitreID
	   ,Recurrent
	   ,SupportAbo
	  )
	SELECT DISTINCT
	       a.IdentifiantOffre  AS OriginalID
	      ,@SourceID
	      ,CAST(a.PrixOffre AS DECIMAL(10 ,2)) AS MontantAbo
	      ,CAST(a.PrixOffre AS DECIMAL(10 ,2)) AS PrixInitial
	      ,a.NomOffre          AS OffreAbo
	      ,CASE 
	            WHEN @FilePrefix <> N'PL' THEN @MarqueId --EQ, FF
	            ELSE CASE --LP
	                      WHEN (
	                               a.NomOffre LIKE N'%AEF%'
	                               OR a.NomOffre LIKE 
	                                  N'%Aujourd''hui en France%'
	                           ) THEN 2
	                      ELSE 6
	                 END
	       END AS Marque
	      ,CASE 
	            WHEN @FilePrefix = N'LP' THEN CASE 
	                                               WHEN (
	                                                        a.NomOffre LIKE 
	                                                        N'%AEF%'
	                                                        OR a.NomOffre LIKE 
	                                                           N'%Aujourd''hui en France%'
	                                                    ) THEN 2
	                                               ELSE 8
	                                          END
	            ELSE NULL
	       END AS TitreID
	      ,CASE 
	            WHEN a.TypeProduit LIKE N'Abonnement [à,a] tacite reconduction' THEN 
	                 1
	            ELSE 0
	       END AS Recurrent
	      ,CASE 
	            WHEN @FilePrefix = N'LP' THEN 1
	            ELSE NULL
	       END AS SupportAbo -- Numerique
	FROM   import.PVL_CatalogueOffres a
	WHERE  a.FichierTS = @FichierTS
	       AND a.LigneStatut = 0
	       AND a.TypeOffre = N'Abonnements'
	
	IF @FilePrefix <> N'LP'
	BEGIN
	    UPDATE a
	    SET    TitreID = b.CodeValN
	    FROM   #T_CatAbos a
	           CROSS JOIN ref.Misc b
	    WHERE  b.TypeRef = N'TITREPRESSE'
	           AND b.Valeur = @TitrePressValue
	    
	    UPDATE a
	    SET    SupportAbo = b.CodeValN
	    FROM   #T_CatAbos a
	           CROSS JOIN ref.Misc b
	    WHERE  b.TypeRef = N'SUPPORTABO'
	           AND b.Valeur = N'Numérique'
	END
	
	UPDATE a
	SET    MontantAbo = 0.00
	FROM   #T_CatAbos a
	WHERE  a.MontantAbo IS NULL
	
	UPDATE a
	SET    PrixInitial = MontantAbo
	FROM   #T_CatAbos a
	WHERE  a.PrixInitial IS NULL
	
	UPDATE b
	SET    MontantAbo = a.MontantAbo
	      ,PrixInitial = a.PrixInitial
	      ,OffreAbo = a.OffreAbo
	      ,Recurrent = a.Recurrent
	FROM   #T_CatAbos a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.OriginalID = b.OriginalID
	                AND a.SourceID = b.SourceID 
	
	INSERT ref.CatalogueAbonnements
	  (
	    OriginalID
	   ,SourceID
	   ,MontantAbo
	   ,TitreID
	   ,OffreAbo
	   ,SupportAbo
	   ,Marque
	   ,Recurrent
	   ,isCouple
	   ,PrixInitial
	   ,CodeOffre
	   ,CodeOption
	   ,CodeTarif
	  )
	SELECT a.OriginalID
	      ,a.SourceID
	      ,a.MontantAbo
	      ,a.TitreID
	      ,a.OffreAbo
	      ,a.SupportAbo
	      ,a.Marque
	      ,a.Recurrent
	      ,a.isCouple
	      ,a.PrixInitial
	      ,CAST(a.OriginalID AS NVARCHAR(8))
	      ,CAST(a.OriginalID AS NVARCHAR(8))
	      ,CAST(a.OriginalID AS NVARCHAR(8))
	FROM   #T_CatAbos a
	       LEFT OUTER JOIN ref.CatalogueAbonnements b
	            ON  a.OriginalID = b.OriginalID
	                AND a.SourceID = b.SourceID
	WHERE  a.OriginalID IS NOT NULL
	       AND b.OriginalID IS NULL
	
	IF OBJECT_ID(N'#T_CatAbos') IS NOT NULL
	    DROP TABLE #T_CatAbos
	
	UPDATE a
	SET    LigneStatut = 99
	FROM   import.PVL_CatalogueOffres a
	WHERE  a.FichierTS = @FichierTS
	       AND a.LigneStatut = 0
	           
	           /********** AUTOCALCULATE REJECTSTATS **********/
	           IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_CatalogueOffres'))
	           	EXECUTE [QTSDQF].[dbo].[RejetsStats] '95940C81-C7A7-4BD9-A523-445A343A9605', 'PVL_CatalogueOffres', @FichierTS
END
