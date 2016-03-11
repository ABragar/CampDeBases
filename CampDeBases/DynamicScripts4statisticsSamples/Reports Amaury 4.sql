use AmauryVUC
go

-- SUPPORT ABONNES
-- Volume mensuel des abonn�s payants sur les douze derniers mois, pour chaque support.

; with s as (
 select AbonnementID from dbo.Abonnements
 )
 
 , m as (
select a.AbonnementID
, a.MasterID
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
, m.MasterID
, m.ModeExpedition
, m.SupportAbo
, m.isCouple
, c.MontantAbo
, b.DebutAboDate
, b.FinAboDate
from m inner join dbo.Abonnements b on b.AbonnementID=m.AbonnementID
inner join ref.CatalogueAbonnements c on b.CatalogueAbosID=c.CatalogueAbosID
where b.DebutAboDate<DATEADD(month,1,m.Mois) and b.FinAboDate>=m.Mois
)

, p as (
select
n.Mois
, COUNT(distinct n.MasterID) as NombreAbonnes
, case when	n.ModeExpedition=3 and n.isCouple=1 then N'Coupl� port�'
		when n.ModeExpedition in (4,5,6) and n.isCouple=1 then N'Coupl� post�'
		when n.ModeExpedition=3 and n.SupportAbo=2 then N'Papier port�'
		when n.ModeExpedition  in (4,5,6) and n.SupportAbo=2 then N'Papier post�'
		when n.ModeExpedition=2 then N'Num�rique'
		else N'Autre'
		end as Supports
from n
where MontantAbo<>0.00
group by n.Mois
, case when	n.ModeExpedition=3 and n.isCouple=1 then N'Coupl� port�'
		when n.ModeExpedition in (4,5,6) and n.isCouple=1 then N'Coupl� post�'
		when n.ModeExpedition=3 and n.SupportAbo=2 then N'Papier port�'
		when n.ModeExpedition  in (4,5,6) and n.SupportAbo=2 then N'Papier post�'
		when n.ModeExpedition=2 then N'Num�rique'
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
	,coalesce(p.NombreAbonnes,0) as NombreAbonnes
	, q.Support 
	from q left outer join p 
	on q.Support=p.Supports 
	and q.Mois=p.Mois
)

, w as 
(
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

, x as
(
select w.Mois
	, sum(w.CA_Mensuel) as CA_Mensuel
from w
group by w.Mois
)

, y as
(
select 
r.Mois
, sum(case when r.Support=N'Autre' then r.NombreAbonnes else 0 end) as Autre
, sum(case when r.Support=N'Coupl� port�' then r.NombreAbonnes else 0 end) as CouplePorte
, sum(case when r.Support=N'Coupl� post�' then r.NombreAbonnes else 0 end) as CouplePoste
, sum(case when r.Support=N'Num�rique' then r.NombreAbonnes else 0 end) as Numerique
, sum(case when r.Support=N'Papier port�' then r.NombreAbonnes else 0 end) as PapierPorte
, sum(case when r.Support=N'Papier post�' then r.NombreAbonnes else 0 end) as PapierPoste
from r
group by r.Mois
)

, t as 
(
select y.Mois
	, y.Autre
	, y.CouplePorte
	, y.CouplePoste
	, y.Numerique
	, y.PapierPorte
	, y.PapierPoste 
	, x.CA_Mensuel
from y inner join x on y.Mois=x.Mois
)

select * from t order by Mois
