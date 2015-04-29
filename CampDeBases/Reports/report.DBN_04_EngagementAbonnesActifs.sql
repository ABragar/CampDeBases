USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [report].[DB_7_NouvAbos]    Script Date: 04/20/2015 16:28:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [report].[DBN_04_EngagementAbonnesActifs] (@Editeur NVARCHAR(8) ,@P NVARCHAR(30))
AS
-- =============================================
-- Author:		Andrey Bragar
-- Creation date: 29/04/2015
-- Description:	Calcul du Dashboard Abos Numeriques 
--				N°4
--				ENGAGEMENT ABONNES ACTIFS
-- Modiification date :
-- Modified by :
-- Modification :
-- =============================================

BEGIN
	-- @Editeur : EQ, FF, LP
	SET NOCOUNT ON
	
	DECLARE @IdTemplate AS UNIQUEIDENTIFIER = NULL
	DECLARE @IdTemplate_Num_EQ AS UNIQUEIDENTIFIER =
	        N'AE9B6FBA-06EF-4855-885A-BA3C2F955279'
	
	DECLARE @IdTemplate_Num_FF AS UNIQUEIDENTIFIER =
	        N'9D260307-3BEF-4B0F-9B87-0BE3CE30AD3D'
	
	DECLARE @IdTemplate_Num_LP AS UNIQUEIDENTIFIER =
	        N'202D2833-6EEF-449C-A2A5-509CBFB936FC'
	
	DECLARE @MarqueList TABLE (VALUE INT)
	IF @Editeur = N'EQ'
	BEGIN
	    INSERT INTO @MarqueList
	    VALUES
	      (
	        7
	      ) 
	    
	    SET @IdTemplate = @IdTemplate_Num_EQ
	END
	ELSE
	IF @Editeur = N'FF'
	BEGIN
	    INSERT INTO @MarqueList
	    VALUES
	      (
	        3
	      ) 
	    
	    SET @IdTemplate = @IdTemplate_Num_FF
	END
	ELSE
	IF @Editeur = N'LP'
	BEGIN
	    INSERT INTO @MarqueList
	    VALUES
	      (
	        6
	      ),(2) 
	    
	    SET @IdTemplate = @IdTemplate_Num_LP
	END
	
	IF @IdTemplate IS NULL
	    RAISERROR('Invalid value for parameter @Editeur' ,16 ,1);
	
	DECLARE @Period AS NVARCHAR(30)
	DECLARE @IdPeriod AS UNIQUEIDENTIFIER
	DECLARE @IdGraph AS INT
	DECLARE @SnapshotDate AS DATETIME
	DECLARE @IdOwner AS UNIQUEIDENTIFIER
	
	DECLARE @Progression AS FLOAT
	DECLARE @PrecPeriod AS NVARCHAR(30)
	
	DECLARE @ValeurFloatMin AS FLOAT
	DECLARE @ValeurFloatMax AS FLOAT
	DECLARE @EcartType AS FLOAT
	
	SET @Period = @P
	
	SET @SnapshotDate = GETDATE()
	
	SET @IdGraph = 4
	
	SELECT @IdPeriod = IdPeriode
	FROM   report.RefPeriodeOwnerDB_Num
	WHERE  Periode            = @Period
	       AND Editeur        = @Editeur
	       AND IdTemplate     = @IdTemplate
	
	SELECT @IdOwner = IdOwner
	FROM   report.RefPeriodeOwnerDB_Num
	WHERE  Periode            = @Period
	       AND Editeur        = @Editeur
	       AND IdTemplate     = @IdTemplate
	
	DECLARE @DebutPeriod AS DATETIME
	SELECT @DebutPeriod = DebutPeriod
	FROM   report.RefPeriodeOwnerDB_Num
	WHERE  IdPeriode = @IdPeriod
	
	SET @PrecPeriod = N'Semaine_' + RIGHT(
	        N'00' + CAST(
	            DATEPART(week ,DATEADD(week ,-1 ,@DebutPeriod)) AS NVARCHAR(2)
	        )
	       ,2
	    ) + N'_' + CAST(
	        DATEPART(YEAR ,DATEADD(week ,-1 ,@DebutPeriod)) AS NVARCHAR(4)
	    )
	
	DELETE report.DashboardAboNumerique
	WHERE  Periode = @Period
	       AND IdGraph = @IdGraph
	       AND Editeur = @Editeur;
	
	WITH period AS (
	         --find period	         
	         SELECT CAST(a.DebutPeriod AS DATETIME) AS DebutPeriod
	               ,CAST(DATEADD(DAY ,1 ,a.FinPeriod) AS DATETIME) AS FinPeriod
	         FROM   report.RefPeriodeOwnerDB_Num a
	         WHERE  IdPeriode = @IdPeriod
	     )
	     
	     , abosByMarques AS (
	         -- filter abos
	         SELECT a.AbonnementID
	         FROM   dbo.Abonnements a
	                INNER JOIN ref.V_Typologies t
	                     ON  a.Typologie = t.CodeValN
	         WHERE  a.Marque IN (SELECT VALUE
	                             FROM   @MarqueList) -- by marques,
	                AND t.Valeur LIKE N'CSNP%' ---digital, paid
	     )
	     
	     ,reccurentAbos AS (
	         SELECT a.*
	         FROM   dbo.Abonnements a
	                INNER JOIN abosByMarques am
	                     ON  a.AbonnementID = am.AbonnementID
	                INNER JOIN ref.CatalogueAbonnements AS ca
	                     ON  a.CatalogueAbosID = ca.CatalogueAbosID
	                         AND ca.Recurrent = 1
	                INNER JOIN period
	                     ON  (
	                             a.FinAboDate BETWEEN period.DebutPeriod AND 
	                             period.FinPeriod
	                         )
	         OR (
	                a.ReaboDate BETWEEN period.DebutPeriod AND period.FinPeriod
	            )
	     )
	     ,tacitesReconductions AS (--Tacites reconductions 
	         SELECT COUNT(AbonnementID) AS cnt
	         FROM   reccurentAbos
	     )
	     ,x1 AS (--% ?checs pr?l?vement 
	         SELECT COUNT(AbonnementID)  AS cnt
	         FROM   reccurentAbos r
	                INNER JOIN period    AS p
	                     ON  r.AnnulationDate BETWEEN p.DebutPeriod AND p.FinPeriod
	         WHERE  r.SubscriptionStatusID = 4 --Cancelled By AutoRenew Process
	     )
	     ,x2 AS (--% Annulations
	         SELECT COUNT(AbonnementID)     cnt
	         FROM   reccurentAbos r
	                INNER JOIN period    AS p
	                     ON  r.AnnulationDate BETWEEN p.DebutPeriod AND p.FinPeriod
	         WHERE  r.SubscriptionStatusID IN (5 ,3 ,1)	--Cancelled By User, Expired Subscription, Cancelled By Customer Support Agent
	                AND r.ReaboDate IS NULL --
	     ) 
	     , percents AS (
	         SELECT t.cnt                 AS val
	               ,CASE t.cnt
	                     WHEN 0 THEN 0
	                     ELSE ISNULL(x1.cnt ,0) / t.cnt * 100
	                END                   AS p1
	               ,CASE t.cnt
	                     WHEN 0 THEN 0
	                     ELSE ISNULL(x2.cnt ,0) / t.cnt * 100
	                END                   AS p2
	         FROM   tacitesReconductions     t
	               ,x1
	               ,x2
	     )
	     ,result AS (
	         SELECT N'Tacites reconductions' AS label
	               ,val  AS ValeurFloat
	               ,1    AS NumOrder
	         FROM   percents
	         UNION ALL
	         SELECT N'% ?checs pr?l?vement' AS label
	               ,p1  AS ValeurFloat
	               ,2   AS NumOrder
	         FROM   percents
	         UNION ALL
	         SELECT N'% Annulations'   AS label
	               ,p2                 AS ValeurFloat
	               ,3                  AS NumOrder
	         FROM   percents
	     )
	
	INSERT report.DashboardAboNumerique
	  (
	    Periode
	   ,IdPeriode
	   ,IdOwner
	   ,IdTemplate
	   ,SnapshotDate
	   ,IdGraph
	   ,Editeur
	   ,Libelle
	   ,NumOrdre
	   ,ValeurFloat
	  )
	SELECT @Period        AS Periode
	      ,@IdPeriod      AS IdPeriode
	      ,@IdOwner       AS IdOwner
	      ,@IdTemplate    AS IdTemplate
	      ,@SnapshotDate  AS SnapshotDate
	      ,@IdGraph       AS IdGraph
	      ,@Editeur       AS Editeur
	      ,r.label        AS Libelle
	      ,r.NumOrder
	      ,r.ValeurFloat  AS ValeurFloat
	FROM   result            r
	ORDER BY
	       r.NumOrder
END
       