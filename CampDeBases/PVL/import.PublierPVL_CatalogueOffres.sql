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
-- Modification date: 
-- Modifications :
-- =============================================

BEGIN
	SET NOCOUNT ON
	
	-- On suppose que la table PVL_CatalogueOffres est alimentee en annule/remplace
	
	DECLARE @SourceID INT
	
	SET @SourceID = 10 -- PVL
	
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
	SELECT a.IdentifiantOffre          AS OriginalID
	      ,@SourceID
	      ,CAST(a.PrixOffre AS DECIMAL(10 ,4)) AS PrixUnitaire
	      ,N'EUR'                      AS Devise
	      ,a.NomOffre                  AS NomProduit
	      ,a.TypeProduit               AS CategorieProduit
	      ,7                           AS Marque -- L'Equipe
	FROM   import.PVL_CatalogueOffres     a
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
	
	-- est-ce qu'on va gerer des suppressions des produits ?
	
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
	   ,Recurrent
	  )
	SELECT DISTINCT
	       a.IdentifiantOffre          AS OriginalID
	      ,@SourceID
	      ,CAST(a.PrixOffre AS DECIMAL(10 ,2)) AS MontantAbo
	      ,CAST(a.PrixOffre AS DECIMAL(10 ,2)) AS PrixInitial
	      ,a.NomOffre                  AS OffreAbo
	      ,7                           AS Marque -- L'Equipe
	      ,CASE 
	            WHEN a.TypeProduit = N'Abonnement a tacite reconduction' THEN 1
	            ELSE 0
	       END                         AS Recurrent
	FROM   import.PVL_CatalogueOffres     a
	WHERE  a.FichierTS = @FichierTS
	       AND a.LigneStatut = 0
	       AND a.TypeOffre = N'Abonnements'
	
	UPDATE a
	SET    TitreID = b.CodeValN
	FROM   #T_CatAbos a
	       CROSS JOIN ref.Misc b
	WHERE  b.TypeRef = N'TITREPRESSE'
	       AND b.Valeur = N'L''Equipe Numerique'
	
	UPDATE a
	SET    SupportAbo = b.CodeValN
	FROM   #T_CatAbos a
	       CROSS JOIN ref.Misc b
	WHERE  b.TypeRef = N'SUPPORTABO'
	       AND b.Valeur = N'Numerique'
	
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
	           --IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_CatalogueOffres'))
	           --	EXECUTE [QTSDQF].[dbo].[RejetsStats] '95940C81-C7A7-4BD9-A523-445A343A9605', 'PVL_CatalogueOffres', @FichierTS
END
