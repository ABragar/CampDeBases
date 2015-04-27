USE [AmauryVUC]

GO
/****** Object:  StoredProcedure [report].[DB_7_NouvAbos]    Script Date: 04/20/2015 16:28:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--alter proc [report].[DBN_02_PortefeuilleAbonnes] (@Appartenance int, @P nvarchar(30))
--as 
--begin 

DECLARE @Appartenance INT = 1
DECLARE @P NVARCHAR(30) 

set nocount on

-- @Appartenance : 1 = EQ, 2 = LP, 3 = Groupe

declare @Period as nvarchar(30)
declare @IdPeriod as uniqueidentifier
declare @IdGraph as int
declare @SnapshotDate as datetime
declare @IdOwner as uniqueidentifier
declare @IdTemplate as uniqueidentifier

declare @Progression as float
declare @PrecPeriod as nvarchar(30)

declare @ValeurFloatMin as float
declare @ValeurFloatMax as float
declare @EcartType as float

set @Period=@P

set @SnapshotDate=GETDATE()
set @IdGraph=2
set @IdTemplate='DC44A189-E076-4E7F-9668-B014E7AAB3B4' -- donnée de Kayak : Template DB Numérique

select @IdPeriod=IdPeriode from report.RefPeriodeOwnerDB where Periode=@Period and Appartenance=@Appartenance and IdTemplate=@IdTemplate

select @IdOwner=IdOwner from report.RefPeriodeOwnerDB where Periode=@Period and Appartenance=@Appartenance and IdTemplate=@IdTemplate

declare @DebutPeriod as datetime
select @DebutPeriod=DebutPeriod from report.RefPeriodeOwnerDB where IdPeriode=@IdPeriod
--why 	right(N'00'

set @PrecPeriod=N'Semaine_'+right(N'00'+cast(datepart(week,dateadd(week,-1,@DebutPeriod)) as nvarchar(2)),2)+N'_'+cast(datepart(year,dateadd(week,-1,@DebutPeriod)) as nvarchar(4))

--delete report.DashboardAboNumerique where Periode=@Period and IdGraph=@IdGraph and Appartenance=@Appartenance

-- Abonnées numériques payants actifs

; with s as (
select a.AbonnementID from dbo.Abonnements a
where a.Appartenance in (1 & @Appartenance, 2 & @Appartenance)
)--AbonnementID by @Appartenance
, y as (
select cast(a.DebutPeriod as datetime) as DebutPeriod
	, cast(dateadd(day,1,a.FinPeriod) as datetime) as FinPeriod
	from report.RefPeriodeOwnerDB a where IdPeriode=@IdPeriod
)--Periods by Pieriod, Appartenance, Template (Begin, end)
, u as (
select COUNT(distinct a.MasterID) as NombreActifsPayants from dbo.Abonnements a inner join s on a.AbonnementID=s.AbonnementID
inner join ref.Misc b on a.Typologie=b.CodeValN and b.TypeRef=N'TYPOLOGIE'
inner join y on a.DebutAboDate<y.FinPeriod and a.FinAboDate>=y.DebutPeriod
where b.Valeur like N'CSNP%'
) --abonemens (qty)	by CSNP active

, x as (
select COUNT(distinct a.MasterID) as NombreRenouveles from dbo.Abonnements a 
inner join ref.Misc b on a.Typologie=b.CodeValN and b.TypeRef=N'TYPOLOGIE'
inner join y on a.ReaboDate<y.FinPeriod and a.ReaboDate>=y.DebutPeriod
and b.Valeur like N'CSNP%'
) --qty abons update

, z as (
select COUNT(*) as NombreNouveaux from dbo.Abonnements a 
inner join ref.Misc b on a.Typologie=b.CodeValN and b.TypeRef=N'TYPOLOGIE'
inner join y on a.DebutAboDate<y.FinPeriod and a.DebutAboDate>=y.DebutPeriod
and b.Valeur like N'CSNP%'
) --qty new

, a as (
select 
1 as NumOrder, (select NombreActifsPayants from u) as NombreActifs
union select 2 as NumOrder, (select NombreRenouveles from x) as NombreActifs
union select 3 as NumOrder,  (select NombreNouveaux from z) as NombreActifs
)

, b as (
select N'Abonnés Actifs Payants' as Libelle, 1 as NumOrder
union select N'dont Renbouvelés' as Libelle, 2 as NumOrder
union select N'dont Nouveaux' as Libelle, 3 as NumOrder
)

, t as (
select a.NombreActifs
	, a.NumOrder
	, b.Libelle from a inner join b on a.NumOrder=b.NumOrder
)

--insert report.DashboardAboNumerique
--(
--Periode
--, IdPeriode
--, IdOwner
--, IdTemplate
--, SnapshotDate
--, IdGraph
--, Appartenance
--, Libelle
--, NumOrdre
--, ValeurFloat
--)
select @Period as Periode
, @IdPeriod as IdPeriode
, @IdOwner as IdOwner
, @IdTemplate as IdTemplate
, @SnapshotDate as SnapshotDate
, @IdGraph as IdGraph
, @Appartenance as Appartenance
, t.Libelle as Libelle
, t.NumOrder
, t.NombreActifs as ValeurFloat 
from t 
order by t.NumOrder

--end
