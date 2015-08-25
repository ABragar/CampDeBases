SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure [report].[DBN_1_Web_1] (@Period nvarchar(30), @IdTemplate uniqueidentifier, @weekn int, @yearn int)
as
begin

set nocount on


declare @IdPeriod as uniqueidentifier
declare @IdGraph as int
declare @SnapshotDate as datetime
declare @IdOwner as uniqueidentifier

declare @Progression as float
declare @PrecPeriod as nvarchar(30)

declare @ValeurFloatMin as float
declare @ValeurFloatMax as float
declare @EcartType as float


set @SnapshotDate=GETDATE() 
set @IdGraph=2  -- Numéro relatif à l'appartenance


set dateformat ymd

insert into report.Week_EditeurVisites_DBN_2 (r_year, r_week, appartenance)
	select @yearn, @weekn, S.appartenance
	from ref.SitesWeb S
	left join report.Week_EditeurVisites_DBN_2 DBN2 on DBN2.r_week = @weekn and DBN2.r_year = @yearn and DBN2.appartenance = S.Appartenance 
	where DBN2.appartenance  is null
	group by r_year, r_week, S.appartenance

update DBN2
set VisiteursNb = S.VisiteursNb
from report.Week_EditeurVisites_DBN_2 DBN2
inner join 
(
select Appartenance, count(distinct bA.MasterID) as VisiteursNb
from import.Xiti_Sessions iX
inner join ref.SitesWeb S on iX.SiteID = S.WebSiteID
inner join brut.ActiviteWeb bA on S.WebSiteID = bA.SiteWebID and bA.ClientID = iX.ClientID
where (datepart(year, cast(SessionDebut as datetime)) = @yearn and datepart(week, cast(SessionDebut as datetime)) = @weekn)
	or (datepart(year, cast(SessionDebut as datetime)) = @yearn+1 and datepart(week, cast(SessionDebut as datetime)) = 1 and @weekn = 53)
group by Appartenance
) S on DBN2.appartenance = S.appartenance and DBN2.r_year = @yearn and DBN2.r_week = @weekn 



declare @appartenance as int
declare @curweek as int
declare @curyear as int
declare @backweek as int

set @appartenance = 1
set @backweek = 1
set @curyear = @yearn
set @curweek = @weekn+1


declare @DebutPeriod as datetime
select @DebutPeriod=DebutPeriod from report.RefPeriodeOwnerDB where IdPeriode=@IdPeriod
set @PrecPeriod=N'Semaine_'+right(N'00'+cast(datepart(week,dateadd(week,-1,@DebutPeriod)) as nvarchar(2)),2)+N'_'+cast(datepart(year,dateadd(week,-1,@DebutPeriod)) as nvarchar(4))

set @appartenance = 1


while @appartenance < 4
begin

	set @backweek = 1
	set @curyear = @yearn
	set @curweek = @weekn+1

	delete report.DashboardNumerique where Periode=@Period and IdGraph in (3,4) and Appartenance=@Appartenance


	while @backweek < 13
	begin



		select @IdPeriod=IdPeriode from report.RefPeriodeOwnerDB where Periode=@Period and Appartenance=@Appartenance and IdTemplate=@IdTemplate

		select @IdOwner=IdOwner from report.RefPeriodeOwnerDB where Periode=@Period and Appartenance=@Appartenance and IdTemplate=@IdTemplate


		set @curweek = @curweek - 1

		if @curweek = 1 
		begin
			set @curweek = 53 
			set @curyear = @curyear - 1
		end

		if @appartenance in (1,2)
		begin

			insert into AmauryVUC.report.DashboardNumerique (Periode, IdPeriode, IdOwner, IdTemplate, SnapshotDate, IdGraph, Appartenance, Libelle, NumOrdre, ValeurInt)
			select @Period as Periode, @IdPeriod as IdPeriode, @IdOwner as IdOwner, @IdTemplate as IdTemplate, @SnapshotDate as SnapshotDate, appartenance+@IdGraph as IdGraph, @appartenance as Appartenance,
			'S-' + cast(@backweek as nchar(2)) as libelle, 13-@backweek as NumOrdre, isnull(VisiteursNb, 0) as ValeurInt 
			from report.Week_EditeurVisites_DBN_2  where appartenance = @appartenance and r_week = @curweek and r_year = @curyear

		end
		else
		begin

			insert into AmauryVUC.report.DashboardNumerique (Periode, IdPeriode, IdOwner, IdTemplate, SnapshotDate, IdGraph, Appartenance, Libelle, NumOrdre, ValeurInt)
			select @Period as Periode, @IdPeriod as IdPeriode, @IdOwner as IdOwner, @IdTemplate as IdTemplate, @SnapshotDate as SnapshotDate, 3 as IdGraph, @appartenance as Appartenance,
			'S-' + cast(@backweek as nchar(2)) as libelle, 13-@backweek as NumOrdre, isnull(VisiteursNb, 0) as ValeurInt 
			from report.Week_EditeurVisites_DBN_2  where appartenance = 1 and r_week = @curweek and r_year = @curyear

			insert into AmauryVUC.report.DashboardNumerique (Periode, IdPeriode, IdOwner, IdTemplate, SnapshotDate, IdGraph, Appartenance, Libelle, NumOrdre, ValeurInt)
			select @Period as Periode, @IdPeriod as IdPeriode, @IdOwner as IdOwner, @IdTemplate as IdTemplate, @SnapshotDate as SnapshotDate, 4 as IdGraph, @appartenance as Appartenance,
			'S-' + cast(@backweek as nchar(2)) as libelle, 13-@backweek as NumOrdre, isnull(VisiteursNb, 0) as ValeurInt 
			from report.Week_EditeurVisites_DBN_2  where appartenance = 2 and r_week = @curweek and r_year = @curyear
			
		end

		set @backweek = @backweek + 1
	end



	set @appartenance = @appartenance + 1

end


end
GO
