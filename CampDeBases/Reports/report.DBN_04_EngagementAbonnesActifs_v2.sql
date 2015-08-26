USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [report].[DBN_04_EngagementAbonnesActifs]    Script Date: 25/08/2015 17:45:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [report].[DBN_04_EngagementAbonnesActifs] (@Editeur NVARCHAR(8) ,@P NVARCHAR(30))
AS
-- =============================================
-- Author:		Andrey Bragar
-- Creation date: 29/04/2015
-- Description:	Calcul du Dashboard Abos Numeriques 
--				NÂ°4
--				ENGAGEMENT ABONNES ACTIFS
-- Modiification date : 23/06/2015
-- Modified by : Anatoli VELITCHKO
-- Modification : 1) Ajout de la marque "Le Parisien Magazine"
--			2) Remplacement de Typologie par une condition équivalente calculée 
--			3) Utilisation de la table import.Xiti_Sessions
-- Modiification date : 21/08/2015
-- Modified by : Andrey Bragar
-- Modification : change import.Xiti_Sessions by etl.VisitesWeb 
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
	      (7) /* L'Equipe */
	    
	    SET @IdTemplate = @IdTemplate_Num_EQ
	END
	ELSE
	IF @Editeur = N'FF'
	BEGIN
	    INSERT INTO @MarqueList
	    VALUES
	      (3) /* France Football */
	    
	    SET @IdTemplate = @IdTemplate_Num_FF
	END
	ELSE
	IF @Editeur = N'LP'
	BEGIN
	    INSERT INTO @MarqueList
	    VALUES
	      (6) /* Le Parisien */
	      ,(2) /* Aujourd'hui en France */
	      ,(9) /* Le Parisien Magazine */
	          
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

	DECLARE @FinPeriod AS DATETIME
	SELECT @FinPeriod = FinPeriod
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
	       AND Editeur = @Editeur 

	       
	set dateformat ymd
	
	if object_id(N'tempdb..#T_ClientID_MasterID') is not null
		drop table #T_ClientID_MasterID
			
	create table #T_ClientID_MasterID
	(
	--ClientID nvarchar(18) not null
	 WebSiteID nvarchar(18) not null
	, Marque int null
	, MasterID int null
	, DateMin date null
	, DateMax date null
	, MobileOS bit null
	)
	
	insert #T_ClientID_MasterID (MasterID, WebSiteID, Marque, MobileOS, DateMin, DateMax)
		select a.MasterID, a.SiteID, sw.Marque , case when a.CodeOS is null then 0 else 1 end, min(cast(a.DateVisite as date)), max(cast(a.DateVisite as date))
		FROM etl.VisitesWeb	 a
--		LEFT JOIN ref.Misc AS m ON m.RefID = a.CodeOS
		INNER JOIN ref.SitesWeb AS sw ON a.SiteId = sw.WebSiteID 
			where cast(a.DateVisite as date)>=dateadd(week,-3,@DebutPeriod) and cast(a.DateVisite as date) <= @FinPeriod
			group by a.MasterID, a.SiteID, case when a.CodeOS is null then 0 else 1 end, sw.Marque
			
			create index idx_02_T_ClientID_MasterID on #T_ClientID_MasterID (WebSiteID)
			create clustered index idx_03_T_ClientID_MasterID on #T_ClientID_MasterID (DateMin,DateMax)
	
