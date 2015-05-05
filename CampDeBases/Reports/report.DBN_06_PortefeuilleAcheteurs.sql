USE [AmauryVUC]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter proc [report].[DBN_06_PortefeuilleAcheteurs] (@Editeur nvarchar(8), @P nvarchar(30))
as 

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 30/04/2015
-- Description:	Calcul du Dashboard Abos Numériques 
--				N°6
--				PORTEFEUILLE ACHETEURS
-- Modiification date :
-- Modified by :
-- Modification :
-- =============================================

begin 

set nocount on

-- @Editeur : EQ, FF, LP

declare @Period as nvarchar(30)
declare @IdPeriod as uniqueidentifier
declare @IdGraph as int
declare @SnapshotDate as datetime
declare @IdOwner as uniqueidentifier

declare @IdTemplate as uniqueidentifier

declare @IdTemplate_Num_EQ as uniqueidentifier
declare @IdTemplate_Num_FF as uniqueidentifier
declare @IdTemplate_Num_LP as uniqueidentifier

declare @Progression as float
declare @PrecPeriod as nvarchar(30)

declare @ValeurFloatMin as float
declare @ValeurFloatMax as float
declare @EcartType as float

set @Period=@P

set @SnapshotDate=GETDATE()
set @IdGraph=6

set @IdTemplate_Num_EQ=N'AE9B6FBA-06EF-4855-885A-BA3C2F955279'
set @IdTemplate_Num_FF=N'9D260307-3BEF-4B0F-9B87-0BE3CE30AD3D'
set @IdTemplate_Num_LP=N'202D2833-6EEF-449C-A2A5-509CBFB936FC'

set @IdTemplate=case @Editeur 
	when N'EQ' then @IdTemplate_Num_EQ
	when N'FF' then @IdTemplate_Num_FF
	when N'LP' then @IdTemplate_Num_LP
end

select @IdPeriod=IdPeriode from report.RefPeriodeOwnerDB_Num where Periode=@Period and Editeur=@Editeur and IdTemplate=@IdTemplate

select @IdOwner=IdOwner from report.RefPeriodeOwnerDB_Num where Periode=@Period and Editeur=@Editeur and IdTemplate=@IdTemplate

declare @DebutPeriod as datetime
select @DebutPeriod=DebutPeriod from report.RefPeriodeOwnerDB_Num where IdPeriode=@IdPeriod
set @PrecPeriod=N'Semaine_'+right(N'00'+cast(datepart(week,dateadd(week,-1,@DebutPeriod)) as nvarchar(2)),2)+N'_'+cast(datepart(year,dateadd(week,-1,@DebutPeriod)) as nvarchar(4))

delete report.DashboardAboNumerique where Periode=@Period and IdGraph=@IdGraph and Editeur=@Editeur

-- Abonnés numériques payants actifs

; with s as (
select a.AchatID from dbo.AchatsALActe a
where a.Marque in (
case @Editeur 
	when N'EQ' then 7
	when N'FF' then 3
	when N'LP' then 6
end
, case @Editeur 
	when N'EQ' then 0
	when N'FF' then 0
	when N'LP' then 2 -- Aujourd'hui en France
end
)
)

, y as (
select cast(a.DebutPeriod as datetime) as DebutPeriod
	, cast(dateadd(day,1,a.FinPeriod) as datetime) as FinPeriod
	from report.RefPeriodeOwnerDB_Num a where IdPeriode=@IdPeriod
)

, u as (
select COUNT(distinct a.MasterID) as NombreAchats from dbo.AchatsALActe a inner join s on a.AchatID=s.AchatID
inner join ref.CatalogueProduits b on a.ProduitID=b.ProduitID
inner join y on a.AchatDate<y.FinPeriod and a.AchatDate>=y.DebutPeriod
where b.CategorieProduit=N'Offre à jetons'
and a.MontantAchat>0.00
)

