

USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [etl].[BuildTypologies]    Script Date: 07/02/2015 11:35:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc [etl].[BuildTypologies]
as

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
-- Modification date :	20/07/2015
-- Modified by :		Andrei BRAGAR
-- Modifications : changes in OEN, OEA, OEI  
-- =============================================


begin

set nocount on

declare @SourceID_NEO int
declare @SourceID_LPSSO int
declare @SourceID_SDVP int
declare @SourceID_LPPROSP int
declare @SourceID_PVL int

select @SourceID_NEO = 1		-- Neolane
select @SourceID_LPSSO = 2		-- LSSO LP
select @SourceID_SDVP = 3		-- SDVP
select @SourceID_LPPROSP = 4	-- Prospects LP
select @SourceID_PVL = 10		-- Vente en ligne

-- Création de table temporaire

 if OBJECT_ID('tempdb..#T_Lignes_Typologies') is not null
	drop table #T_Lignes_Typologies
	
create table #T_Lignes_Typologies
(
TypologieID int not null
, MasterID int null
, MarqueID int null
)

-- #T_Abos_Agreg - Table de lignes agrégées
-- Tronquée et réutilisée pour chaque typologie

if OBJECT_ID('tempdb..#T_Abos_Agreg') is not null
	drop table #T_Abos_Agreg
 
create table #T_Abos_Agreg
(
N int not null
, MasterID int null
, MarqueID int null
)

if OBJECT_ID('tempdb..#T_Abos') is not null
	drop table #T_Abos
	
create table #T_Abos
(
MasterID int null
, MarqueID int null
, DebutFinAboDate datetime null
, AbonnementID int null
)

-- Typologies 1 - 20 : Abonnements, papier et numériques, gratuits et payants

