--QUERY 2 - SITES WEB - VISITES

;with s as 
(
	select WebSiteId from ref.SitesWeb 
)
, r as (
select a.MasterID
, a.CodeOS
, a.DateVisite 
, a.VisiteID
from AmauryVUC.etl.VisitesWeb a inner join s on a.SiteID=s.WebSiteID
)

, p as (
select m.Mois
, a.MasterID
, a.CodeOS
, a.DateVisite
, a.VisiteID
from r as a inner join AmauryVUC.report.DouzeDerniersMois m 
on a.DateVisite>=m.Mois and a.DateVisite<m.FinMois
)

, q as (
select a.SiteID
, cast(a.Visites as int) as Visites
, convert(datetime,left(right(a.FichierTS,12),8),112) as TS
from AmauryVUC.import.Xiti_Sites a inner join s on a.SiteID=s.WebSiteID
)

, u as (
select m.Mois
, sum(a.Visites) as TotalVisites
from q as a inner join AmauryVUC.report.DouzeDerniersMois m on a.TS>=m.Mois and a.TS<m.FinMois
group by m.Mois
)

, w as (
select a.Mois
, a.MasterID
, COUNT(distinct a.VisiteID) as NombreWeb
from p as a left outer join AmauryVUC.ref.Misc b on a.CodeOS=b.RefID and b.TypeRef in (N'OSMOBILE',N'OSTABLETTE')
where b.RefID is null
group by a.Mois
, a.MasterID
)

, v as (
select a.Mois
, a.MasterID
, COUNT(distinct a.VisiteID) as NombreMobile
from p as a inner join AmauryVUC.ref.Misc b on a.CodeOS=b.RefID and b.TypeRef in (N'OSMOBILE',N'OSTABLETTE')
group by a.Mois
, a.MasterID
)

, x  as (
select a.Mois
, a.MasterID
, COUNT(*) as NombreMulti
from w as a inner join v as b on a.Mois=b.Mois and a.MasterID=b.MasterID
group by a.Mois
, a.MasterID
)

, w1 as (
select a.Mois, a.MasterID, a.NombreWeb from w as a left outer join x as b on a.Mois=b.Mois and a.MasterID=b.MasterID where b.MasterID is null
)

, v1 as (
select a.Mois, a.MasterID, a.NombreMobile from v as a left outer join x as b on a.Mois=b.Mois and a.MasterID=b.MasterID where b.MasterID is null
)

, x1 as (
select a.Mois,a.MasterID,COUNT(distinct a.VisiteID) as NombreMulti from p as a inner join x as b on a.Mois=b.Mois and a.MasterID=b.MasterID
group by a.Mois,a.MasterID
)

, t as (
select m.Mois
, (select coalesce(sum(a.NombreWeb),0) from w1 as a where a.Mois=m.Mois ) as VisitesWeb
, (select coalesce(sum(a.NombreMobile),0) from v1 as a where a.Mois=m.Mois ) as VisitesMobile
, (select coalesce(sum(a.NombreMulti),0) from x1 as a where a.Mois=m.Mois )  as VisitesMulti
, (select cast(COUNT(*) as float) from p where p.Mois=m.Mois) / (select case coalesce(u.TotalVisites,0) when 0 then 1 else coalesce(u.TotalVisites,0) end as TotalVisites from u where u.Mois=m.Mois)  as Authentifies
from AmauryVUC.report.DouzeDerniersMois m
)

select a.Mois
	, a.VisitesWeb
	, a.VisitesMobile
	, a.VisitesMulti
	, isnull(a.Authentifies,0)
from t as a 
order by a.Mois
