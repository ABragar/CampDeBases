use AmauryVUC
go

-- Reports prêts

-- TYPOLOGIE ABONNES
-- Titre : Nombre d'abonnés payants par typologie

; with s as (
 select AbonnementID from dbo.Abonnements
 )
 
 , t as 
 (
 select 
 case	when a.TypologieID in (6,16,24,30) then N'Nouveaux'
		when a.TypologieID in (7,17,25,31) then N'Actuels'
		when a.TypologieID in (8,18) then N'En renouv.'
		when a.TypologieID in (9,19) then N'Récents'
		when a.TypologieID in (10,20,26,32) then N'Inactifs'
		else N'Autres'
 end as Typologie
 , COUNT(distinct a.MasterID) as NombreAbonnes 
 from dbo.Typologie a 
 inner join report.AboStats b on a.MasterID=b.MasterID
 inner join s on b.AbonnementID=s.AbonnementID
 where b.MontantAbo>0.00
 group by case	when a.TypologieID in (6,16,24,30) then N'Nouveaux'
		when a.TypologieID in (7,17,25,31) then N'Actuels'
		when a.TypologieID in (8,18) then N'En renouv.'
		when a.TypologieID in (9,19) then N'Récents'
		when a.TypologieID in (10,20,26,32) then N'Inactifs'
		else N'Autres'
 end 
 )
 
 select * from t
 
 
 -- SUPPORTS ABONNEMENTS
 -- Titre : Nombre d'abonnements payants par support
 
; with s as (
 select AbonnementID from dbo.Abonnements
 )
 
 , t as 
 (
 select 
 case when	a.ModeExpedition=3 and a.isCouple=1 then N'Couplé porté'
		when a.ModeExpedition in (4,5,6) and a.isCouple=1 then N'Couplé posté'
		when a.ModeExpedition=3 and a.SupportAbo=2 then N'Papier porté'
		when a.ModeExpedition  in (4,5,6) and a.SupportAbo=2 then N'Papier posté'
		when a.ModeExpedition=2 then N'Numérique'
		else N'Autre'
		end as Supports
	, count(*) as NombreAbonnements
 from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
 where a.MontantAbo>0.00
 group by case when	a.ModeExpedition=3 and a.isCouple=1 then N'Couplé porté'
		when a.ModeExpedition in (4,5,6) and a.isCouple=1 then N'Couplé posté'
		when a.ModeExpedition=3 and a.SupportAbo=2 then N'Papier porté'
		when a.ModeExpedition  in (4,5,6) and a.SupportAbo=2 then N'Papier posté'
		when a.ModeExpedition=2 then N'Numérique'
		else N'Autre'
		end
)
select * from t


-- TAUX DE CHURN ABONNEMENTS RESILIES
-- Titre : Taux de churn abonnements résiliés

; with s as (
 select AbonnementID from dbo.Abonnements
 )
 
 , t as 
 (select
cast((select count(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.SupportAbo=2 
and DATEDIFF(MONTH,a.DebutAboDate,a.FinAboDate)<1
and a.FinAboDate<=GETDATE() and a.FinAboDate>dateadd(month,-12,getdate()) 
and a.MontantAbo>0
) as float)/cast((select COUNT(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.SupportAbo=2 and a.FinAboDate<=GETDATE() and a.FinAboDate>dateadd(month,-12,getdate()) and a.MontantAbo>0) as float)
as Papier_1_mois
, 
cast((select count(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.SupportAbo=1 
and DATEDIFF(MONTH,a.DebutAboDate,a.FinAboDate)<1
and a.FinAboDate<=GETDATE() and a.FinAboDate>dateadd(month,-12,getdate()) 
and a.MontantAbo>0
) as float)/cast((select COUNT(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.SupportAbo=1 and a.FinAboDate<=GETDATE() and a.FinAboDate>dateadd(month,-12,getdate()) and a.MontantAbo>0) as float)
as Numeriques_1_mois
,
cast((select count(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.SupportAbo=2 
and DATEDIFF(MONTH,a.DebutAboDate,a.FinAboDate) between 1 and 12
and a.FinAboDate<=GETDATE() and a.FinAboDate>dateadd(month,-12,getdate()) 
and a.MontantAbo>0
) as float)/cast((select COUNT(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.SupportAbo=2 and a.FinAboDate<=GETDATE() and a.FinAboDate>dateadd(month,-12,getdate()) and a.MontantAbo>0) as float)
as Papier_12_mois
,
cast((select count(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.SupportAbo=1 
and DATEDIFF(MONTH,a.DebutAboDate,a.FinAboDate) between 1 and 12
and a.FinAboDate<=GETDATE() and a.FinAboDate>dateadd(month,-12,getdate()) 
and a.MontantAbo>0
) as float)/cast((select COUNT(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.SupportAbo=1 and a.FinAboDate<=GETDATE() and a.FinAboDate>dateadd(month,-12,getdate()) and a.MontantAbo>0) as float)
as Numeriques_12_mois
,
cast((select count(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.SupportAbo=2 
and a.DebutAboDate>=cast(cast(dateadd(day,-datepart(DY,GETDATE())+1,getdate()) as date) as datetime)
and a.FinAboDate<=GETDATE() and a.FinAboDate>dateadd(month,-12,getdate()) 
and a.MontantAbo>0
) as float)/cast((select COUNT(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.SupportAbo=2 and a.FinAboDate<=GETDATE() and a.FinAboDate>dateadd(month,-12,getdate()) and a.MontantAbo>0) as float)
as Papier_Janvier
,
cast((select count(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID
where a.SupportAbo=1
and a.DebutAboDate>=cast(cast(dateadd(day,-datepart(DY,GETDATE())+1,getdate()) as date) as datetime)
and a.FinAboDate<=GETDATE() and a.FinAboDate>dateadd(month,-12,getdate()) 
and a.MontantAbo>0
) as float)/cast((select COUNT(*) from report.AboStats a inner join s on a.AbonnementID=s.AbonnementID 
where a.SupportAbo=1 and a.FinAboDate<=GETDATE() and a.FinAboDate>dateadd(month,-12,getdate()) and a.MontantAbo>0 ) as float)
as Numeriques_Janvier
)

select * from t


-- CHURN ABONNEMENTS
-- Titre : Churn abonnements

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

