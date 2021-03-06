USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [report].[InitialiserKayakDB]    Script Date: 04/27/2015 18:55:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc [report].[InitialiserKayakDB] (@D datetime)
as

begin 

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 28/04/2015
-- Description:	Alimentation des tables : 
--			AmauryVUC.report.RefPeriodeOwnerDB 
--			AmauryVUC.report.RefPeriodeOwnerDB_Num
--			Kayak.dbo.DashboardValues
--			avec la nouvelle période (= semaine passée)
-- =============================================

set nocount on


declare @Period as nvarchar(30)
declare @LibellePeriode as nvarchar(30)
declare @IdTemplate as uniqueidentifier

declare @IdTemplate_Num_EQ as uniqueidentifier
declare @IdTemplate_Num_FF as uniqueidentifier
declare @IdTemplate_Num_LP as uniqueidentifier

declare @SnapshotDate as datetime

declare @IdOwner1 as uniqueidentifier
declare @IdOwner2 as uniqueidentifier
declare @IdOwner3 as uniqueidentifier

declare @IdPeriod1 as uniqueidentifier
declare @IdPeriod2 as uniqueidentifier
declare @IdPeriod3 as uniqueidentifier

declare @IdPeriod1_Num as uniqueidentifier
declare @IdPeriod2_Num as uniqueidentifier
declare @IdPeriod3_Num as uniqueidentifier

declare @SemainePrec as date
declare @DebutPeriod as date
declare @FinPeriod as date

set @SemainePrec=@D

set @Period=N'Semaine_'+right(N'00'+cast(datepart(week,@SemainePrec) as nvarchar(2)),2)+N'_'+cast(datepart(year,@SemainePrec) as nvarchar(4))

set @DebutPeriod=dateadd(day,-datepart(dw,@SemainePrec)+2,@SemainePrec)
set @FinPeriod=dateadd(day,6,@DebutPeriod)

set @LibellePeriode=N'Semaine '+cast(datepart(week,@DebutPeriod) as nvarchar(2))

-- set @Period=N'Semaine_'+right(N'00'+cast(datepart(week,dateadd(week,-1,getdate())) as nvarchar(2)),2)+N'_'+cast(datepart(year,dateadd(week,-1,getdate())) as nvarchar(4))

set @IdTemplate='4EC12A95-0587-46C1-9BE5-4C2FCF5DF337' -- template Kayak Dashboard Métier

-- Templates Dashboard Abos Numériques

set @IdTemplate_Num_EQ=N'AE9B6FBA-06EF-4855-885A-BA3C2F955279'
set @IdTemplate_Num_FF=N'9D260307-3BEF-4B0F-9B87-0BE3CE30AD3D'
set @IdTemplate_Num_LP=N'202D2833-6EEF-449C-A2A5-509CBFB936FC'

set @SnapshotDate=GETDATE()

set @IdOwner1='A1868C59-6D0C-4CD4-9AB3-610163343E14' -- EQ
set @IdOwner2='3EDDDB62-8AE3-4B08-9D29-117BE237F7A5' -- LP
set @IdOwner3='95940C81-C7A7-4BD9-A523-445A343A9605' -- Groupe Amaury

set @IdPeriod1=NEWID()
set @IdPeriod2=NEWID()
set @IdPeriod3=NEWID()


-- Dashboard Métier

insert AmauryVUC.report.RefPeriodeOwnerDB
(
IdPeriode
, Periode
, Appartenance
, IdOwner
, IdTemplate
, SnapshotDate
, DebutPeriod
, FinPeriod
)
select 
@IdPeriod1
, @Period
, 1
, @IdOwner1
, @IdTemplate
, @SnapshotDate
, @DebutPeriod
, @FinPeriod
where not exists (select 1 from AmauryVUC.report.RefPeriodeOwnerDB where Periode=@Period and Appartenance=1 and IdOwner=@IdOwner1)

insert AmauryVUC.report.RefPeriodeOwnerDB
(
IdPeriode
, Periode
, Appartenance
, IdOwner
, IdTemplate
, SnapshotDate
, DebutPeriod
, FinPeriod
)
select 
@IdPeriod2
, @Period
, 2
, @IdOwner2
, @IdTemplate
, @SnapshotDate
, @DebutPeriod
, @FinPeriod
where not exists (select 1 from AmauryVUC.report.RefPeriodeOwnerDB where Periode=@Period and Appartenance=2 and IdOwner=@IdOwner2)

insert AmauryVUC.report.RefPeriodeOwnerDB
(
IdPeriode
, Periode
, Appartenance
, IdOwner
, IdTemplate
, SnapshotDate
, DebutPeriod
, FinPeriod
)
select 
@IdPeriod3
, @Period
, 3
, @IdOwner3
, @IdTemplate
, @SnapshotDate
, @DebutPeriod
, @FinPeriod
where not exists (select 1 from AmauryVUC.report.RefPeriodeOwnerDB where Periode=@Period and Appartenance=3 and IdOwner=@IdOwner3 )

