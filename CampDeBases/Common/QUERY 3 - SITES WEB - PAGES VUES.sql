-- QUERY 3 - SITES WEB - PAGES VUES

;with s as 
(
	select WebSiteId from ref.SitesWeb 
)
, r as (
select a.MasterID
, a.CodeOS
, a.DateVisite 
, a.VisiteID
, a.PagesNb as PagesVues
from AmauryVUC.etl.VisitesWeb a inner join s on a.SiteID=s.WebSiteID
)

, p as (
select m.Mois
, a.MasterID
, a.CodeOS
, a.DateVisite
, a.VisiteID
, a.PagesVues
from r as a inner join AmauryVUC.report.DouzeDerniersMois m 
on a.DateVisite>=m.Mois and a.DateVisite<m.FinMois
)
, q as (
select a.SiteID
, cast(coalesce(a.PagesVues,0) as int) as PagesVues
, convert(datetime,left(right(a.FichierTS,12),8),112) as TS
from AmauryVUC.import.Xiti_Sites a inner join s on a.SiteID=s.WebSiteID
)
, u as (
select m.Mois
, sum(a.PagesVues) as TotalPagesVues
from q as a inner join AmauryVUC.report.DouzeDerniersMois m on a.TS>=m.Mois and a.TS<m.FinMois
group by m.Mois
)

, w as (
select a.Mois
, a.MasterID
, sum(a.PagesVues) as PagesVuesWeb
from p as a left outer join AmauryVUC.ref.Misc b on a.CodeOS=b.RefID and b.TypeRef in (N'OSMOBILE',N'OSTABLETTE')
where b.RefID is null
group by a.Mois
, a.MasterID
)

, v as (
select a.Mois
, a.MasterID
, sum(a.PagesVues) as PagesVuesMobile
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
select a.Mois, a.MasterID, a.PagesVuesWeb from w as a left outer join x as b on a.Mois=b.Mois and a.MasterID=b.MasterID where b.MasterID is null
)

, v1 as (
select a.Mois, a.MasterID, a.PagesVuesMobile from v as a left outer join x as b on a.Mois=b.Mois and a.MasterID=b.MasterID where b.MasterID is null
)

, x1 as (
select a.Mois,a.MasterID,sum(a.PagesVues) as PagesVuesMulti from p as a inner join x as b on a.Mois=b.Mois and a.MasterID=b.MasterID
group by a.Mois,a.MasterID
)

, t as (
select m.Mois
, (select coalesce(sum(a.PagesVuesWeb),0) from w1 as a where a.Mois=m.Mois ) as PagesVuesWeb
, (select coalesce(sum(a.PagesVuesMobile),0) from v1 as a where a.Mois=m.Mois ) as PagesVuesMobile
, (select coalesce(sum(a.PagesVuesMulti),0) from x1 as a where a.Mois=m.Mois )  as PagesVuesMulti
, (select cast(sum(p.PagesVues) as float) from p where p.Mois=m.Mois) / (select case coalesce(u.TotalPagesVues,0) when 0 then 1 else coalesce(u.TotalPagesVues,0) end as TotalPagesVues from u where u.Mois=m.Mois)  as Authentifies
from AmauryVUC.report.DouzeDerniersMois m
)

select a.Mois
	, a.PagesVuesWeb
	, a.PagesVuesMobile
	, a.PagesVuesMulti 
	, coalesce(a.Authentifies,0.00) as Authentifies
from t as a 
order by a.Mois
