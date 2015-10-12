USE [AmauryVUC]
GO

/****** Object:  StoredProcedure [import].[rejeterLPPROSP_Prospects]    Script Date: 12.10.2015 19:22:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [import].[rejeterLPPROSP_Prospects] 
@FichierTS nvarchar(255) 
AS
BEGIN

set nocount on 

-- Modification AVE 04/11/2014 :
-- J’ai inhibй toutes les vйrifications des dates entre elles. C’est la proc de publication qui choisira la plus ancienne.

exec import.TrimColonnes 'import', 'Prospects'
update import.LPPROSP_Prospects set FichierTS= @FichierTS where FichierTS is null

update import.LPPROSP_Prospects set datejoin=NULL where datejoin=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set adresse=NULL where adresse=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set civilite=NULL where civilite=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set code_postal=NULL where code_postal=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_de_naissance=NULL where date_de_naissance=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_modif_profil=NULL where date_modif_profil=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_resil_optin_alerte=NULL where date_resil_optin_alerte=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_resil_optin_auj_etudiant=NULL where date_resil_optin_auj_etudiant=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_resil_optin_leparisien=NULL where date_resil_optin_leparisien=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_resil_optin_newsletter=NULL where date_resil_optin_newsletter=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_resil_optin_partenaire=NULL where date_resil_optin_partenaire=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_resiliation_nl_thematique=replace (date_resiliation_nl_thematique,N';',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_resiliation_nl_thematique=REPLACE(date_resiliation_nl_thematique,char(9),N'')
update import.LPPROSP_Prospects set date_resiliation_nl_thematique=NULL where left(date_resiliation_nl_thematique,2)=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_souscr_nl_thematique=NULL where date_souscr_nl_thematique=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_souscr_optin_auj_etudiant=NULL where date_souscr_optin_auj_etudiant=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_souscrip_optin_alerte=NULL where date_souscrip_optin_alerte=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_souscrip_optin_leparisien=NULL where date_souscrip_optin_leparisien=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_souscrip_optin_newsletter=NULL where date_souscrip_optin_newsletter=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_souscrip_optin_partenaire=NULL where date_souscrip_optin_partenaire=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set email_courant=NULL where email_courant=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set email_origine=NULL where email_origine=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set marque_mobile=NULL where marque_mobile=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set modele_mobile=NULL where modele_mobile=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set nom=NULL where nom=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_alerte=NULL where optin_alerte=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_aujourdhui_etudiant=NULL where optin_aujourdhui_etudiant=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_leparisien=NULL where optin_leparisien=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_news_them_laparisienne=NULL where optin_news_them_laparisienne=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_news_them_psg=NULL where optin_news_them_psg=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_news_them_loisirs=NULL where optin_news_them_loisirs=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_news_them_politique=NULL where optin_news_them_politique=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter=NULL where optin_newsletter=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_partenaire=NULL where optin_partenaire=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set pays=NULL where pays=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set prenom=NULL where prenom=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set source_detail_jc=NULL where source_detail_jc=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set source_recrutement=NULL where source_recrutement=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set telephone_particulier=NULL where telephone_particulier=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set username=NULL where username=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set ville=NULL where ville=N'\N' and FichierTS = @FichierTS

update import.LPPROSP_Prospects set optin_newsletter_thematique_ile_de_france=NULL where optin_newsletter_thematique_ile_de_france=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter_thematique_paris=NULL where optin_newsletter_thematique_paris=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter_thematique_seine_et_marne=NULL where optin_newsletter_thematique_seine_et_marne=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter_thematique_yvelines=NULL where optin_newsletter_thematique_yvelines=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter_thematique_essonne=NULL where optin_newsletter_thematique_essonne=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter_thematique_hauts_de_seine=NULL where optin_newsletter_thematique_hauts_de_seine=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter_thematique_seine_st_denis=NULL where optin_newsletter_thematique_seine_st_denis=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter_thematique_val_de_marne=NULL where optin_newsletter_thematique_val_de_marne=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter_thematique_val_oise=NULL where optin_newsletter_thematique_val_oise=N'\N' and FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter_thematique_oise=NULL where optin_newsletter_thematique_oise=N'\N' and FichierTS = @FichierTS


update import.LPPROSP_Prospects set adresse=replace (adresse,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set civilite=replace (civilite,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set code_postal=replace (code_postal,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_de_naissance=replace (date_de_naissance,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_modif_profil=replace (date_modif_profil,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_resil_optin_alerte=replace (date_resil_optin_alerte,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_resil_optin_auj_etudiant=replace (date_resil_optin_auj_etudiant,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_resil_optin_leparisien=replace (date_resil_optin_leparisien,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_resil_optin_newsletter=replace (date_resil_optin_newsletter,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_resil_optin_partenaire=replace (date_resil_optin_partenaire,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_resiliation_nl_thematique=replace (date_resiliation_nl_thematique,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_souscr_nl_thematique=replace (date_souscr_nl_thematique,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_souscr_optin_auj_etudiant=replace (date_souscr_optin_auj_etudiant,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_souscrip_optin_alerte=replace (date_souscrip_optin_alerte,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_souscrip_optin_leparisien=replace (date_souscrip_optin_leparisien,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_souscrip_optin_newsletter=replace (date_souscrip_optin_newsletter,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set date_souscrip_optin_partenaire=replace (date_souscrip_optin_partenaire,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set datejoin=replace (datejoin,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set email_courant=replace (email_courant,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set email_origine=replace (email_origine,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set marque_mobile=replace (marque_mobile,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set modele_mobile=replace (modele_mobile,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set nom=replace (nom,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_alerte=replace (optin_alerte,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_aujourdhui_etudiant=replace (optin_aujourdhui_etudiant,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_leparisien=replace (optin_leparisien,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_news_them_laparisienne=replace (optin_news_them_laparisienne,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_news_them_psg=replace (optin_news_them_psg,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_news_them_loisirs=replace (optin_news_them_loisirs,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_news_them_politique=replace (optin_news_them_politique,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter=replace (optin_newsletter,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_partenaire=replace (optin_partenaire,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set pays=replace (pays,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set prenom=replace (prenom,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set source_detail_jc=replace (source_detail_jc,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set source_recrutement=replace (source_recrutement,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set telephone_particulier=replace (telephone_particulier,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set username=replace (username,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set ville=replace (ville,N'"',N'') where FichierTS = @FichierTS

update import.LPPROSP_Prospects set optin_newsletter_thematique_ile_de_france=replace (optin_newsletter_thematique_ile_de_france,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter_thematique_paris=replace (optin_newsletter_thematique_paris,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter_thematique_seine_et_marne=replace (optin_newsletter_thematique_seine_et_marne,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter_thematique_yvelines=replace (optin_newsletter_thematique_yvelines,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter_thematique_essonne=replace (optin_newsletter_thematique_essonne,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter_thematique_hauts_de_seine=replace (optin_newsletter_thematique_hauts_de_seine,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter_thematique_seine_st_denis=replace (optin_newsletter_thematique_seine_st_denis,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter_thematique_val_de_marne=replace (optin_newsletter_thematique_val_de_marne,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter_thematique_val_oise=replace (optin_newsletter_thematique_val_oise,N'"',N'') where FichierTS = @FichierTS
update import.LPPROSP_Prospects set optin_newsletter_thematique_oise=replace (optin_newsletter_thematique_oise,N'"',N'') where FichierTS = @FichierTS

SET Language ENGLISH

-- Rйfйrentiel

-- Civilitй : effacer si n'est pas dans TRANSCO

update i set civilite=null
-- rejetCode = i.rejetCode | POWER(cast(2 as bigint),6)
from import.LPPROSP_Prospects i
left outer join etl.TRANSCO a on i.civilite=a.Origine and a.TranscoCode=N'Civilite' and a.SourceId=N'4'
where FichierTS = @FichierTS and LigneStatut = 0
and i.civilite is not null
and a.TranscoCode is null

-- Eliminer les doublons dans email_courant

update a 
set rejetCode = a.rejetCode | POWER(cast(2 as bigint),4) 
from import.LPPROSP_Prospects a
inner join (select RANK() over (partition by a.email_courant order by 
	 a.nom desc
	, a.prenom desc
	, a.date_de_naissance desc
	, a.adresse desc
	, a.code_postal desc
	, a.ville desc
	, pays desc
	, newid() ) as N1
, a.email_courant
, a.ImportID
from import.LPPROSP_Prospects a inner join (
select COUNT(*) as N, a.email_courant from import.LPPROSP_Prospects a
group by a.email_courant
having COUNT(*)>1) as r1 on a.email_courant=r1.email_courant) as r2 on a.ImportID=r2.ImportID
where r2.N1>1

-- Taille
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),4)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (len(isnull(email_courant,'')) < 1 or len(isnull(email_courant,'')) > 255)

-- Taille
/*
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),31)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and len(isnull(source_recrutement,'')) < 1
*/
-- nouvelle rиgle : source_recrutement n'est pas obligatoire

