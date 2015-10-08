USE [AmauryVUC]
GO

/****** Object:  StoredProcedure [import].[CumulLPPROSP_Prospects]    Script Date: 07/10/2015 17:44:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE proc [import].[CumulLPPROSP_Prospects] (@FichierTS nvarchar(255))
as

begin

set nocount on

-- Vérification du fichier s'il n'est pas vide ni trop court

declare @m xml
declare @n int

select @n=COUNT(*) from import.LPPROSP_Prospects where FichierTS=@FichierTS

if @n<500000 -- la taille moyenne est d'environ 1000000 lignes
begin
	set @m=N'<StepResult>
				<ExitCode>1</ExitCode>
				<Messages>
					<Message>
						<Id>004AE05E-95A6-4C0D-B34A-B03E690370FB</Id>
						<Destinataires>
							<Destinataire ModeEnvoi="3">924AFE01-3F9E-4C40-B54E-87293CB8CF6E</Destinataire>
						</Destinataires>
						<Parametres>
							<Parametre>'+@FichierTS+N'</Parametre>
						</Parametres>
					</Message>
				</Messages>
			</StepResult>'
	select @m
	return
end 

-- Détection de lignes à mettre à jour, avant l'insertion des nouvelles lignes

-- Ce sont les lignes qui ont le email_courant déjà existant dans Prospects_Cumul mais les valeurs des champs ont changé

-- Pour s'assurer qu'il n'y a pas de lignes avec ModifieTop=1 restées d'un tratement précédent,
-- on les remet toutes à 0

update import.Prospects_Cumul
set ModifieTop=0
where ModifieTop=1

update import.Prospects_Cumul
set ModifOptin=0
where ModifOptin=1

update import.Prospects_Cumul
set ModifProfil=0
where ModifProfil=1

-- On détecte les lignes à modifier

-- Traiter séparément la modification du profil et modification d'opt-in

update a
set ModifProfil=1
from import.Prospects_Cumul a inner join import.LPPROSP_Prospects b on a.email_courant=b.email_courant
where (
coalesce(a.datejoin,N'')<>coalesce(b.datejoin,N'')
or coalesce(a.email_origine,N'')<>coalesce(b.email_origine,N'')
or coalesce(a.username,N'')<>coalesce(b.username,N'')
or coalesce(a.civilite,N'')<>coalesce(b.civilite,N'')
or coalesce(a.nom,N'')<>coalesce(b.nom,N'')
or coalesce(a.prenom,N'')<>coalesce(b.prenom,N'')
or coalesce(a.date_de_naissance,N'')<>coalesce(b.date_de_naissance,N'')
or coalesce(a.adresse,N'')<>coalesce(b.adresse,N'')
or coalesce(a.code_postal,N'')<>coalesce(b.code_postal,N'')
or coalesce(a.ville,N'')<>coalesce(b.ville,N'')
or coalesce(a.pays,N'')<>coalesce(b.pays,N'')
or coalesce(a.telephone_particulier,N'')<>coalesce(b.telephone_particulier,N'')
)
and b.FichierTS=@FichierTS
and b.LigneStatut=0

update a
set ModifOptin=1
from import.Prospects_Cumul a inner join import.LPPROSP_Prospects b on a.email_courant=b.email_courant
where (
coalesce(a.optin_leparisien,N'')<>coalesce(b.optin_leparisien,N'')
or coalesce(a.optin_partenaire,N'')<>coalesce(b.optin_partenaire,N'')
or coalesce(a.optin_newsletter,N'')<>coalesce(b.optin_newsletter,N'')
or coalesce(a.optin_alerte,N'')<>coalesce(b.optin_alerte,N'')
or coalesce(a.optin_aujourdhui_etudiant,N'')<>coalesce(b.optin_aujourdhui_etudiant,N'')
or coalesce(a.date_souscrip_optin_leparisien,N'')<>coalesce(b.date_souscrip_optin_leparisien,N'')
or coalesce(a.date_resil_optin_leparisien,N'')<>coalesce(b.date_resil_optin_leparisien,N'')
or coalesce(a.date_souscrip_optin_partenaire,N'')<>coalesce(b.date_souscrip_optin_partenaire,N'')
or coalesce(a.date_resil_optin_partenaire,N'')<>coalesce(b.date_resil_optin_partenaire,N'')
or coalesce(a.date_souscrip_optin_newsletter,N'')<>coalesce(b.date_souscrip_optin_newsletter,N'')
or coalesce(a.date_resil_optin_newsletter,N'')<>coalesce(b.date_resil_optin_newsletter,N'')
or coalesce(a.date_souscrip_optin_alerte,N'')<>coalesce(b.date_souscrip_optin_alerte,N'')
or coalesce(a.date_resil_optin_alerte,N'')<>coalesce(b.date_resil_optin_alerte,N'')
or coalesce(a.date_souscr_optin_auj_etudiant,N'')<>coalesce(b.date_souscr_optin_auj_etudiant,N'')
or coalesce(a.date_resil_optin_auj_etudiant,N'')<>coalesce(b.date_resil_optin_auj_etudiant,N'')
or coalesce(a.date_modif_profil,N'')<>coalesce(b.date_modif_profil,N'')
or coalesce(a.source_recrutement,N'')<>coalesce(b.source_recrutement,N'')
or coalesce(a.source_detail_jc,N'')<>coalesce(b.source_detail_jc,N'')
or coalesce(a.marque_mobile,N'')<>coalesce(b.marque_mobile,N'')
or coalesce(a.modele_mobile,N'')<>coalesce(b.modele_mobile,N'')
or coalesce(a.optin_news_them_laparisienne,N'')<>coalesce(b.optin_news_them_laparisienne,N'')
or coalesce(a.optin_news_them_politique,N'')<>coalesce(b.optin_news_them_politique,N'')
or coalesce(a.optin_news_them_loisirs,N'')<>coalesce(b.optin_news_them_loisirs,N'')
or coalesce(a.date_souscr_nl_thematique,N'')<>coalesce(b.date_souscr_nl_thematique,N'')
or coalesce(a.date_resiliation_nl_thematique,N'')<>coalesce(b.date_resiliation_nl_thematique,N'')
or coalesce(a.optin_news_them_psg,N'')<>coalesce(b.optin_news_them_psg,N'')
)
and b.FichierTS=@FichierTS
and b.LigneStatut=0

update import.Prospects_Cumul set ModifieTop=1 where (ModifOptin=1 or ModifProfil=1)

if object_id(N'tempdb..#T_MarquerModif') is not null
	drop table #T_MarquerModif

create table #T_MarquerModif
(
email_courant nvarchar(255) null
, ModifOptin bit not null default(0)
, ModifProfil bit not null default(0)
)

insert #T_MarquerModif
(
email_courant
)
select email_courant from import.Prospects_Cumul where ModifieTop=1

create index idx01_T_MarquerModif on #T_MarquerModif (email_courant)

update c
set ModifOptin=a.ModifOptin
from #T_MarquerModif c inner join import.Prospects_Cumul a on c.email_courant=a.email_courant

update c
set ModifProfil=a.ModifProfil
from #T_MarquerModif c inner join import.Prospects_Cumul a on c.email_courant=a.email_courant


if OBJECT_ID('tempdb..#T_MAJ_Prospects') is not null
	drop table #T_MAJ_Prospects

create table #T_MAJ_Prospects (email_courant nvarchar(255) null, ImportID int null)

insert #T_MAJ_Prospects (email_courant, ImportID)
select email_courant, ImportID from import.Prospects_Cumul 
where ModifieTop=1

-- Supprimer les anciennes lignes marquées "A modifier" et les remplacer par les nouvelles
delete a
from import.Prospects_Cumul a inner join #T_MAJ_Prospects t on a.ImportID=t.ImportID and a.email_courant=t.email_courant

insert import.Prospects_Cumul
(
RejetCode
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
, telephone_particulier
, optin_leparisien
, optin_partenaire
, optin_newsletter
, optin_alerte
, optin_aujourdhui_etudiant
, date_souscrip_optin_leparisien
, date_resil_optin_leparisien
, date_souscrip_optin_partenaire
, date_resil_optin_partenaire
, date_souscrip_optin_newsletter
, date_resil_optin_newsletter
, date_souscrip_optin_alerte
, date_resil_optin_alerte
, date_souscr_optin_auj_etudiant
, date_resil_optin_auj_etudiant
, date_modif_profil
, source_recrutement
, source_detail_jc
, marque_mobile
, modele_mobile
, optin_news_them_laparisienne
, optin_news_them_politique
, optin_news_them_loisirs
, date_souscr_nl_thematique
, date_resiliation_nl_thematique
, ModifieTop
, LigneStatut
, FichierTS
, optin_news_them_psg
)
select 
a.RejetCode
, a.datejoin
, a.email_origine
, a.email_courant
, a.username
, a.civilite
, a.nom
, a.prenom
, a.date_de_naissance
, a.adresse
, a.code_postal
, a.ville
, a.pays
, a.telephone_particulier
, a.optin_leparisien
, a.optin_partenaire
, a.optin_newsletter
, a.optin_alerte
, a.optin_aujourdhui_etudiant
, a.date_souscrip_optin_leparisien
, a.date_resil_optin_leparisien
, a.date_souscrip_optin_partenaire
, a.date_resil_optin_partenaire
, a.date_souscrip_optin_newsletter
, a.date_resil_optin_newsletter
, a.date_souscrip_optin_alerte
, a.date_resil_optin_alerte
, a.date_souscr_optin_auj_etudiant
, a.date_resil_optin_auj_etudiant
, a.date_modif_profil
, a.source_recrutement
, a.source_detail_jc
, a.marque_mobile
, a.modele_mobile
, a.optin_news_them_laparisienne
, a.optin_news_them_politique
, a.optin_news_them_loisirs
, a.date_souscr_nl_thematique
, a.date_resiliation_nl_thematique
, 1 as ModifieTop
, a.LigneStatut
, a.FichierTS
, a.optin_news_them_psg
from import.LPPROSP_Prospects a
inner join #T_MAJ_Prospects t on a.email_courant=t.email_courant
where a.FichierTS=@FichierTS
and a.LigneStatut=0

update a 
set ModifOptin=b.ModifOptin,ModifProfil=b.ModifProfil
from import.Prospects_Cumul a
inner join #T_MarquerModif b on a.email_courant=b.email_courant and a.ModifieTop=1

-- Insertion des nouvelles lignes

-- Chaque nouvelle ligne est censée donner lieu à un nouveau contacts et ses opt-ins
-- on l'on met d'office ModifOptin=1, ModifProfil=1

insert import.Prospects_Cumul
(
RejetCode
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
, telephone_particulier
, optin_leparisien
, optin_partenaire
, optin_newsletter
, optin_alerte
, optin_aujourdhui_etudiant
, date_souscrip_optin_leparisien
, date_resil_optin_leparisien
, date_souscrip_optin_partenaire
, date_resil_optin_partenaire
, date_souscrip_optin_newsletter
, date_resil_optin_newsletter
, date_souscrip_optin_alerte
, date_resil_optin_alerte
, date_souscr_optin_auj_etudiant
, date_resil_optin_auj_etudiant
, date_modif_profil
, source_recrutement
, source_detail_jc
, marque_mobile
, modele_mobile
, optin_news_them_laparisienne
, optin_news_them_politique
, optin_news_them_loisirs
, date_souscr_nl_thematique
, date_resiliation_nl_thematique
, LigneStatut
, FichierTS
, ModifOptin
, ModifProfil
, optin_news_them_psg
)
select 
a.RejetCode
, a.datejoin
, a.email_origine
, a.email_courant
, a.username
, a.civilite
, a.nom
, a.prenom
, a.date_de_naissance
, a.adresse
, a.code_postal
, a.ville
, a.pays
, a.telephone_particulier
, a.optin_leparisien
, a.optin_partenaire
, a.optin_newsletter
, a.optin_alerte
, a.optin_aujourdhui_etudiant
, a.date_souscrip_optin_leparisien
, a.date_resil_optin_leparisien
, a.date_souscrip_optin_partenaire
, a.date_resil_optin_partenaire
, a.date_souscrip_optin_newsletter
, a.date_resil_optin_newsletter
, a.date_souscrip_optin_alerte
, a.date_resil_optin_alerte
, a.date_souscr_optin_auj_etudiant
, a.date_resil_optin_auj_etudiant
, a.date_modif_profil
, a.source_recrutement
, a.source_detail_jc
, a.marque_mobile
, a.modele_mobile
, a.optin_news_them_laparisienne
, a.optin_news_them_politique
, a.optin_news_them_loisirs
, a.date_souscr_nl_thematique
, a.date_resiliation_nl_thematique
, a.LigneStatut
, a.FichierTS
, 1 as ModifOptin 
, 1 as ModifProfil
, a.optin_news_them_psg
from import.LPPROSP_Prospects a
left outer join import.Prospects_Cumul b on a.email_courant=b.email_courant
where a.FichierTS=@FichierTS
and a.LigneStatut=0
and b.ImportID is null


if OBJECT_ID('tempdb..#T_MAJ_Prospects') is not null
	drop table #T_MAJ_Prospects
	
if object_id(N'tempdb..#T_MarquerModif') is not null
	drop table #T_MarquerModif
	
-- Suppression dans import.Prospects_Cumul et SupprimeTop=1 dans brut.Contacts des lignes qui ne sont plus dans le fichier Prospects d'origine
	
if object_id(N'tempdb..#T_Prospects_Cumul_Suppr') is not null
	drop table #T_Prospects_Cumul_Suppr

create table #T_Prospects_Cumul_Suppr
(
email_courant nvarchar(255) 
, email_origine nvarchar(255) 
)

insert #T_Prospects_Cumul_Suppr 
(
email_courant
,email_origine
)
select 
a.email_courant
, a.email_origine  
from import.Prospects_Cumul a left outer join import.LPPROSP_Prospects b on a.email_courant=b.email_courant
where a.email_courant is not null and b.email_courant is null

create index idx01_T_SSO_Cumul_Suppr on #T_Prospects_Cumul_Suppr(email_courant)
create index idx02_T_SSO_Cumul_Suppr on #T_Prospects_Cumul_Suppr(email_origine)

delete a 
from import.Prospects_Cumul a inner join #T_Prospects_Cumul_Suppr b on a.email_courant=b.email_courant

update a 
set SupprimeTop=1 
from brut.Contacts a inner join #T_Prospects_Cumul_Suppr b on a.OriginalID=b.email_courant
where a.SourceID=4 -- Prospects

if object_id(N'tempdb..#T_Prospects_Cumul_Suppr') is not null
	drop table #T_Prospects_Cumul_Suppr

end

GO

/****** Object:  StoredProcedure [import].[PublierLPPROSP_Prospects]    Script Date: 07/10/2015 17:44:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [import].[PublierLPPROSP_Prospects] @FichierTS nvarchar(255)
as

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 02/10/2013
-- Description:	Publication des Contacts, Emails, Téléphones, Domiciliations, ConsentmentsEmail
-- à partir des fichiers LPPROSP_Prospects du Parisien
-- Modification date: 12/12/2013
-- Modifications :	source_detail_jc as Origine
--					source_recrutement as TypeOrigine
-- Modification date: 31/10/2014
-- Modifications :	la date de création est la plus ancienne 
--					des dates de join, modif ou souscr
-- Modification date: 20/11/2014
-- Modifications :	1) si seulement optin est modifié, on ne met pas ModifieTop=1 dans les Contacts
--					2) les opt-out
-- Modified by :	Andrei BRAGAR
-- Modification date: 20/07/2015
-- Modifications : add optin_news_them_psg
-- =============================================

begin

set nocount on

-- Publication des données de la table Prospects_Cumul

declare @SourceID int

select @SourceID = 4 -- Prospects LP

-- Création de table temporaire

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

/****** Object:  StoredProcedure [import].[rejeterLPPROSP_Prospects]    Script Date: 07/10/2015 17:44:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [import].[rejeterLPPROSP_Prospects] 
@FichierTS nvarchar(255) 
AS
BEGIN

set nocount on 

-- Modification AVE 04/11/2014 :
-- J’ai inhibé toutes les vérifications des dates entre elles. C’est la proc de publication qui choisira la plus ancienne.

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


SET Language ENGLISH

-- Référentiel

-- Civilité : effacer si n'est pas dans TRANSCO

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
-- nouvelle règle : source_recrutement n'est pas obligatoire

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

/* Les vérifications sur l'antériorité des dates ne sont pas pertinentes mais il faut recalculer les échantillons */
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
update import.LPPROSP_Prospects set rejetCode = i.rejetCode | POWER(cast(2 as bigint),40)
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

update import.LPPROSP_Prospects set RejetCode = RejetCode/2 where RejetCode<>0 and FichierTS = @FichierTS

update import.LPPROSP_Prospects set LigneStatut = case when RejetCode = 0 then 0 else 1 end where FichierTS = @FichierTS 

insert into rejet.LPPROSP_Prospects select * from import.LPPROSP_Prospects where RejetCode != 0 and FichierTS = @FichierTS 


END

GO


