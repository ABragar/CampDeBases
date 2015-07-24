USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [import].[CumulLPPROSP_Prospects]    Script Date: 20.07.2015 11:46:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [import].[CumulLPPROSP_Prospects] (@FichierTS nvarchar(255))
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
