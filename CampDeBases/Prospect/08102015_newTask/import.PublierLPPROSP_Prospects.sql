USE [AmauryVUC]
GO

/****** Object:  StoredProcedure [import].[PublierLPPROSP_Prospects]    Script Date: 12.10.2015 21:35:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [import].[PublierLPPROSP_Prospects] @FichierTS nvarchar(255)
as

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 02/10/2013
-- Description:	Publication des Contacts, Emails, Tйlйphones, Domiciliations, ConsentmentsEmail
-- а partir des fichiers LPPROSP_Prospects du Parisien
-- Modification date: 12/12/2013
-- Modifications :	source_detail_jc as Origine
--					source_recrutement as TypeOrigine
-- Modification date: 31/10/2014
-- Modifications :	la date de crйation est la plus ancienne 
--					des dates de join, modif ou souscr
-- Modification date: 20/11/2014
-- Modifications :	1) si seulement optin est modifiй, on ne met pas ModifieTop=1 dans les Contacts
--					2) les opt-out
-- Modified by :	Andrei BRAGAR
-- Modification date: 20/07/2015
-- Modifications : add optin_news_them_psg
-- =============================================

begin

set nocount on

-- Publication des donnйes de la table Prospects_Cumul

declare @SourceID int

select @SourceID = 4 -- Prospects LP

-- Crйation de table temporaire

if OBJECT_ID('tempdb..#T_Contacts_Prospects') is not null
	drop table #T_Contacts_Prospects

create table #T_Contacts_Prospects (
ProfilID int null
, SourceID int null
, OriginalID nvarchar(255) null
, datejoin datetime null
, email_origine nvarchar(255) null
, email_courant nvarchar(255) null
, username nvarchar(255) null
, civilite nvarchar(255) null
, nom nvarchar(255) null
, prenom nvarchar(255) null
, date_de_naissance datetime null
, adresse nvarchar(255) null
, code_postal nvarchar(255) null
, ville nvarchar(255) null
, pays nvarchar(255) null
, telephone nvarchar(255) null
, date_modif_profil datetime null
, date_resil_optin_alerte datetime null
, date_resil_optin_auj_etudiant datetime null
, date_resil_optin_leparisien datetime null
, date_resil_optin_newsletter datetime null
, date_resil_optin_partenaire datetime null
, date_souscr_optin_auj_etudiant datetime null
, date_souscrip_optin_alerte datetime null
, date_souscrip_optin_leparisien datetime null
, date_souscrip_optin_newsletter datetime null
, date_souscrip_optin_partenaire datetime null
, date_resiliation_nl_thematique datetime null
, date_souscr_nl_thematique datetime null
, optin_alerte tinyint null
, optin_aujourdhui_etudiant tinyint null
, optin_leparisien tinyint null
, optin_news_them_laparisienne tinyint null
, optin_news_them_loisirs tinyint null
, optin_news_them_politique tinyint null
, optin_newsletter tinyint null
, optin_partenaire tinyint null
, source_detail_jc nvarchar(255) null
, source_recrutement nvarchar(255) null
, CreationDate datetime null
, ModifOptin bit null 
, ModifProfil bit null
, optin_news_them_psg tinyint null
)

set dateformat ymd

insert #T_Contacts_Prospects
( ProfilID
, SourceID
, OriginalID
, datejoin
, email_origine
, email_courant
, username
, civilite
, nom
, prenom
, date_de_naissance
, adresse
, code_postal
, ville
, pays
, telephone
, date_modif_profil
, date_resil_optin_alerte
, date_resil_optin_auj_etudiant
, date_resil_optin_leparisien
, date_resil_optin_newsletter
, date_resil_optin_partenaire
, date_souscr_optin_auj_etudiant
, date_souscrip_optin_alerte
, date_souscrip_optin_leparisien
, date_souscrip_optin_newsletter
, date_souscrip_optin_partenaire
, date_resiliation_nl_thematique
, date_souscr_nl_thematique
, optin_alerte
, optin_aujourdhui_etudiant
, optin_leparisien
, optin_news_them_laparisienne
, optin_news_them_loisirs
, optin_news_them_politique
, optin_newsletter
, optin_partenaire
, source_detail_jc
, source_recrutement
, ModifOptin
, ModifProfil
,optin_news_them_psg
)
select 
null as ProfilID
, @SourceID
, email_courant as OriginalID
, cast(datejoin as datetime)
, email_origine
, email_courant
, username
, civilite
, nom
, prenom
, cast(date_de_naissance as datetime)
, adresse
, code_postal
, ville
, pays
, telephone_particulier
, cast(date_modif_profil as datetime) as date_modif_profil
, cast(date_resil_optin_alerte as datetime) as date_resil_optin_alerte
, cast(date_resil_optin_auj_etudiant as datetime) as date_resil_optin_auj_etudiant
, cast(date_resil_optin_leparisien as datetime) as date_resil_optin_leparisien
, cast(date_resil_optin_newsletter as datetime) as date_resil_optin_newsletter
, cast(date_resil_optin_partenaire as datetime) as date_resil_optin_partenaire
, cast(date_souscr_optin_auj_etudiant as datetime) as date_souscr_optin_auj_etudiant
, cast(date_souscrip_optin_alerte as datetime) as date_souscrip_optin_alerte
, cast(date_souscrip_optin_leparisien as datetime) as date_souscrip_optin_leparisien
, cast(date_souscrip_optin_newsletter as datetime) as date_souscrip_optin_newsletter
, cast(date_souscrip_optin_partenaire as datetime) as date_souscrip_optin_partenaire
, cast(date_resiliation_nl_thematique as datetime) as date_resiliation_nl_thematique
, cast(date_souscr_nl_thematique as datetime) as date_souscr_nl_thematique
, cast(optin_alerte as tinyint) as optin_alerte
, cast(optin_aujourdhui_etudiant as tinyint) as optin_aujourdhui_etudiant
, cast(optin_leparisien as tinyint) as optin_leparisien
, cast(optin_news_them_laparisienne as tinyint) as optin_news_them_laparisienne
, cast(optin_news_them_loisirs as tinyint) as optin_news_them_loisirs
, cast(optin_news_them_politique as tinyint) as optin_news_them_politique
, cast(optin_newsletter as tinyint) as optin_newsletter
, cast(optin_partenaire as tinyint) as optin_partenaire
, source_detail_jc
, source_recrutement
, ModifOptin
, ModifProfil
, cast(optin_news_them_psg as tinyint) as optin_news_them_psg
from import.Prospects_Cumul
where FichierTS=@FichierTS
and LigneStatut=0

update #T_Contacts_Prospects
set email_origine=REPLACE(email_origine,CHAR(9),N'')
where PATINDEX(N'%'+char(9)+N'%',email_origine)>0

update #T_Contacts_Prospects
set email_courant=REPLACE(email_courant,CHAR(9),N'')
where PATINDEX(N'%'+char(9)+N'%',email_courant)>0

update #T_Contacts_Prospects
set username=REPLACE(username,CHAR(9),N'')
where PATINDEX(N'%'+char(9)+N'%',username)>0

update #T_Contacts_Prospects
set email_origine=REPLACE(email_origine,CHAR(13),N'')
where PATINDEX(N'%'+char(13)+N'%',email_origine)>0

update #T_Contacts_Prospects
set email_courant=REPLACE(email_courant,CHAR(13),N'')
where PATINDEX(N'%'+char(13)+N'%',email_courant)>0

update #T_Contacts_Prospects
set username=REPLACE(username,CHAR(13),N'')
where PATINDEX(N'%'+char(13)+N'%',username)>0

create index idx01_OriginalID on #T_Contacts_Prospects(OriginalID)

if object_id(N'tempdb..#T_Dates') is not null
	drop table #T_Dates

create table #T_Dates (OriginalID nvarchar(255) null, CreationDate datetime null, TpDt nvarchar(255) null)

insert #T_Dates (OriginalID, CreationDate, TpDt)
select r1.OriginalID,r1.CreationDate, r1.TpDt from (
	select b.OriginalID, datejoin as CreationDate, N'datejoin' as TpDt from #T_Contacts_Prospects b 
union select b.OriginalID, date_souscrip_optin_leparisien as CreationDate, N'optin_leparisien' as TpDt from #T_Contacts_Prospects b 
union select b.OriginalID, date_souscrip_optin_partenaire as CreationDate, N'optin_partenaire' as TpDt from #T_Contacts_Prospects b 
union select b.OriginalID, date_souscrip_optin_newsletter as CreationDate, N'optin_newsletter' as TpDt from #T_Contacts_Prospects b 
union select b.OriginalID, date_souscrip_optin_alerte as CreationDate, N'optin_alerte' as TpDt from #T_Contacts_Prospects b 
union select b.OriginalID, date_souscr_optin_auj_etudiant as CreationDate, N'optin_auj_etudiant' as TpDt from #T_Contacts_Prospects b 
union select b.OriginalID, date_modif_profil as CreationDate, N'modif_profil' as TpDt from #T_Contacts_Prospects b 
union select b.OriginalID, date_souscr_nl_thematique as CreationDate, N'nl_thematique' as TpDt from #T_Contacts_Prospects b 
) as r1

create index idx01_OriginalID on #T_Dates (OriginalID)

update a
set CreationDate=b.date_resil_optin_leparisien
from #T_Dates a inner join #T_Contacts_Prospects b on a.OriginalID=b.OriginalID and coalesce(a.CreationDate,N'2079-01-01')>b.date_resil_optin_leparisien
where a.TpDt=N'optin_leparisien'

update a
set CreationDate=b.date_resil_optin_partenaire
from #T_Dates a inner join #T_Contacts_Prospects b on a.OriginalID=b.OriginalID and coalesce(a.CreationDate,N'2079-01-01')>b.date_resil_optin_partenaire
where a.TpDt=N'optin_partenaire'

update a
set CreationDate=b.date_resil_optin_newsletter
from #T_Dates a inner join #T_Contacts_Prospects b on a.OriginalID=b.OriginalID and coalesce(a.CreationDate,N'2079-01-01')>b.date_resil_optin_newsletter
where a.TpDt=N'optin_newsletter'

update a
set CreationDate=b.date_resil_optin_alerte
from #T_Dates a inner join #T_Contacts_Prospects b on a.OriginalID=b.OriginalID and coalesce(a.CreationDate,N'2079-01-01')>b.date_resil_optin_alerte
where a.TpDt=N'optin_alerte'

update a
set CreationDate=b.date_resil_optin_auj_etudiant
from #T_Dates a inner join #T_Contacts_Prospects b on a.OriginalID=b.OriginalID and coalesce(a.CreationDate,N'2079-01-01')>b.date_resil_optin_auj_etudiant
where a.TpDt=N'optin_auj_etudiant'

update a
set CreationDate=b.date_resiliation_nl_thematique
from #T_Dates a inner join #T_Contacts_Prospects b on a.OriginalID=b.OriginalID and coalesce(a.CreationDate,N'2079-01-01')>b.date_resiliation_nl_thematique
where a.TpDt=N'nl_thematique'

if object_id(N'tempdb..#T_Dates_Min') is not null
	drop table #T_Dates_Min
	
create table #T_Dates_Min (OriginalID nvarchar(255) null, CreationDate datetime null)

insert #T_Dates_Min (OriginalID, CreationDate)
select a.OriginalID,min(a.CreationDate) as CreationDate
from #T_Dates a
where a.OriginalID is not null and a.CreationDate is not null
group by a.OriginalID

if object_id(N'tempdb..#T_Dates') is not null
	drop table #T_Dates

create index idx01_OriginalID on #T_Dates_Min (OriginalID)

update a
set CreationDate=b.CreationDate
from #T_Contacts_Prospects a inner join #T_Dates_Min b on a.OriginalID=b.OriginalID

if object_id(N'tempdb..#T_Dates_Min') is not null
	drop table #T_Dates_Min
	
update b
set Origine=a.source_detail_jc
, TypeOrigine=a.source_recrutement
, Civilite=a.civilite
, Prenom=a.prenom
, Nom=a.nom
, NaissanceDate=a.date_de_naissance
, Age=datediff(year,a.date_de_naissance,getdate())
, CreationDate=coalesce(a.CreationDate,getdate())
, ModificationDate=coalesce(a.date_modif_profil,a.CreationDate,getdate())
, MasterID=b.ProfilID
, ModifieTop=1
from #T_Contacts_Prospects a inner join brut.Contacts b on a.OriginalID=b.OriginalID and b.SourceID=@SourceID
where a.ModifProfil=1

update b
set CreationDate=coalesce(a.CreationDate,getdate())
, ModificationDate=coalesce(a.date_modif_profil,a.CreationDate,getdate())
from #T_Contacts_Prospects a inner join brut.Contacts b on a.OriginalID=b.OriginalID and b.SourceID=@SourceID
where (
b.CreationDate<>coalesce(a.CreationDate,getdate())
or b.ModificationDate<>coalesce(a.date_modif_profil,a.CreationDate,getdate())
)


insert brut.Contacts
(
SourceID
, OriginalID
, Origine
, TypeOrigine
, Civilite
, Prenom
, Nom
, Genre
, NaissanceDate
, Age
, CreationDate
, ModificationDate
, ModifieTop
, SupprimeTop
, FichierSource
, Appartenance
)
select
a.SourceID
, a.OriginalID
, a.source_detail_jc as Origine
, a.source_recrutement as TypeOrigine
, a.civilite
, a.prenom
, a.nom
, null as Genre
, a.date_de_naissance
, datediff(year,a.date_de_naissance,getdate())
, coalesce(a.CreationDate,getdate()) as CreationDate
, coalesce(a.date_modif_profil,a.CreationDate,getdate()) as ModificationDate
, 1 as ModifieTop
, 0 as SupprimeTop
, @FichierTS as FichierSource
, 2
from #T_Contacts_Prospects a left outer join brut.Contacts b on a.OriginalID=b.OriginalID and b.SourceID=@SourceID
where a.OriginalID is not null
and b.OriginalID is null
and a.ModifProfil=1

update a 
set ProfilID=b.ProfilID
from #T_Contacts_Prospects a inner join brut.Contacts b 
on a.OriginalID=b.OriginalID 
and a.SourceID=b.SourceID

update b 
set MasterID=b.ProfilID
from #T_Contacts_Prospects a inner join brut.Contacts b 
on a.OriginalID=b.OriginalID 
and a.SourceID=b.SourceID
and b.MasterID is null

create index idx02_ProfilID on #T_Contacts_Prospects(ProfilID)

delete #T_Contacts_Prospects where ProfilID is null

insert brut.Domiciliations
(
ProfilID
, Adr1
, Adr2
, Adr3
, Adr4
, CodePostal
, Ville
, Pays
, CreationDate
, ModificationDate
, ValeurOrigine
)
select
a.ProfilID
, left(a.adresse,80) as Adr1
, null as Adr2
, null as Adr3
, null as Adr4
, left(a.code_postal,32) as CodePostal
, left(a.ville,80) as Ville
, left(a.pays,80) as Pays
, coalesce(a.CreationDate,getdate()) as CreationDate
, coalesce(a.date_modif_profil,a.CreationDate,getdate()) as ModificationDate
, coalesce(left(a.adresse,80),N'')+coalesce(left(a.code_postal,32),N'')+coalesce(left(a.ville,80),N'') as ValeurOrigine
from #T_Contacts_Prospects a left outer join brut.Domiciliations b on a.ProfilID=b.ProfilID
and coalesce(left(a.adresse,80),N'')=coalesce(b.Adr1,N'')
and coalesce(left(a.code_postal,32),N'') = coalesce(b.CodePostal,N'')
and coalesce(left(a.ville,80),N'') = coalesce(b.Ville,N'')
and coalesce(left(a.pays,80),N'') = coalesce(b.Pays,N'')
where not (a.adresse is null and a.code_postal is null and a.ville is null and a.pays is null)
and a.ProfilID is not null
and b.ProfilID is null
and a.ModifProfil=1

-- brut.Emails

insert brut.Emails
(
Email
, ProfilID
, ValeurOrigine
, CreationDate
, ModificationDate 
)
select 
LEFT(t.email_courant,128)
, t.ProfilID
, LEFT(t.email_courant,128)
, coalesce(t.CreationDate,getdate()) as CreationDate
, coalesce(t.date_modif_profil,t.CreationDate,getdate()) as ModificationDate
from #T_Contacts_Prospects t
inner join [brut].[Contacts] bc on t.[ProfilID]=bc.[ProfilID]
	left outer join [brut].[Emails] em on bc.ProfilID=em.ProfilID and t.email_courant=em.Email
where em.ProfilID is null
and coalesce(t.[email_courant],N'')<>N'' 
and t.ModifProfil=1

insert brut.Telephones
(
ProfilID
, LigneType
, NumeroTelephone
, CreationDate
, ModificationDate 
)
select 
t.ProfilID
, case when (len(t.telephone)=9 and LEFT(t.telephone,1) in (N'6',N'7')) 
			or (len(t.telephone)=10 and LEFT(t.telephone,2) in (N'06',N'07')) 
		then 4 else 3 end
, left(telephone,20) as NumeroTelephone
, coalesce(t.CreationDate,getdate()) as CreationDate
, coalesce(t.date_modif_profil,t.CreationDate,getdate()) as ModificationDate
from #T_Contacts_Prospects t
inner join [brut].[Contacts] bc on t.[ProfilID]=bc.[ProfilID]
	left outer join [brut].[Telephones] bt on bc.ProfilID=bt.ProfilID and t.telephone=bt.NumeroTelephone
where bt.ProfilID is null
and coalesce(t.telephone,N'')<>N'' 
and t.ModifProfil=1

insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select
t.ProfilID
, t.ProfilID
, LEFT(t.email_courant,128)
, c.ContenuID
, 1 as Valeur
, coalesce(t.date_souscrip_optin_alerte,t.date_modif_profil,t.CreationDate,getdate()) as ConsentementDate
from #T_Contacts_Prospects t
inner join ref.Contenus c on c.NomContenu=N'optin_alerte'
left outer join brut.ConsentementsEmail d on t.ProfilID=d.ProfilID and c.ContenuID=d.ContenuID and d.Valeur in (1,-4)
where t.optin_alerte=1
and (t.date_resil_optin_alerte is null or t.date_resil_optin_alerte<t.date_souscrip_optin_alerte)
and t.ProfilID is not null and d.ProfilID is null
and t.ModifOptin=1

insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select
t.ProfilID
, t.ProfilID
, LEFT(t.email_courant,128)
, c.ContenuID
, -1 as Valeur
, coalesce(t.date_resil_optin_alerte,t.date_modif_profil,t.CreationDate,getdate()) as ConsentementDate
from #T_Contacts_Prospects t
inner join ref.Contenus c on c.NomContenu=N'optin_alerte'
left outer join brut.ConsentementsEmail d on t.ProfilID=d.ProfilID and c.ContenuID=d.ContenuID and d.Valeur in (-1,-4)
where t.date_resil_optin_alerte is not null and t.date_resil_optin_alerte>coalesce(t.date_souscrip_optin_alerte,N'1900-01-01')
and t.ProfilID is not null and d.ProfilID is null
and t.ModifOptin=1


insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select
t.ProfilID
, t.ProfilID
, LEFT(t.email_courant,128)
, c.ContenuID
, 1 as Valeur
, coalesce(t.date_souscr_optin_auj_etudiant,t.date_modif_profil,t.CreationDate,getdate()) as ConsentementDate
from #T_Contacts_Prospects t
inner join ref.Contenus c on c.NomContenu=N'optin_aujourdhui_etudiant'
left outer join brut.ConsentementsEmail d on t.ProfilID=d.ProfilID and c.ContenuID=d.ContenuID and d.Valeur in (1,-4)
where t.optin_aujourdhui_etudiant=1
and (t.date_resil_optin_auj_etudiant is null or t.date_resil_optin_auj_etudiant<t.date_souscr_optin_auj_etudiant)
and t.ProfilID is not null and d.ProfilID is null
and t.ModifOptin=1

insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select
t.ProfilID
, t.ProfilID
, LEFT(t.email_courant,128)
, c.ContenuID
, -1 as Valeur
, coalesce(t.date_resil_optin_auj_etudiant,t.date_modif_profil,t.CreationDate,getdate()) as ConsentementDate
from #T_Contacts_Prospects t
inner join ref.Contenus c on c.NomContenu=N'optin_aujourdhui_etudiant'
left outer join brut.ConsentementsEmail d on t.ProfilID=d.ProfilID and c.ContenuID=d.ContenuID and d.Valeur in (-1,-4)
where t.date_resil_optin_auj_etudiant is not null and t.date_resil_optin_auj_etudiant>coalesce(t.date_souscr_optin_auj_etudiant,N'1900-01-01')
and t.ProfilID is not null and d.ProfilID is null
and t.ModifOptin=1

insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select
t.ProfilID
, t.ProfilID
, LEFT(t.email_courant,128)
, c.ContenuID
, 1 as Valeur
, coalesce(t.date_souscrip_optin_leparisien,t.date_modif_profil,t.CreationDate,getdate()) as ConsentementDate
from #T_Contacts_Prospects t
inner join ref.Contenus c on c.NomContenu=N'Optin Editeur LP' -- 51 remplace 43 optin_leparisien
left outer join brut.ConsentementsEmail d on t.ProfilID=d.ProfilID and c.ContenuID=d.ContenuID and d.Valeur in (1,-4)
where t.optin_leparisien=1
and (t.date_resil_optin_leparisien is null or t.date_resil_optin_leparisien<t.date_souscrip_optin_leparisien)
and t.ProfilID is not null and d.ProfilID is null
and t.ModifOptin=1

insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select
t.ProfilID
, t.ProfilID
, LEFT(t.email_courant,128)
, c.ContenuID
, -1 as Valeur
, coalesce(t.date_resil_optin_leparisien,t.date_modif_profil,t.CreationDate,getdate()) as ConsentementDate
from #T_Contacts_Prospects t
inner join ref.Contenus c on c.NomContenu=N'Optin Editeur LP' -- 51 remplace 43 optin_leparisien
left outer join brut.ConsentementsEmail d on t.ProfilID=d.ProfilID and c.ContenuID=d.ContenuID and d.Valeur in (-1,-4)
where t.date_resil_optin_leparisien is not null and t.date_resil_optin_leparisien>coalesce(t.date_souscrip_optin_leparisien,N'1900-01-01')
and t.ProfilID is not null and d.ProfilID is null
and t.ModifOptin=1

insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select
t.ProfilID
, t.ProfilID
, LEFT(t.email_courant,128)
, c.ContenuID
, 1 as Valeur
, coalesce(t.date_souscr_nl_thematique,t.date_modif_profil,t.CreationDate,getdate()) as ConsentementDate
from #T_Contacts_Prospects t
inner join ref.Contenus c on c.NomContenu=N'optin_news_them_laparisienne'
left outer join brut.ConsentementsEmail d on t.ProfilID=d.ProfilID and c.ContenuID=d.ContenuID and d.Valeur in (1,-4)
where t.optin_news_them_laparisienne=1
and (t.date_resiliation_nl_thematique is null or t.date_resiliation_nl_thematique<t.date_souscr_nl_thematique)
and t.ProfilID is not null and d.ProfilID is null
and t.ModifOptin=1

insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select
t.ProfilID
, t.ProfilID
, LEFT(t.email_courant,128)
, c.ContenuID
, -1 as Valeur
, coalesce(t.date_resiliation_nl_thematique,t.date_modif_profil,t.CreationDate,getdate()) as ConsentementDate
from #T_Contacts_Prospects t
inner join ref.Contenus c on c.NomContenu=N'optin_news_them_laparisienne'
left outer join brut.ConsentementsEmail d on t.ProfilID=d.ProfilID and c.ContenuID=d.ContenuID and d.Valeur in (-1,-4)
where t.date_resiliation_nl_thematique is not null and t.date_resiliation_nl_thematique>coalesce(t.date_souscr_nl_thematique,N'1900-01-01')
and t.ProfilID is not null and d.ProfilID is null
and t.ModifOptin=1

insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select
t.ProfilID
, t.ProfilID
, LEFT(t.email_courant,128)
, c.ContenuID
, 1 as Valeur
, coalesce(t.date_souscr_nl_thematique,t.date_modif_profil,t.CreationDate,getdate()) as ConsentementDate
from #T_Contacts_Prospects t
inner join ref.Contenus c on c.NomContenu=N'optin_news_them_loisirs'
left outer join brut.ConsentementsEmail d on t.ProfilID=d.ProfilID and c.ContenuID=d.ContenuID and d.Valeur in (1,-4)
where t.optin_news_them_loisirs=1
and (t.date_resiliation_nl_thematique is null or t.date_resiliation_nl_thematique<t.date_souscr_nl_thematique)
and t.ProfilID is not null and d.ProfilID is null
and t.ModifOptin=1

insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select
t.ProfilID
, t.ProfilID
, LEFT(t.email_courant,128)
, c.ContenuID
, -1 as Valeur
, coalesce(t.date_resiliation_nl_thematique,t.date_modif_profil,t.CreationDate,getdate()) as ConsentementDate
from #T_Contacts_Prospects t
inner join ref.Contenus c on c.NomContenu=N'optin_news_them_loisirs'
left outer join brut.ConsentementsEmail d on t.ProfilID=d.ProfilID and c.ContenuID=d.ContenuID and d.Valeur in (-1,-4)
where t.date_resiliation_nl_thematique is not null and t.date_resiliation_nl_thematique>coalesce(t.date_souscr_nl_thematique,N'1900-01-01')
and t.ProfilID is not null and d.ProfilID is null
and t.ModifOptin=1

--optin_news_them_psg

DECLARE @optin_news_them_psg_date DATETIME = CAST(
           SUBSTRING(@FichierTS ,LEN(@FichierTS) -7 ,4) + SUBSTRING(@FichierTS ,LEN(@FichierTS) -9 ,2) + 
           SUBSTRING(@FichierTS ,LEN(@FichierTS) -11 ,2) AS DATETIME
       ) 

UPDATE ce
SET    ce.Valeur = -1
      ,ConsentementDate = @optin_news_them_psg_date
FROM   #T_Contacts_Prospects t
       INNER JOIN ref.Contenus c
            ON  c.NomContenu = N'Newsletter PSG'
       INNER JOIN brut.ConsentementsEmail ce
            ON  t.ProfilID = ce.ProfilID
                AND c.ContenuID = ce.ContenuID
WHERE  t.ProfilID IS NOT NULL
       AND t.optin_news_them_psg = 2

UPDATE ce
SET    ce.Valeur = 1
      ,ConsentementDate = @optin_news_them_psg_date
FROM   #T_Contacts_Prospects t
       INNER JOIN ref.Contenus c
            ON  c.NomContenu = N'Newsletter PSG'
       INNER JOIN brut.ConsentementsEmail ce
            ON  t.ProfilID = ce.ProfilID
                AND c.ContenuID = ce.ContenuID
WHERE  t.ProfilID IS NOT NULL
       AND t.optin_news_them_psg = 1

INSERT brut.ConsentementsEmail
  (
    ProfilID
   ,MasterID
   ,Email
   ,ContenuID
   ,Valeur
   ,ConsentementDate
  )
SELECT t.ProfilID
      ,t.ProfilID
      ,LEFT(t.email_courant ,128)
      ,c.ContenuID --,58
      ,1                          AS Valeur
      ,@optin_news_them_psg_date  AS ConsentementDate
FROM   #T_Contacts_Prospects t
       INNER JOIN ref.Contenus c
            ON  c.NomContenu = N'Newsletter PSG'
       LEFT JOIN brut.ConsentementsEmail ce
            ON  t.ProfilID = ce.ProfilID
                AND c.ContenuID = ce.ContenuID
WHERE  t.ProfilID IS NOT NULL
AND  t.optin_news_them_psg = 1
       AND ce.ProfilID IS            NULL

--end of optin_news_them_psg

insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select
t.ProfilID
, t.ProfilID
, LEFT(t.email_courant,128)
, c.ContenuID
, 1 as Valeur
, coalesce(t.date_souscr_nl_thematique,t.date_modif_profil,t.CreationDate,getdate()) as ConsentementDate
from #T_Contacts_Prospects t
inner join ref.Contenus c on c.NomContenu=N'optin_news_them_politique'
left outer join brut.ConsentementsEmail d on t.ProfilID=d.ProfilID and c.ContenuID=d.ContenuID and d.Valeur in (1,-4)
where t.optin_news_them_politique=1
and (t.date_resiliation_nl_thematique is null or t.date_resiliation_nl_thematique<t.date_souscr_nl_thematique)
and t.ProfilID is not null and d.ProfilID is null
and t.ModifOptin=1


insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select
t.ProfilID
, t.ProfilID
, LEFT(t.email_courant,128)
, c.ContenuID
, -1 as Valeur
, coalesce(t.date_resiliation_nl_thematique,t.date_modif_profil,t.CreationDate,getdate()) as ConsentementDate
from #T_Contacts_Prospects t
inner join ref.Contenus c on c.NomContenu=N'optin_news_them_politique'
left outer join brut.ConsentementsEmail d on t.ProfilID=d.ProfilID and c.ContenuID=d.ContenuID and d.Valeur in (-1,-4)
where t.date_resiliation_nl_thematique is not null and t.date_resiliation_nl_thematique>coalesce(t.date_souscr_nl_thematique,N'1900-01-01')
and t.ProfilID is not null and d.ProfilID is null
and t.ModifOptin=1

insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select
t.ProfilID
, t.ProfilID
, LEFT(t.email_courant,128)
, c.ContenuID
, 1 as Valeur
, coalesce(t.date_souscrip_optin_newsletter,t.date_modif_profil,t.CreationDate,getdate()) as ConsentementDate
from #T_Contacts_Prospects t
inner join ref.Contenus c on c.NomContenu=N'Newsletter Le Parisien.fr'
left outer join brut.ConsentementsEmail d on t.ProfilID=d.ProfilID and c.ContenuID=d.ContenuID and d.Valeur in (1,-4)
where t.optin_newsletter=1
and (t.date_resil_optin_newsletter is null or t.date_resil_optin_newsletter<t.date_souscrip_optin_newsletter)
and t.ProfilID is not null and d.ProfilID is null
and t.ModifOptin=1

insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select
t.ProfilID
, t.ProfilID
, LEFT(t.email_courant,128)
, c.ContenuID
, -1 as Valeur
, coalesce(t.date_resil_optin_newsletter,t.date_modif_profil,t.CreationDate,getdate()) as ConsentementDate
from #T_Contacts_Prospects t
inner join ref.Contenus c on c.NomContenu=N'Newsletter Le Parisien.fr'
left outer join brut.ConsentementsEmail d on t.ProfilID=d.ProfilID and c.ContenuID=d.ContenuID and d.Valeur in (-1,-4)
where t.date_resil_optin_newsletter is not null and t.date_resil_optin_newsletter>coalesce(t.date_souscrip_optin_newsletter,N'1900-01-01')
and t.ProfilID is not null and d.ProfilID is null
and t.ModifOptin=1

insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select
t.ProfilID
, t.ProfilID
, LEFT(t.email_courant,128)
, c.ContenuID
, 1 as Valeur
, coalesce(t.date_souscrip_optin_partenaire,t.date_modif_profil,t.CreationDate,getdate()) as ConsentementDate
from #T_Contacts_Prospects t
inner join ref.Contenus c on c.NomContenu=N'Optin Partenaires LP'
left outer join brut.ConsentementsEmail d on t.ProfilID=d.ProfilID and c.ContenuID=d.ContenuID and d.Valeur in (1,-4)
where t.optin_partenaire=1
and (t.date_resil_optin_partenaire is null or t.date_resil_optin_partenaire<t.date_souscrip_optin_partenaire)
and t.ProfilID is not null and d.ProfilID is null
and t.ModifOptin=1

insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select
t.ProfilID
, t.ProfilID
, LEFT(t.email_courant,128)
, c.ContenuID
, -1 as Valeur
, coalesce(t.date_resil_optin_partenaire,t.date_modif_profil,t.CreationDate,getdate()) as ConsentementDate
from #T_Contacts_Prospects t
inner join ref.Contenus c on c.NomContenu=N'Optin Partenaires LP'
left outer join brut.ConsentementsEmail d on t.ProfilID=d.ProfilID and c.ContenuID=d.ContenuID and d.Valeur in (-1,-4)
where t.date_resil_optin_partenaire is not null and t.date_resil_optin_partenaire>coalesce(t.date_souscrip_optin_partenaire,N'1900-01-01')
and t.ProfilID is not null and d.ProfilID is null
and t.ModifOptin=1

update a
set LigneStatut=99
from import.Prospects_Cumul a inner join #T_Contacts_Prospects b
on a.email_courant=b.OriginalID
where a.FichierTS=@FichierTS
and a.LigneStatut=0

update a
set LigneStatut=99
from import.LPPROSP_Prospects a inner join #T_Contacts_Prospects b
on a.email_courant=b.OriginalID
where a.FichierTS=@FichierTS
and a.LigneStatut=0

if OBJECT_ID('tempdb..#T_Contacts_Prospects') is not null
	drop table #T_Contacts_Prospects
	
	/********** AUTOCALCULATE REJECTSTATS **********/
	DELETE FROM QTSDQF.rejet.REJETS_TAUX where TableName = '[AmauryVUC].[import].[LPPROSP_Prospects]'

	IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'LPPROSP_Prospects'))
		EXECUTE [QTSDQF].[dbo].[RejetsStats] '95940C81-C7A7-4BD9-A523-445A343A9605', 'LPPROSP_Prospects', @FichierTS	

end


GO


