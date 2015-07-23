USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [etl].[BuildTypologies]    Script Date: 07/02/2015 11:35:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [etl].[BuildTypologies]
AS

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 28/01/2014
-- Description:	Alimentation de la table dbo.Typologies
-- pour le recalcul quotidien de cette table
-- Modification date: 04/03/2014
-- Modifications :	Mise en place de nouvelles règles 
--					définies par Nadia Belnet et validées par Pablo Fourcat
-- Modification date: 22/07/2014
-- Modifications :	Typologie des abonnements
-- Modification date: 01/12/2014
-- Modifications :	prise en compte de SourceID=10 -- PVL
-- Modification date: 10/02/2015
-- Modifications :	suppression des futurs face aux actuels et nouveaux
-- Modification date :	06/07/2015
-- Modified by :		Andrei BRAGAR
-- Modifications : Add new typologies "Termines", "Visiteurs identifies" (VIMN,VIMA, VIMI) 
-- =============================================


BEGIN
	SET NOCOUNT ON
	
	DECLARE @SourceID_NEO INT
	DECLARE @SourceID_LPSSO INT
	DECLARE @SourceID_SDVP INT
	DECLARE @SourceID_LPPROSP INT
	DECLARE @SourceID_PVL INT
	
	SELECT @SourceID_NEO = 1 -- Neolane
	SELECT @SourceID_LPSSO = 2 -- LSSO LP
	SELECT @SourceID_SDVP = 3 -- SDVP
	SELECT @SourceID_LPPROSP = 4 -- Prospects LP
	SELECT @SourceID_PVL = 10 -- Vente en ligne
	
	-- Creation de table temporaire
	
	IF OBJECT_ID('tempdb..#T_Lignes_Typologies') IS NOT NULL
	    DROP TABLE #T_Lignes_Typologies
	
	CREATE TABLE #T_Lignes_Typologies
	(
		TypologieID     INT NOT NULL
	   ,MasterID        INT NULL
	   ,MarqueID        INT NULL
	)
	
	-- #T_Abos_Agreg - Table de lignes agregees
	-- Tronquee et reutilisee pour chaque typologie
	
	IF OBJECT_ID('tempdb..#T_Abos_Agreg') IS NOT NULL
	    DROP TABLE #T_Abos_Agreg
	
	CREATE TABLE #T_Abos_Agreg
	(
		N            INT NOT NULL
	   ,MasterID     INT NULL
	   ,MarqueID     INT NULL
	)
	
	IF OBJECT_ID('tempdb..#T_Abos') IS NOT NULL
	    DROP TABLE #T_Abos
	
	CREATE TABLE #T_Abos
	(
		MasterID            INT NULL
	   ,MarqueID            INT NULL
	   ,DebutFinAboDate     DATETIME NULL
	   ,AbonnementID        INT NULL
	)
	
	-- Typologies 1 - 20 : Abonnements, papier et numeriques, gratuits et payants
	
	-- 1. Nouvel abonne ayant souscrit depuis moins d'un mois son premier abonnement papier gratuit
	-- (et dont le dernier abonnement, s'il y en a eu, et que celui-ci soit numerique ou papier, payant ou gratuit, est arrete depuis plus de six mois).	
	
	-- Nouvel abonne : c'est son premier abonnement pour la marque depuis 6 mois (peut etre un faux nouveau)
	
	TRUNCATE TABLE #T_Abos
	
	-- SDVP
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.DebutAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.DebutAboDate >= DATEADD(MONTH ,-1 ,GETDATE())
	       AND a.StatutAbo = 3 -- en cours
	       AND (
	               COALESCE(a.ModePaiement ,0) IN (23 ,24)
	               OR b.OriginalID LIKE N'%GRATUIT%'
	               OR b.OriginalID LIKE N'% 0E %'
	           ) -- gratuit
	       AND a.SourceID = 3 -- SDVP
	       AND b.SupportAbo = 2 -- Papier
	
	UPDATE a
	SET    Typologie = 1
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	/*
	-- Neolane
	insert #T_Abos
	(
	MasterID
	, MarqueID
	, DebutFinAboDate
	)
	select 
	a.MasterID
	, a.Marque
	, a.DebutAboDate
	from dbo.Abonnements a
	inner join ref.CatalogueAbonnements b
	on a.CatalogueAbosID=b.CatalogueAbosID
	where a.DebutAboDate>=DATEADD(month,-1,getdate())
	and a.StatutAbo=3 -- en cours
	and a.SourceID=1 -- Neolane
	and b.MontantAbo=0.00 -- Gratuit
	*/
	
-- Supprimer ceux qui ont eu un abonnement numérique ou papier, payant ou gratuit, souscrit ou arrêté
	-- depuis plus d'un mois mais moins de 6 mois
/* Delete à la fin
	delete a
	from #T_Abos a inner join dbo.Abonnements b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueAbonnements c on b.CatalogueAbosID=c.CatalogueAbosID
	where a.DebutFinAboDate>b.DebutAboDate
	and		(
	(b.DebutAboDate<DATEADD(month,-1,getdate()) 
	and b.DebutAboDate>DATEADD(month,-6,getdate()) 
	) or
	(b.FinAboDate<DATEADD(month,-1,getdate()) 
	and b.FinAboDate>DATEADD(month,-6,getdate())
	)
	)
	*/
	/*
	and c.SupportAbo=2 -- Papier
	and 
	(
	(b.SourceID=3 -- SDVP
	and
	(b.ModePaiement in (23,24) or c.OriginalID like N'%GRATUIT%' or c.OriginalID like N'% 0E %') -- gratuit
	)
	or
	(
	b.SourceID=1 -- Neolane
	and c.MontantAbo=0.00 -- gratuit
	)
	)
	*/
	-- Eliminer les doublons éventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 1              AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	
	-- 2	CAPGA	Abonné actif depuis plus d'un mois ayant souscrit un abonnement papier gratuit.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.DebutAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.DebutAboDate < DATEADD(MONTH ,-1 ,GETDATE())
	       AND a.StatutAbo = 3 -- en cours
	       AND (
	               COALESCE(a.ModePaiement ,0) IN (23 ,24)
	               OR b.OriginalID LIKE N'%GRATUIT%'
	               OR b.OriginalID LIKE N'% 0E %'
	           ) -- gratuit
	       AND a.SourceID = 3 -- SDVP
	       AND b.SupportAbo = 2 -- Papier
	
	UPDATE a
	SET    Typologie = 2
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	/*
	insert #T_Abos
	(
	MasterID
	, MarqueID
	, DebutFinAboDate
	)
	select 
	a.MasterID
	, a.Marque
	, a.DebutAboDate
	from dbo.Abonnements a
	inner join ref.CatalogueAbonnements b
	on a.CatalogueAbosID=b.CatalogueAbosID
	where a.DebutAboDate<DATEADD(month,-1,getdate())
	and a.StatutAbo=3 -- en cours
	and a.SourceID=1 -- Neolane
	and b.MontantAbo=0.00 -- Gratuit
	*/
	
	-- Eliminer les doublons éventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 2              AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
from #T_Abos_Agreg a


-- 3	CAPGE	Abonné en période de renouvellement d'un abonnement papier gratuit.

-- a) Abonnements à durée ferme : entre les deux semaines qui précèdent la fin de l’abonnement en cours et les deux semaines qui suivent le renouvellement de son abonnement.

-- b) Abonnements à reconduction tacite : entre les deux semaines qui précèdent la fin de la validité de la carte bleue et les deux semaines qui suivent le renouvellement de l’autorisation de prélèvement.

-- Développement en attendant les définition de la durée ferme pour SDVP

-- Durée ferme et reconduction tacite sont opérationnelles pour Neolane ; mais Neolane c'est uniquement numérique - donc, rien pour l'instant

truncate table #T_Abos
	
	/*
	insert #T_Abos 
	(
	MasterID
	, MarqueID
	, DebutFinAboDate
	)
	select 
	a.MasterID
	, b.Marque
	, a.FinAboDate 
	from dbo.Abonnements a
	inner join ref.CatalogueAbonnements b 
	on a.CatalogueAbosID=b.CatalogueAbosID
	where a.SourceID=1 -- Neolane
and b.Recurrent=0 -- à durée ferme
	and a.StatutAbo=3 -- Actif
	and b.MontantAbo=0.00 -- Gratuit
	and datediff(day,getdate(),a.FinAboDate) between 0 and 14 -- deux semaines avant la date de fin
	
	
	insert #T_Abos 
	(
	MasterID
	, MarqueID
	, DebutFinAboDate
	)
	select 
	a.MasterID
	, b.Marque
	, a.FinAboDate 
	from dbo.Abonnements a
	inner join ref.CatalogueAbonnements b 
	on a.CatalogueAbosID=b.CatalogueAbosID
	where a.SourceID=1 -- Neolane
and b.Recurrent=0 -- à durée ferme
	and a.StatutAbo=3 -- Actif
	and b.MontantAbo=0.00 -- Gratuit
and datediff(day,a.ReaboDate,getdate()) between 0 and 14 -- deux semaines après la date de réabonnement
	*/
	
-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 3              AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	UPDATE a
	SET    Typologie = 3
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	--82 CSPGT - Clients souscripteurs papier gratuits termines
	TRUNCATE TABLE #T_Abos
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,b.Marque
	      ,a.FinAboDate
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.SourceID = 3
	       AND a.StatutAbo = 3 -- Actif
	       AND b.MontantAbo = 0.00 -- Gratuit
	       AND DATEDIFF(DAY ,GETDATE() ,a.FinAboDate) BETWEEN -14 AND -1 
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 82             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	UPDATE a
	SET    Typologie = 82
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	
	-- 4	CAPGR	Abonne recent dont l'abonnement papier gratuit est arrete depuis moins de six mois.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.FinAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.FinAboDate > DATEADD(MONTH ,-6 ,GETDATE())
	       AND a.StatutAbo = 2 -- Echu
	       AND (
	               COALESCE(a.ModePaiement ,0) IN (23 ,24)
	               OR b.OriginalID LIKE N'%GRATUIT%'
	               OR b.OriginalID LIKE N'% 0E %'
	           ) -- gratuit
	       AND a.SourceID = 3 -- SDVP
	       AND b.SupportAbo = 2 -- Papier
	
	UPDATE a
	SET    Typologie = 4
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	/*
	insert #T_Abos
	(
	MasterID
	, MarqueID
	, DebutFinAboDate
	)
	select 
	a.MasterID
	, a.Marque
	, a.FinAboDate
	from dbo.Abonnements a
	inner join ref.CatalogueAbonnements b
	on a.CatalogueAbosID=b.CatalogueAbosID
	where a.FinAboDate>DATEADD(month,-6,getdate())
	and a.StatutAbo=2 -- Echu
	and a.SourceID=1 -- Neolane
	and b.MontantAbo=0.00 -- Gratuit
	*/
	
