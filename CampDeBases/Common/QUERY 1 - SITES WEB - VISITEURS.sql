-- QUERY 1 - SITES WEB - VISITEURS

;with s as 	--websites
(
	select WebSiteId from ref.SitesWeb 
)
, r as (	--visites
select a.MasterID, a.CodeOS, a.DateVisite from etl.VisitesWeb a --TABLESAMPLE (1 PERCENT) REPEATABLE (205) 
inner join s on a.SiteID=s.WebSiteID
)

, p as (   --last year
select m.Mois
, a.MasterID
, a.CodeOS
, a.DateVisite
from r as a inner join AmauryVUC.report.DouzeDerniersMois m 
on a.DateVisite>=m.Mois and a.DateVisite<m.FinMois
)

, w as (  -- NombreWeb
select a.Mois
, a.MasterID
, COUNT(*) as NombreWeb
from p as a left outer join AmauryVUC.ref.Misc b on a.CodeOS=b.RefID and b.TypeRef in (N'OSMOBILE',N'OSTABLETTE')
where b.RefID is null
group by a.Mois
, a.MasterID
)

, v as ( --	NombreMobile
select a.Mois
, a.MasterID
, COUNT(*) as NombreMobile
from p as a inner join AmauryVUC.ref.Misc b on a.CodeOS=b.RefID and b.TypeRef in (N'OSMOBILE',N'OSTABLETTE')
group by a.Mois
, a.MasterID
)

, x  as (  --NombreMulti
select a.Mois
, a.MasterID
, COUNT(*) as NombreMulti
from w as a inner join v as b on a.Mois=b.Mois and a.MasterID=b.MasterID
group by a.Mois
, a.MasterID
)

, w1 as ( --exclude multi from web
select a.Mois, a.MasterID from w as a left outer join x as b on a.Mois=b.Mois and a.MasterID=b.MasterID where b.MasterID is null
)

, v1 as ( --exclude multi from mobile
select a.Mois, a.MasterID from v as a left outer join x as b on a.Mois=b.Mois and a.MasterID=b.MasterID where b.MasterID is null
)

, t as (  --count
select m.Mois
, (select COUNT(distinct MasterID) from w1 where w1.Mois=m.Mois ) as VisiteursWeb
, (select COUNT(distinct MasterID) from v1 where v1.Mois=m.Mois ) as VisiteursMobile
, (select COUNT(distinct MasterID) from x where x.Mois=m.Mois )  as VisiteursMulti
from AmauryVUC.report.DouzeDerniersMois m
)

select a.Mois
	, a.VisiteursWeb
	, a.VisiteursMobile
	, a.VisiteursMulti
from t as a 
order by a.Mois



