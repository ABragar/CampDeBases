use AmauryVUC
go

-- SUPPORTS SOUSCRIPTIONS :	Nombre de souscription payantes par support

; with s as (
 select AbonnementID from dbo.Abonnements
 )
 
, m as (
select a.AbonnementID
, a.ModeExpedition
, a.SupportAbo
, a.isCouple
, m.Mois
from report.AboStats a 
inner join s on a.AbonnementID=s.AbonnementID 
cross join report.DouzeDerniersMois m
)

, n as (

select m.Mois 
, b.AbonnementID
, m.ModeExpedition
, m.SupportAbo
, m.isCouple
, c.MontantAbo
, b.DebutAboDate
, b.FinAboDate
from m inner join dbo.Abonnements b on b.AbonnementID=m.AbonnementID
inner join ref.CatalogueAbonnements c on b.CatalogueAbosID=c.CatalogueAbosID
where b.DebutAboDate>=m.Mois and b.DebutAboDate<DATEADD(month,1,m.Mois) 
)


, p as (
select
n.Mois
, COUNT(*) as NombreSouscriptions
, case when	n.ModeExpedition=3 and n.isCouple=1 then N'Couplé porté'
		when n.ModeExpedition in (4,5,6) and n.isCouple=1 then N'Couplé posté'
		when n.ModeExpedition=3 and n.SupportAbo=2 then N'Papier porté'
		when n.ModeExpedition  in (4,5,6) and n.SupportAbo=2 then N'Papier posté'
		when n.ModeExpedition=2 then N'Numérique'
		else N'Autre'
		end as Supports
from n
where MontantAbo<>0.00
group by n.Mois
, case when	n.ModeExpedition=3 and n.isCouple=1 then N'Couplé porté'
		when n.ModeExpedition in (4,5,6) and n.isCouple=1 then N'Couplé posté'
		when n.ModeExpedition=3 and n.SupportAbo=2 then N'Papier porté'
		when n.ModeExpedition  in (4,5,6) and n.SupportAbo=2 then N'Papier posté'
		when n.ModeExpedition=2 then N'Numérique'
		else N'Autre'
		end
)

, q as 
(
select b.Mois,a.Support from report.SupportAbo a
cross join report.DouzeDerniersMois b
)

, r as 
(
select q.Mois
	,coalesce(p.NombreSouscriptions,0) as NombreSouscriptions
	, q.Support 
	from q left outer join p 
	on q.Support=p.Supports 
	and q.Mois=p.Mois
)

, t as
(
select 
r.Mois
, sum(case when r.Support=N'Autre' then r.NombreSouscriptions else 0 end) as Autre
, sum(case when r.Support=N'Couplé porté' then r.NombreSouscriptions else 0 end) as CouplePorte
, sum(case when r.Support=N'Couplé posté' then r.NombreSouscriptions else 0 end) as CouplePoste
, sum(case when r.Support=N'Numérique' then r.NombreSouscriptions else 0 end) as Numerique
, sum(case when r.Support=N'Papier porté' then r.NombreSouscriptions else 0 end) as PapierPorte
, sum(case when r.Support=N'Papier posté' then r.NombreSouscriptions else 0 end) as PapierPoste
from r
group by r.Mois
)

select * from t order by Mois
-- 0'01"

-- CA ABONNEMENTS :	CA théorique abonnements payants par support.

; with s as (
 select AbonnementID from dbo.Abonnements
 )

, m as (
select a.AbonnementID
, a.ModeExpedition
, a.SupportAbo
, a.isCouple
, m.Mois
from report.AboStats a 
inner join s on a.AbonnementID=s.AbonnementID 
cross join report.DouzeDerniersMois m
)

, n as (

select m.Mois 
, b.AbonnementID
, m.ModeExpedition
, m.SupportAbo
, m.isCouple
, case when b.FinAboDate is null and b.DebutAboDate>=m.Mois then c.MontantAbo
	else
	cast(
		coalesce(
			b.MontantAbo/
				(
					round(
							case	when coalesce(
											cast(DATEDIFF(day,b.DebutAboDate,b.FinAboDate) as float)/30.42,1)<1 then 1 
									else coalesce(cast(DATEDIFF(day,b.DebutAboDate,b.FinAboDate) as float)/30.42,1) end,0)
				),0.00)
						as numeric(10,2)
		) end
	as CA_Mensuel
, b.DebutAboDate
, b.FinAboDate
from m inner join dbo.Abonnements b on b.AbonnementID=m.AbonnementID
inner join ref.CatalogueAbonnements c on b.CatalogueAbosID=c.CatalogueAbosID
where b.DebutAboDate<DATEADD(month,1,m.Mois) and coalesce(b.FinAboDate,N'01-01-2079')>=m.Mois
)

, p as (
select
n.Mois
, SUM(n.CA_Mensuel) CA_Mensuel
, case when	n.ModeExpedition=3 and n.isCouple=1 then N'Couplé porté'
		when n.ModeExpedition in (4,5,6) and n.isCouple=1 then N'Couplé posté'
		when n.ModeExpedition=3 and n.SupportAbo=2 then N'Papier porté'
		when n.ModeExpedition  in (4,5,6) and n.SupportAbo=2 then N'Papier posté'
		when n.ModeExpedition=2 then N'Numérique'
		else N'Autre'
		end as Supports
from n
group by n.Mois
, case when	n.ModeExpedition=3 and n.isCouple=1 then N'Couplé porté'
		when n.ModeExpedition in (4,5,6) and n.isCouple=1 then N'Couplé posté'
		when n.ModeExpedition=3 and n.SupportAbo=2 then N'Papier porté'
		when n.ModeExpedition  in (4,5,6) and n.SupportAbo=2 then N'Papier posté'
		when n.ModeExpedition=2 then N'Numérique'
		else N'Autre'
		end
)

, q as 
(
select b.Mois,a.Support from report.SupportAbo a
cross join report.DouzeDerniersMois b
)

, r as 
(
select q.Mois
	,coalesce(p.CA_Mensuel,0.00) as CA_Mensuel
	, q.Support 
	from q left outer join p 
	on q.Support=p.Supports 
	and q.Mois=p.Mois
)

, t as
(
select 
r.Mois
, sum(case when r.Support=N'Autre' then r.CA_Mensuel else 0.00 end) as Autre
, sum(case when r.Support=N'Couplé porté' then r.CA_Mensuel else 0.00 end) as CouplePorte
, sum(case when r.Support=N'Couplé posté' then r.CA_Mensuel else 0.00 end) as CouplePoste
, sum(case when r.Support=N'Numérique' then r.CA_Mensuel else 0.00 end) as Numerique
, sum(case when r.Support=N'Papier porté' then r.CA_Mensuel else 0.00 end) as PapierPorte
, sum(case when r.Support=N'Papier posté' then r.CA_Mensuel else 0.00 end) as PapierPoste
from r
group by r.Mois
)

select * from t order by Mois

-- 0'13"