-- Supprimer ceux qui ont un abonnement papier gratuit pour la même marque actif ou anticipé
/* Delete à la fin
	delete a
	from #T_Abos a inner join dbo.Abonnements b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueAbonnements c
	on b.CatalogueAbosID=c.CatalogueAbosID
where b.StatutAbo in (1,3) -- actif ou anticipé
	and c.SupportAbo=2 -- Papier
	and b.SourceID=3 -- SDVP
	and	(coalesce(b.ModePaiement,0) in (23,24) or c.OriginalID like N'%GRATUIT%' or c.OriginalID like N'% 0E %') -- gratuit
	*/
	-- Eliminer les doublons éventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 4              AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 5	CAPGI	Ancien abonné dont l'abonnement papier gratuit est arrêté depuis plus de six mois.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.FinAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.FinAboDate <= DATEADD(MONTH ,-6 ,GETDATE())
	       AND a.StatutAbo = 2 -- Echu
	       AND (
	               COALESCE(a.ModePaiement ,0) IN (23 ,24)
	               OR b.OriginalID LIKE N'%GRATUIT%'
	               OR b.OriginalID LIKE N'% 0E %'
	           ) -- gratuit
	       AND a.SourceID = 3 -- SDVP
	       AND b.SupportAbo = 2 -- Papier
	
	UPDATE a
	SET    Typologie = 5
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	-- Supprimer ceux qui ont un abonnement papier gratuit pour la meme marque actif ou anticipe
	-- ou echu depuis moins de 6 mois
	/* Delete a la fin
	delete a
	from #T_Abos a inner join dbo.Abonnements b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueAbonnements c on b.CatalogueAbosID=c.CatalogueAbosID
	where (
(b.StatutAbo in (1,3)) -- actif ou anticipé
	or (b.StatutAbo=2 -- Echu 
	and b.FinAboDate>DATEADD(month,-6,getdate()) )
	)
	and (
	(b.SourceID=3 -- SDVP
	and (coalesce(b.ModePaiement,0) in (23,24) or c.OriginalID like N'%GRATUIT%' or c.OriginalID like N'% 0E %') -- gratuit
	)
	)
	and c.SupportAbo=2 -- Papier
	*/
	-- Eliminer les doublons éventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 5              AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	
	-- 6	CAPPN	Nouvel abonné ayant souscrit depuis moins d'un mois un abonnement papier payant.
	-- Nouvel abonné : c'est son premier abonnement pour la marque depuis 6 mois (peut être un faux nouveau)
	
	TRUNCATE TABLE #T_Abos
	
	-- SDVP
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.DebutAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.DebutAboDate >= DATEADD(MONTH ,-1 ,GETDATE())
	       AND a.StatutAbo = 3 -- en cours
	       AND NOT (
	               COALESCE(a.ModePaiement ,0) IN (23 ,24)
	               OR b.OriginalID LIKE N'%GRATUIT%'
	               OR b.OriginalID LIKE N'% 0E %'
	           ) -- payant SDVP
	       AND a.SourceID = 3 -- SDVP
	       AND b.SupportAbo = 2 -- Papier
	
	UPDATE a
	SET    Typologie = 6
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	/*
	-- Neolane
	insert #T_Abos
	(
	MasterID
	, MarqueID
	, DebutFinAboDate
	)
	select 
	a.MasterID
	, a.Marque
	, a.DebutAboDate
	from dbo.Abonnements a
	inner join ref.CatalogueAbonnements b
	on a.CatalogueAbosID=b.CatalogueAbosID
	where a.DebutAboDate>=DATEADD(month,-1,getdate())
	and a.StatutAbo=3 -- en cours
	and a.SourceID=1 -- Neolane
	and b.MontantAbo<>0.00 -- Payant
	*/
	