/*
	update a 
		set a.MobileOS=
		(case when a.OS like N'Android%' 
			or a.OS like N'BlackBerry%'
			or a.OS like N'iOS%'
			or a.OS like N'Windows Phone%'
			then 1
			else 0
		end)
		from #T_ClientID_MasterID a

	update a 
		set a.WebFixeOS=~(a.MobileOS) /* WebFixeOS = l'inverse de MobileOS */
		from #T_ClientID_MasterID a
			
	
		;	WITH period1week AS (
	         --find period	1 week         
	         SELECT CAST(a.DebutPeriod AS DATETIME) AS DebutPeriod
	               ,CAST(DATEADD(DAY ,1 ,a.FinPeriod) AS DATETIME) AS FinPeriod
	         FROM   report.RefPeriodeOwnerDB_Num a
	         WHERE  IdPeriode = @IdPeriod
	     )
	     
	     ,period4week AS (
	         SELECT DATEADD(week,-3,p1.DebutPeriod) AS DebutPeriod
	               ,p1.FinPeriod
	         FROM  period1week p1
	     )
  */
    
	     ; WITH abosByMarques AS (
	         -- filter abos
	         SELECT a.MasterId
	         FROM   dbo.Abonnements a
	                INNER JOIN ref.CatalogueAbonnements b
	                     ON  a.CatalogueAbosID = b.CatalogueAbosID
	         WHERE  a.MontantAbo>0.00 /* Payant */
						and	b.SupportAbo=1	 /* Numérique */
						and (a.DebutAboDate <= @FinPeriod AND a.FinAboDate >= DATEADD(week,-3,@DebutPeriod))
						and a.Marque IN (SELECT VALUE
	                             FROM   @MarqueList)	  
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
	         -- filter sessions by sites
	         SELECT s.DateMax
					, s.DateMin
					, s.Marque
					, s.MasterID
					, s.WebSiteID
					, s.MobileOS
	         FROM   #T_ClientID_MasterID s
	                INNER JOIN sitebyMarques sm
	                     ON  s.WebSiteID = sm.WebSiteID
	     ) 
	     
	     ,Filtered4week AS (
	         --get 4 week period
	         SELECT s.DateMax
					, s.DateMin
					, s.Marque
					, s.MasterID
					, s.WebSiteID
					, s.MobileOS
	         FROM   SessionsPremiumByMarques s
	         WHERE s.DateMin >= DATEADD(week,-3,@DebutPeriod) AND s.DateMax <= @FinPeriod
	     ) 
	     
	     ,SessionsPremiumAbos AS (
	         --apply filter abosByMarques  
	         SELECT f.DateMax
					, f.DateMin
					, f.Marque
					, f.MasterID
					, f.WebSiteID
					, f.MobileOS
	         FROM   Filtered4week f
	                INNER JOIN abosByMarques am
	                     ON  f.MasterID = am.MasterId
	     ) 
	     
	     , access1week AS (
	         --1 week
	         SELECT sp.MasterID
	         FROM   SessionsPremiumAbos sp
			 WHERE sp.DateMax  >= @DebutPeriod and sp.DateMax <= @FinPeriod 
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
	                    WHERE  a.MobileOS =1
	                ) x
	         GROUP BY
	                x.masterID
	     )
	     , WebFixeOS AS (
	         SELECT masterID
	         FROM   SessionsPremiumAbos a
	         WHERE  a.MobileOS=0
	         GROUP BY
	                masterID
	     )
	     ,MultiScreen AS (
	         SELECT mobileOS.masterID
	         FROM   mobileOS
	                INNER JOIN WebFixeOS
	                     ON  mobileOS.masterID = WebFixeOS.masterID
	     )
	     , counts AS 
	     (
	         SELECT SUM(ACTIVE) AS ACTIVE
	               ,SUM(week1)        AS week1
	               ,SUM(week4)        AS week4
	               ,SUM(MultiScreen)  AS MultiScreen
	         FROM   (
	                    SELECT COUNT(x1.MasterID) AS ACTIVE
	                          ,0  AS week1
	                          ,0  AS week4
	                          ,0  AS MultiScreen
	                    FROM   abosByMarques x1
	                    UNION ALL 
	                    SELECT 0
	                          ,COUNT(x2.MasterID)
	                          ,0
	                          ,0 --
	                    FROM   access1week x2
	                    UNION ALL
	                    SELECT 0
	                          ,0
	                          ,COUNT(x3.MasterID)
	                          ,0
	                    FROM   access4week x3
	                    UNION ALL
	                    SELECT 0
	                          ,0
	                          ,0
	                          ,COUNT(x4.MasterId)
	                    FROM   MultiScreen x4
	                )                    x
	     )
	     , res AS
	     (
	         SELECT 1    AS NumOrder
	               ,N'Accès à 1 semaine' AS label
	               ,CASE ACTIVE
	                     WHEN 0 THEN 0
	                     ELSE CAST(week1 AS FLOAT) / ACTIVE
	                END     ValeurFloat
	         FROM   counts
	         UNION ALL
	         SELECT 2
	               ,N'Accès à 4 semaines'
	               ,CASE ACTIVE
	                     WHEN 0 THEN 0
	                     ELSE CAST(week4 AS FLOAT) / ACTIVE
	                END
	         FROM   counts
	         UNION ALL
	         SELECT 3
	               ,N'Multi-screen'
	               ,CASE ACTIVE
	                     WHEN 0 THEN 0
	                     ELSE CAST(MultiScreen AS FLOAT) / ACTIVE
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
	FROM   res            r
	ORDER BY
	       r.NumOrder
		   
END
       

