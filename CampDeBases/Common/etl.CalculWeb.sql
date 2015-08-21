ALTER procedure [etl].[CalculAWeb]
as
begin

--truncate table dbo.ActiviteWeb

update a 
set Appartenance=2
from ref.SitesWeb a where Marque in (2,6,9) and a.Appartenance is null

update a 
set Appartenance=1
from ref.SitesWeb a where Marque in (1,3,4,5,7,8) and a.Appartenance is null

insert into dbo.ActiviteWeb (MasterID, SiteWebID)
select bAW.MasterID, bAW.SiteWebID
from brut.ActiviteWeb bAW left join dbo.ActiviteWeb dAW on bAW.MasterID = dAW.MasterID and bAW.SiteWebID = dAW.SiteWebID 
where dAW.MasterID is null and bAW.MasterID is not null
group by bAW.MasterID, bAW.SiteWebID

/*
insert into dbo.ActiviteWeb (MasterID, SiteWebID, InscriptionDate, DerniereVisiteDate,  VisitesNb,
	DerniereConnexAbonnesDate, ConnexAbonnesNb, DerniereContributionDate, ContributionsNb, DernierConcoursDate, 
	ConcoursNb, DernierJeuDate, JeuxNb, DernierPariDate, ParisNb, NbPagesVues, NbPagesVuesPremium, Appartenance)
select 
	bAW.MasterID, bAW.SiteWebID, MIN(bAW.InscriptionDate), MAX(bAW.DerniereVisiteDate), SUM(bAW.VisitesNb),
	MAX(bAW.DerniereConnexAbonnesDate), SUM(bAW.ConnexAbonnesNb), MAX(bAW.DerniereContributionDate), SUM(bAW.ContributionsNb), MAX(bAW.DernierConcoursDate), 
	SUM(bAW.ConcoursNb), MAX(bAW.DernierJeuDate), SUM(bAW.JeuxNb), MAX(bAW.DernierPariDate), SUM(bAW.ParisNb),
	SUM(bAW.NbPagesVues), SUM(baW.NbPagesVuesPremium), rS.Appartenance 
from brut.ActiviteWeb bAW
inner join ref.SitesWeb rS on bAW.SiteWebID = rS.WebSiteID 
where bAW.MasterID is not null and bAW.SiteWebID is not null
group by bAW.MasterID, bAW.SiteWebID, rS.Appartenance  
*/

update daW
set 
	InscriptionDate = S.InscriptionDate, 
	DerniereVisiteDate = S.DerniereVisiteDate,  
	VisitesNb = S.VisitesNb,
	DerniereConnexAbonnesDate = S.DerniereConnexAbonnesDate, 
	ConnexAbonnesNb = S.ConnexAbonnesNb, 
	DerniereContributionDate = S.DerniereContributionDate, 
	ContributionsNb = S.ContributionsNb, 
	DernierConcoursDate = S.DernierConcoursDate, 
	ConcoursNb = S.ConcoursNb, 
	DernierJeuDate = S.DernierJeuDate, 
	JeuxNb = S.JeuxNb, 
	DernierPariDate = S.DernierPariDate, 
	ParisNb = S.ParisNb, 
	NbPagesVues = S.NbPagesVues, 
	NbPagesVuesPremium = S.NbPagesVuesPremium, 
	Appartenance = S.Appartenance
from dbo.ActiviteWeb dAW
inner join 
(
	select 
		bAW.MasterID, bAW.SiteWebID, MIN(bAW.InscriptionDate) as InscriptionDate, MAX(bAW.DerniereVisiteDate) as DerniereVisiteDate, SUM(bAW.VisitesNb) as VisitesNb,
		MAX(bAW.DerniereConnexAbonnesDate) as DerniereConnexAbonnesDate, SUM(bAW.ConnexAbonnesNb) as ConnexAbonnesNb, MAX(bAW.DerniereContributionDate) as DerniereContributionDate, 
		SUM(bAW.ContributionsNb) as ContributionsNb, MAX(bAW.DernierConcoursDate) as DernierConcoursDate, 
		SUM(bAW.ConcoursNb) as ConcoursNb, MAX(bAW.DernierJeuDate) as DernierJeuDate, SUM(bAW.JeuxNb) as JeuxNb, MAX(bAW.DernierPariDate) as DernierPariDate, SUM(bAW.ParisNb) as ParisNb,
		SUM(bAW.NbPagesVues) as NbPagesVues, SUM(baW.NbPagesVuesPremium) as NbPagesVuesPremium, rS.Appartenance
	from brut.ActiviteWeb bAW
	inner join ref.SitesWeb rS on bAW.SiteWebID = rS.WebSiteID 
	where bAW.MasterID is not null and bAW.SiteWebID is not null
	group by bAW.MasterID, bAW.SiteWebID, rS.Appartenance
) S on dAW.MasterID = S.MasterID and dAW.SiteWebID = S.SiteWebID 
		
update AW
set PremiereConnexionAbonnesDate = S.LaDate
from ActiviteWeb AW
inner join 
(
select MasterID, SiteID, min(DateVisite) as LaDate from etl.VisitesWeb 
WHERE PagesPremiumNb > 0
group by MasterID, SiteID
) S on AW.MasterID = S.MasterID and AW.SiteWebID = S.SiteID
where AW.PremiereConnexionAbonnesDate is null



-- Export ATOS

insert into export.ActionID_ATOS_ActiviteWeb (ActionID, ActiviteWebID)
select 2 as ActionID, dAW.ActiviteWebID
from dbo.ActiviteWeb dAW
inner join brut.ActiviteWeb bAW on dAW.MasterID = bAW.MasterID and dAW.SiteWebID = bAW.SiteWebID 
where bAW.TraiteTop = 0 and dAW.Appartenance = 1
group by dAW.ActiviteWebID

/*-- Init ATOS

insert into export.ActionID_ATOS_ActiviteWeb (ActionID, ActiviteWebID)
select 2 as ActionID, dAW.ActiviteWebID
from dbo.ActiviteWeb dAW
where  dAW.Appartenance = 1



*/


-- Fin Export ATOS



-- On consolide ici les indicateurs des visites web

update V
set TypeAbo = 1, TraiteTop = 0
from etl.VisitesWeb V
inner join ref.SitesWeb S on V.SiteId = S.WebSiteID 
inner join Abonnements A on A.MasterID = V.MasterID  and DateVisite between A.DebutAboDate and isnull(A.FinAboDate, '2099-01-01') and S.Appartenance = A.Appartenance
inner join ref.CatalogueAbonnements CA on CA.CatalogueAbosID = A.CatalogueAbosID and CA.SupportAbo = 1
where V.TypeAbo = 0


update V
set OptinEditorial  = 1, TraiteTop = 0
from etl.VisitesWeb V
inner join ref.SitesWeb S on V.SiteId = S.WebSiteID 
inner join report.NumDyn_Lassitude N on N.MasterID = V.MasterID  and DateVisite between N.DateAbo and isnull(N.DateDesabo, '2099-01-01') 
inner join ref.Contenus RC on N.ContenuID = rC.ContenuID and rC.TypeContenu = 1
inner join ref.Misc M on M.Typeref = 'MARQUE' and M.CodeValN = rC.MarqueID and M.Appartenance = S.Appartenance 
where V.OptinEditorial = 0


end