, x as (
select COUNT(distinct a.MasterID) as NombreAchats from dbo.AchatsALActe a inner join s on a.AchatID=s.AchatID
inner join ref.CatalogueProduits b on a.ProduitID=b.ProduitID
inner join y on a.AchatDate<y.FinPeriod and a.AchatDate>=y.DebutPeriod
where b.CategorieProduit=N'Offre à l''acte'
and a.MontantAchat>0.00
)

-- Dont nouveaux jetons

, un as (
select count(distinct r1.MasterID) as NombreNouveauxAcheteurs from (
select a.MasterID, a.AchatDate, a.ProduitID, a.MontantAchat from dbo.AchatsALActe a
) as r1
inner join ref.CatalogueProduits b on r1.ProduitID=b.ProduitID
inner join y on r1.AchatDate<y.FinPeriod and r1.AchatDate>=y.DebutPeriod
where b.CategorieProduit=N'Offre à jetons'
and r1.MontantAchat>0.00
and not exists (select a.MasterID from dbo.AchatsALActe a 
		inner join ref.CatalogueProduits b on a.ProduitID=b.ProduitID
		where a.MasterID=r1.MasterID 
		and b.CategorieProduit=N'Offre à jetons' 
		and a.MontantAchat>0.00 
		and a.AchatDate<y.DebutPeriod 
		and a.AchatDate>=dateadd(month,-6,y.DebutPeriod))
)

-- Dont nouveaux à l'acte

, xn as (
select count(distinct r1.MasterID) as NombreNouveauxAcheteurs from (
select a.MasterID, a.AchatDate, a.ProduitID, a.MontantAchat from dbo.AchatsALActe a
) as r1
inner join ref.CatalogueProduits b on r1.ProduitID=b.ProduitID
inner join y on r1.AchatDate<y.FinPeriod and r1.AchatDate>=y.DebutPeriod
where b.CategorieProduit=N'Offre à l''acte'
and r1.MontantAchat>0.00
and not exists (select a.MasterID from dbo.AchatsALActe a 
		inner join ref.CatalogueProduits b on a.ProduitID=b.ProduitID
		where a.MasterID=r1.MasterID 
		and b.CategorieProduit=N'Offre à l''acte' 
		and a.MontantAchat>0.00 
		and a.AchatDate<y.DebutPeriod 
		and a.AchatDate>=dateadd(month,-6,y.DebutPeriod))
)

, a as (
select		1 as NumOrder, (select cast(NombreAchats as float) as NombreAchats from u) as NombreAchats
union select 2 as NumOrder, (select cast(NombreAchats as float) as NombreAchats from x) as NombreAchats
union select 3 as NumOrder,  (select cast(NombreNouveauxAcheteurs as float) from un) as NombreAchats
union select 4 as NumOrder,  (select cast(NombreNouveauxAcheteurs as float) from xn) as NombreAchats
)

, b as (
select N'Acheteurs offre jetons' as Libelle, 1 as NumOrder
union select N'Acheteurs offre à l''acte' as Libelle, 2 as NumOrder
union select N'Dont nouveaux jetons' as Libelle, 3 as NumOrder
union select N'Dont nouveaux à l''acte' as Libelle, 4 as NumOrder
)

, t as (
select coalesce(a.NombreAchats,0) as NombreAchats
	, a.NumOrder
	, b.Libelle from b left join a on b.NumOrder=a.NumOrder
)

insert report.DashboardAboNumerique
(
Periode
, IdPeriode
, IdOwner
, IdTemplate
, SnapshotDate
, IdGraph
, Editeur
, Libelle
, NumOrdre
, ValeurFloat
)
select @Period as Periode
, @IdPeriod as IdPeriode
, @IdOwner as IdOwner
, @IdTemplate as IdTemplate
, @SnapshotDate as SnapshotDate
, @IdGraph as IdGraph
, @Editeur as Appartenance
, t.Libelle as Libelle
, t.NumOrder
, t.NombreAchats as ValeurFloat 
from t 
order by t.NumOrder

end
