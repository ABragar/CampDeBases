/************************************************************
 * Code formatted by SoftTree SQL Assistant © v7.1.246
 * Time: 23.04.2015 15:02:37
 ************************************************************/

USE [AmauryVUC] 
GO
/****** Object:  StoredProcedure [report].[DB_1_CA_Annuel]    Script Date: 23.04.2015 13:54:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [report].[DB_1_CA_Annuel] (@Appartenance INT ,@P NVARCHAR(30))
AS 
BEGIN
	SET NOCOUNT ON
	
	-- @Appartenance : 1 = EQ, 2 = LP, 3 = Groupe
	
	--declaration of variables		
	BEGIN
		DECLARE @Period AS NVARCHAR(30)
		DECLARE @IdPeriod AS UNIQUEIDENTIFIER
		DECLARE @IdGraph AS INT
		DECLARE @SnapshotDate AS DATETIME
		DECLARE @IdOwner AS UNIQUEIDENTIFIER
		DECLARE @IdTemplate AS UNIQUEIDENTIFIER
		
		DECLARE @Progression     AS FLOAT
		DECLARE @PrecPeriod      AS NVARCHAR(30)
	END	
	--Init variables
	BEGIN
		SET @Period = @P
		SET @SnapshotDate = GETDATE()
		SET @IdGraph = 1
		SET @IdTemplate = '4EC12A95-0587-46C1-9BE5-4C2FCF5DF337' -- donnee de Kayak
	END	
	--Init @IdPeriod, @IdOwner
	BEGIN
		SELECT @IdPeriod = IdPeriode
		FROM   report.RefPeriodeOwnerDB
		WHERE  Periode              = @Period --week
		       AND Appartenance     = @Appartenance
		       AND IdTemplate       = @IdTemplate
		
		SELECT @IdOwner = IdOwner
		FROM   report.RefPeriodeOwnerDB
		WHERE  Periode              = @Period
		       AND Appartenance     = @Appartenance
		       AND IdTemplate       = @IdTemplate
	END
	
	
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
	
	DELETE report.DashboardMetier
	WHERE  Periode = @Period
	       AND IdGraph = @IdGraph
	       AND Appartenance = @Appartenance
	
	; 
	WITH sa AS (
	         SELECT a.AbonnementID
	         FROM   AmauryVUC.dbo.Abonnements a
	         WHERE  a.Appartenance IN (1 & @Appartenance ,2 & @Appartenance)
	     )
	     
	     , y AS (
	         SELECT DATEADD(YEAR ,-1 ,@DebutPeriod) AS IlyaUnAn
	                --from report.DouzeDerniersMois a
	     )
	     
	     , sb AS (
	         SELECT a.AchatID
	         FROM   AmauryVUC.dbo.AchatsALActe a
	         WHERE  a.Appartenance IN (1 & @Appartenance ,2 & @Appartenance)
	     )
	     
	     , ra AS (
	         SELECT a.AbonnementID
	               ,a.DebutAboDate
	               ,a.FinAboDate
	               ,a.DureeMois
	               ,a.MontantAbo
	               ,a.SupportAbo
	         FROM   AmauryVUC.report.AboStatsPayants a
	                INNER JOIN sa
	                     ON  a.AbonnementID = sa.AbonnementID
	     )
	     
	     , rb AS (
	         SELECT a.AchatID
	               ,a.AchatDate
	               ,a.MontantAchat
	         FROM   AmauryVUC.dbo.AchatsALActe a
	                INNER JOIN sb
	                     ON  a.AchatID = sb.AchatID
	                         AND a.MontantAchat > 0.00
	     )
	     
	     , m AS (
	         SELECT a.AbonnementID
	               ,a.MasterID
	               ,a.ModeExpedition
	               ,a.SupportAbo
	               ,a.isCouple
	               ,m.Mois
	         FROM   AmauryVUC.report.AboStats a
	                INNER JOIN sa
	                     ON  a.AbonnementID = sa.AbonnementID
	                CROSS JOIN AmauryVUC.report.DouzeDerniersMois m
	     )
	     
	     , w AS 
	     (
	         SELECT m.Mois
	               ,b.AbonnementID
	               ,m.ModeExpedition
	               ,m.SupportAbo
	               ,m.isCouple
	               ,CASE 
	                     WHEN b.FinAboDate IS NULL
	         AND b.DebutAboDate >= m.Mois THEN c.MontantAbo
	             ELSE
	             CAST(
	                 COALESCE(
	                     b.MontantAbo / (
	                         ROUND(
	                             CASE 
	                                  WHEN COALESCE(
	                                           CAST(DATEDIFF(DAY ,b.DebutAboDate ,b.FinAboDate) AS FLOAT)
	                                           / 30.42
	                                          ,1
	                                       ) < 1 THEN 1
	                                  ELSE COALESCE(
	                                           CAST(DATEDIFF(DAY ,b.DebutAboDate ,b.FinAboDate) AS FLOAT)
	                                           / 30.42
	                                          ,1
	                                       )
	                             END
	                            ,0
	                         )
	                     )
	                    ,0.00
	                 )
	                 AS NUMERIC(10 ,2)
	             ) END
	             AS CA_Mensuel
	        ,b.DebutAboDate
	        ,b.FinAboDate
	         FROM m INNER JOIN AmauryVUC.dbo.Abonnements b ON b.AbonnementID = m.AbonnementID
	         INNER JOIN AmauryVUC.ref.CatalogueAbonnements c ON b.CatalogueAbosID
	         = c.CatalogueAbosID
	         WHERE b.DebutAboDate < DATEADD(MONTH ,1 ,m.Mois)
	         AND COALESCE(b.FinAboDate ,N'01-01-2079') >= m.Mois
	     )
	     
	     , x AS
	     (
	         SELECT w.Mois
	               ,SUM(w.CA_Mensuel) AS CA_Mensuel
	         FROM   w
	         GROUP BY
	                w.Mois
	     )
	     
	     /*
	     , y as (
	     select min(a.Mois) as IlyaUnAn
	     from report.DouzeDerniersMois a
	     )
	     */
	     
	     
	     -- Achats :
	     
	     , j AS (
	         SELECT SUM(a.MontantAchat)  AS Montant_Annuel_Achat
	         FROM   rb                   AS a
	         WHERE  a.AchatDate >= (
	                    SELECT IlyaUnAn
	                    FROM   y
	                )
	     )
	     
	     -- select * from j
	     
	     , k AS (
	         SELECT SUM(a.CA_Mensuel)  AS CA_Annuel_Abo
	         FROM   x                  AS a
	         WHERE  a.Mois >= (
	                    SELECT IlyaUnAn
	                    FROM   y
	                )
	     )
	     
	     , t AS (
	         SELECT (
	                    (
	                        SELECT COALESCE(a.CA_Annuel_Abo ,0.00)
	                        FROM   k AS a
	                    ) + (
	                        SELECT COALESCE(a.Montant_Annuel_Achat ,0.00)
	                        FROM   j AS a
	                    )
	                ) AS CA_Annuel_Abos_Achats
	     )
	
	INSERT report.DashboardMetier
	  (
	    Periode
	   ,IdPeriode
	   ,IdOwner
	   ,IdTemplate
	   ,SnapshotDate
	   ,IdGraph
	   ,Appartenance
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
	      ,@Appartenance  AS Appartenance
	      ,a.NomGraph     AS Libelle
	      ,1              AS NumOrdre
	      ,t.CA_Annuel_Abos_Achats / 1000 AS ValeurFloat -- K€
	FROM   t
	       CROSS JOIN report.RefGraphDashboard a
	WHERE  a.IdGraph = @IdGraph
	
	SELECT @Progression = CASE 
	                           WHEN a.ValeurFloat = 0 OR COALESCE(b.ValeurFloat ,0)
	                                = 0 THEN 0.00
	                           ELSE -(
	                                    1 -(
	                                        a.ValeurFloat / COALESCE(
	                                            CASE 
	                                                 WHEN b.ValeurFloat = 0 THEN 
	                                                      1.00
	                                                 ELSE b.ValeurFloat
	                                            END
	                                           ,CASE 
	                                                 WHEN a.ValeurFloat = 0 THEN 
	                                                      1.00
	                                                 ELSE a.ValeurFloat
	                                            END
	                                        )
	                                    )
	                                )
	                      END
	FROM   report.DashboardMetier a
	       LEFT OUTER JOIN report.DashboardMetier b
	            ON  a.IdGraph = b.IdGraph
	                AND a.NumOrdre = b.NumOrdre
	                AND a.Appartenance = b.Appartenance
	                AND b.Periode = @PrecPeriod
	WHERE  a.Periode = @Period
	       AND a.IdGraph = @IdGraph
	       AND a.NumOrdre = 1
	       AND a.Appartenance = @Appartenance
	
	INSERT report.DashboardMetier
	  (
	    Periode
	   ,IdPeriode
	   ,IdOwner
	   ,IdTemplate
	   ,SnapshotDate
	   ,IdGraph
	   ,Appartenance
	   ,Libelle
	   ,NumOrdre
	   ,ValeurFloat
	  )
	VALUES
	  (
	    @Period
	   ,@IdPeriod
	   ,@IdOwner
	   ,@IdTemplate
	   ,@SnapshotDate
	   ,@IdGraph
	   ,@Appartenance
	   ,NULL
	   ,2
	   ,@Progression
	  )
	
	-- Calcul de la tendance sur 5 dernieres semaines
	
	IF OBJECT_ID(N'tempdb..#T_Taux_Variation') IS NOT NULL
	    DROP TABLE #T_Taux_Variation
	
	CREATE TABLE #T_Taux_Variation
	(
		Periode         NVARCHAR(30) NULL
	   ,ValeurFloat     FLOAT NULL
	)
	
	TRUNCATE TABLE #T_Taux_Variation
	
	DECLARE @PeriodeP_5 NVARCHAR(30)
	DECLARE @PeriodeP_4 NVARCHAR(30)
	DECLARE @PeriodeP_3 NVARCHAR(30)
	DECLARE @PeriodeP_2 NVARCHAR(30)
	DECLARE @PeriodeP_1 NVARCHAR(30)
	
	SET @PeriodeP_5 = N'Semaine_' + RIGHT(
	        N'00' + CAST(
	            DATEPART(week ,DATEADD(week ,-4 ,@DebutPeriod)) AS NVARCHAR(2)
	        )
	       ,2
	    ) + N'_' + CAST(
	        DATEPART(YEAR ,DATEADD(week ,-4 ,@DebutPeriod)) AS NVARCHAR(4)
	    )
	
	SET @PeriodeP_4 = N'Semaine_' + RIGHT(
	        N'00' + CAST(
	            DATEPART(week ,DATEADD(week ,-3 ,@DebutPeriod)) AS NVARCHAR(2)
	        )
	       ,2
	    ) + N'_' + CAST(
	        DATEPART(YEAR ,DATEADD(week ,-3 ,@DebutPeriod)) AS NVARCHAR(4)
	    )
	
	SET @PeriodeP_3 = N'Semaine_' + RIGHT(
	        N'00' + CAST(
	            DATEPART(week ,DATEADD(week ,-2 ,@DebutPeriod)) AS NVARCHAR(2)
	        )
	       ,2
	    ) + N'_' + CAST(
	        DATEPART(YEAR ,DATEADD(week ,-2 ,@DebutPeriod)) AS NVARCHAR(4)
	    )
	
	SET @PeriodeP_2 = N'Semaine_' + RIGHT(
	        N'00' + CAST(
	            DATEPART(week ,DATEADD(week ,-1 ,@DebutPeriod)) AS NVARCHAR(2)
	        )
	       ,2
	    ) + N'_' + CAST(
	        DATEPART(YEAR ,DATEADD(week ,-1 ,@DebutPeriod)) AS NVARCHAR(4)
	    )
	
	SET @PeriodeP_1 = @Period
	
	INSERT #T_Taux_Variation
	  (
	    Periode
	   ,ValeurFloat
	  )
	SELECT Periode
	      ,ValeurFloat
	FROM   report.DashboardMetier a
	WHERE  a.IdGraph = @IdGraph
	       AND a.NumOrdre = 2 -- Taux de variation
	       AND a.Periode IN (@PeriodeP_5
	                        ,@PeriodeP_4
	                        ,@PeriodeP_3
	                        ,@PeriodeP_2
	                        ,@PeriodeP_1)
	       AND a.Appartenance = @Appartenance
	
	DECLARE @MoyenneTaux FLOAT
	DECLARE @EcartType FLOAT
	DECLARE @MinIntervalle FLOAT
	DECLARE @MaxIntervalle FLOAT
	DECLARE @TauxCourant FLOAT
	DECLARE @Tendance FLOAT
	
	SELECT @MoyenneTaux = AVG(a.ValeurFloat)
	FROM   #T_Taux_Variation a
	
	SELECT @EcartType = STDEV(a.ValeurFloat)
	FROM   #T_Taux_Variation a
	
	IF OBJECT_ID(N'tempdb..#T_Taux_Variation') IS NOT NULL
	    DROP TABLE #T_Taux_Variation
	
	SET @MoyenneTaux = COALESCE(@MoyenneTaux ,0.00)
	SET @EcartType = COALESCE(@EcartType ,0.00)
	
	SET @MinIntervalle = @MoyenneTaux -@EcartType
	SET @MaxIntervalle = @MoyenneTaux + @EcartType
	
	SELECT @TauxCourant = ValeurFloat
	FROM   report.DashboardMetier a
	WHERE  a.IdGraph = @IdGraph
	       AND a.NumOrdre = 2 -- Taux de variation
	       AND a.Periode = @PeriodeP_1
	       AND a.Appartenance = @Appartenance
	
	SET @Tendance = CASE 
	                     WHEN COALESCE(@TauxCourant ,0.00) < @MinIntervalle THEN 
	                          -1 -- Negative
	                     WHEN COALESCE(@TauxCourant ,0.00) > @MaxIntervalle THEN 
	                          1 -- Positive
	                     ELSE 0 -- Neutre
	                END
	
	INSERT report.DashboardMetier
	  (
	    Periode
	   ,IdPeriode
	   ,IdOwner
	   ,IdTemplate
	   ,SnapshotDate
	   ,IdGraph
	   ,Appartenance
	   ,Libelle
	   ,NumOrdre
	   ,ValeurFloat
	  )
	VALUES
	  (
	    @Period
	   ,@IdPeriod
	   ,@IdOwner
	   ,@IdTemplate
	   ,@SnapshotDate
	   ,@IdGraph
	   ,@Appartenance
	   ,N'Tendance'
	   ,3
	   ,@Tendance
	  )
	
	INSERT report.DashboardMetier
	  (
	    Periode
	   ,IdPeriode
	   ,IdOwner
	   ,IdTemplate
	   ,SnapshotDate
	   ,IdGraph
	   ,Appartenance
	   ,Libelle
	   ,NumOrdre
	   ,ValeurFloat
	  )
	VALUES
	  (
	    @Period
	   ,@IdPeriod
	   ,@IdOwner
	   ,@IdTemplate
	   ,@SnapshotDate
	   ,@IdGraph
	   ,@Appartenance
	   ,N'Moyenne Taux Variation'
	   ,4
	   ,@MoyenneTaux
	  )
	
	INSERT report.DashboardMetier
	  (
	    Periode
	   ,IdPeriode
	   ,IdOwner
	   ,IdTemplate
	   ,SnapshotDate
	   ,IdGraph
	   ,Appartenance
	   ,Libelle
	   ,NumOrdre
	   ,ValeurFloat
	  )
	VALUES
	  (
	    @Period
	   ,@IdPeriod
	   ,@IdOwner
	   ,@IdTemplate
	   ,@SnapshotDate
	   ,@IdGraph
	   ,@Appartenance
	   ,N'Ecart Type Taux Variation'
	   ,5
	   ,@EcartType
	  )
END