insert Kayak.dbo.DashboardValues
(
Id
, Owner
, IdTemplate
, SnapshotDate
, Periode
, DebutPeriod
, FinPeriod
, LibellePeriode
)
select 
@IdPeriod1
, @IdOwner1
, @IdTemplate
, @SnapshotDate
, @Period
, @DebutPeriod
, @FinPeriod
, @LibellePeriode
where not exists (select 1 from Kayak.dbo.DashboardValues where Periode=@Period and Owner=@IdOwner1 and IdTemplate=@IdTemplate)

insert Kayak.dbo.DashboardValues
(
Id
, Owner
, IdTemplate
, SnapshotDate
, Periode
, DebutPeriod
, FinPeriod
, LibellePeriode
)
select 
@IdPeriod2
, @IdOwner2
, @IdTemplate
, @SnapshotDate
, @Period
, @DebutPeriod
, @FinPeriod
, @LibellePeriode
where not exists (select 1 from Kayak.dbo.DashboardValues where Periode=@Period and Owner=@IdOwner2 and IdTemplate=@IdTemplate)


insert Kayak.dbo.DashboardValues
(
Id
, Owner
, IdTemplate
, SnapshotDate
, Periode
, DebutPeriod
, FinPeriod
, LibellePeriode
)
select
@IdPeriod3
, @IdOwner3
, @IdTemplate
, @SnapshotDate
, @Period
, @DebutPeriod
, @FinPeriod
, @LibellePeriode
where not exists (select 1 from Kayak.dbo.DashboardValues where Periode=@Period and Owner=@IdOwner3 and IdTemplate=@IdTemplate)


-- Dashboard abos numériques

set @IdPeriod1_Num=NEWID()
set @IdPeriod2_Num=NEWID()
set @IdPeriod3_Num=NEWID()


insert Kayak.dbo.DashboardValues
(
Id
, Owner
, IdTemplate
, SnapshotDate
, Periode
, DebutPeriod
, FinPeriod
, LibellePeriode
)
select 
@IdPeriod1_Num
, @IdOwner1
, @IdTemplate_Num_EQ
, @SnapshotDate
, @Period
, @DebutPeriod
, @FinPeriod
, @LibellePeriode
where not exists (select 1 from Kayak.dbo.DashboardValues where Periode=@Period and Owner=@IdOwner1 and IdTemplate=@IdTemplate_Num_EQ)

insert Kayak.dbo.DashboardValues
(
Id
, Owner
, IdTemplate
, SnapshotDate
, Periode
, DebutPeriod
, FinPeriod
, LibellePeriode
)
select 
@IdPeriod2_Num
, @IdOwner1
, @IdTemplate_Num_FF
, @SnapshotDate
, @Period
, @DebutPeriod
, @FinPeriod
, @LibellePeriode
where not exists (select 1 from Kayak.dbo.DashboardValues where Periode=@Period and Owner=@IdOwner1 and IdTemplate=@IdTemplate_Num_FF)


insert Kayak.dbo.DashboardValues
(
Id
, Owner
, IdTemplate
, SnapshotDate
, Periode
, DebutPeriod
, FinPeriod
, LibellePeriode
)
select
@IdPeriod3_Num
, @IdOwner2
, @IdTemplate_Num_LP
, @SnapshotDate
, @Period
, @DebutPeriod
, @FinPeriod
, @LibellePeriode
where not exists (select 1 from Kayak.dbo.DashboardValues where Periode=@Period and Owner=@IdOwner2 and IdTemplate=@IdTemplate_Num_LP)



insert AmauryVUC.report.RefPeriodeOwnerDB_Num
(
IdPeriode
, Periode
, Editeur
, IdOwner
, IdTemplate
, SnapshotDate
, DebutPeriod
, FinPeriod
)
select 
@IdPeriod1_Num
, @Period
, N'EQ' as Editeur
, @IdOwner1
, @IdTemplate_Num_EQ
, @SnapshotDate
, @DebutPeriod
, @FinPeriod
where not exists (select 1 from AmauryVUC.report.RefPeriodeOwnerDB_Num where Periode=@Period and Editeur=N'EQ' and IdOwner=@IdOwner1)

insert AmauryVUC.report.RefPeriodeOwnerDB_Num
(
IdPeriode
, Periode
, Editeur
, IdOwner
, IdTemplate
, SnapshotDate
, DebutPeriod
, FinPeriod
)
select 
@IdPeriod2_Num
, @Period
, N'FF'
, @IdOwner1
, @IdTemplate_Num_FF
, @SnapshotDate
, @DebutPeriod
, @FinPeriod
where not exists (select 1 from AmauryVUC.report.RefPeriodeOwnerDB_Num where Periode=@Period and Editeur=N'FF' and IdOwner=@IdOwner1)

insert AmauryVUC.report.RefPeriodeOwnerDB_Num
(
IdPeriode
, Periode
, Editeur
, IdOwner
, IdTemplate
, SnapshotDate
, DebutPeriod
, FinPeriod
)
select 
@IdPeriod3_Num
, @Period
, N'LP'
, @IdOwner2
, @IdTemplate_Num_LP
, @SnapshotDate
, @DebutPeriod
, @FinPeriod
where not exists (select 1 from AmauryVUC.report.RefPeriodeOwnerDB_Num where Periode=@Period and Editeur=N'LP' and IdOwner=@IdOwner2 )


end