-- 1. Nouvel abonné ayant souscrit depuis moins d'un mois son premier abonnement papier gratuit 
-- (et dont le dernier abonnement, s'il y en a eu, et que celui-ci soit numérique ou papier, payant ou gratuit, est arrêté depuis plus de six mois).	

-- Nouvel abonné : c'est son premier abonnement pour la marque depuis 6 mois (peut être un faux nouveau)

truncate table #T_Abos

-- SDVP
insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.DebutAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.DebutAboDate>=DATEADD(month,-1,getdate())
and 
a.StatutAbo = 3 -- en cours 
and (coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- gratuit
and a.SourceID=3 -- SDVP
and b.SupportAbo=2 -- Papier

update a
set Typologie=1
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

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
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
1 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a


-- 2	CAPGA	Abonné actif depuis plus d'un mois ayant souscrit un abonnement papier gratuit.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.DebutAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.DebutAboDate<DATEADD(month,-1,getdate())
and a.StatutAbo=3 -- en cours
and (coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- gratuit
and a.SourceID=3 -- SDVP
and b.SupportAbo=2 -- Papier

update a
set Typologie=2
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

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
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
2 as TypologieID
, a.MasterID
, a.MarqueID
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
, MasterID
, MarqueID
)
select
3 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

update a
set Typologie=3
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

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
		   and b.SupportAbo=2 -- Papier
	       AND a.StatutAbo = 2 
	       AND b.MontantAbo = 0.00 -- Gratuit
	       AND DATEDIFF(DAY ,GETDATE() ,a.FinAboDate) BETWEEN -14 AND 0 
	
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
	
-- 4	CAPGR	Abonné récent dont l'abonnement papier gratuit est arrêté depuis moins de six mois.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.FinAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.FinAboDate>DATEADD(month,-6,getdate()) and not (datediff(day,getdate(),a.FinAboDate) between -14 and 0)
and a.StatutAbo=2 -- Echu
and (coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- gratuit
and a.SourceID=3 -- SDVP
and b.SupportAbo=2 -- Papier

update a
set Typologie=4
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

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
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
4 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 5	CAPGI	Ancien abonné dont l'abonnement papier gratuit est arrêté depuis plus de six mois.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.FinAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.FinAboDate<=DATEADD(month,-6,getdate())
and a.StatutAbo=2 -- Echu
and (coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- gratuit
and a.SourceID=3 -- SDVP
and b.SupportAbo=2 -- Papier

update a
set Typologie=5
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

-- Supprimer ceux qui ont un abonnement papier gratuit pour la même marque actif ou anticipé
-- ou échu depuis moins de 6 mois
/* Delete à la fin
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
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
5 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a


-- 6	CAPPN	Nouvel abonné ayant souscrit depuis moins d'un mois un abonnement papier payant.
-- Nouvel abonné : c'est son premier abonnement pour la marque depuis 6 mois (peut être un faux nouveau)

truncate table #T_Abos

-- SDVP
insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.DebutAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.DebutAboDate>=DATEADD(month,-1,getdate())
and 
a.StatutAbo=3 -- en cours
and not (coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- payant SDVP
and a.SourceID=3 -- SDVP
and b.SupportAbo=2 -- Papier

update a
set Typologie=6
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

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
/* Delete à la fin
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
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
6 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a


-- 7	CAPPA	Abonné actif depuis plus d'un mois ayant souscrit un abonnement papier payant.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.DebutAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.DebutAboDate<DATEADD(month,-1,getdate())
and a.StatutAbo=3 -- en cours
and not (coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- payant
and a.SourceID=3 -- SDVP
and b.SupportAbo=2 -- Papier

update a
set Typologie=7
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

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

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
7 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 8	CAPPE	Abonné en période de renouvellement d'un abonnement papier payant.

-- Neolane - pas d'abonnement papier
-- SDVP - même problème que dans 3 CAPGE

truncate table #T_Abos

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
and b.Recurrent=0 -- à durée ferme
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
and b.Recurrent=0 -- à durée ferme
and a.StatutAbo=3 -- Actif
and b.MontantAbo<>0.00 -- Payant
and datediff(day,a.ReaboDate,getdate()) between 0 and 14 -- deux semaines après la date de réabonnement
*/

update a
set Typologie=8
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
8 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

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
			and b.SupportAbo=2 -- Papier
	       AND a.StatutAbo = 2
	       AND b.MontantAbo <> 0.00 -- Payant
	       AND DATEDIFF(DAY ,GETDATE() ,a.FinAboDate) BETWEEN -14 AND 0

	
	
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

-- 9	CAPPR	Abonné récent dont l'abonnement papier payant est arrêté depuis moins de six mois.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.FinAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.FinAboDate>DATEADD(month,-6,getdate()) and not (datediff(day,getdate(),a.FinAboDate) between -14 and 0)
and a.StatutAbo=2 -- Echu
and not (coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- payant
and a.SourceID=3 -- SDVP
and b.SupportAbo=2 -- Papier

update a
set Typologie=9
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

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

-- Supprimer ceux qui ont un abonnement papier payant pour la même marque actif ou anticipé
/* Delete à la fin
delete a
from #T_Abos a inner join dbo.Abonnements b 
on a.MasterID=b.MasterID 
and a.MarqueID=b.Marque
inner join ref.CatalogueAbonnements c
on b.CatalogueAbosID=c.CatalogueAbosID
where b.StatutAbo in (1,3) -- actif ou anticipé
and 
(b.SourceID=3 -- SDVP
and not (coalesce(b.ModePaiement,0) in (23,24) or c.OriginalID like N'%GRATUIT%' or c.OriginalID like N'% 0E %') -- payant
)
and c.SupportAbo=2 -- Papier -- ICI
*/

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
9 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 10	CAPPI	Ancien abonné dont l'abonnement papier payant est arrêté depuis plus de six mois.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.FinAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.FinAboDate<=DATEADD(month,-6,getdate())
and a.StatutAbo=2 -- Echu
and not (coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- payant
and a.SourceID=3 -- SDVP
and b.SupportAbo=2 -- Papier

update a
set Typologie=10
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

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

-- Supprimer ceux qui ont un abonnement payant pour la même marque actif ou anticipé
-- ou échu depuis moins de 6 mois
/* Delete à la fin
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
and not (coalesce(b.ModePaiement,0) in (23,24) or c.OriginalID like N'%GRATUIT%' or c.OriginalID like N'% 0E %') -- payant
)
)
and c.SupportAbo=2 -- Papier
*/

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
10 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 11	CANGN	Nouvel abonné ayant souscrit depuis moins d'un mois un abonnement numérique gratuit.

truncate table #T_Abos

-- SDVP
insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.DebutAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.DebutAboDate>=DATEADD(month,-1,getdate())
and 
a.StatutAbo=3 -- en cours
and
(coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- gratuit
and a.SourceID=3 -- SDVP
and b.SupportAbo=1 -- Numérique

-- Neolane
insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.DebutAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.DebutAboDate>=DATEADD(month,-1,getdate())
and a.StatutAbo=3 -- en cours
and a.SourceID in (1,10) -- Neolane et PVL
and b.MontantAbo=0.00 -- Gratuit
and b.SupportAbo=1 -- Numérique

update a
set Typologie=11
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID


-- Supprimer ceux qui ont eu un abonnement pour la même marque 
-- depuis plus d'un mois mais moins de 6 mois
/* Delete à la fin
delete a
from #T_Abos a inner join dbo.Abonnements b 
on a.MasterID=b.MasterID 
and a.MarqueID=b.Marque
inner join ref.CatalogueAbonnements c on b.CatalogueAbosID=c.CatalogueAbosID
where a.DebutFinAboDate>b.DebutAboDate
and b.DebutAboDate<DATEADD(month,-1,getdate()) 
and b.DebutAboDate>DATEADD(month,-6,getdate()) 
and c.SupportAbo=1 -- Numérique
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
-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
11 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 12	CANGA	Abonné actif depuis plus d'un mois ayant souscrit un abonnement numérique gratuit.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.DebutAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.DebutAboDate<DATEADD(month,-1,getdate())
and a.StatutAbo=3 -- en cours
and (coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- gratuit
and a.SourceID=3 -- SDVP
and b.SupportAbo=1 -- Numérique


insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.DebutAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.DebutAboDate<DATEADD(month,-1,getdate())
and a.StatutAbo=3 -- en cours
and a.SourceID in (1,10) -- Neolane et PVL
and b.MontantAbo=0.00 -- Gratuit
and b.SupportAbo=1 -- Numérique

update a
set Typologie=12
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID


-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
12 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 13	CANGE	Abonné en période de renouvellement d'un abonnement numérique gratuit.

truncate table #T_Abos

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
where a.SourceID in (1,10) -- Neolane et PVL
and b.Recurrent=0 -- à durée ferme
and a.StatutAbo=3 -- Actif
and b.MontantAbo=0.00 -- Gratuit
and b.SupportAbo=1 -- Numérique
and datediff(day,getdate(),a.FinAboDate) between 0 and 14 -- deux semaines avant la date de fin


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
where a.SourceID in (1,10) -- Neolane et PVL
and b.Recurrent=0 -- à durée ferme
and a.StatutAbo=3 -- Actif
and b.MontantAbo=0.00 -- Gratuit
and b.SupportAbo=1 -- Numérique
and datediff(day,a.ReaboDate,getdate()) between 0 and 14 -- deux semaines après la date de réabonnement

update a
set Typologie=13
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
13 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

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
	       AND a.StatutAbo = 2 
	       AND b.MontantAbo = 0.00 -- Gratuit
	       AND b.SupportAbo = 1 -- Numerique
	       AND DATEDIFF(DAY ,GETDATE() ,a.FinAboDate) BETWEEN -14 AND 0
	
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

-- 14	CANGR	Abonné récent dont l'abonnement numérique gratuit est arrêté depuis moins de six mois.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.FinAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.FinAboDate>DATEADD(month,-6,getdate()) and not (datediff(day,getdate(),a.FinAboDate) between -14 and 0)
and a.StatutAbo=2 -- Echu
and (coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- gratuit
and a.SourceID=3 -- SDVP
and b.SupportAbo=1 -- Numérique

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.FinAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.FinAboDate>DATEADD(month,-6,getdate())
and a.StatutAbo=2 -- Echu
and a.SourceID in (1,10) -- Neolane et PVL
and b.MontantAbo=0.00 -- Gratuit
and b.SupportAbo=1 -- Numérique

update a
set Typologie=14
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

-- Supprimer ceux qui ont un abonnement pour la même marque actif ou anticipé 
/* Delete à la fin 
delete a
from #T_Abos a inner join dbo.Abonnements b 
on a.MasterID=b.MasterID 
and a.MarqueID=b.Marque
inner join ref.CatalogueAbonnements c
on b.CatalogueAbosID=c.CatalogueAbosID
where 
b.StatutAbo in (1,3) -- actif ou anticipé 
and (
(b.SourceID=3 -- SDVP
and (coalesce(b.ModePaiement,0) in (23,24) or c.OriginalID like N'%GRATUIT%' or c.OriginalID like N'% 0E %') -- gratuit
)
or (b.SourceID=1 -- Neolane
	and c.MontantAbo=0.00 -- Gratuit
	 )
)
and c.SupportAbo=1 -- Numérique
*/
-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
14 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 15	CANGI	Ancien abonné dont l'abonnement numérique gratuit est arrêté depuis plus de six mois.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.FinAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.FinAboDate<=DATEADD(month,-6,getdate())
and a.StatutAbo=2 -- Echu
and (coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- gratuit
and a.SourceID=3 -- SDVP
and b.SupportAbo=1 -- Numérique

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.FinAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.FinAboDate<=DATEADD(month,-6,getdate())
and a.StatutAbo=2 -- Echu
and a.SourceID in (1,10) -- Neolane et PVL
and b.MontantAbo=0.00 -- Gratuit
and b.SupportAbo=1 -- Numérique

update a
set Typologie=15
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

-- Supprimer ceux qui ont un abonnement gratuit pour la même marque actif ou anticipé
-- ou échu depuis moins de 6 mois
/* Delete à la fin
delete a
from #T_Abos a inner join dbo.Abonnements b 
on a.MasterID=b.MasterID 
and a.MarqueID=b.Marque
inner join ref.CatalogueAbonnements c on b.CatalogueAbosID=c.CatalogueAbosID
where (
(b.StatutAbo in (1,3)) -- actif ou anticipé
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
and c.SupportAbo=1 -- Numérique
*/

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
15 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 16	CANPN	Nouvel abonné ayant souscrit depuis moins d'un mois un abonnement numérique payant.

truncate table #T_Abos

-- SDVP
insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.DebutAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.DebutAboDate>=DATEADD(month,-1,getdate())
and 
a.StatutAbo=3 -- en cours
and
not (coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- payant
and a.SourceID=3 -- SDVP
and b.SupportAbo=1 -- Numérique

-- Neolane
insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.DebutAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.DebutAboDate>=DATEADD(month,-1,getdate())
and a.StatutAbo=3 -- en cours
and a.SourceID in (1,10) -- Neolane et PVL
and b.MontantAbo<>0.00 -- payant
and b.SupportAbo=1 -- Numérique

update a
set Typologie=16
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

-- Supprimer ceux qui ont eu un abonnement payant pour la même marque 
-- depuis plus d'un mois mais moins de 6 mois
/* Delete à la fin
delete a
from #T_Abos a inner join dbo.Abonnements b 
on a.MasterID=b.MasterID 
and a.MarqueID=b.Marque
inner join ref.CatalogueAbonnements c on b.CatalogueAbosID=c.CatalogueAbosID
where a.DebutFinAboDate>b.DebutAboDate
and b.DebutAboDate<DATEADD(month,-1,getdate()) 
and b.DebutAboDate>DATEADD(month,-6,getdate()) 
and c.SupportAbo=1 -- Numérique
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

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
16 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 17	CANPA	Abonné actif depuis plus d'un mois ayant souscrit un abonnement numérique payant.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.DebutAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.DebutAboDate<DATEADD(month,-1,getdate())
and a.StatutAbo=3 -- en cours
and not (coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- payant
and a.SourceID=3 -- SDVP
and b.SupportAbo=1 -- Numérique


insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.DebutAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.DebutAboDate<DATEADD(month,-1,getdate())
and a.StatutAbo=3 -- en cours
and a.SourceID in (1,10) -- Neolane et PVL
and b.MontantAbo<>0.00 -- payant
and b.SupportAbo=1 -- Numérique

update a
set Typologie=17
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
17 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 18	CANPE	Abonné en période de renouvellement d'un abonnement numérique payant.

truncate table #T_Abos

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
where a.SourceID in (1,10) -- Neolane et PVL
and b.Recurrent=0 -- à durée ferme
and a.StatutAbo=3 -- Actif
and b.MontantAbo<>0.00 -- Payant
and b.SupportAbo=1 -- Numérique
and datediff(day,getdate(),a.FinAboDate) between 0 and 14 -- deux semaines avant la date de fin


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
where a.SourceID in (1,10) -- Neolane et PVL
and b.Recurrent=0 -- à durée ferme
and a.StatutAbo=3 -- Actif
and b.MontantAbo<>0.00 -- Payant
and b.SupportAbo=1 -- Numérique
and datediff(day,a.ReaboDate,getdate()) between 0 and 14 -- deux semaines après la date de réabonnement

update a
set Typologie=18
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID


-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
18 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

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
	       AND a.StatutAbo = 2
	       AND b.MontantAbo <> 0.00 -- Payant
	       AND b.SupportAbo = 1 -- Numerique
	       AND DATEDIFF(DAY ,GETDATE() ,a.FinAboDate) BETWEEN -14 AND 0
	
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

-- 19	CANPR	Abonné récent dont l'abonnement numérique payant est arrêté depuis moins de six mois.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.FinAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.FinAboDate>DATEADD(month,-6,getdate()) and not (datediff(day,getdate(),a.FinAboDate) between -14 and 0)
and a.StatutAbo=2 -- Echu
and not (coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- Payant
and a.SourceID=3 -- SDVP
and b.SupportAbo=1 -- Numérique

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.FinAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.FinAboDate>DATEADD(month,-6,getdate())
and a.StatutAbo=2 -- Echu
and a.SourceID in (1,10) -- Neolane et PVL
and b.MontantAbo<>0.00 -- Payant
and b.SupportAbo=1 -- Numérique

update a
set Typologie=19
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

-- Supprimer ceux qui ont un abonnement pour la même marque actif ou anticipé  
/* Delete à la fin
delete a
from #T_Abos a inner join dbo.Abonnements b 
on a.MasterID=b.MasterID 
and a.MarqueID=b.Marque
inner join ref.CatalogueAbonnements c
on b.CatalogueAbosID=c.CatalogueAbosID
where 
b.StatutAbo in (1,3) -- actif ou anticipé 
and (
(b.SourceID=3 -- SDVP
and not ((coalesce(b.ModePaiement,0) in (23,24) or c.OriginalID like N'%GRATUIT%' or c.OriginalID like N'% 0E %')) -- Payant
)
or (b.SourceID=1 -- Neolane
	and c.MontantAbo<>0.00 -- Payant
	 )
)
and c.SupportAbo=1 -- Numérique
*/

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
19 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 20	CANPI	Ancien abonné dont l'abonnement numérique payant est arrêté depuis plus de six mois.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.FinAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.FinAboDate<=DATEADD(month,-6,getdate())
and a.StatutAbo=2 -- Echu
and not (coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- Payant
and a.SourceID=3 -- SDVP
and b.SupportAbo=1 -- Numérique

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.FinAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.FinAboDate<=DATEADD(month,-6,getdate())
and a.StatutAbo=2 -- Echu
and a.SourceID in (1,10) -- Neolane et PVL
and b.MontantAbo<>0.00 -- Payant
and b.SupportAbo=1 -- Numérique

update a
set Typologie=20
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

-- Supprimer ceux qui ont un abonnement payant pour la même marque actif ou anticipé
-- ou échu depuis moins de 6 mois
/* Delete à la fin
delete a
from #T_Abos a inner join dbo.Abonnements b 
on a.MasterID=b.MasterID 
and a.MarqueID=b.Marque
inner join ref.CatalogueAbonnements c on b.CatalogueAbosID=c.CatalogueAbosID
where (
(b.StatutAbo in (1,3)) -- actif ou anticipé
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
and c.SupportAbo=1 -- Numérique
*/

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
20 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- Typologies 21-32 : Achats à l'acte, produits physiques et numériques, gratuits et payants

-- 21	CAPGN	Nouvel acheteur ayant acquis depuis moins d'un mois un produit numérique gratuit.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, a.Marque
, a.AchatDate
from dbo.AchatsALActe a
inner join ref.CatalogueProduits b
on a.ProduitID=b.ProduitID
where a.AchatDate>=DATEADD(month,-1,getdate())
and b.SourceID in (1,3,10)
and b.Physique = 0  --Num
and a.MontantAchat=0.00 -- Gratuit

-- Supprimer ceux qui ont acheté un produit quelconque, 
-- numérique ou physique, gratuit ou payant, pour la même marque 
-- depuis plus d'un mois mais moins de 6 mois
/* Delete à la fin
delete a
from #T_Abos a inner join dbo.AchatsALActe b 
on a.MasterID=b.MasterID 
and a.MarqueID=b.Marque
inner join ref.CatalogueProduits c on b.ProduitID=c.ProduitID
where a.DebutFinAboDate>b.AchatDate
and b.AchatDate<DATEADD(month,-1,getdate()) 
and b.AchatDate>DATEADD(month,-6,getdate()) 
*/

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
21 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 22	CAPGA	Acheteur ayant acquis depuis moins de six mois un produit numérique gratuit.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, a.Marque
, a.AchatDate
from dbo.AchatsALActe a
inner join ref.CatalogueProduits b
on a.ProduitID=b.ProduitID
where a.AchatDate>=DATEADD(month,-6,getdate())
and b.SourceID in (1,3,10)
and b.Physique = 0 
--coalesce(b.CategorieProduit,N'')=N'NUM'
and a.MontantAchat=0.00 -- Gratuit

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
22 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 23	CAPGI	Ancien acheteur ayant acquis depuis plus de six mois un produit numérique gratuit.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, a.Marque
, a.AchatDate
from dbo.AchatsALActe a
inner join ref.CatalogueProduits b
on a.ProduitID=b.ProduitID
where a.AchatDate<DATEADD(month,-6,getdate())
and b.SourceID in (1,3,10)
and b.Physique = 0 
and a.MontantAchat=0.00 -- Gratuit

-- Supprimer ceux qui ont acheté un produit quelconque, 
-- numérique ou physique, gratuit ou payant, pour la même marque 
-- depuis moins de 6 mois
/* Delete à la fin
delete a
from #T_Abos a inner join dbo.AchatsALActe b 
on a.MasterID=b.MasterID 
and a.MarqueID=b.Marque
inner join ref.CatalogueProduits c on b.ProduitID=c.ProduitID
where b.AchatDate>DATEADD(month,-6,getdate()) 
*/

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
23 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 24	CAPPN	Nouvel acheteur ayant acquis depuis moins d'un mois un produit numérique payant.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, a.Marque
, a.AchatDate
from dbo.AchatsALActe a
inner join ref.CatalogueProduits b
on a.ProduitID=b.ProduitID
where a.AchatDate>=DATEADD(month,-1,getdate())
and b.SourceID in (1,3,10)
and b.Physique = 0 
and a.MontantAchat<>0.00 -- Payant

-- Supprimer ceux qui ont acheté un produit quelconque, 
-- numérique ou physique, gratuit ou payant, pour la même marque 
-- depuis plus d'un mois mais moins de 6 mois
/* Delete à la fin
delete a
from #T_Abos a inner join dbo.AchatsALActe b 
on a.MasterID=b.MasterID 
and a.MarqueID=b.Marque
inner join ref.CatalogueProduits c on b.ProduitID=c.ProduitID
where a.DebutFinAboDate>b.AchatDate
and b.AchatDate<DATEADD(month,-1,getdate()) 
and b.AchatDate>DATEADD(month,-6,getdate()) 
*/

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
24 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 25	CAPPA	Acheteur ayant acquis depuis moins de six mois un produit numérique payant.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, a.Marque
, a.AchatDate
from dbo.AchatsALActe a
inner join ref.CatalogueProduits b
on a.ProduitID=b.ProduitID
where a.AchatDate>=DATEADD(month,-6,getdate())
and b.SourceID in (1,3,10)
and b.Physique = 0 
and a.MontantAchat<>0.00 -- Payant

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
25 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 26	CAPPI	Ancien acheteur ayant acquis depuis plus de six mois un produit numérique payant.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, a.Marque
, a.AchatDate
from dbo.AchatsALActe a
inner join ref.CatalogueProduits b
on a.ProduitID=b.ProduitID
where a.AchatDate<DATEADD(month,-6,getdate())
and a.MontantAchat<>0.00 -- Payant

-- Supprimer ceux qui ont acheté un produit quelconque, 
-- numérique ou physique, gratuit ou payant, pour la même marque 
-- depuis moins de 6 mois
/* Delete à la fin
delete a
from #T_Abos a inner join dbo.AchatsALActe b 
on a.MasterID=b.MasterID 
and a.MarqueID=b.Marque
inner join ref.CatalogueProduits c on b.ProduitID=c.ProduitID
where b.AchatDate>DATEADD(month,-6,getdate()) 
*/
-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
26 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 27	CAPGN	Nouvel acheteur ayant acquis depuis moins d'un mois un produit physique gratuit.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, a.Marque
, a.AchatDate
from dbo.AchatsALActe a
inner join ref.CatalogueProduits b
on a.ProduitID=b.ProduitID
where a.AchatDate>=DATEADD(month,-1,getdate())
and b.SourceID in (1,3,10)
and b.Physique = 1  -- Physique
and a.MontantAchat=0.00 -- Gratuit

-- Supprimer ceux qui ont acheté un produit quelconque, 
-- numérique ou physique, gratuit ou payant, pour la même marque 
-- depuis plus d'un mois mais moins de 6 mois
/* Delete à la fin
delete a
from #T_Abos a inner join dbo.AchatsALActe b 
on a.MasterID=b.MasterID 
and a.MarqueID=b.Marque
inner join ref.CatalogueProduits c on b.ProduitID=c.ProduitID
where a.DebutFinAboDate>b.AchatDate
and b.AchatDate<DATEADD(month,-1,getdate()) 
and b.AchatDate>DATEADD(month,-6,getdate()) 
*/

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
27 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 28	CAPGA	Acheteur ayant acquis depuis moins de six mois un produit physique gratuit.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, a.Marque
, a.AchatDate
from dbo.AchatsALActe a
inner join ref.CatalogueProduits b
on a.ProduitID=b.ProduitID
where a.AchatDate>=DATEADD(month,-6,getdate())
and b.SourceID in (1,3,10)
and b.Physique = 1  -- Physique
and a.MontantAchat=0.00 -- Gratuit

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
28 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 29	CAPGI	Ancien acheteur ayant acquis depuis plus de six mois un produit physique gratuit.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, a.Marque
, a.AchatDate
from dbo.AchatsALActe a
inner join ref.CatalogueProduits b
on a.ProduitID=b.ProduitID
where a.AchatDate<DATEADD(month,-6,getdate())
and b.SourceID in (1,3,10)
and b.Physique = 1  -- Physique
and a.MontantAchat=0.00 -- Gratuit

-- Supprimer ceux qui ont acheté un produit quelconque, 
-- numérique ou physique, gratuit ou payant, pour la même marque 
-- depuis moins de 6 mois
/* Delete à la fin
delete a
from #T_Abos a inner join dbo.AchatsALActe b 
on a.MasterID=b.MasterID 
and a.MarqueID=b.Marque
inner join ref.CatalogueProduits c on b.ProduitID=c.ProduitID
where b.AchatDate>DATEADD(month,-6,getdate()) 
*/

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
29 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 30	CAPPN	Nouvel acheteur ayant acquis depuis moins d'un mois un produit physique payant.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, a.Marque
, a.AchatDate
from dbo.AchatsALActe a
inner join ref.CatalogueProduits b
on a.ProduitID=b.ProduitID
where a.AchatDate>=DATEADD(month,-1,getdate())
and b.SourceID in (1,3,10)
and b.Physique = 1  -- Physique
and a.MontantAchat<>0.00 -- Payant

-- Supprimer ceux qui ont acheté un produit quelconque, 
-- numérique ou physique, gratuit ou payant, pour la même marque 
-- depuis plus d'un mois mais moins de 6 mois
/* Delete à la fin
delete a
from #T_Abos a inner join dbo.AchatsALActe b 
on a.MasterID=b.MasterID 
and a.MarqueID=b.Marque
inner join ref.CatalogueProduits c on b.ProduitID=c.ProduitID
where a.DebutFinAboDate>b.AchatDate
and b.AchatDate<DATEADD(month,-1,getdate()) 
and b.AchatDate>DATEADD(month,-6,getdate()) 
*/

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
30 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 31	CAPPA	Acheteur ayant acquis depuis moins de six mois un produit physique payant.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, a.Marque
, a.AchatDate
from dbo.AchatsALActe a
inner join ref.CatalogueProduits b
on a.ProduitID=b.ProduitID
where a.AchatDate>=DATEADD(month,-6,getdate())
and b.SourceID in (1,3,10)
and b.Physique = 1  -- Physique
and a.MontantAchat<>0.00 -- Payant

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
31 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 32	CAPPI	Ancien acheteur ayant acquis depuis plus de six mois un produit physique payant.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, a.Marque
, a.AchatDate
from dbo.AchatsALActe a
inner join ref.CatalogueProduits b
on a.ProduitID=b.ProduitID
where a.AchatDate<DATEADD(month,-6,getdate())
and b.SourceID in (1,3,10)
and b.Physique = 1  -- Physique
and a.MontantAchat<>0.00 -- Payant

-- Supprimer ceux qui ont acheté un produit quelconque, 
-- numérique ou physique, gratuit ou payant, pour la même marque 
-- depuis moins de 6 mois
/* Delete à la fin
delete a
from #T_Abos a inner join dbo.AchatsALActe b 
on a.MasterID=b.MasterID 
and a.MarqueID=b.Marque
inner join ref.CatalogueProduits c on b.ProduitID=c.ProduitID
where b.AchatDate>DATEADD(month,-6,getdate()) 
*/

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
32 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 65	PN	Nouveau prospect inscrit depuis moins d'un mois.

-- Moins d'un mois - par date d'opt-in 

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, b.MarqueID
, a.ConsentementDate
from dbo.ConsentementsEmail a inner join ref.Contenus b on a.ContenuID=b.ContenuID
where b.TypeContenu=2 -- Marque
and a.Valeur=1 -- Opt-in
and a.ConsentementDate>DATEADD(month,-1,getdate()) 

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

-- Enlever ceux qui ont effectué un achat ou contracté un abonnement

delete a
from #T_Abos_Agreg a inner join dbo.AchatsALActe b on a.MasterID=b.MasterID and a.MarqueID=b.Marque

delete a
from #T_Abos_Agreg a inner join dbo.Abonnements b on a.MasterID=b.MasterID and a.MarqueID=b.Marque

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
65 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 66	PA	Prospect actif ayant eu une activité lors des six derniers mois.
-- La notion d'actif/inactif nécessite les résultats de tracking 

-- On a l'activité e-mail déjà mais pas encore l'activité Web
-- Champs dans dbo.ConsentementsEmail :
-- DernierClickDate	DerniereOuvertureDate

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, b.MarqueID
, a.ConsentementDate
from dbo.ConsentementsEmail a inner join ref.Contenus b on a.ContenuID=b.ContenuID
where b.TypeContenu=2 -- Marque
and a.Valeur=1 -- Opt-in
and (a.DerniereOuvertureDate>=DATEADD(month,-6,getdate()) or a.DernierClickDate>=DATEADD(month,-6,getdate()))

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

-- Enlever ceux qui ont effectué un achat ou contracté un abonnement

delete a
from #T_Abos_Agreg a inner join dbo.AchatsALActe b on a.MasterID=b.MasterID and a.MarqueID=b.Marque

delete a
from #T_Abos_Agreg a inner join dbo.Abonnements b on a.MasterID=b.MasterID and a.MarqueID=b.Marque

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
66 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 67	PI	Prospect inactif n'ayant pas eu d'activité lors des six derniers mois.
-- La notion d'actif/inactif nécessite les résultats de tracking 

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, b.MarqueID
, a.ConsentementDate
from dbo.ConsentementsEmail a inner join ref.Contenus b on a.ContenuID=b.ContenuID
where b.TypeContenu=2 -- Marque
and a.Valeur=1 -- Opt-in
and (a.DerniereOuvertureDate<DATEADD(month,-6,getdate()) or a.DernierClickDate<DATEADD(month,-6,getdate()) or a.DerniereOuvertureDate is null or a.DernierClickDate is null)

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

-- Enlever ceux qui ont effectué un achat ou contracté un abonnement

delete a
from #T_Abos_Agreg a inner join dbo.AchatsALActe b on a.MasterID=b.MasterID and a.MarqueID=b.Marque

delete a
from #T_Abos_Agreg a inner join dbo.Abonnements b on a.MasterID=b.MasterID and a.MarqueID=b.Marque

-- Eliminer l'intersection avec le groupe 66

delete a
from #T_Abos_Agreg a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
where b.TypologieID=66

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
67 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- Commercialisable = commercialisable à l'extérieur = Opt-in Partenaire

-- 68	ON	Nouveau prospect commercialisable inscrit depuis moins d'un mois.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, b.MarqueID
, a.ConsentementDate
from dbo.ConsentementsEmail a inner join ref.Contenus b on a.ContenuID=b.ContenuID
where b.TypeContenu=3 -- opt-in Partenaire
and a.Valeur=1 -- Opt-in
and a.ConsentementDate>DATEADD(month,-1,getdate()) 

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

-- Enlever ceux qui ont effectué un achat ou contracté un abonnement

delete a
from #T_Abos_Agreg a inner join dbo.AchatsALActe b on a.MasterID=b.MasterID and a.MarqueID=b.Marque

delete a
from #T_Abos_Agreg a inner join dbo.Abonnements b on a.MasterID=b.MasterID and a.MarqueID=b.Marque

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
68 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 69	OA	Prospect actif commercialisable ayant eu une activité lors des six derniers mois.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, b.MarqueID
, a.ConsentementDate
from dbo.ConsentementsEmail a inner join ref.Contenus b on a.ContenuID=b.ContenuID
where b.TypeContenu=3 -- opt-in Partenaire
and a.Valeur=1 -- Opt-in
and (a.DerniereOuvertureDate>=DATEADD(month,-6,getdate()) or a.DernierClickDate>=DATEADD(month,-6,getdate()))

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

-- Enlever ceux qui ont effectué un achat ou contracté un abonnement

delete a
from #T_Abos_Agreg a inner join dbo.AchatsALActe b on a.MasterID=b.MasterID and a.MarqueID=b.Marque

delete a
from #T_Abos_Agreg a inner join dbo.Abonnements b on a.MasterID=b.MasterID and a.MarqueID=b.Marque

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
69 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a


-- 70	OI	Prospect inactif commercialisable n'ayant pas eu d'activité lors des six derniers mois.
-- La notion d'actif/inactif nécessite les résultats de tracking 

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, b.MarqueID
, a.ConsentementDate
from dbo.ConsentementsEmail a inner join ref.Contenus b on a.ContenuID=b.ContenuID
where b.TypeContenu=3 -- opt-in Partenaire
and a.Valeur=1 -- Opt-in
and (a.DerniereOuvertureDate<DATEADD(month,-6,getdate()) or a.DernierClickDate<DATEADD(month,-6,getdate()) or a.DerniereOuvertureDate is null or a.DernierClickDate is null)

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

-- Enlever ceux qui ont effectué un achat ou contracté un abonnement

delete a
from #T_Abos_Agreg a inner join dbo.AchatsALActe b on a.MasterID=b.MasterID and a.MarqueID=b.Marque

delete a
from #T_Abos_Agreg a inner join dbo.Abonnements b on a.MasterID=b.MasterID and a.MarqueID=b.Marque

-- Eliminer l'intersection avec le groupe 69

delete a
from #T_Abos_Agreg a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
where b.TypologieID=69

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
70 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 71	CSPGF	Abonné ayant souscrit un abonnement papier gratuit n'ayant pas encore démarré.

truncate table #T_Abos

-- SDVP
insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.DebutAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.DebutAboDate>=DATEADD(month,-1,getdate())
and 
a.StatutAbo = 1 -- Anticipé
and
(coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- gratuit
and a.SourceID=3 -- SDVP
and b.SupportAbo=2 -- Papier

update a
set Typologie=71
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
71 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 72	CSPPF	Abonné ayant souscrit un abonnement papier payant n'ayant pas encore démarré.

truncate table #T_Abos

-- SDVP
insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.DebutAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.DebutAboDate>=DATEADD(month,-1,getdate())
and 
a.StatutAbo = 1 -- Anticipé
and not (coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- payant
and a.SourceID=3 -- SDVP
and b.SupportAbo=2 -- Papier

update a
set Typologie=72
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
72 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a


-- 73	CSNGF	Abonné ayant souscrit un abonnement numérique gratuit n'ayant pas encore démarré.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.DebutAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.DebutAboDate>=DATEADD(month,-1,getdate())
and 
a.StatutAbo = 1 -- Anticipé
and ((
(coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') -- gratuit
and a.SourceID=3 ) -- SDVP
	or
(a.SourceID in (1,10) -- Neolane et PVL
and b.MontantAbo=0.00 )) -- Gratuit
and b.SupportAbo=1 -- Numérique

update a
set Typologie=73
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
73 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 74	CSNPF	Abonné ayant souscrit un abonnement numérique payant n'ayant pas encore démarré.

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
, AbonnementID
)
select 
a.MasterID
, a.Marque
, a.DebutAboDate
, a.AbonnementID
from dbo.Abonnements a
inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID
where a.DebutAboDate>=DATEADD(month,-1,getdate())
and 
a.StatutAbo = 1 -- Anticipé
and not (( -- Payant
(coalesce(a.ModePaiement,0) in (23,24) or b.OriginalID like N'%GRATUIT%' or b.OriginalID like N'% 0E %') 
and a.SourceID=3 ) -- SDVP
	or
(a.SourceID in (1,10) -- Neolane et PVL
and b.MontantAbo=0.00 )) 
and b.SupportAbo=1 -- Numérique

update a
set Typologie=74
from dbo.Abonnements a inner join #T_Abos b on a.AbonnementID=b.AbonnementID

truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
74 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- Opt-ins éditoriaux : 79, 80, 81

-- 79	OEN	Optins éditoriaux nouveaux - Contact ayant un opt-in éditorial marque actif sur une adresse e-mail valide, inscrit depuis moins d'un mois.

-- Moins d'un mois - par date d'opt-in 

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, b.MarqueID
, a.ConsentementDate
from dbo.ConsentementsEmail a inner join ref.Contenus b on a.ContenuID=b.ContenuID
where b.TypeContenu=1 -- Editorial
and a.Valeur=1 -- Opt-in
and a.ConsentementDate>DATEADD(month,-1,getdate()) 

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

-- Enlever ceux qui ont effectué un achat ou contracté un abonnement

--delete a
--from #T_Abos_Agreg a inner join dbo.AchatsALActe b on a.MasterID=b.MasterID and a.MarqueID=b.Marque

--delete a
--from #T_Abos_Agreg a inner join dbo.Abonnements b on a.MasterID=b.MasterID and a.MarqueID=b.Marque

-- Enlever ceux qui ont un opt-in marque ou partenaire

--delete a
--from #T_Abos_Agreg a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID 
--where b.TypologieID in (65,66,67,68,69,70) -- opt-in marque ou partenaire

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
79 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 80	OEA	Optins éditoriaux actuels - Contact inscrit depuis plus d'un mois, 
-- ayant un opt-in éditorial marque actif sur une adresse e-mail valide, 
-- ayant eu une activité (c'est-à-dire du tracking web et/ou e-mail) lors des six derniers mois (et qui n'est pas "nouveau").
-- La notion d'actif/inactif nécessite les résultats de tracking 

-- On a l'activité e-mail déjà mais pas encore l'activité Web
-- Champs dans dbo.ConsentementsEmail :
-- DernierClickDate	DerniereOuvertureDate

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, b.MarqueID
, a.ConsentementDate
from dbo.ConsentementsEmail a inner join ref.Contenus b on a.ContenuID=b.ContenuID
where b.TypeContenu=1 -- Editorial
and a.Valeur=1 -- Opt-in
and (a.DerniereOuvertureDate>=DATEADD(month,-6,getdate()) or a.DernierClickDate>=DATEADD(month,-6,getdate()))

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

---- Enlever ceux qui ont effectué un achat ou contracté un abonnement

--delete a
--from #T_Abos_Agreg a inner join dbo.AchatsALActe b on a.MasterID=b.MasterID and a.MarqueID=b.Marque

--delete a
--from #T_Abos_Agreg a inner join dbo.Abonnements b on a.MasterID=b.MasterID and a.MarqueID=b.Marque

-- Enlever ceux qui ont un opt-in marque ou partenaire

delete a
from #T_Abos_Agreg a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID 
where b.TypologieID in (79)
--where ( b.TypologieID in (65,66,67,68,69,70) -- opt-in marque ou partenaire
--	or b.TypologieID in (79) -- Nouveau 
--	)

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
80 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a

-- 81	OEI	Optins éditoriaux inactifs - Contact ayant un opt-in éditorial marque actif sur une adresse e-mail valide, 
-- n'ayant pas eu d'activité (c'est-à-dire du tracking web et/ou e-mail) lors des six derniers mois (et qui n'est ni "nouveau, ni "actuel").
-- La notion d'actif/inactif nécessite les résultats de tracking 

truncate table #T_Abos

insert #T_Abos
(
MasterID
, MarqueID
, DebutFinAboDate
)
select 
a.MasterID
, b.MarqueID
, a.ConsentementDate
from dbo.ConsentementsEmail a inner join ref.Contenus b on a.ContenuID=b.ContenuID
where b.TypeContenu=1 -- Editorial
and a.Valeur=1 -- Opt-in
and (a.DerniereOuvertureDate<DATEADD(month,-6,getdate()) or a.DernierClickDate<DATEADD(month,-6,getdate()) or a.DerniereOuvertureDate is null or a.DernierClickDate is null)

-- Eliminer les doublons éventuels
truncate table #T_Abos_Agreg

insert #T_Abos_Agreg (N,MasterID,MarqueID)
select COUNT(*) as N, MasterID, MarqueID from #T_Abos a
group by MasterID, MarqueID

-- Enlever ceux qui ont effectué un achat ou contracté un abonnement

--delete a
--from #T_Abos_Agreg a inner join dbo.AchatsALActe b on a.MasterID=b.MasterID and a.MarqueID=b.Marque

--delete a
--from #T_Abos_Agreg a inner join dbo.Abonnements b on a.MasterID=b.MasterID and a.MarqueID=b.Marque

delete a
from #T_Abos_Agreg a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID 
WHERE b.TypologieID in (79,80)
--where ( b.TypologieID in (65,66,67,68,69,70) -- opt-in marque ou partenaire
--	or b.TypologieID in (79,80) -- Nouveau et actif
--	)

insert #T_Lignes_Typologies
(
TypologieID
, MasterID
, MarqueID
)
select
81 as TypologieID
, a.MasterID
, a.MarqueID
from #T_Abos_Agreg a


IF OBJECT_ID('tempdb..#T_Vim') IS NOT NULL
    DROP TABLE #T_Vim
	
CREATE TABLE #T_Vim
(
	TypologieID      INT NOT NULL
   ,MasterID         INT NULL
   ,MarqueID         INT NULL
   ,Appartenance     INT NULL
)

IF OBJECT_ID('tempdb..#T_Vie') IS NOT NULL
    DROP TABLE #T_Vie
	
CREATE TABLE #T_Vie
(
	TypologieID     INT NOT NULL
   ,MasterID        INT NULL
   ,MarqueID        INT NULL
)

-- begin VI
--VIMN 
;
WITH firstVisite AS (
         SELECT masterID
               ,marque
               ,sw.Appartenance
               ,MIN(vw.DateVisite)          minDateVisite
         FROM   etl.VisitesWeb           AS vw
                INNER JOIN ref.SitesWeb  AS sw
                     ON  vw.SiteId = sw.WebSiteID
         WHERE  masterId IS NOT NULL
         GROUP BY
                vw.MasterID
               ,marque
               ,Appartenance
         HAVING MIN(vw.DateVisite) >= DATEADD(MONTH ,-1 ,GETDATE())
     )

INSERT INTO #T_Vim
  (
    TypologieID
   ,MasterID
   ,MarqueID
   ,Appartenance
  )
SELECT 86      AS TypologieID
      ,masterID
      ,marque  AS MarqueID
      ,Appartenance
FROM   firstVisite
GROUP BY
       masterID
      ,marque
      ,Appartenance

--VIMA
;
WITH ACTIVE AS (
         SELECT masterID
               ,marque
               ,sw.Appartenance
               ,MAX(vw.DateVisite)          maxDateVisite
         FROM   etl.VisitesWeb           AS vw
                INNER JOIN ref.SitesWeb  AS sw
                     ON  vw.SiteId = sw.WebSiteID
         WHERE  masterId IS NOT NULL
         GROUP BY
                vw.MasterID
               ,marque
               ,sw.Appartenance
         HAVING MAX(vw.DateVisite) >= DATEADD(MONTH ,-6 ,GETDATE())
         AND MIN(vw.DateVisite) < DATEADD(MONTH ,-1 ,GETDATE())
     )

INSERT INTO #T_Vim
  (
    TypologieID
   ,MasterID
   ,MarqueID
   ,Appartenance
  )
SELECT 87      AS TypologieID
      ,masterID
      ,marque  AS MarqueID
      ,Appartenance
FROM   ACTIVE
GROUP BY
       masterID
      ,marque
      ,Appartenance
	
--VIMI       
;
WITH inactive AS (
         SELECT masterID
               ,marque
               ,sw.Appartenance
               ,MAX(vw.DateVisite)          MaxDateVisite
         FROM   etl.VisitesWeb           AS vw
                INNER JOIN ref.SitesWeb  AS sw
                     ON  vw.SiteId = sw.WebSiteID
         WHERE  masterId IS NOT NULL
         GROUP BY
                vw.MasterID
               ,marque
               ,sw.Appartenance
         HAVING MAX(vw.DateVisite) < DATEADD(MONTH ,-6 ,GETDATE())
     )

INSERT INTO #T_Vim
  (
    TypologieID
   ,MasterID
   ,MarqueID
   ,Appartenance
  )
SELECT 88      AS TypologieID
      ,masterID
      ,marque  AS MarqueID
      ,Appartenance
FROM   inactive
GROUP BY
       masterID
      ,marque
      ,Appartenance

CREATE INDEX idx_masterID ON #T_Vim(MasterID)

INSERT INTO #T_Vie
  (
    TypologieID
   ,MasterID
   ,MarqueID
  )
SELECT DISTINCT CASE 
                     WHEN x.marqueID <> v1.MarqueID THEN v1.TypologieID + 3 --VIE
                     ELSE v1.TypologieID --VIM
                END AS Typologie
      ,v1.MasterID
      ,x.MarqueID
FROM   #T_Vim v1
       CROSS APPLY (
    SELECT CodeValN  AS MarqueID
          ,sw.Appartenance
    FROM   ref.Misc  AS sw
    WHERE  TypeRef = N'MARQUE'
           AND sw.Appartenance = v1.Appartenance
           AND sw.CodeValN NOT IN (SELECT MarqueID
                                   FROM   #T_Vim v2
                                   WHERE  v2.masterID = v1.masterId)
    GROUP BY
           sw.CodeValN
          ,sw.Appartenance
) x
INNER JOIN dbo.LienAvecMarques L
            ON  l.MasterID = v1.MasterID
                AND l.MarqueID = x.MarqueID


--DELETE by priority 90>89>91
--A 90>(89,91)
DELETE t2
FROM   #T_Vie t1
       INNER JOIN #T_Vie t2
            ON  t1.MasterID = t2.MasterID
                AND t1.marqueId = t2.marqueId
                AND t1.TypologieID = 90
                AND t2.TypologieID IN (89 ,91)

--N 89 > 91
DELETE t2
FROM   #T_Vie t1
       INNER JOIN #T_Vie t2
            ON  t1.MasterID = t2.MasterID
                AND t1.marqueId = t2.marqueId
                AND t1.TypologieID = 89
                AND t2.TypologieID = 91

--VIM*
INSERT INTO #T_Lignes_Typologies
  (
    TypologieID
   ,MasterID
   ,MarqueID
  )
SELECT tv.TypologieID
      ,tv.MasterID
      ,tv.MarqueID
FROM   #T_Vim AS tv

--VIE*
INSERT INTO #T_Lignes_Typologies
  (
    TypologieID
   ,MasterID
   ,MarqueID
  )
SELECT tv.TypologieID
      ,tv.MasterID
      ,tv.MarqueID
FROM   #T_Vie AS tv

--end VI**

-- Effectuer les suppressions en fonction du tableau des priorités des typologies

-- Suppressions dans les typologies des abonnements

-- Supprimer les nouveaux abonnements face aux abonnements actuels 




delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
and a.TypologieID+1=b.TypologieID
where a.TypologieID in (1,6,11,16) -- Nouveaux
-- and b.TypologieID in (2,7,12,17) -- Actuels

-- Supprimer les nouveaux abonnements face aux abonnements "en renouvellement" 

delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
and a.TypologieID+2=b.TypologieID
where a.TypologieID in (1,6,11,16) -- Nouveaux
-- and b.TypologieID in (3,8,13,18) -- En renouvellement

-- Supprimer les abonnements actuels face aux abonnements "en renouvellement" 
delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
and a.TypologieID+1=b.TypologieID
where a.TypologieID in (2,7,12,17) -- Actuels
-- and b.TypologieID in (3,8,13,18) -- En renouvellement

-- Supprimer les abonnements "en renouvellement" face aux abonnements futurs

delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
and (70+((a.TypologieID+2)/5))=b.TypologieID
where a.TypologieID in (3,8,13,18) -- En renouvellement

-- Récents doivent être supprimés face aux nouveaux, actuels, en renouvellement, futurs

-- Récents doivent être supprimés face aux nouveaux
delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
and a.TypologieID-3=b.TypologieID
where a.TypologieID in (4,9,14,19) -- Récents
-- and b.TypologieID in (1,6,11,16) -- Nouveaux

-- ...aux actuels
delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
and a.TypologieID-2=b.TypologieID
where a.TypologieID in (4,9,14,19) -- Récents
-- and b.TypologieID in (2,7,12,17) -- Actuels

-- ... en renouvellement

delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
and a.TypologieID-1=b.TypologieID
where a.TypologieID in (4,9,14,19) -- Récents
-- and b.TypologieID in (3,8,13,18) -- En renouvellement

-- ... futurs

delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
and (70+((a.TypologieID+1)/5))=b.TypologieID
where a.TypologieID in (4,9,14,19) -- Récents


-- Inactifs doivent être supprimés face à tous les autres : nouveaux, actuels, en renouvellement, récents, futurs
-- ... aux nouveaux
delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
and a.TypologieID-4=b.TypologieID
where a.TypologieID in (5,10,15,20) -- Inactifs
-- and b.TypologieID in (1,6,11,16) -- Nouveaux

-- ... aux actuels
delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
and a.TypologieID-3=b.TypologieID
where a.TypologieID in (5,10,15,20) -- Inactifs
-- and b.TypologieID in (2,7,12,17) -- Actuels

-- ... En renouvellement 
delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
and a.TypologieID-2=b.TypologieID
where a.TypologieID in (5,10,15,20) -- Inactifs
-- and b.TypologieID in (3,8,13,18) -- En renouvellement

-- ... Récents
delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
and a.TypologieID-1=b.TypologieID
where a.TypologieID in (5,10,15,20) -- Inactifs
-- and b.TypologieID in (4,9,14,19) -- Récents

-- ... futurs

delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
and (70+(a.TypologieID/5))=b.TypologieID
where a.TypologieID in (5,10,15,20) -- Inactifs

-- Futurs doivent être supprimés face aux actuels et nouveaux :

-- ... nouveaux
delete b
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
and (70+(a.TypologieID/5))=b.TypologieID
where a.TypologieID in (1,6,11,16) -- Nouveaux

-- ... actuels
delete b
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
and (70+(a.TypologieID/5))+1=b.TypologieID
where a.TypologieID in (2,7,12,17) -- Actuels

-- Suppressions dans les typologies des achats

-- Actuels face aux nouveaux
delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
and a.TypologieID-1=b.TypologieID
where a.TypologieID in (22,25,28,31) -- Actuels
-- and b.TypologieID in (21,24,27,30) -- Nouveaux

-- Inactifs face aux nouveaux et actuels

-- Inactifs face aux nouveaux
delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
and a.TypologieID-2=b.TypologieID
where a.TypologieID in (23,26,29,32) -- Inactifs
-- and b.TypologieID in (21,24,27,30) -- Nouveaux

-- Inactifs face aux actuels
delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
and a.TypologieID-1=b.TypologieID
where a.TypologieID in (23,26,29,32) -- Inactifs
-- and b.TypologieID in (22,25,28,31) -- Actuels

-- Suppressions dans les typologies des opt-ins marque et partenaires

-- Opt-in Marques

-- Actuels face aux nouveaux
delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
where a.TypologieID = 66 -- Actuels
and b.TypologieID = 65 -- Nouveaux

-- Inactifs face aux nouveaux et actuels

delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
where a.TypologieID = 67 -- Inactifs
and b.TypologieID = 65 -- Nouveaux

delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
where a.TypologieID = 67 -- Inactifs
and b.TypologieID = 66 -- Actuels


-- Opt-in Partenaires

-- Actuels face aux nouveaux
delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
where a.TypologieID = 69  -- Actuels
and b.TypologieID = 68 -- Nouveaux

-- Inactifs face aux nouveaux et actuels

-- Inactifs face aux nouveaux	
delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
where a.TypologieID = 70  -- Inactifs
and b.TypologieID = 68 -- Nouveaux

-- Inactifs face aux actuels	
delete a
from #T_Lignes_Typologies a inner join #T_Lignes_Typologies b on a.MasterID=b.MasterID and a.MarqueID=b.MarqueID
where a.TypologieID = 70  -- Inactifs
and b.TypologieID = 69 -- Actuels

	--delete conflicts for a ....termines typologies
	--82
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  a.TypologieID = 82
	       AND b.TypologieID IN (1 ,2 ,3, 71)
	       
	DELETE b
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  a.TypologieID = 82
	       AND b.TypologieID IN (4,5) 
	        
	--83
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  a.TypologieID = 83
	       AND b.TypologieID IN (6 ,7 ,8,72)
	       
	DELETE b
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  a.TypologieID = 83
	       AND b.TypologieID IN (9,10) 	        
	--84
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  a.TypologieID = 84
	       AND b.TypologieID IN (11 ,12 ,13, 73)
	DELETE b
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  a.TypologieID = 84
	       AND b.TypologieID IN (14,15) 
	        
	--85
	DELETE a
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  a.TypologieID = 85
	       AND b.TypologieID IN (16 ,17 ,18,74) 

	DELETE b
	FROM   #T_Lignes_Typologies a
	       INNER JOIN #T_Lignes_Typologies b
	            ON  a.MasterID = b.MasterID
	                AND a.MarqueID = b.MarqueID
	WHERE  a.TypologieID = 85
	       AND b.TypologieID IN (19,20) 

-- Après que toutes les typologies ont été calculées dans une table temporaire,
-- on les insère dans la table dbo.Typologie
-- Comme à chaque fois la table temporaire contient l'ensemble des typologies, 
-- dbo.Typologie est tronquée 

truncate table dbo.Typologie

insert dbo.Typologie (
TypologieID
, MasterID
, MarqueID
)
select 
TypologieID
, MasterID
, MarqueID
from
#T_Lignes_Typologies


 if OBJECT_ID('tempdb..#T_Lignes_Typologies') is not null
	drop table #T_Lignes_Typologies

if OBJECT_ID('tempdb..#T_Abos') is not null
	drop table #T_Abos

if OBJECT_ID('tempdb..#T_Abos_Agreg') is not null
	drop table #T_Abos_Agreg

end