-- Supprimer ceux qui ont eu un abonnement papier payant pour la même marque 
	-- depuis plus d'un mois mais moins de 6 mois
	/* Delete a la fin
	delete a
	from #T_Abos a inner join dbo.Abonnements b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueAbonnements c on b.CatalogueAbosID=c.CatalogueAbosID
	where a.DebutFinAboDate>b.DebutAboDate
	and b.DebutAboDate<DATEADD(month,-1,getdate()) 
	and b.DebutAboDate>DATEADD(month,-6,getdate()) 
	and c.SupportAbo=2 -- Papier
	and b.SourceID=3 -- SDVP
	and	(not (coalesce(b.ModePaiement,0) in (23,24) or c.OriginalID like N'%GRATUIT%' or c.OriginalID like N'% 0E %')) -- payant
	*/
	
	
	-- Eliminer les doublons éventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 6              AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	
	-- 7	CAPPA	Abonne actif depuis plus d'un mois ayant souscrit un abonnement papier payant.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.DebutAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.DebutAboDate < DATEADD(MONTH ,-1 ,GETDATE())
	       AND a.StatutAbo = 3 -- en cours
	       AND NOT (
	               COALESCE(a.ModePaiement ,0) IN (23 ,24)
	               OR b.OriginalID LIKE N'%GRATUIT%'
	               OR b.OriginalID LIKE N'% 0E %'
	           ) -- payant
	       AND a.SourceID = 3 -- SDVP
	       AND b.SupportAbo = 2 -- Papier
	
	UPDATE a
	SET    Typologie = 7
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	/*
	insert #T_Abos
	(
	MasterID
	, MarqueID
	, DebutFinAboDate
	)
	select 
	a.MasterID
	, a.Marque
	, a.DebutAboDate
	from dbo.Abonnements a
	inner join ref.CatalogueAbonnements b
	on a.CatalogueAbosID=b.CatalogueAbosID
	where a.DebutAboDate<DATEADD(month,-1,getdate())
	and a.StatutAbo=3 -- en cours
	and a.SourceID=1 -- Neolane
	and b.MontantAbo<>0.00 -- Payant
	*/
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 7              AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 8	CAPPE	Abonne en periode de renouvellement d'un abonnement papier payant.
	
	-- Neolane - pas d'abonnement papier
	-- SDVP - meme probleme que dans 3 CAPGE
	
	TRUNCATE TABLE #T_Abos
	
	/*
	insert #T_Abos 
	(
	MasterID
	, MarqueID
	, DebutFinAboDate
	, AbonnementID
	)
	select 
	a.MasterID
	, b.Marque
	, a.FinAboDate 
	, a.AbonnementID
	from dbo.Abonnements a
	inner join ref.CatalogueAbonnements b 
	on a.CatalogueAbosID=b.CatalogueAbosID
	where a.SourceID=1 -- Neolane
	and b.Recurrent=0 -- a duree ferme
	and a.StatutAbo=3 -- Actif
	and b.MontantAbo<>0.00 -- Payant
	and datediff(day,getdate(),a.FinAboDate) between 0 and 14 -- deux semaines avant la date de fin
	*/
	
	/*
	insert #T_Abos 
	(
	MasterID
	, MarqueID
	, DebutFinAboDate
	, AbonnementID
	)
	select 
	a.MasterID
	, b.Marque
	, a.FinAboDate 
	, a.AbonnementID
	from dbo.Abonnements a
	inner join ref.CatalogueAbonnements b 
	on a.CatalogueAbosID=b.CatalogueAbosID
	where a.SourceID=1 -- Neolane
	and b.Recurrent=0 -- a duree ferme
	and a.StatutAbo=3 -- Actif
	and b.MontantAbo<>0.00 -- Payant
	and datediff(day,a.ReaboDate,getdate()) between 0 and 14 -- deux semaines apres la date de reabonnement
	*/
	
	UPDATE a
	SET    Typologie = 8
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 8              AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	
	--83 CSPPT - Clients souscripteurs papier payants termines
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,b.Marque
	      ,a.FinAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.SourceID = 3
	       AND a.StatutAbo = 3 -- Actif
	       AND b.MontantAbo <> 0.00 -- Payant
	       AND DATEDIFF(DAY ,GETDATE() ,a.FinAboDate) BETWEEN -14 AND -1
	
	
	UPDATE a
	SET    Typologie = 83
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 83             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	
	-- 9	CAPPR	Abonne recent dont l'abonnement papier payant est arrete depuis moins de six mois.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.FinAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.FinAboDate > DATEADD(MONTH ,-6 ,GETDATE())
	       AND a.StatutAbo = 2 -- Echu
	       AND NOT (
	               COALESCE(a.ModePaiement ,0) IN (23 ,24)
	               OR b.OriginalID LIKE N'%GRATUIT%'
	               OR b.OriginalID LIKE N'% 0E %'
	           ) -- payant
	       AND a.SourceID = 3 -- SDVP
	       AND b.SupportAbo = 2 -- Papier
	
	UPDATE a
	SET    Typologie = 9
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	/*
	insert #T_Abos
	(
	MasterID
	, MarqueID
	, DebutFinAboDate
	)
	select 
	a.MasterID
	, a.Marque
	, a.FinAboDate
	from dbo.Abonnements a
	inner join ref.CatalogueAbonnements b
	on a.CatalogueAbosID=b.CatalogueAbosID
	where a.FinAboDate>DATEADD(month,-6,getdate())
	and a.StatutAbo=2 -- Echu
	and a.SourceID=1 -- Neolane
	and b.MontantAbo<>0.00 -- Payant
	*/
	
	-- Supprimer ceux qui ont un abonnement papier payant pour la meme marque actif ou anticipe
	/* Delete a la fin
	delete a
	from #T_Abos a inner join dbo.Abonnements b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueAbonnements c
	on b.CatalogueAbosID=c.CatalogueAbosID
	where b.StatutAbo in (1,3) -- actif ou anticipe
	and 
	(b.SourceID=3 -- SDVP
	and not (coalesce(b.ModePaiement,0) in (23,24) or c.OriginalID like N'%GRATUIT%' or c.OriginalID like N'% 0E %') -- payant
	)
	and c.SupportAbo=2 -- Papier -- ICI
	*/
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 9              AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 10	CAPPI	Ancien abonne dont l'abonnement papier payant est arrete depuis plus de six mois.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.FinAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.FinAboDate <= DATEADD(MONTH ,-6 ,GETDATE())
	       AND a.StatutAbo = 2 -- Echu
	       AND NOT (
	               COALESCE(a.ModePaiement ,0) IN (23 ,24)
	               OR b.OriginalID LIKE N'%GRATUIT%'
	               OR b.OriginalID LIKE N'% 0E %'
	           ) -- payant
	       AND a.SourceID = 3 -- SDVP
	       AND b.SupportAbo = 2 -- Papier
	
	UPDATE a
	SET    Typologie = 10
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	/*
	insert #T_Abos
	(
	MasterID
	, MarqueID
	, DebutFinAboDate
	)
	select 
	a.MasterID
	, a.Marque
	, a.FinAboDate
	from dbo.Abonnements a
	inner join ref.CatalogueAbonnements b
	on a.CatalogueAbosID=b.CatalogueAbosID
	where a.FinAboDate<=DATEADD(month,-6,getdate())
	and a.StatutAbo=2 -- Echu
	and a.SourceID=1 -- Neolane
	and b.MontantAbo<>0.00 -- Payant
	*/
	
	-- Supprimer ceux qui ont un abonnement payant pour la meme marque actif ou anticipe
	-- ou echu depuis moins de 6 mois
	/* Delete a la fin
	delete a
	from #T_Abos a inner join dbo.Abonnements b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueAbonnements c on b.CatalogueAbosID=c.CatalogueAbosID
	where (
	(b.StatutAbo in (1,3)) -- actif ou anticipe
	or (b.StatutAbo=2 -- Echu 
	and b.FinAboDate>DATEADD(month,-6,getdate()) )
	)
	and (
	(b.SourceID=3 -- SDVP
	and not (coalesce(b.ModePaiement,0) in (23,24) or c.OriginalID like N'%GRATUIT%' or c.OriginalID like N'% 0E %') -- payant
	)
	)
	and c.SupportAbo=2 -- Papier
	*/
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 10             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 11	CANGN	Nouvel abonne ayant souscrit depuis moins d'un mois un abonnement numerique gratuit.
	
	TRUNCATE TABLE #T_Abos
	
	-- SDVP
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.DebutAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.DebutAboDate >= DATEADD(MONTH ,-1 ,GETDATE())
	       AND a.StatutAbo = 3 -- en cours
	       AND (
	               COALESCE(a.ModePaiement ,0) IN (23 ,24)
	               OR b.OriginalID LIKE N'%GRATUIT%'
	               OR b.OriginalID LIKE N'% 0E %'
	           ) -- gratuit
	       AND a.SourceID = 3 -- SDVP
	       AND b.SupportAbo = 1 -- Numerique
	
	-- Neolane
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.DebutAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.DebutAboDate >= DATEADD(MONTH ,-1 ,GETDATE())
	       AND a.StatutAbo = 3 -- en cours
	       AND a.SourceID IN (1 ,10) -- Neolane et PVL
	       AND b.MontantAbo = 0.00 -- Gratuit
	       AND b.SupportAbo = 1 -- Numerique
	
	UPDATE a
	SET    Typologie = 11
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	
	-- Supprimer ceux qui ont eu un abonnement pour la meme marque
	-- depuis plus d'un mois mais moins de 6 mois
	/* Delete a la fin
	delete a
	from #T_Abos a inner join dbo.Abonnements b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueAbonnements c on b.CatalogueAbosID=c.CatalogueAbosID
	where a.DebutFinAboDate>b.DebutAboDate
	and b.DebutAboDate<DATEADD(month,-1,getdate()) 
	and b.DebutAboDate>DATEADD(month,-6,getdate()) 
	and c.SupportAbo=1 -- Numerique
	and 
	(
	(b.SourceID=3 -- SDVP
	and
	(coalesce(b.ModePaiement,0) in (23,24) or c.OriginalID like N'%GRATUIT%' or c.OriginalID like N'% 0E %') -- gratuit
	)
	or
	(
	b.SourceID=1 -- Neolane
	and c.MontantAbo=0.00 -- gratuit
	)
	)
	*/
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 11             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 12	CANGA	Abonne actif depuis plus d'un mois ayant souscrit un abonnement numerique gratuit.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.DebutAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.DebutAboDate < DATEADD(MONTH ,-1 ,GETDATE())
	       AND a.StatutAbo = 3 -- en cours
	       AND (
	               COALESCE(a.ModePaiement ,0) IN (23 ,24)
	               OR b.OriginalID LIKE N'%GRATUIT%'
	               OR b.OriginalID LIKE N'% 0E %'
	           ) -- gratuit
	       AND a.SourceID = 3 -- SDVP
	       AND b.SupportAbo = 1 -- Numerique
	
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.DebutAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.DebutAboDate < DATEADD(MONTH ,-1 ,GETDATE())
	       AND a.StatutAbo = 3 -- en cours
	       AND a.SourceID IN (1 ,10) -- Neolane et PVL
	       AND b.MontantAbo = 0.00 -- Gratuit
	       AND b.SupportAbo = 1 -- Numerique
	
	UPDATE a
	SET    Typologie = 12
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 12             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 13	CSNGE - Clients souscripteurs numerique gratuits en renouvellement
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,b.Marque
	      ,a.FinAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.SourceID IN (1 ,10) -- Neolane et PVL
	       AND b.Recurrent = 0 -- a duree ferme
	       AND a.StatutAbo = 3 -- Actif
	       AND b.MontantAbo = 0.00 -- Gratuit
	       AND b.SupportAbo = 1 -- Numerique
	       AND DATEDIFF(DAY ,GETDATE() ,a.FinAboDate) BETWEEN 0 AND 14 -- deux semaines avant la date de fin
	
	
	--insert #T_Abos
	--(
	--MasterID
	--, MarqueID
	--, DebutFinAboDate
	--, AbonnementID
	--)
	--select
	--a.MasterID
	--, b.Marque
	--, a.FinAboDate
	--, a.AbonnementID
	--from dbo.Abonnements a
	--inner join ref.CatalogueAbonnements b
	--on a.CatalogueAbosID=b.CatalogueAbosID
	--where a.SourceID in (1,10) -- Neolane et PVL
	--and b.Recurrent=0 -- a duree ferme
	--and a.StatutAbo=3 -- Actif
	--and b.MontantAbo=0.00 -- Gratuit
	--and b.SupportAbo=1 -- Numerique
	--and datediff(day,a.ReaboDate,getdate()) between 0 and 14 -- deux semaines apres la date de reabonnement
	
	UPDATE a
	SET    Typologie = 13
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 13             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 84 CSNGT - Clients souscripteurs numerique gratuits termines
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,b.Marque
	      ,a.FinAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.SourceID IN (1 ,3 ,10) -- Neolane et PVL
	       AND a.StatutAbo = 3 -- Actif
	       AND b.MontantAbo = 0.00 -- Gratuit
	       AND b.SupportAbo = 1 -- Numerique
	       AND DATEDIFF(DAY ,GETDATE() ,a.FinAboDate) BETWEEN -14 AND -1
	
	UPDATE a
	SET    Typologie = 84
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 84             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 14	CANGR	Abonne recent dont l'abonnement numerique gratuit est arrete depuis moins de six mois.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.FinAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.FinAboDate > DATEADD(MONTH ,-6 ,GETDATE())
	       AND a.StatutAbo = 2 -- Echu
	       AND (
	               COALESCE(a.ModePaiement ,0) IN (23 ,24)
	               OR b.OriginalID LIKE N'%GRATUIT%'
	               OR b.OriginalID LIKE N'% 0E %'
	           ) -- gratuit
	       AND a.SourceID = 3 -- SDVP
	       AND b.SupportAbo = 1 -- Numerique
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.FinAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.FinAboDate > DATEADD(MONTH ,-6 ,GETDATE())
	       AND a.StatutAbo = 2 -- Echu
	       AND a.SourceID IN (1 ,10) -- Neolane et PVL
	       AND b.MontantAbo = 0.00 -- Gratuit
	       AND b.SupportAbo = 1 -- Numerique
	
	UPDATE a
	SET    Typologie = 14
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	-- Supprimer ceux qui ont un abonnement pour la meme marque actif ou anticipe 
	/* Delete a la fin 
	delete a
	from #T_Abos a inner join dbo.Abonnements b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueAbonnements c
	on b.CatalogueAbosID=c.CatalogueAbosID
	where 
	b.StatutAbo in (1,3) -- actif ou anticipe 
	and (
	(b.SourceID=3 -- SDVP
	and (coalesce(b.ModePaiement,0) in (23,24) or c.OriginalID like N'%GRATUIT%' or c.OriginalID like N'% 0E %') -- gratuit
	)
	or (b.SourceID=1 -- Neolane
	and c.MontantAbo=0.00 -- Gratuit
	)
	)
	and c.SupportAbo=1 -- Numerique
	*/
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 14             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 15	CANGI	Ancien abonne dont l'abonnement numerique gratuit est arrete depuis plus de six mois.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.FinAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.FinAboDate <= DATEADD(MONTH ,-6 ,GETDATE())
	       AND a.StatutAbo = 2 -- Echu
	       AND (
	               COALESCE(a.ModePaiement ,0) IN (23 ,24)
	               OR b.OriginalID LIKE N'%GRATUIT%'
	               OR b.OriginalID LIKE N'% 0E %'
	           ) -- gratuit
	       AND a.SourceID = 3 -- SDVP
	       AND b.SupportAbo = 1 -- Numerique
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.FinAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.FinAboDate <= DATEADD(MONTH ,-6 ,GETDATE())
	       AND a.StatutAbo = 2 -- Echu
	       AND a.SourceID IN (1 ,10) -- Neolane et PVL
	       AND b.MontantAbo = 0.00 -- Gratuit
	       AND b.SupportAbo = 1 -- Numerique
	
	UPDATE a
	SET    Typologie = 15
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	-- Supprimer ceux qui ont un abonnement gratuit pour la meme marque actif ou anticipe
	-- ou echu depuis moins de 6 mois
	/* Delete a la fin
	delete a
	from #T_Abos a inner join dbo.Abonnements b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueAbonnements c on b.CatalogueAbosID=c.CatalogueAbosID
	where (
	(b.StatutAbo in (1,3)) -- actif ou anticipe
	or (b.StatutAbo=2 -- Echu depuis moins de 6 mois
	and b.FinAboDate>DATEADD(month,-6,getdate()) )
	)
	and (
	(b.SourceID=3 -- SDVP
	and (coalesce(b.ModePaiement,0) in (23,24) or c.OriginalID like N'%GRATUIT%' or c.OriginalID like N'% 0E %') -- gratuit
	)
	or (b.SourceID=1 -- Neolane
	and c.MontantAbo=0.00 -- Gratuit
	)
	)
	and c.SupportAbo=1 -- Numerique
	*/
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 15             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 16	CANPN	Nouvel abonne ayant souscrit depuis moins d'un mois un abonnement numerique payant.
	
	TRUNCATE TABLE #T_Abos
	
	-- SDVP
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.DebutAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.DebutAboDate >= DATEADD(MONTH ,-1 ,GETDATE())
	       AND a.StatutAbo = 3 -- en cours
	       AND NOT (
	               COALESCE(a.ModePaiement ,0) IN (23 ,24)
	               OR b.OriginalID LIKE N'%GRATUIT%'
	               OR b.OriginalID LIKE N'% 0E %'
	           ) -- payant
	       AND a.SourceID = 3 -- SDVP
	       AND b.SupportAbo = 1 -- Numerique
	
	-- Neolane
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.DebutAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.DebutAboDate >= DATEADD(MONTH ,-1 ,GETDATE())
	       AND a.StatutAbo = 3 -- en cours
	       AND a.SourceID IN (1 ,10) -- Neolane et PVL
	       AND b.MontantAbo <> 0.00 -- payant
	       AND b.SupportAbo = 1 -- Numerique
	
	UPDATE a
	SET    Typologie = 16
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	-- Supprimer ceux qui ont eu un abonnement payant pour la meme marque
	-- depuis plus d'un mois mais moins de 6 mois
	/* Delete a la fin
	delete a
	from #T_Abos a inner join dbo.Abonnements b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueAbonnements c on b.CatalogueAbosID=c.CatalogueAbosID
	where a.DebutFinAboDate>b.DebutAboDate
	and b.DebutAboDate<DATEADD(month,-1,getdate()) 
	and b.DebutAboDate>DATEADD(month,-6,getdate()) 
	and c.SupportAbo=1 -- Numerique
	and 
	(
	(b.SourceID=3 -- SDVP
	and
	(not (coalesce(b.ModePaiement,0) in (23,24) or c.OriginalID like N'%GRATUIT%' or c.OriginalID like N'% 0E %') ) -- payant
	)
	or
	(
	b.SourceID=1 -- Neolane
	and c.MontantAbo<>0.00 -- payant
	)
	)
	*/
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 16             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 17	CANPA	Abonne actif depuis plus d'un mois ayant souscrit un abonnement numerique payant.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.DebutAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.DebutAboDate < DATEADD(MONTH ,-1 ,GETDATE())
	       AND a.StatutAbo = 3 -- en cours
	       AND NOT (
	               COALESCE(a.ModePaiement ,0) IN (23 ,24)
	               OR b.OriginalID LIKE N'%GRATUIT%'
	               OR b.OriginalID LIKE N'% 0E %'
	           ) -- payant
	       AND a.SourceID = 3 -- SDVP
	       AND b.SupportAbo = 1 -- Numerique
	
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.DebutAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.DebutAboDate < DATEADD(MONTH ,-1 ,GETDATE())
	       AND a.StatutAbo = 3 -- en cours
	       AND a.SourceID IN (1 ,10) -- Neolane et PVL
	       AND b.MontantAbo <> 0.00 -- payant
	       AND b.SupportAbo = 1 -- Numerique
	
	UPDATE a
	SET    Typologie = 17
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 17             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 18	CANPE	Abonne en periode de renouvellement d'un abonnement numerique payant.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,b.Marque
	      ,a.FinAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.SourceID IN (1 ,10) -- Neolane et PVL
	       AND b.Recurrent = 0 -- a duree ferme
	       AND a.StatutAbo = 3 -- Actif
	       AND b.MontantAbo <> 0.00 -- Payant
	       AND b.SupportAbo = 1 -- Numerique
	       AND DATEDIFF(DAY ,GETDATE() ,a.FinAboDate) BETWEEN 0 AND 14 -- deux semaines avant la date de fin
	
	
	--insert #T_Abos
	--(
	--MasterID
	--, MarqueID
	--, DebutFinAboDate
	--, AbonnementID
	--)
	--select
	--a.MasterID
	--, b.Marque
	--, a.FinAboDate
	--, a.AbonnementID
	--from dbo.Abonnements a
	--inner join ref.CatalogueAbonnements b
	--on a.CatalogueAbosID=b.CatalogueAbosID
	--where a.SourceID in (1,10) -- Neolane et PVL
	--and b.Recurrent=0 -- a duree ferme
	--and a.StatutAbo=3 -- Actif
	--and b.MontantAbo<>0.00 -- Payant
	--and b.SupportAbo=1 -- Numerique
	--and datediff(day,a.ReaboDate,getdate()) between 0 and 14 -- deux semaines apres la date de reabonnement
	
	UPDATE a
	SET    Typologie = 18
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 18             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 85 CSNPT - Clients souscripteurs numerique payants termines
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,b.Marque
	      ,a.FinAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.SourceID IN (1 ,3 ,10) -- Neolane et PVL
	       AND a.StatutAbo = 3 -- Actif
	       AND b.MontantAbo <> 0.00 -- Payant
	       AND b.SupportAbo = 1 -- Numerique
	       AND DATEDIFF(DAY ,GETDATE() ,a.FinAboDate) BETWEEN -14 AND -1
	
	UPDATE a
	SET    Typologie = 85
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 85             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	
	-- 19	CANPR	Abonne recent dont l'abonnement numerique payant est arrete depuis moins de six mois.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.FinAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.FinAboDate > DATEADD(MONTH ,-6 ,GETDATE())
	       AND a.StatutAbo = 2 -- Echu
	       AND NOT (
	               COALESCE(a.ModePaiement ,0) IN (23 ,24)
	               OR b.OriginalID LIKE N'%GRATUIT%'
	               OR b.OriginalID LIKE N'% 0E %'
	           ) -- Payant
	       AND a.SourceID = 3 -- SDVP
	       AND b.SupportAbo = 1 -- Numerique
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.FinAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.FinAboDate > DATEADD(MONTH ,-6 ,GETDATE())
	       AND a.StatutAbo = 2 -- Echu
	       AND a.SourceID IN (1 ,10) -- Neolane et PVL
	       AND b.MontantAbo <> 0.00 -- Payant
	       AND b.SupportAbo = 1 -- Numerique
	
	UPDATE a
	SET    Typologie = 19
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	-- Supprimer ceux qui ont un abonnement pour la meme marque actif ou anticipe  
	/* Delete a la fin
	delete a
	from #T_Abos a inner join dbo.Abonnements b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueAbonnements c
	on b.CatalogueAbosID=c.CatalogueAbosID
	where 
	b.StatutAbo in (1,3) -- actif ou anticipe 
	and (
	(b.SourceID=3 -- SDVP
	and not ((coalesce(b.ModePaiement,0) in (23,24) or c.OriginalID like N'%GRATUIT%' or c.OriginalID like N'% 0E %')) -- Payant
	)
	or (b.SourceID=1 -- Neolane
	and c.MontantAbo<>0.00 -- Payant
	)
	)
	and c.SupportAbo=1 -- Numerique
	*/
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 19             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 20	CANPI	Ancien abonne dont l'abonnement numerique payant est arrete depuis plus de six mois.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.FinAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.FinAboDate <= DATEADD(MONTH ,-6 ,GETDATE())
	       AND a.StatutAbo = 2 -- Echu
	       AND NOT (
	               COALESCE(a.ModePaiement ,0) IN (23 ,24)
	               OR b.OriginalID LIKE N'%GRATUIT%'
	               OR b.OriginalID LIKE N'% 0E %'
	           ) -- Payant
	       AND a.SourceID = 3 -- SDVP
	       AND b.SupportAbo = 1 -- Numerique
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.FinAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.FinAboDate <= DATEADD(MONTH ,-6 ,GETDATE())
	       AND a.StatutAbo = 2 -- Echu
	       AND a.SourceID IN (1 ,10) -- Neolane et PVL
	       AND b.MontantAbo <> 0.00 -- Payant
	       AND b.SupportAbo = 1 -- Numerique
	
	UPDATE a
	SET    Typologie = 20
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	-- Supprimer ceux qui ont un abonnement payant pour la meme marque actif ou anticipe
	-- ou echu depuis moins de 6 mois
	/* Delete a la fin
	delete a
	from #T_Abos a inner join dbo.Abonnements b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueAbonnements c on b.CatalogueAbosID=c.CatalogueAbosID
	where (
	(b.StatutAbo in (1,3)) -- actif ou anticipe
	or (b.StatutAbo=2 -- Echu depuis moins de 6 mois
	and b.FinAboDate>DATEADD(month,-6,getdate()) )
	)
	and (
	(b.SourceID=3 -- SDVP
	and not (coalesce(b.ModePaiement,0) in (23,24) or c.OriginalID like N'%GRATUIT%' or c.OriginalID like N'% 0E %') -- Payant
	)
	or (b.SourceID=1 -- Neolane
	and c.MontantAbo<>0.00 -- Payant
	)
	)
	and c.SupportAbo=1 -- Numerique
	*/
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 20             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- Typologies 21-32 : Achats a l'acte, produits physiques et numeriques, gratuits et payants
	
	-- 21	CAPGN	Nouvel acheteur ayant acquis depuis moins d'un mois un produit numerique gratuit.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	WHERE  a.AchatDate >= DATEADD(MONTH ,-1 ,GETDATE())
	       AND b.SourceID = 3 -- SDVP
	       AND COALESCE(b.CategorieProduit ,N'') = N'NUM'
	       AND a.MontantAchat = 0.00 -- Gratuit
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	       LEFT OUTER JOIN etl.TRANSCO c
	            ON  b.CategorieProduit = c.Origine
	                AND c.TranscoCode = N'ORIGINEACHAT'
	                AND c.SourceId = N'1'
	WHERE  a.AchatDate >= DATEADD(MONTH ,-1 ,GETDATE())
	       AND (
	               (
	                   b.SourceID = 1 /* Neolane */
	                   AND c.Destination = N'Numerique'
	               )
	               OR (
	                      b.SourceID = 10 /* PVL : on presuppose que le produit est numerique dans Ventes en ligne */
	                  )
	           )
	       AND a.MontantAchat = 0.00 -- Gratuit
	
	
	-- Supprimer ceux qui ont achete un produit quelconque,
	-- numerique ou physique, gratuit ou payant, pour la meme marque
	-- depuis plus d'un mois mais moins de 6 mois
	/* Delete a la fin
	delete a
	from #T_Abos a inner join dbo.AchatsALActe b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueProduits c on b.ProduitID=c.ProduitID
	where a.DebutFinAboDate>b.AchatDate
	and b.AchatDate<DATEADD(month,-1,getdate()) 
	and b.AchatDate>DATEADD(month,-6,getdate()) 
	*/
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 21             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 22	CAPGA	Acheteur ayant acquis depuis moins de six mois un produit numerique gratuit.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	WHERE  a.AchatDate >= DATEADD(MONTH ,-6 ,GETDATE())
	       AND b.SourceID = 3 -- SDVP
	       AND COALESCE(b.CategorieProduit ,N'') = N'NUM'
	       AND a.MontantAchat = 0.00 -- Gratuit
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	       LEFT OUTER JOIN etl.TRANSCO c
	            ON  b.CategorieProduit = c.Origine
	                AND c.TranscoCode = N'ORIGINEACHAT'
	                AND c.SourceId = N'1'
	WHERE  a.AchatDate >= DATEADD(MONTH ,-6 ,GETDATE())
	       AND (
	               (
	                   b.SourceID = 1 /* Neolane */
	                   AND c.Destination = N'Numerique'
	               )
	               OR (
	                      b.SourceID = 10 /* PVL : on presuppose que le produit est numerique dans Ventes en ligne */
	                  )
	           )
	       AND a.MontantAchat = 0.00 -- Gratuit
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 22             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 23	CAPGI	Ancien acheteur ayant acquis depuis plus de six mois un produit numerique gratuit.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	WHERE  a.AchatDate < DATEADD(MONTH ,-6 ,GETDATE())
	       AND b.SourceID = 3 -- SDVP
	       AND COALESCE(b.CategorieProduit ,N'') = N'NUM'
	       AND a.MontantAchat = 0.00 -- Gratuit
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	       LEFT OUTER JOIN etl.TRANSCO c
	            ON  b.CategorieProduit = c.Origine
	                AND c.TranscoCode = N'ORIGINEACHAT'
	                AND c.SourceId = N'1'
	WHERE  a.AchatDate < DATEADD(MONTH ,-6 ,GETDATE())
	       AND (
	               (
	                   b.SourceID = 1 /* Neolane */
	                   AND c.Destination = N'Numerique'
	               )
	               OR (
	                      b.SourceID = 10 /* PVL : on presuppose que le produit est numerique dans Ventes en ligne */
	                  )
	           )
	       AND a.MontantAchat = 0.00 -- Gratuit
	
	-- Supprimer ceux qui ont achete un produit quelconque,
	-- numerique ou physique, gratuit ou payant, pour la meme marque
	-- depuis moins de 6 mois
	/* Delete a la fin
	delete a
	from #T_Abos a inner join dbo.AchatsALActe b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueProduits c on b.ProduitID=c.ProduitID
	where b.AchatDate>DATEADD(month,-6,getdate()) 
	*/
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 23             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 24	CAPPN	Nouvel acheteur ayant acquis depuis moins d'un mois un produit numerique payant.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	WHERE  a.AchatDate >= DATEADD(MONTH ,-1 ,GETDATE())
	       AND b.SourceID = 3 -- SDVP
	       AND COALESCE(b.CategorieProduit ,N'') = N'NUM'
	       AND a.MontantAchat <> 0.00 -- Payant
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	       LEFT OUTER JOIN etl.TRANSCO c
	            ON  b.CategorieProduit = c.Origine
	                AND c.TranscoCode = N'ORIGINEACHAT'
	                AND c.SourceId = N'1'
	WHERE  a.AchatDate >= DATEADD(MONTH ,-1 ,GETDATE())
	       AND (
	               (
	                   b.SourceID = 1 /* Neolane */
	                   AND c.Destination = N'Numerique'
	               )
	               OR (
	                      b.SourceID = 10 /* PVL : on presuppose que le produit est numerique dans Ventes en ligne */
	                  )
	           )
	       AND a.MontantAchat <> 0.00 -- Payant
	
	
	-- Supprimer ceux qui ont achete un produit quelconque,
	-- numerique ou physique, gratuit ou payant, pour la meme marque
	-- depuis plus d'un mois mais moins de 6 mois
	/* Delete a la fin
	delete a
	from #T_Abos a inner join dbo.AchatsALActe b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueProduits c on b.ProduitID=c.ProduitID
	where a.DebutFinAboDate>b.AchatDate
	and b.AchatDate<DATEADD(month,-1,getdate()) 
	and b.AchatDate>DATEADD(month,-6,getdate()) 
	*/
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 24             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 25	CAPPA	Acheteur ayant acquis depuis moins de six mois un produit numerique payant.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	WHERE  a.AchatDate >= DATEADD(MONTH ,-6 ,GETDATE())
	       AND b.SourceID = 3 -- SDVP
	       AND COALESCE(b.CategorieProduit ,N'') = N'NUM'
	       AND a.MontantAchat <> 0.00 -- Payant
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	       LEFT OUTER JOIN etl.TRANSCO c
	            ON  b.CategorieProduit = c.Origine
	                AND c.TranscoCode = N'ORIGINEACHAT'
	                AND c.SourceId = N'1'
	WHERE  a.AchatDate >= DATEADD(MONTH ,-6 ,GETDATE())
	       AND (
	               (
	                   b.SourceID = 1 /* Neolane */
	                   AND c.Destination = N'Numerique'
	               )
	               OR (
	                      b.SourceID = 10 /* PVL : on presuppose que le produit est numerique dans Ventes en ligne */
	                  )
	           )
	       AND a.MontantAchat <> 0.00 -- Payant
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 25             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 26	CAPPI	Ancien acheteur ayant acquis depuis plus de six mois un produit numerique payant.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	WHERE  a.AchatDate < DATEADD(MONTH ,-6 ,GETDATE())
	       AND b.SourceID = 3 -- SDVP
	       AND COALESCE(b.CategorieProduit ,N'') = N'NUM'
	       AND a.MontantAchat <> 0.00 -- Payant
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	       LEFT OUTER JOIN etl.TRANSCO c
	            ON  b.CategorieProduit = c.Origine
	                AND c.TranscoCode = N'ORIGINEACHAT'
	                AND c.SourceId = N'1'
	WHERE  a.AchatDate < DATEADD(MONTH ,-6 ,GETDATE())
	       AND (
	               (
	                   b.SourceID = 1 /* Neolane */
	                   AND c.Destination = N'Numerique'
	               )
	               OR (
	                      b.SourceID = 10 /* PVL : on presuppose que le produit est numerique dans Ventes en ligne */
	                  )
	           )
	       AND a.MontantAchat <> 0.00 -- Payant
	
	-- Supprimer ceux qui ont achete un produit quelconque,
	-- numerique ou physique, gratuit ou payant, pour la meme marque
	-- depuis moins de 6 mois
	/* Delete a la fin
	delete a
	from #T_Abos a inner join dbo.AchatsALActe b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueProduits c on b.ProduitID=c.ProduitID
	where b.AchatDate>DATEADD(month,-6,getdate()) 
	*/
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 26             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 27	CAPGN	Nouvel acheteur ayant acquis depuis moins d'un mois un produit physique gratuit.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	WHERE  a.AchatDate >= DATEADD(MONTH ,-1 ,GETDATE())
	       AND b.SourceID = 3 -- SDVP
	       AND COALESCE(b.CategorieProduit ,N'') <> N'NUM' -- Physique
	       AND a.MontantAchat = 0.00 -- Gratuit
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	       INNER JOIN etl.TRANSCO c
	            ON  b.CategorieProduit = c.Origine
	                AND c.TranscoCode = N'ORIGINEACHAT'
	                AND c.SourceId = N'1'
	WHERE  a.AchatDate >= DATEADD(MONTH ,-1 ,GETDATE())
	       AND b.SourceID = 1 -- Neolane
	       AND c.Destination = N'Physique' /* Ici, pas de PVL */
	       AND a.MontantAchat = 0.00 -- Gratuit
	
	
	-- Supprimer ceux qui ont achete un produit quelconque,
	-- numerique ou physique, gratuit ou payant, pour la meme marque
	-- depuis plus d'un mois mais moins de 6 mois
	/* Delete a la fin
	delete a
	from #T_Abos a inner join dbo.AchatsALActe b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueProduits c on b.ProduitID=c.ProduitID
	where a.DebutFinAboDate>b.AchatDate
	and b.AchatDate<DATEADD(month,-1,getdate()) 
	and b.AchatDate>DATEADD(month,-6,getdate()) 
	*/
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 27             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 28	CAPGA	Acheteur ayant acquis depuis moins de six mois un produit physique gratuit.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	WHERE  a.AchatDate >= DATEADD(MONTH ,-6 ,GETDATE())
	       AND b.SourceID = 3 -- SDVP
	       AND COALESCE(b.CategorieProduit ,N'') <> N'NUM' -- Physique
	       AND a.MontantAchat = 0.00 -- Gratuit
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	       INNER JOIN etl.TRANSCO c
	            ON  b.CategorieProduit = c.Origine
	                AND c.TranscoCode = N'ORIGINEACHAT'
	                AND c.SourceId = N'1'
	WHERE  a.AchatDate >= DATEADD(MONTH ,-6 ,GETDATE())
	       AND b.SourceID = 1 -- Neolane
	       AND c.Destination = N'Physique' /* Ici, pas de PVL */
	       AND a.MontantAchat = 0.00 -- Gratuit
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 28             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 29	CAPGI	Ancien acheteur ayant acquis depuis plus de six mois un produit physique gratuit.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	WHERE  a.AchatDate < DATEADD(MONTH ,-6 ,GETDATE())
	       AND b.SourceID = 3 -- SDVP
	       AND COALESCE(b.CategorieProduit ,N'') <> N'NUM' -- Physique
	       AND a.MontantAchat = 0.00 -- Gratuit
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	       INNER JOIN etl.TRANSCO c
	            ON  b.CategorieProduit = c.Origine
	                AND c.TranscoCode = N'ORIGINEACHAT'
	                AND c.SourceId = N'1'
	WHERE  a.AchatDate < DATEADD(MONTH ,-6 ,GETDATE())
	       AND b.SourceID = 1 -- Neolane
	       AND c.Destination = N'Physique' /* Ici, pas de PVL */
	       AND a.MontantAchat = 0.00 -- Gratuit
	
	-- Supprimer ceux qui ont achete un produit quelconque,
	-- numerique ou physique, gratuit ou payant, pour la meme marque
	-- depuis moins de 6 mois
	/* Delete a la fin
	delete a
	from #T_Abos a inner join dbo.AchatsALActe b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueProduits c on b.ProduitID=c.ProduitID
	where b.AchatDate>DATEADD(month,-6,getdate()) 
	*/
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 29             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 30	CAPPN	Nouvel acheteur ayant acquis depuis moins d'un mois un produit physique payant.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	WHERE  a.AchatDate >= DATEADD(MONTH ,-1 ,GETDATE())
	       AND b.SourceID = 3 -- SDVP
	       AND COALESCE(b.CategorieProduit ,N'') <> N'NUM' -- Physique
	       AND a.MontantAchat <> 0.00 -- Payant
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	       INNER JOIN etl.TRANSCO c
	            ON  b.CategorieProduit = c.Origine
	                AND c.TranscoCode = N'ORIGINEACHAT'
	                AND c.SourceId = N'1'
	WHERE  a.AchatDate >= DATEADD(MONTH ,-1 ,GETDATE())
	       AND b.SourceID = 1 -- Neolane
	       AND c.Destination = N'Physique' /* Ici, pas de PVL */
	       AND a.MontantAchat <> 0.00 -- Payant
	
	
	-- Supprimer ceux qui ont achete un produit quelconque,
	-- numerique ou physique, gratuit ou payant, pour la meme marque
	-- depuis plus d'un mois mais moins de 6 mois
	/* Delete a la fin
	delete a
	from #T_Abos a inner join dbo.AchatsALActe b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueProduits c on b.ProduitID=c.ProduitID
	where a.DebutFinAboDate>b.AchatDate
	and b.AchatDate<DATEADD(month,-1,getdate()) 
	and b.AchatDate>DATEADD(month,-6,getdate()) 
	*/
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 30             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 31	CAPPA	Acheteur ayant acquis depuis moins de six mois un produit physique payant.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	WHERE  a.AchatDate >= DATEADD(MONTH ,-6 ,GETDATE())
	       AND b.SourceID = 3 -- SDVP
	       AND COALESCE(b.CategorieProduit ,N'') <> N'NUM' -- Physique
	       AND a.MontantAchat <> 0.00 -- Payant
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	       INNER JOIN etl.TRANSCO c
	            ON  b.CategorieProduit = c.Origine
	                AND c.TranscoCode = N'ORIGINEACHAT'
	                AND c.SourceId = N'1'
	WHERE  a.AchatDate >= DATEADD(MONTH ,-6 ,GETDATE())
	       AND b.SourceID = 1 -- Neolane
	       AND c.Destination = N'Physique' /* Ici, pas de PVL */
	       AND a.MontantAchat <> 0.00 -- Payant
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 31             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 32	CAPPI	Ancien acheteur ayant acquis depuis plus de six mois un produit physique payant.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	WHERE  a.AchatDate < DATEADD(MONTH ,-6 ,GETDATE())
	       AND b.SourceID = 3 -- SDVP
	       AND COALESCE(b.CategorieProduit ,N'') <> N'NUM' -- Physique
	       AND a.MontantAchat <> 0.00 -- Payant
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.AchatDate
	FROM   dbo.AchatsALActe a
	       INNER JOIN ref.CatalogueProduits b
	            ON  a.ProduitID = b.ProduitID
	       INNER JOIN etl.TRANSCO c
	            ON  b.CategorieProduit = c.Origine
	                AND c.TranscoCode = N'ORIGINEACHAT'
	                AND c.SourceId = N'1'
	WHERE  a.AchatDate < DATEADD(MONTH ,-6 ,GETDATE())
	       AND b.SourceID = 1 -- Neolane
	       AND c.Destination = N'Physique' /* Ici, pas de PVL */
	       AND a.MontantAchat <> 0.00 -- Payant
	
	-- Supprimer ceux qui ont achete un produit quelconque,
	-- numerique ou physique, gratuit ou payant, pour la meme marque
	-- depuis moins de 6 mois
	/* Delete a la fin
	delete a
	from #T_Abos a inner join dbo.AchatsALActe b 
	on a.MasterID=b.MasterID 
	and a.MarqueID=b.Marque
	inner join ref.CatalogueProduits c on b.ProduitID=c.ProduitID
	where b.AchatDate>DATEADD(month,-6,getdate()) 
	*/
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 32             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 65	PN	Nouveau prospect inscrit depuis moins d'un mois.
	
	-- Moins d'un mois - par date d'opt-in 
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,b.MarqueID
	      ,a.ConsentementDate
	FROM   dbo.ConsentementsEmail a
	       INNER JOIN ref.Contenus b
	            ON  a.ContenuID = b.ContenuID
	WHERE  b.TypeContenu = 2 -- Marque
	       AND a.Valeur = 1 -- Opt-in
	       AND a.ConsentementDate > DATEADD(MONTH ,-1 ,GETDATE()) 
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	-- Enlever ceux qui ont effectue un achat ou contracte un abonnement
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN dbo.AchatsALActe b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.Marque
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN dbo.Abonnements b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.Marque
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 65             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 66	PA	Prospect actif ayant eu une activite lors des six derniers mois.
	-- La notion d'actif/inactif necessite les resultats de tracking 
	
	-- On a l'activite e-mail deja mais pas encore l'activite Web
	-- Champs dans dbo.ConsentementsEmail :
	-- DernierClickDate	DerniereOuvertureDate
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,b.MarqueID
	      ,a.ConsentementDate
	FROM   dbo.ConsentementsEmail a
	       INNER JOIN ref.Contenus b
	            ON  a.ContenuID = b.ContenuID
	WHERE  b.TypeContenu = 2 -- Marque
	       AND a.Valeur = 1 -- Opt-in
	       AND (
	               a.DerniereOuvertureDate >= DATEADD(MONTH ,-6 ,GETDATE())
	               OR a.DernierClickDate >= DATEADD(MONTH ,-6 ,GETDATE())
	           )
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	-- Enlever ceux qui ont effectue un achat ou contracte un abonnement
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN dbo.AchatsALActe b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.Marque
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN dbo.Abonnements b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.Marque
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 66             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 67	PI	Prospect inactif n'ayant pas eu d'activite lors des six derniers mois.
	-- La notion d'actif/inactif necessite les resultats de tracking 
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,b.MarqueID
	      ,a.ConsentementDate
	FROM   dbo.ConsentementsEmail a
	       INNER JOIN ref.Contenus b
	            ON  a.ContenuID = b.ContenuID
	WHERE  b.TypeContenu = 2 -- Marque
	       AND a.Valeur = 1 -- Opt-in
	       AND (
	               a.DerniereOuvertureDate < DATEADD(MONTH ,-6 ,GETDATE())
	               OR a.DernierClickDate < DATEADD(MONTH ,-6 ,GETDATE())
	               OR a.DerniereOuvertureDate IS NULL
	               OR a.DernierClickDate IS NULL
	           )
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	-- Enlever ceux qui ont effectue un achat ou contracte un abonnement
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN dbo.AchatsALActe b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.Marque
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN dbo.Abonnements b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.Marque
	
	-- Eliminer l'intersection avec le groupe 66
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  b.TypologieID = 66
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 67             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- Commercialisable = commercialisable a l'exterieur = Opt-in Partenaire
	
	-- 68	ON	Nouveau prospect commercialisable inscrit depuis moins d'un mois.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,b.MarqueID
	      ,a.ConsentementDate
	FROM   dbo.ConsentementsEmail a
	       INNER JOIN ref.Contenus b
	            ON  a.ContenuID = b.ContenuID
	WHERE  b.TypeContenu = 3 -- opt-in Partenaire
	       AND a.Valeur = 1 -- Opt-in
	       AND a.ConsentementDate > DATEADD(MONTH ,-1 ,GETDATE()) 
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	-- Enlever ceux qui ont effectue un achat ou contracte un abonnement
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN dbo.AchatsALActe b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.Marque
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN dbo.Abonnements b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.Marque
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 68             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 69	OA	Prospect actif commercialisable ayant eu une activite lors des six derniers mois.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,b.MarqueID
	      ,a.ConsentementDate
	FROM   dbo.ConsentementsEmail a
	       INNER JOIN ref.Contenus b
	            ON  a.ContenuID = b.ContenuID
	WHERE  b.TypeContenu = 3 -- opt-in Partenaire
	       AND a.Valeur = 1 -- Opt-in
	       AND (
	               a.DerniereOuvertureDate >= DATEADD(MONTH ,-6 ,GETDATE())
	               OR a.DernierClickDate >= DATEADD(MONTH ,-6 ,GETDATE())
	           )
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	-- Enlever ceux qui ont effectue un achat ou contracte un abonnement
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN dbo.AchatsALActe b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.Marque
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN dbo.Abonnements b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.Marque
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 69             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	
	-- 70	OI	Prospect inactif commercialisable n'ayant pas eu d'activite lors des six derniers mois.
	-- La notion d'actif/inactif necessite les resultats de tracking 
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,b.MarqueID
	      ,a.ConsentementDate
	FROM   dbo.ConsentementsEmail a
	       INNER JOIN ref.Contenus b
	            ON  a.ContenuID = b.ContenuID
	WHERE  b.TypeContenu = 3 -- opt-in Partenaire
	       AND a.Valeur = 1 -- Opt-in
	       AND (
	               a.DerniereOuvertureDate < DATEADD(MONTH ,-6 ,GETDATE())
	               OR a.DernierClickDate < DATEADD(MONTH ,-6 ,GETDATE())
	               OR a.DerniereOuvertureDate IS NULL
	               OR a.DernierClickDate IS NULL
	           )
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	-- Enlever ceux qui ont effectue un achat ou contracte un abonnement
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN dbo.AchatsALActe b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.Marque
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN dbo.Abonnements b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.Marque
	
	-- Eliminer l'intersection avec le groupe 69
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  b.TypologieID = 69
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 70             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 71	CSPGF	Abonne ayant souscrit un abonnement papier gratuit n'ayant pas encore demarre.
	
	TRUNCATE TABLE #T_Abos
	
	-- SDVP
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.DebutAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.DebutAboDate >= DATEADD(MONTH ,-1 ,GETDATE())
	       AND a.StatutAbo = 1 -- Anticipe
	       AND (
	               COALESCE(a.ModePaiement ,0) IN (23 ,24)
	               OR b.OriginalID LIKE N'%GRATUIT%'
	               OR b.OriginalID LIKE N'% 0E %'
	           ) -- gratuit
	       AND a.SourceID = 3 -- SDVP
	       AND b.SupportAbo = 2 -- Papier
	
	UPDATE a
	SET    Typologie = 71
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 71             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 72	CSPPF	Abonne ayant souscrit un abonnement papier payant n'ayant pas encore demarre.
	
	TRUNCATE TABLE #T_Abos
	
	-- SDVP
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.DebutAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.DebutAboDate >= DATEADD(MONTH ,-1 ,GETDATE())
	       AND a.StatutAbo = 1 -- Anticipe
	       AND NOT (
	               COALESCE(a.ModePaiement ,0) IN (23 ,24)
	               OR b.OriginalID LIKE N'%GRATUIT%'
	               OR b.OriginalID LIKE N'% 0E %'
	           ) -- payant
	       AND a.SourceID = 3 -- SDVP
	       AND b.SupportAbo = 2 -- Papier
	
	UPDATE a
	SET    Typologie = 72
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 72             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	
	-- 73	CSNGF	Abonne ayant souscrit un abonnement numerique gratuit n'ayant pas encore demarre.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.DebutAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.DebutAboDate >= DATEADD(MONTH ,-1 ,GETDATE())
	       AND a.StatutAbo = 1 -- Anticipe
	       AND (
	               (
	                   (
	                       COALESCE(a.ModePaiement ,0) IN (23 ,24)
	                       OR b.OriginalID LIKE N'%GRATUIT%'
	                       OR b.OriginalID LIKE N'% 0E %'
	                   ) -- gratuit
	                   AND a.SourceID = 3
	               ) -- SDVP
	               OR (
	                      a.SourceID IN (1 ,10) -- Neolane et PVL
	                      AND b.MontantAbo = 0.00
	                  )
	           ) -- Gratuit
	       AND b.SupportAbo = 1 -- Numerique
	
	UPDATE a
	SET    Typologie = 73
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 73             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 74	CSNPF	Abonne ayant souscrit un abonnement numerique payant n'ayant pas encore demarre.
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	   ,AbonnementID
	  )
	SELECT a.MasterID
	      ,a.Marque
	      ,a.DebutAboDate
	      ,a.AbonnementID
	FROM   dbo.Abonnements a
	       INNER JOIN ref.CatalogueAbonnements b
	            ON  a.CatalogueAbosID = b.CatalogueAbosID
	WHERE  a.DebutAboDate >= DATEADD(MONTH ,-1 ,GETDATE())
	       AND a.StatutAbo = 1 -- Anticipe
	       AND NOT (
	               (
	                   -- Payant
	                   (
	                       COALESCE(a.ModePaiement ,0) IN (23 ,24)
	                       OR b.OriginalID LIKE N'%GRATUIT%'
	                       OR b.OriginalID LIKE N'% 0E %'
	                   )
	                   AND a.SourceID = 3
	               ) -- SDVP
	               OR (
	                      a.SourceID IN (1 ,10) -- Neolane et PVL
	                      AND b.MontantAbo = 0.00
	                  )
	           )
	       AND b.SupportAbo = 1 -- Numerique
	
	UPDATE a
	SET    Typologie = 74
	FROM   dbo.Abonnements a
	       INNER JOIN #T_Abos b
	            ON  a.AbonnementID = b.AbonnementID
	
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 74             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- Opt-ins editoriaux : 79, 80, 81
	
	-- 79	OEN	Optins editoriaux nouveaux - Contact ayant un opt-in editorial marque actif sur une adresse e-mail valide, inscrit depuis moins d'un mois.
	
	-- Moins d'un mois - par date d'opt-in 
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,b.MarqueID
	      ,a.ConsentementDate
	FROM   dbo.ConsentementsEmail a
	       INNER JOIN ref.Contenus b
	            ON  a.ContenuID = b.ContenuID
	WHERE  b.TypeContenu = 1 -- Editorial
	       AND a.Valeur = 1 -- Opt-in
	       AND a.ConsentementDate > DATEADD(MONTH ,-1 ,GETDATE()) 
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	-- Enlever ceux qui ont effectue un achat ou contracte un abonnement
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN dbo.AchatsALActe b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.Marque
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN dbo.Abonnements b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.Marque
	
	-- Enlever ceux qui ont un opt-in marque ou partenaire
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  b.TypologieID IN (65 ,66 ,67 ,68 ,69 ,70) -- opt-in marque ou partenaire
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 79             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 80	OEA	Optins editoriaux actuels - Contact inscrit depuis plus d'un mois,
	-- ayant un opt-in editorial marque actif sur une adresse e-mail valide,
	-- ayant eu une activite (c'est-a-dire du tracking web et/ou e-mail) lors des six derniers mois (et qui n'est pas "nouveau").
	-- La notion d'actif/inactif necessite les resultats de tracking 
	
	-- On a l'activite e-mail deja mais pas encore l'activite Web
	-- Champs dans dbo.ConsentementsEmail :
	-- DernierClickDate	DerniereOuvertureDate
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,b.MarqueID
	      ,a.ConsentementDate
	FROM   dbo.ConsentementsEmail a
	       INNER JOIN ref.Contenus b
	            ON  a.ContenuID = b.ContenuID
	WHERE  b.TypeContenu = 1 -- Editorial
	       AND a.Valeur = 1 -- Opt-in
	       AND (
	               a.DerniereOuvertureDate >= DATEADD(MONTH ,-6 ,GETDATE())
	               OR a.DernierClickDate >= DATEADD(MONTH ,-6 ,GETDATE())
	           )
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	-- Enlever ceux qui ont effectue un achat ou contracte un abonnement
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN dbo.AchatsALActe b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.Marque
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN dbo.Abonnements b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.Marque
	
	-- Enlever ceux qui ont un opt-in marque ou partenaire
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  (
	           b.TypologieID IN (65 ,66 ,67 ,68 ,69 ,70) -- opt-in marque ou partenaire
	           OR b.TypologieID IN (79) -- Nouveau
	       )
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 80             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- 81	OEI	Optins editoriaux inactifs - Contact ayant un opt-in editorial marque actif sur une adresse e-mail valide,
	-- n'ayant pas eu d'activite (c'est-a-dire du tracking web et/ou e-mail) lors des six derniers mois (et qui n'est ni "nouveau, ni "actuel").
	-- La notion d'actif/inactif necessite les resultats de tracking 
	
	TRUNCATE TABLE #T_Abos
	
	INSERT #T_Abos
	  (
	    MasterID
	   ,MarqueID
	   ,DebutFinAboDate
	  )
	SELECT a.MasterID
	      ,b.MarqueID
	      ,a.ConsentementDate
	FROM   dbo.ConsentementsEmail a
	       INNER JOIN ref.Contenus b
	            ON  a.ContenuID = b.ContenuID
	WHERE  b.TypeContenu = 1 -- Editorial
	       AND a.Valeur = 1 -- Opt-in
	       AND (
	               a.DerniereOuvertureDate < DATEADD(MONTH ,-6 ,GETDATE())
	               OR a.DernierClickDate < DATEADD(MONTH ,-6 ,GETDATE())
	               OR a.DerniereOuvertureDate IS NULL
	               OR a.DernierClickDate IS NULL
	           )
	
	-- Eliminer les doublons eventuels
	TRUNCATE TABLE #T_Abos_Agreg
	
	INSERT #T_Abos_Agreg
	  (
	    N
	   ,MasterID
	   ,MarqueID
	  )
	SELECT COUNT(*)  AS N
	      ,MasterID
	      ,MarqueID
	FROM   #T_Abos      a
	GROUP BY
	       MasterID
	      ,MarqueID
	
	-- Enlever ceux qui ont effectue un achat ou contracte un abonnement
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN dbo.AchatsALActe b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.Marque
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN dbo.Abonnements b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.Marque
	
	DELETE a
	FROM   #T_Abos_Agreg a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  (
	           b.TypologieID IN (65 ,66 ,67 ,68 ,69 ,70) -- opt-in marque ou partenaire
	           OR b.TypologieID IN (79 ,80) -- Nouveau et actif
	       )
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 81             AS TypologieID
	      ,a.MasterID
	      ,a.MarqueID
	FROM   #T_Abos_Agreg     a
	
	-- Effectuer les suppressions en fonction du tableau des priorites des typologies
	
	-- Suppressions dans les typologies des abonnements
	
	-- Supprimer les nouveaux abonnements face aux abonnements actuels 
	
	--VI
	--VIMN 
	;
	WITH firstVisite AS (
	         SELECT masterID
	               ,marque
	               ,MIN(vw.DateVisite)     minDateVisite
	         FROM   etl.VisitesWeb      AS vw
	                INNER JOIN ref.SitesWeb AS sw
	                     ON  vw.SiteId = sw.WebSiteID
	         WHERE  masterId IS NOT NULL
	         GROUP BY
	                vw.MasterID
	               ,marque
	         HAVING MIN(vw.DateVisite) >= DATEADD(MONTH ,-1 ,GETDATE())
	     )
	     , xxx AS (
	         SELECT vw.masterID
	               ,marque
	               ,DateVisite
	         FROM   etl.VisitesWeb vw
	                INNER JOIN firstVisite f
	                     ON  f.masterID = vw.MasterID
	                         AND minDateVisite = vw.DateVisite
	     )
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 86      AS TypologieID
	      ,masterID
	      ,marque  AS MarqueID
	FROM   xxx
	GROUP BY
	       masterID
	      ,marque
	
	
	--VIMA
	;
	WITH firstVisite AS (
	         SELECT masterID
	               ,marque
	               ,MAX(vw.DateVisite)     maxDateVisite
	         FROM   etl.VisitesWeb      AS vw
	                INNER JOIN ref.SitesWeb AS sw
	                     ON  vw.SiteId = sw.WebSiteID
	         WHERE  masterId IS NOT NULL
	         GROUP BY
	                vw.MasterID
	               ,marque
	         HAVING MAX(vw.DateVisite) >= DATEADD(MONTH ,-6 ,GETDATE())
	         AND MAX(vw.DateVisite) < DATEADD(MONTH ,-1 ,GETDATE())
	     )
	     , xxx AS (
	         SELECT vw.masterID
	               ,marque
	               ,DateVisite
	         FROM   etl.VisitesWeb vw
	                INNER JOIN firstVisite f
	                     ON  f.masterID = vw.MasterID
	                         AND maxDateVisite = vw.DateVisite
	     )
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 87      AS TypologieID
	      ,masterID
	      ,marque  AS MarqueID
	FROM   xxx
	GROUP BY
	       masterID
	      ,marque
	
	--VIMI       
	;
	WITH firstVisite AS (
	         SELECT masterID
	               ,marque
	               ,MAX(vw.DateVisite)     MaxDateVisite
	         FROM   etl.VisitesWeb      AS vw
	                INNER JOIN ref.SitesWeb AS sw
	                     ON  vw.SiteId = sw.WebSiteID
	         WHERE  masterId IS NOT NULL
	         GROUP BY
	                vw.MasterID
	               ,marque
	         HAVING MAX(vw.DateVisite) < DATEADD(MONTH ,-6 ,GETDATE())
	     )
	     , xxx AS (
	         SELECT vw.masterID
	               ,marque
	               ,DateVisite
	         FROM   etl.VisitesWeb vw
	                INNER JOIN firstVisite f
	                     ON  f.masterID = vw.MasterID
	                         AND maxDateVisite = vw.DateVisite
	     )
	
	INSERT #T_Lignes_Typologies
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT 88      AS TypologieID
	      ,masterID
	      ,marque  AS MarqueID
	FROM   xxx
	GROUP BY
	       masterID
	      ,marque
	--end VI
	
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	                AND a.TypologieID + 1 = b.TypologieID
	WHERE  a.TypologieID IN (1 ,6 ,11 ,16) -- Nouveaux
	                                       -- and b.TypologieID in (2,7,12,17) -- Actuels
	
	-- Supprimer les nouveaux abonnements face aux abonnements "en renouvellement" 
	
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	                AND a.TypologieID + 2 = b.TypologieID
	WHERE  a.TypologieID IN (1 ,6 ,11 ,16) -- Nouveaux
	                                       -- and b.TypologieID in (3,8,13,18) -- En renouvellement
	
	-- Supprimer les abonnements actuels face aux abonnements "en renouvellement" 
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	                AND a.TypologieID + 1 = b.TypologieID
	WHERE  a.TypologieID IN (2 ,7 ,12 ,17) -- Actuels
	                                       -- and b.TypologieID in (3,8,13,18) -- En renouvellement
	
	-- Supprimer les abonnements "en renouvellement" face aux abonnements futurs
	
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	                AND (70 + ((a.TypologieID + 2) / 5)) = b.TypologieID
	WHERE  a.TypologieID IN (3 ,8 ,13 ,18) -- En renouvellement
	
	-- Recents doivent etre supprimes face aux nouveaux, actuels, en renouvellement, futurs
	
	-- Recents doivent etre supprimes face aux nouveaux
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	                AND a.TypologieID -3 = b.TypologieID
	WHERE  a.TypologieID IN (4 ,9 ,14 ,19) -- Recents
	                                       -- and b.TypologieID in (1,6,11,16) -- Nouveaux
	
	-- ...aux actuels
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	                AND a.TypologieID -2 = b.TypologieID
	WHERE  a.TypologieID IN (4 ,9 ,14 ,19) -- Recents
	                                       -- and b.TypologieID in (2,7,12,17) -- Actuels
	
	-- ... en renouvellement
	
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	                AND a.TypologieID -1 = b.TypologieID
	WHERE  a.TypologieID IN (4 ,9 ,14 ,19) -- Recents
	                                       -- and b.TypologieID in (3,8,13,18) -- En renouvellement
	
	-- ... futurs
	
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	                AND (70 + ((a.TypologieID + 1) / 5)) = b.TypologieID
	WHERE  a.TypologieID IN (4 ,9 ,14 ,19) -- Recents
	
	
	-- Inactifs doivent etre supprimes face a tous les autres : nouveaux, actuels, en renouvellement, recents, futurs
	-- ... aux nouveaux
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	                AND a.TypologieID -4 = b.TypologieID
	WHERE  a.TypologieID IN (5 ,10 ,15 ,20) -- Inactifs
	                                        -- and b.TypologieID in (1,6,11,16) -- Nouveaux
	
	-- ... aux actuels
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	                AND a.TypologieID -3 = b.TypologieID
	WHERE  a.TypologieID IN (5 ,10 ,15 ,20) -- Inactifs
	                                        -- and b.TypologieID in (2,7,12,17) -- Actuels
	
	-- ... En renouvellement 
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	                AND a.TypologieID -2 = b.TypologieID
	WHERE  a.TypologieID IN (5 ,10 ,15 ,20) -- Inactifs
	                                        -- and b.TypologieID in (3,8,13,18) -- En renouvellement
	
	-- ... Recents
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	                AND a.TypologieID -1 = b.TypologieID
	WHERE  a.TypologieID IN (5 ,10 ,15 ,20) -- Inactifs
	                                        -- and b.TypologieID in (4,9,14,19) -- Recents
	
	-- ... futurs
	
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	                AND (70 + (a.TypologieID / 5)) = b.TypologieID
	WHERE  a.TypologieID IN (5 ,10 ,15 ,20) -- Inactifs
	
	-- Futurs doivent etre supprimes face aux actuels et nouveaux :
	
	-- ... nouveaux
	DELETE b
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	                AND (70 + (a.TypologieID / 5)) = b.TypologieID
	WHERE  a.TypologieID IN (1 ,6 ,11 ,16) -- Nouveaux
	
	-- ... actuels
	DELETE b
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	                AND (70 + (a.TypologieID / 5)) + 1 = b.TypologieID
	WHERE  a.TypologieID IN (2 ,7 ,12 ,17) -- Actuels
	
	-- Suppressions dans les typologies des achats
	
	-- Actuels face aux nouveaux
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	                AND a.TypologieID -1 = b.TypologieID
	WHERE  a.TypologieID IN (22 ,25 ,28 ,31) -- Actuels
	                                         -- and b.TypologieID in (21,24,27,30) -- Nouveaux
	
	-- Inactifs face aux nouveaux et actuels
	
	-- Inactifs face aux nouveaux
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	                AND a.TypologieID -2 = b.TypologieID
	WHERE  a.TypologieID IN (23 ,26 ,29 ,32) -- Inactifs
	                                         -- and b.TypologieID in (21,24,27,30) -- Nouveaux
	
	-- Inactifs face aux actuels
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	                AND a.TypologieID -1 = b.TypologieID
	WHERE  a.TypologieID IN (23 ,26 ,29 ,32) -- Inactifs
	                                         -- and b.TypologieID in (22,25,28,31) -- Actuels
	
	-- Suppressions dans les typologies des opt-ins marque et partenaires
	
	-- Opt-in Marques
	
	-- Actuels face aux nouveaux
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  a.TypologieID = 66 -- Actuels
	       AND b.TypologieID = 65 -- Nouveaux
	
	-- Inactifs face aux nouveaux et actuels
	
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  a.TypologieID = 67 -- Inactifs
	       AND b.TypologieID = 65 -- Nouveaux
	
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  a.TypologieID = 67 -- Inactifs
	       AND b.TypologieID = 66 -- Actuels
	
	
	-- Opt-in Partenaires
	
	-- Actuels face aux nouveaux
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  a.TypologieID = 69 -- Actuels
	       AND b.TypologieID = 68 -- Nouveaux
	
	-- Inactifs face aux nouveaux et actuels
	
	-- Inactifs face aux nouveaux	
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  a.TypologieID = 70 -- Inactifs
	       AND b.TypologieID = 68 -- Nouveaux
	
	-- Inactifs face aux actuels	
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  a.TypologieID = 70 -- Inactifs
	       AND b.TypologieID = 69 -- Actuels
	
	--delete conflicts for a ....termines typologies
	--82
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  a.TypologieID = 82
	       AND b.TypologieID IN (1 ,2 ,3) 
	--83
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  a.TypologieID = 83
	       AND b.TypologieID IN (6 ,7 ,8) 
	--84
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  a.TypologieID = 84
	       AND b.TypologieID IN (11 ,12 ,13) 
	--85
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  a.TypologieID = 84
	       AND b.TypologieID IN (16 ,17 ,18) 
	
	-- Apres que toutes les typologies ont ete calculees dans une table temporaire,
	-- on les insere dans la table dbo.Typologie
	-- Comme a chaque fois la table temporaire contient l'ensemble des typologies,
	-- dbo.Typologie est tronquee 
	
	TRUNCATE TABLE dbo.Typologie
	
	INSERT dbo.Typologie
	  (
	    TypologieID
	   ,MasterID
	   ,MarqueID
	  )
	SELECT TypologieID
	      ,MasterID
	      ,MarqueID
	FROM   #T_Lignes_Typologies
	
	
	IF OBJECT_ID('tempdb..#T_Lignes_Typologies') IS NOT NULL
	    DROP TABLE #T_Lignes_Typologies
	
	IF OBJECT_ID('tempdb..#T_Abos') IS NOT NULL
	    DROP TABLE #T_Abos
	
	IF OBJECT_ID('tempdb..#T_Abos_Agreg') IS NOT NULL
	    DROP TABLE #T_Abos_Agreg
END

