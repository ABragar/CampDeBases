USE [AmauryVUC]
GO
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
--DECLARE @Editeur NVARCHAR(8) = N'EQ'
--DECLARE @P NVARCHAR(30) = N'Semaine_34_2014'
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
	
	
DECLARE @Period4 NVARCHAR(30)
DECLARE @IdPeriod4 AS UNIQUEIDENTIFIER
	
SELECT @Period4 = N'Semaine_' + RIGHT(
           N'00' + CAST(
               DATEPART(week ,DATEADD(week ,-3 ,@DebutPeriod)) AS NVARCHAR(2)
           )
          ,2
       ) + N'_' + CAST(
           DATEPART(YEAR ,DATEADD(week ,-3 ,@DebutPeriod)) AS NVARCHAR(4)
       )	
	
SELECT @IdPeriod4 = IdPeriode
FROM   report.RefPeriodeOwnerDB_Num
WHERE  Periode            = @Period4
       AND Editeur        = @Editeur
       AND IdTemplate     = @IdTemplate
	
DELETE report.DashboardAboNumerique
WHERE  Periode = @Period
       AND IdGraph = @IdGraph
       AND Editeur = @Editeur;
	
WITH period1week AS (
         --find period	1 week         
         SELECT CAST(a.DebutPeriod AS DATETIME) AS DebutPeriod
               ,CAST(DATEADD(DAY ,1 ,a.FinPeriod) AS DATETIME) AS FinPeriod
         FROM   report.RefPeriodeOwnerDB_Num a
         WHERE  IdPeriode = @IdPeriod
     )
     ,period4week AS (
         SELECT CAST(a.DebutPeriod AS DATETIME) AS DebutPeriod
               ,p1.FinPeriod
         FROM   report.RefPeriodeOwnerDB_Num a
               ,period1week p1
         WHERE  IdPeriode = @IdPeriod4
     )
     , abosByMarques AS (
         -- filter abos
         SELECT a.MasterId
         FROM   dbo.Abonnements a
                INNER JOIN ref.V_Typologies t
                     ON  a.Typologie = t.CodeValN
         WHERE  a.Marque IN (SELECT VALUE
                             FROM   @MarqueList) -- by marques,
                AND t.Valeur LIKE N'CSNP%' ---digital, paid
         GROUP BY
                MasterId
     )
     , sitebyMarques AS (
         --sites
         SELECT sw.WebSiteID
         FROM   ref.SitesWeb AS sw
         WHERE  sw.Marque IN (SELECT VALUE
                              FROM   @MarqueList)
     )
     
     ,SessionsPremiumByMarques AS(
         --filter sessions by sites
         SELECT *
         FROM   dbo.SessionsPremium s
                INNER JOIN sitebyMarques sm
                     ON  s.SiteWebID = sm.WebSiteID
     ) 
     
     ,Filtered4week AS (
         --get 4 week period
         SELECT s.* 
         FROM   SessionsPremiumByMarques s
                INNER JOIN period4week AS p
                     ON  (DateVisite >= p.DebutPeriod AND DateVisite < p.FinPeriod)
     ) 
     
     ,SessionsPremiumAbos AS (
         --apply filter abosByMarques  
         SELECT f.* 
         FROM   Filtered4week f
                INNER JOIN abosByMarques am
                     ON  f.MasterID = am.MasterId
     ) 
     
     , access1week AS (
         --1 week
         SELECT sp.MasterID
         FROM   SessionsPremiumAbos sp
                INNER JOIN period1week AS p
                     ON  (DateVisite >= p.DebutPeriod AND DateVisite < p.FinPeriod)
         GROUP BY
                sp.MasterID
     )
     
     , access4week AS (
         --4week
         SELECT sp.MasterID
         FROM   SessionsPremiumAbos sp
         GROUP BY
                sp.MasterID
     )
     
     ,mobileOS AS (
         -- MobileOS and TabletOS
         SELECT x.masterID
         FROM   (
                    SELECT masterID
                    FROM   SessionsPremiumAbos a
                    WHERE  a.CodeTabletteOS IS NULL
                           AND a.AutreOS IS NULL
                    UNION ALL
                    SELECT masterID
                    FROM   SessionsPremiumAbos a
                    WHERE  a.CodeTabletteOS IS NOT NULL
                ) x
         GROUP BY
                x.masterID
     )
     , AutreOS AS (
         SELECT masterID
         FROM   SessionsPremiumAbos a
         WHERE  a.AutreOS IS NOT NULL
         GROUP BY
                masterID
     )
     ,MultiScreen AS (
         SELECT mobileOS.masterID
         FROM   mobileOS
                INNER JOIN AutreOS
                     ON  mobileOS.masterID = AutreOS.masterID
     )
     , counts AS 
     (
         SELECT COUNT(x1.MasterID)   AS ACTIVE
               ,COUNT(x2.MasterID)   AS week1
               ,COUNT(x3.MasterID)   AS week4
               ,COUNT(x4.MasterId)   AS MultiScreen
         FROM   SessionsPremiumAbos     x1
               ,access1week             x2
               ,access4week             x3
               ,MultiScreen             x4
     )
     , result AS
     (
         SELECT 1                      AS NumOrder
               ,N'Acces – 1 semaine'   AS label
               ,CASE ACTIVE
                     WHEN 0 THEN 0
                     ELSE CAST(week1 AS FLOAT) / ACTIVE * 100
                END                       ValeurFloat
         FROM   counts
         UNION ALL
         SELECT 2
               ,N'Acces – 4 semaines'
               ,CASE ACTIVE
                     WHEN 0 THEN 0
                     ELSE CAST(week4 AS FLOAT) / ACTIVE * 100
                END
         FROM   counts
         UNION ALL
         SELECT 3
               ,N'Multi-screen'
               ,CASE ACTIVE
                     WHEN 0 THEN 0
                     ELSE CAST(MultiScreen AS FLOAT) / ACTIVE * 100
                END
         FROM   counts
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
       