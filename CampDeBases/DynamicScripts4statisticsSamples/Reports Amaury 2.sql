use AmauryVUC
go


-- TAUX DE CHURN ABONNEMENTS ACTIFS

; with s as (
 select AbonnementID from dbo.Abonnements
 )
 
 ,  m as (select Mois from report.TauxChurnAbos)
 
 , t as (

select 
m.Mois
,
(
select COUNT(*) as Resilies_2_mois from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.DebutAboDate between -- le 1er  jour du mois en cours il y a deux ans et le dernier jour du mois en cours il y a deux ans
dateadd(month,-24,m.Mois) 
	and dateadd(month,-23,m.Mois)
and a.FinAboDate<DATEADD(month,2,a.DebutAboDate)
) as Resilies_2_mois
,
(
select COUNT(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.DebutAboDate between -- le 1er  jour du mois en cours il y a deux ans et le dernier jour du mois en cours il y a deux ans
dateadd(month,-24,m.Mois) 
	and dateadd(month,-23,m.Mois)
and a.FinAboDate>=DATEADD(month,2,a.DebutAboDate)
and a.FinAboDate<DATEADD(month,4,a.DebutAboDate)
) as Resilies_4_mois
,
(
select COUNT(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.DebutAboDate between -- le 1er  jour du mois en cours il y a deux ans et le dernier jour du mois en cours il y a deux ans
dateadd(month,-24,m.Mois) 
	and dateadd(month,-23,m.Mois)
and a.FinAboDate>=DATEADD(month,4,a.DebutAboDate)
and a.FinAboDate<DATEADD(month,8,a.DebutAboDate)
) as Resilies_8_mois
,
(
select COUNT(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.DebutAboDate between -- le 1er  jour du mois en cours il y a deux ans et le dernier jour du mois en cours il y a deux ans
dateadd(month,-24,m.Mois) 
	and dateadd(month,-23,m.Mois)
and a.FinAboDate>=DATEADD(month,8,a.DebutAboDate)
and a.FinAboDate<DATEADD(month,12,a.DebutAboDate)
) as Resilies_12_mois
,
(
select COUNT(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.DebutAboDate between -- le 1er  jour du mois en cours il y a deux ans et le dernier jour du mois en cours il y a deux ans
dateadd(month,-24,m.Mois) 
	and dateadd(month,-23,m.Mois)
and a.FinAboDate>=DATEADD(month,12,a.DebutAboDate)
and a.FinAboDate<DATEADD(month,24,a.DebutAboDate)
) as Resilies_24_mois
from m

)

select * from t order by t.Mois 
-- 0'39"

-- CHURN ABONNEMENTS

; with s as (
 select AbonnementID from dbo.Abonnements
 )
 
 , t as 
 (select 
 (select COUNT(*) as Recrutes_24_mois from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.DebutAboDate between -- le 1er  jour du mois en cours il y a deux ans et le dernier jour du mois en cours il y a deux ans
dateadd(month,-24,cast(cast(DATEADD(day,-day(getdate())+1,GETDATE()) as date) as datetime)) 
	and dateadd(month,-23,cast(cast(DATEADD(day,-day(getdate())+1,GETDATE()) as date) as datetime))
	) as Recrutes_24_mois
	,
(
select COUNT(*) as Resilies_2_mois from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.DebutAboDate between -- le 1er  jour du mois en cours il y a deux ans et le dernier jour du mois en cours il y a deux ans
dateadd(month,-24,cast(cast(DATEADD(day,-day(getdate())+1,GETDATE()) as date) as datetime)) 
	and dateadd(month,-23,cast(cast(DATEADD(day,-day(getdate())+1,GETDATE()) as date) as datetime))
and a.FinAboDate<DATEADD(month,2,a.DebutAboDate)
) as Resilies_2_mois
,
(
select COUNT(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.DebutAboDate between -- le 1er  jour du mois en cours il y a deux ans et le dernier jour du mois en cours il y a deux ans
dateadd(month,-24,cast(cast(DATEADD(day,-day(getdate())+1,GETDATE()) as date) as datetime)) 
	and dateadd(month,-23,cast(cast(DATEADD(day,-day(getdate())+1,GETDATE()) as date) as datetime))
and a.FinAboDate>=DATEADD(month,2,a.DebutAboDate)
and a.FinAboDate<DATEADD(month,4,a.DebutAboDate)
) as Resilies_4_mois
,
(
select COUNT(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.DebutAboDate between -- le 1er  jour du mois en cours il y a deux ans et le dernier jour du mois en cours il y a deux ans
dateadd(month,-24,cast(cast(DATEADD(day,-day(getdate())+1,GETDATE()) as date) as datetime)) 
	and dateadd(month,-23,cast(cast(DATEADD(day,-day(getdate())+1,GETDATE()) as date) as datetime))
and a.FinAboDate>=DATEADD(month,4,a.DebutAboDate)
and a.FinAboDate<DATEADD(month,8,a.DebutAboDate)
) as Resilies_8_mois
,
(
select COUNT(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.DebutAboDate between -- le 1er  jour du mois en cours il y a deux ans et le dernier jour du mois en cours il y a deux ans
dateadd(month,-24,cast(cast(DATEADD(day,-day(getdate())+1,GETDATE()) as date) as datetime)) 
	and dateadd(month,-23,cast(cast(DATEADD(day,-day(getdate())+1,GETDATE()) as date) as datetime))
and a.FinAboDate>=DATEADD(month,8,a.DebutAboDate)
and a.FinAboDate<DATEADD(month,12,a.DebutAboDate)
) as Resilies_12_mois
,
(
select COUNT(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.DebutAboDate between -- le 1er  jour du mois en cours il y a deux ans et le dernier jour du mois en cours il y a deux ans
dateadd(month,-24,cast(cast(DATEADD(day,-day(getdate())+1,GETDATE()) as date) as datetime)) 
	and dateadd(month,-23,cast(cast(DATEADD(day,-day(getdate())+1,GETDATE()) as date) as datetime))
and a.FinAboDate>=DATEADD(month,12,a.DebutAboDate)
and a.FinAboDate<DATEADD(month,24,a.DebutAboDate)
) as Resilies_24_mois
,
(
select COUNT(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.DebutAboDate between -- le 1er  jour du mois en cours il y a deux ans et le dernier jour du mois en cours il y a deux ans
dateadd(month,-24,cast(cast(DATEADD(day,-day(getdate())+1,GETDATE()) as date) as datetime)) 
	and dateadd(month,-23,cast(cast(DATEADD(day,-day(getdate())+1,GETDATE()) as date) as datetime))
and (a.FinAboDate is null or a.FinAboDate>=DATEADD(month,24,a.DebutAboDate))
) as Actifs_Apres_24_mois
 )
 
 select * from t
 
-- 0'00"