/*-- Taille
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),32)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and len(isnull(source_detail_jc,'')) < 1
*/

-- Taille
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),3)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (len(isnull(email_origine,'')) < 1 or len(isnull(email_origine,'')) > 255)

set dateformat ymd

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),2)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(datejoin,'1900-01-01')) = 0

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),20)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_souscrip_optin_leparisien,'1900-01-01')) = 0

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),21)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_resil_optin_leparisien,'1900-01-01')) = 0

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),22)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_souscrip_optin_partenaire,'1900-01-01')) = 0

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),23)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_resil_optin_partenaire,'1900-01-01')) = 0

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),24)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_souscrip_optin_newsletter,'1900-01-01')) = 0

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),25)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_resil_optin_newsletter,'1900-01-01')) = 0

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),26)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_souscrip_optin_alerte,'1900-01-01')) = 0

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),27)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_resil_optin_alerte,'1900-01-01')) = 0

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),28)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_souscr_optin_auj_etudiant,'1900-01-01')) = 0

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),29)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_resil_optin_auj_etudiant,'1900-01-01')) = 0

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),30)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_modif_profil,'1900-01-01')) = 0

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),38)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_souscr_nl_thematique,'1900-01-01')) = 0

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),39)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_resiliation_nl_thematique,'1900-01-01')) = 0

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),9)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_de_naissance,'1900-01-01')) = 0

