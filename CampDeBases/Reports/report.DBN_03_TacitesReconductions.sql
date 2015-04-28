USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [report].[DB_7_NouvAbos]    Script Date: 04/20/2015 16:28:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--create proc [report.DBN_03_TacitesReconductions] (@Editeur NVARCHAR(8), @P nvarchar(30))
--as 
--begin 
-- =============================================
-- Author:		Andrey Bragar
-- Creation date: 28/04/2015
-- Description:	Calcul du Dashboard Abos Num?riques 
--				N°1
--				DUREE DE VIE ABONNEMENTS
-- Modiification date :
-- Modified by :
-- Modification :
-- =============================================
DECLARE @Editeur NVARCHAR(8) = N'EQ'
DECLARE @P NVARCHAR(30) = N'Semaine_24_2014'

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
	
	SET @IdGraph = 1
	
	SET NOCOUNT ON
	
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
	FROM   report.RefPeriodeOwnerDB
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
	WITH abosByMarques AS (
	         -- filter abos 
	         SELECT a.AbonnementID
	               ,CASE a.StatutAbo
	                     WHEN 2 THEN N'Echu'
	                     WHEN 3 THEN N'En cours'
	                END                AS statusAbonements
	         FROM   dbo.Abonnements a
	                INNER JOIN ref.V_Typologies t
	                     ON  a.Typologie = t.CodeValN
	         WHERE  a.Marque IN (SELECT VALUE
	                             FROM   @MarqueList)
	                AND t.Valeur LIKE     N'CSNP%' ---digital, paid
	     )
	     
	     ,abosWithPeriods AS --calculate duration of the abonements 
	     (
	         SELECT a.AbonnementID
	               ,aa.statusAbonements
	               ,DATEDIFF(MONTH ,a.DebutAboDate ,COALESCE(a.FinAboDate ,GETDATE())) AS -- use current date, if finDate is null
	                duration
	         FROM   Abonnements AS a
	                INNER JOIN abosByMarques aa
	                     ON  a.AbonnementID = aa.AbonnementID
	         WHERE  statusAbonements IS NOT NULL
	     )
	     
	     ,namePeriods AS (
	         SELECT 1             AS NumOrder
	               ,N'< 2 mois'   AS Label
	         UNION ALL
	         SELECT 2 AS durationID
	               ,N'3 – 4 mois'
	         UNION ALL
	         SELECT 3
	               ,N'5 – 8 mois'
	         UNION ALL
	         SELECT 4
	               ,N'9 – 12 mois' 
	         UNION ALL
	         SELECT 5
	               ,N'13 – 24 mois' 
	         UNION ALL
	         SELECT 6
	               ,N'25 – 36 mois' 
	         UNION ALL
	         SELECT 7
	               ,N'> 36 mois'
	     )
	     ,formattedPeriods AS(
	         SELECT AbonnementID
	               ,statusAbonements
	               ,CASE 
	                     WHEN duration <= 2 THEN 1--N'< 2 mois'
	                     WHEN duration BETWEEN 3
	         AND 4 THEN 2 --N'3 – 4 mois'
	             WHEN duration BETWEEN 5 AND 8 THEN 3--	N'5 – 8 mois'
	             WHEN duration BETWEEN 9 AND 12 THEN 4--N'9 – 12 mois'
	             WHEN duration BETWEEN 13 AND 24 THEN 5--N'13 – 24 mois'
	             WHEN duration BETWEEN 25 AND 36 THEN 6-- N'25 – 36 mois'
	             WHEN duration > 36 THEN 7--N'> 36 mois'
	             END AS NumOrder
	             FROM abosWithPeriods AS p
	     )
	     , result AS (
	         SELECT COUNT(AbonnementID) AS cntValue
	               ,statusAbonements
	               ,fp.NumOrder
	               ,label
	         FROM   formattedPeriods fp
	                INNER JOIN namePeriods np
	                     ON  fp.NumOrder = np.NumOrder
	         GROUP BY
	                statusAbonements
	               ,fp.NumOrder
	               ,label
	     )
	
	
	--insert report.DashboardAboNumerique
	--(
	--Periode
	--, IdPeriode
	--, IdOwner
	--, IdTemplate
	--, SnapshotDate
	--, IdGraph
	--, Editeur
	--, Libelle
	--, NumOrdre
	--, ValeurFloat
	--, ValeurChar
	--)
	SELECT @Period             AS Periode
	      ,@IdPeriod           AS IdPeriode
	      ,@IdOwner            AS IdOwner
	      ,@IdTemplate         AS IdTemplate
	      ,@SnapshotDate       AS SnapshotDate
	      ,@IdGraph            AS IdGraph
	      ,@Editeur            AS Editeur
	      ,r.label             AS Libelle
	      ,r.NumOrder
	      ,r.cntValue          AS ValeurFloat
	      ,r.statusAbonements  AS ValeurChar
	FROM   result                 r
	ORDER BY
	       r.NumOrder, r.statusAbonements
--end
       