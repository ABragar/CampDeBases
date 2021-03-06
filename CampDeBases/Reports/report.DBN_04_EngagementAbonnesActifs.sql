﻿ALTER PROC [report].[DBN_04_EngagementAbonnesActifs] (@Editeur NVARCHAR(8) ,@P NVARCHAR(30))
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
	ClientID nvarchar(18) not null
	, WebSiteID nvarchar(18) not null
	, Marque int null
	, MasterID int null
	, OS nvarchar(255) null
	, DateMin date null
	, DateMax date null
	, MobileOS bit null
	, WebFixeOS bit null
	)
	
	insert #T_ClientID_MasterID (ClientID, WebSiteID, OS, DateMin, DateMax)
		select a.ClientID, a.SiteID, a.OS, min(cast(a.SessionDebut as date)), max(cast(a.SessionDebut as date))
			from import.Xiti_Sessions a 
			where cast(a.SessionDebut as date)>=dateadd(week,-3,@DebutPeriod) 
			group by a.ClientID, a.SiteID, a.OS
			
			create index idx_01_T_ClientID_MasterID on #T_ClientID_MasterID (ClientID)
			create index idx_02_T_ClientID_MasterID on #T_ClientID_MasterID (WebSiteID)
			create clustered index idx_03_T_ClientID_MasterID on #T_ClientID_MasterID (DateMin,DateMax)
	
	update a 
			set a.Marque=b.Marque
			from #T_ClientID_MasterID a
			inner join ref.SitesWeb b on a.WebSiteID=b.WebSiteID		
			
	update a 
		set a.MasterID=c.MasterID
		from #T_ClientID_MasterID a 
		inner join 
		(select rank() over (partition by b.sIdCompte order by cast(b.ActionID as int) desc, b.ImportID desc) as N1
		, b.sIdCompte
		, b.iRecipientId
		from import.NEO_CusCompteEFR b where b.LigneStatut<>1)  as b on a.ClientID=b.sIdCompte
		inner join brut.Contacts c on b.iRecipientId=c.OriginalID and c.SourceID=1
		where a.Marque in (7) -- EQ
		and b.N1=1
	
	update a 
		set a.MasterID=c.MasterID
		from #T_ClientID_MasterID a 
		inner join 
		(select rank() over (partition by b.sIdCompte order by cast(b.ActionID as int) desc, b.ImportID desc) as N1
		, b.sIdCompte
		, b.iRecipientId
		from import.NEO_CusCompteFF b where b.LigneStatut<>1)  as b on a.ClientID=b.sIdCompte
		inner join brut.Contacts c on b.iRecipientId=c.OriginalID and c.SourceID=1	
		where a.Marque in (3) -- FF
	
	update a 
		set a.MasterID=c.MasterID
		from #T_ClientID_MasterID a 
		inner join import.SSO_Cumul b on a.ClientID=b.id_SSO
		inner join brut.Contacts c on b.email_origine=c.OriginalID and c.SourceID=2	
		where a.Marque in (2,6,9) -- AF, LP, LP Mag
		
	delete a from #T_ClientID_MasterID a 
		where a.MasterID is null
		
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
	     
	     , abosByMarques AS (
	         -- filter abos
	         SELECT a.MasterId
	         FROM   dbo.Abonnements a
	                INNER JOIN ref.CatalogueAbonnements b
	                     ON  a.CatalogueAbosID = b.CatalogueAbosID
	         WHERE  a.MontantAbo>0.00 /* Payant */
						and	b.SupportAbo=1	 /* Numérique */
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
	         SELECT s.ClientID
					, s.DateMax
					, s.DateMin
					, s.Marque
					, s.MasterID
					, s.OS
					, s.WebSiteID
					, s.MobileOS
					, s.WebFixeOS
	         FROM   #T_ClientID_MasterID s
	                INNER JOIN sitebyMarques sm
	                     ON  s.WebSiteID = sm.WebSiteID
	     ) 
	     
	     ,Filtered4week AS (
	         --get 4 week period
	         SELECT s.ClientID
					, s.DateMax
					, s.DateMin
					, s.Marque
					, s.MasterID
					, s.OS
					, s.WebSiteID
					, s.MobileOS
					, s.WebFixeOS
	         FROM   SessionsPremiumByMarques s
	                INNER JOIN period4week AS p
	                     ON  (s.DateMin >= p.DebutPeriod AND s.DateMax < p.FinPeriod)
	     ) 
	     
	     ,SessionsPremiumAbos AS (
	         --apply filter abosByMarques  
	         SELECT f.ClientID
					, f.DateMax
					, f.DateMin
					, f.Marque
					, f.MasterID
					, f.OS
					, f.WebSiteID
					, f.MobileOS
					, f.WebFixeOS
	         FROM   Filtered4week f
	                INNER JOIN abosByMarques am
	                     ON  f.MasterID = am.MasterId
	     ) 
	     
	     , access1week AS (
	         --1 week
	         SELECT sp.MasterID
	         FROM   SessionsPremiumAbos sp
	                INNER JOIN period1week AS p
	                     ON  (sp.DateMax >= p.DebutPeriod AND sp.DateMax < p.FinPeriod)
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
	         WHERE  a.WebFixeOS=1
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
	                    FROM   SessionsPremiumAbos x1
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