-- Date
update i
set date_de_naissance=null
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_de_naissance as datetime) < cast(dateadd(year,-100,getdate()) as datetime) or cast(date_de_naissance as datetime) > cast(dateadd(year,-7,getdate()) as dateTime))
and i.rejetCode & POWER(cast(2 as bigint),9)<>POWER(cast(2 as bigint),9)

/* Les vйrifications sur l'antйrioritй des dates ne sont pas pertinentes mais il faut recalculer les йchantillons */
/*
-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),30)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_modif_profil as date) < cast(datejoin as date) or cast(date_modif_profil as date) > cast(getdate() as date))
and i.rejetCode & POWER(cast(2 as bigint),30)<>POWER(cast(2 as bigint),30)
and i.rejetCode & POWER(cast(2 as bigint),2)<>POWER(cast(2 as bigint),2) -- datejoin


-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),27)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_resil_optin_alerte as date) < cast(date_souscrip_optin_alerte as date) or cast(date_resil_optin_alerte as date) > cast(getdate() as date))
and i.rejetCode & POWER(cast(2 as bigint),27)<>POWER(cast(2 as bigint),27)
and i.rejetCode & POWER(cast(2 as bigint),26)<>POWER(cast(2 as bigint),26) -- date_souscrip_optin_alerte

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),29)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_resil_optin_auj_etudiant as date) < cast(date_souscr_optin_auj_etudiant as date) or cast(date_resil_optin_auj_etudiant as date) > cast(getdate() as date))
and i.rejetCode & POWER(cast(2 as bigint),29)<>POWER(cast(2 as bigint),29)
and i.rejetCode & POWER(cast(2 as bigint),28)<>POWER(cast(2 as bigint),28) -- date_souscr_optin_auj_etudiant


-- Date
update import.LPPROSP_Prospects 
-- set rejetCode = i.rejetCode | POWER(cast(2 as bigint),21)
set date_resil_optin_leparisien=null 
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_resil_optin_leparisien as date) < cast(date_souscrip_optin_leparisien as date) or cast(date_resil_optin_leparisien as date) > cast(getdate() as date))
and i.rejetCode & POWER(cast(2 as bigint),21)<>POWER(cast(2 as bigint),21)
and i.rejetCode & POWER(cast(2 as bigint),20)<>POWER(cast(2 as bigint),20) -- date_souscrip_optin_leparisien

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),25)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_resil_optin_newsletter as date) < dateadd(day,-1,cast(date_souscrip_optin_newsletter as date)) or cast(date_resil_optin_newsletter as date) > cast(getdate() as date))
and i.rejetCode & POWER(cast(2 as bigint),25)<>POWER(cast(2 as bigint),25)
and i.rejetCode & POWER(cast(2 as bigint),24)<>POWER(cast(2 as bigint),24) -- date_souscrip_optin_newsletter


-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),22)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_resil_optin_partenaire as date) < cast(date_souscrip_optin_partenaire as date) or cast(date_resil_optin_partenaire as date) > cast(getdate() as date))
and i.rejetCode & POWER(cast(2 as bigint),23)<>POWER(cast(2 as bigint),23)
and i.rejetCode & POWER(cast(2 as bigint),22)<>POWER(cast(2 as bigint),22) -- date_souscrip_optin_partenaire


-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),38)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_souscr_nl_thematique as date) < cast(datejoin as date) or cast(date_souscr_nl_thematique as date) > cast(getdate() as date))
and i.rejetCode & POWER(cast(2 as bigint),38)<>POWER(cast(2 as bigint),38)
and i.rejetCode & POWER(cast(2 as bigint),2)<>POWER(cast(2 as bigint),2) -- datejoin

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),39)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_resiliation_nl_thematique as date) < cast(date_souscr_nl_thematique as date) or cast(date_resiliation_nl_thematique as date) > cast(getdate() as date))
and i.rejetCode & POWER(cast(2 as bigint),39)<>POWER(cast(2 as bigint),39)
and i.rejetCode & POWER(cast(2 as bigint),38)<>POWER(cast(2 as bigint),38) -- date_souscr_nl_thematique


-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),28)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_souscr_optin_auj_etudiant as date) < cast(datejoin as date) or cast(date_souscr_optin_auj_etudiant as date) > cast(getdate() as date))
and i.rejetCode & POWER(cast(2 as bigint),28)<>POWER(cast(2 as bigint),28)
and i.rejetCode & POWER(cast(2 as bigint),2)<>POWER(cast(2 as bigint),2) -- datejoin

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),26)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_souscrip_optin_alerte as date) < cast(datejoin as date) or cast(date_souscrip_optin_alerte as date) > cast(getdate() as date))
and i.rejetCode & POWER(cast(2 as bigint),26)<>POWER(cast(2 as bigint),26)
and i.rejetCode & POWER(cast(2 as bigint),2)<>POWER(cast(2 as bigint),2) -- datejoin

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),20)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_souscrip_optin_leparisien as date) < cast(datejoin as date) or cast(date_souscrip_optin_leparisien as date) > cast(getdate() as date))
and i.rejetCode & POWER(cast(2 as bigint),20)<>POWER(cast(2 as bigint),20)
and i.rejetCode & POWER(cast(2 as bigint),2)<>POWER(cast(2 as bigint),2) -- datejoin

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),24)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_souscrip_optin_newsletter as date) < cast(datejoin as date) or cast(date_souscrip_optin_newsletter as date) > cast(getdate() as date))
and i.rejetCode & POWER(cast(2 as bigint),24)<>POWER(cast(2 as bigint),24)
and i.rejetCode & POWER(cast(2 as bigint),2)<>POWER(cast(2 as bigint),2) -- datejoin

-- Date
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),22)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_souscrip_optin_partenaire as date) < cast(datejoin as date) or cast(date_souscrip_optin_partenaire as date) > cast(getdate() as date))
and i.rejetCode & POWER(cast(2 as bigint),22)<>POWER(cast(2 as bigint),22)
and i.rejetCode & POWER(cast(2 as bigint),2)<>POWER(cast(2 as bigint),2) -- datejoin

 */

