USE [AmauryVUC]

GO
/****** Object:  StoredProcedure [report].[DB_7_NouvAbos]    Script Date: 04/20/2015 16:28:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter proc [report].[DBN_02_PortefeuilleAbonnes] (@Editeur nvarchar(8), @P nvarchar(30))
as 

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 28/04/2015
-- Description:	Calcul du Dashboard Abos Numériques 
--				N°2
--				PORTEFEUILLE ABONNES
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
set @IdGraph=2

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
select @DebutPeriod=DebutPeriod from report.RefPeriodeOwnerDB where IdPeriode=@IdPeriod
set @PrecPeriod=N'Semaine_'+right(N'00'+cast(datepart(week,dateadd(week,-1,@DebutPeriod)) as nvarchar(2)),2)+N'_'+cast(datepart(year,dateadd(week,-1,@DebutPeriod)) as nvarchar(4))

delete report.DashboardAboNumerique where Periode=@Period and IdGraph=@IdGraph and Editeur=@Editeur

-- Abonnés numériques payants actifs

; with s as (
select a.AbonnementID from dbo.Abonnements a
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
	from report.RefPeriodeOwnerDB a where IdPeriode=@IdPeriod
)

, u as (
select COUNT(distinct a.MasterID) as NombreActifsPayants from dbo.Abonnements a inner join s on a.AbonnementID=s.AbonnementID
inner join ref.Misc b on a.Typologie=b.CodeValN and b.TypeRef=N'TYPOLOGIE'
inner join y on a.DebutAboDate<y.FinPeriod and a.FinAboDate>=y.DebutPeriod
where b.Valeur like N'CSNP%'
)

, x as (
select COUNT(distinct a.MasterID) as NombreRenouveles from dbo.Abonnements a 
inner join ref.Misc b on a.Typologie=b.CodeValN and b.TypeRef=N'TYPOLOGIE'
inner join y on a.ReaboDate<y.FinPeriod and a.ReaboDate>=y.DebutPeriod
and b.Valeur like N'CSNP%'
)

, z as (
select COUNT(*) as NombreNouveaux from dbo.Abonnements a 
inner join ref.Misc b on a.Typologie=b.CodeValN and b.TypeRef=N'TYPOLOGIE'
inner join y on a.DebutAboDate<y.FinPeriod and a.DebutAboDate>=y.DebutPeriod
and b.Valeur like N'CSNP%'
)

, a as (
select 
1 as NumOrder, (select NombreActifsPayants from u) as NombreActifs
union select 2 as NumOrder, (select NombreRenouveles from x) as NombreActifs
union select 3 as NumOrder,  (select NombreNouveaux from z) as NombreActifs
)

, b as (
select N'Abonnés Actifs Payants' as Libelle, 1 as NumOrder
union select N'dont Renouvelés' as Libelle, 2 as NumOrder
union select N'dont Nouveaux' as Libelle, 3 as NumOrder
)

, t as (
select a.NombreActifs
	, a.NumOrder
	, b.Libelle from a inner join b on a.NumOrder=b.NumOrder
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
, t.NombreActifs as ValeurFloat 
from t 
order by t.NumOrder

end