-- Entier
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),35)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_news_them_laparisienne as int) < 0 or cast(optin_news_them_laparisienne as int) > 2)

-- Entier
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),36)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_news_them_politique as int) < 0 or cast(optin_news_them_politique as int) > 2)

-- Entier
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),37)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_news_them_loisirs as int) < 0 or cast(optin_news_them_loisirs as int) > 2)

-- Entier
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | etl.GetErrorCode('import.LPPROSP_Prospects','optin_news_them_psg')
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_news_them_psg as int) < 0 or cast(optin_news_them_psg as int) > 2)

-- Entier
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),15)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_leparisien as int) < 0 or cast(optin_leparisien as int) > 2)

-- Entier
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),16)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_partenaire as int) < 0 or cast(optin_partenaire as int) > 2)

-- Entier
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),17)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_newsletter as int) < 0 or cast(optin_newsletter as int) > 2)

-- Entier
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),18)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_alerte as int) < 0 or cast(optin_alerte as int) > 2)

-- Entier
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),19)
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_aujourdhui_etudiant as int) < 0 or cast(optin_aujourdhui_etudiant as int) > 2)



update import.LPPROSP_Prospects set rejetCode = i.rejetCode | etl.GetErrorCode('import.LPPROSP_Prospects','optin_newsletter_thematique_ile_de_france')
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_newsletter_thematique_ile_de_france as int) < 0 or cast(optin_newsletter_thematique_ile_de_france as int) > 2)

update import.LPPROSP_Prospects set rejetCode = i.rejetCode | etl.GetErrorCode('import.LPPROSP_Prospects','optin_newsletter_thematique_paris')
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_newsletter_thematique_paris as int) < 0 or cast(optin_newsletter_thematique_paris as int) > 2)

update import.LPPROSP_Prospects set rejetCode = i.rejetCode | etl.GetErrorCode('import.LPPROSP_Prospects','optin_newsletter_thematique_seine_et_marne')
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_newsletter_thematique_seine_et_marne as int) < 0 or cast(optin_newsletter_thematique_seine_et_marne as int) > 2)

update import.LPPROSP_Prospects set rejetCode = i.rejetCode | etl.GetErrorCode('import.LPPROSP_Prospects','optin_newsletter_thematique_yvelines')
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_newsletter_thematique_yvelines as int) < 0 or cast(optin_newsletter_thematique_yvelines as int) > 2)

update import.LPPROSP_Prospects set rejetCode = i.rejetCode | etl.GetErrorCode('import.LPPROSP_Prospects','optin_newsletter_thematique_essonne')
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_newsletter_thematique_essonne as int) < 0 or cast(optin_newsletter_thematique_essonne as int) > 2)

update import.LPPROSP_Prospects set rejetCode = i.rejetCode | etl.GetErrorCode('import.LPPROSP_Prospects','optin_newsletter_thematique_hauts_de_seine')
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_newsletter_thematique_hauts_de_seine as int) < 0 or cast(optin_newsletter_thematique_hauts_de_seine as int) > 2)

update import.LPPROSP_Prospects set rejetCode = i.rejetCode | etl.GetErrorCode('import.LPPROSP_Prospects','optin_newsletter_thematique_seine_st_denis')
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_newsletter_thematique_seine_st_denis as int) < 0 or cast(optin_newsletter_thematique_seine_st_denis as int) > 2)

update import.LPPROSP_Prospects set rejetCode = i.rejetCode | etl.GetErrorCode('import.LPPROSP_Prospects','optin_newsletter_thematique_val_de_marne')
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_newsletter_thematique_val_de_marne as int) < 0 or cast(optin_newsletter_thematique_val_de_marne as int) > 2)

update import.LPPROSP_Prospects set rejetCode = i.rejetCode | etl.GetErrorCode('import.LPPROSP_Prospects','optin_newsletter_thematique_val_oise')
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_newsletter_thematique_val_oise as int) < 0 or cast(optin_newsletter_thematique_val_oise as int) > 2)

update import.LPPROSP_Prospects set rejetCode = i.rejetCode | etl.GetErrorCode('import.LPPROSP_Prospects','optin_newsletter_thematique_oise')
from import.LPPROSP_Prospects i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(optin_newsletter_thematique_oise as int) < 0 or cast(optin_newsletter_thematique_oise as int) > 2)

update import.LPPROSP_Prospects set RejetCode = RejetCode/2 where RejetCode<>0 and FichierTS = @FichierTS

update import.LPPROSP_Prospects set LigneStatut = case when RejetCode = 0 then 0 else 1 end where FichierTS = @FichierTS 

insert into rejet.LPPROSP_Prospects select * from import.LPPROSP_Prospects where RejetCode != 0 and FichierTS = @FichierTS 


END


GO


