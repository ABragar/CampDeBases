USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [import].[rejeterLPSSO_SSO]    Script Date: 15.07.2015 16:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [import].[rejeterLPSSO_SSO] 
@FichierTS nvarchar(255) 
AS
BEGIN
-- =============================================
-- Modified by :	Andrei BRAGAR
-- Modification date: 15/07/2015
-- Modifications : username, partenaires, nb_commentaires_articles, nb_posts_You, nb_evnmt_Etudiants, nb_identification_SSO, nb_acces_abo  => Not mandatory anymore
-- =============================================
set nocount on 

-- Modification AVE 04/11/2014 :
-- J’ai inhibé toutes les vérifications des dates entre elles. C’est la proc de publication qui choisira la plus ancienne.

exec import.TrimColonnes 'import', 'LPSSO_SSO'
update import.LPSSO_SSO set FichierTS= @FichierTS where FichierTS is null

update import.LPSSO_SSO set adresse=NULL where adresse=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set civilite=NULL where civilite=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set cp=NULL where cp=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set date_abo=NULL where date_abo=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set date_creation=NULL where date_creation=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set date_dernier_acces_abo=NULL where date_dernier_acces_abo=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set date_dernier_commentaire_article=NULL where date_dernier_commentaire_article=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set date_dernier_evnmt_Etudiants=NULL where date_dernier_evnmt_Etudiants=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set date_dernier_post_You=NULL where date_dernier_post_You=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set datelastlogin=NULL where datelastlogin=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set datemaj=NULL where datemaj=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set dixit=NULL where dixit=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set email_courant=NULL where email_courant=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set email_origine=NULL where email_origine=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set etat=NULL where etat=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set facebook=NULL where facebook=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set genre=NULL where genre=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set id_Leparisien=NULL where id_Leparisien=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set id_SSO=NULL where id_SSO=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set naissance=NULL where naissance=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set nb_acces_abo=NULL where nb_acces_abo=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set nb_commentaires_articles=NULL where nb_commentaires_articles=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set nb_evnmt_Etudiants=NULL where nb_evnmt_Etudiants=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set nb_identification_SSO=NULL where nb_identification_SSO=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set nb_posts_You=NULL where nb_posts_You=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set nom=NULL where nom=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set partenaires=NULL where partenaires=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set pays=NULL where pays=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set prenom=NULL where prenom=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set provenance=NULL where provenance=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set telephone=NULL where telephone=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set twitter=NULL where twitter=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set twitter_username=NULL where twitter_username=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set username=NULL where username=N'\N' and FichierTS = @FichierTS
update import.LPSSO_SSO set ville=NULL where ville=N'\N' and FichierTS = @FichierTS

update import.LPSSO_SSO set adresse=replace (adresse,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set civilite=replace (civilite,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set cp=replace (cp,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set date_abo=replace (date_abo,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set date_creation=replace (date_creation,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set date_dernier_acces_abo=replace (date_dernier_acces_abo,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set date_dernier_commentaire_article=replace (date_dernier_commentaire_article,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set date_dernier_evnmt_Etudiants=replace (date_dernier_evnmt_Etudiants,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set date_dernier_post_You=replace (date_dernier_post_You,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set datelastlogin=replace (datelastlogin,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set datemaj=replace (datemaj,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set dixit=replace (dixit,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set email_courant=replace (email_courant,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set email_origine=replace (email_origine,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set etat=replace (etat,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set facebook=replace (facebook,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set genre=replace (genre,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set id_Leparisien=replace (id_Leparisien,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set id_SSO=replace (id_SSO,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set naissance=replace (naissance,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set nb_acces_abo=replace (nb_acces_abo,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set nb_commentaires_articles=replace (nb_commentaires_articles,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set nb_evnmt_Etudiants=replace (nb_evnmt_Etudiants,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set nb_identification_SSO=replace (nb_identification_SSO,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set nb_posts_You=replace (nb_posts_You,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set nom=replace (nom,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set partenaires=replace (partenaires,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set pays=replace (pays,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set prenom=replace (prenom,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set provenance=replace (provenance,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set telephone=replace (telephone,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set twitter=replace (twitter,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set twitter_username=replace (twitter_username,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set username=replace (username,N'"',N'') where FichierTS = @FichierTS
update import.LPSSO_SSO set ville=replace (ville,N'"',N'') where FichierTS = @FichierTS

/*
update import.LPSSO_SSO
set civilite=N'M'
where ( 
civilite=N'1'
or civilite=N'homme'
or civilite=N'M'
or civilite=N'M.'
or civilite=N'Monsi'
or civilite=N'Mr'
)

update import.LPSSO_SSO
set civilite=N'Mme'
where (
civilite=N'2'
or civilite=N'femme'
or civilite=N'Madam'
or civilite=N'Madem'
or civilite=N'MM'
or civilite=N'MME'
or civilite=N'MMES'
)

update import.LPSSO_SSO
set civilite=N'Mlle'
where (
civilite=N'3'
or civilite=N'MLLE'
)

update import.LPSSO_SSO
set civilite=null
where civilite not in (N'M',N'Mme',N'Mlle',N'Dr',N'Mgr',N'Me')
*/

SET Language ENGLISH

-- Référentiel

update i set civilite=null
from import.LPSSO_SSO i
left outer join etl.TRANSCO a on i.civilite=a.Origine and a.TranscoCode=N'Civilite' and a.SourceId=N'2'
where FichierTS = @FichierTS and LigneStatut = 0
and i.civilite is not null
and a.TranscoCode is null

-- Taille
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),4)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and (len(isnull(email_courant,'')) < 1 or len(isnull(email_courant,'')) > 255)

-- Taille
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),5)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and (len(isnull(email_origine,'')) < 1 or len(isnull(email_origine,'')) > 255)

-- Taille
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),12)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and (len(isnull(prenom,'')) > 255)

-- Taille
/*
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),25)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and (len(isnull(provenance,'')) < 1 or len(isnull(provenance,'')) > 255)
*/
-- nouvelle règle : provenance c'est pas obligatoire

-- Taille
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),3)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
AND len(isnull(username,'')) > 255
--and (len(isnull(username,'')) < 1 or len(isnull(username,'')) > 255)	-username => Not mandatory anymore

-- Taille
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),11)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and (len(isnull(nom,'')) > 255)

-- Booléen
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),6)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and etat not in ('1','0')

set dateformat ymd

-- Date
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),14)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(naissance,'1900-01-01')) = 0

-- Date
update i
set naissance=null -- Effacer si incorrecte
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(naissance as datetime) < cast(DATEADD(year,-100,getdate()) as datetime) or cast(naissance as datetime) > cast(DATEADD(year,-7,getdate()) as dateTime))
and i.rejetCode & POWER(cast(2 as bigint),14)<>POWER(cast(2 as bigint),14)

-- Date
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),7)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_creation,'a')) = 0

-- Date
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),34)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_abo,'1900-01-01')) = 0

/*
-- Date
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),34)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_abo as datetime) < dateadd(day,-1,cast(date_creation as datetime)) or cast(date_abo as datetime) > cast(getdate() as dateTime))
and i.rejetCode & POWER(cast(2 as bigint),34)<>POWER(cast(2 as bigint),34)
and i.rejetCode & POWER(cast(2 as bigint),7)<>POWER(cast(2 as bigint),7) -- date_creation
*/

-- Date
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),35)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_dernier_acces_abo,'1900-01-01')) = 0

/*
-- Date
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),35)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_dernier_acces_abo as datetime) < cast(date_creation as datetime) or cast(date_dernier_acces_abo as datetime) > cast(getdate() as dateTime))
and i.rejetCode & POWER(cast(2 as bigint),35)<>POWER(cast(2 as bigint),35)
and i.rejetCode & POWER(cast(2 as bigint),7)<>POWER(cast(2 as bigint),7) -- date_creation
*/

-- Date
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),26)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_dernier_commentaire_article,'1900-01-01')) = 0

/*
-- Date
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),26)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_dernier_commentaire_article as datetime) < dateadd(day,-1,cast(date_creation as datetime)) or cast(date_dernier_commentaire_article as datetime) > cast(getdate() as dateTime))
and i.rejetCode & POWER(cast(2 as bigint),26)<>POWER(cast(2 as bigint),26)
and i.rejetCode & POWER(cast(2 as bigint),7)<>POWER(cast(2 as bigint),7) -- date_creation
*/

-- Date
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),30)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_dernier_evnmt_Etudiants,'1900-01-01')) = 0

/*
-- Date
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),30)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_dernier_evnmt_Etudiants as datetime) < dateadd(day,-1,cast(date_creation as datetime)) or cast(date_dernier_evnmt_Etudiants as datetime) > cast(getdate() as dateTime))
and i.rejetCode & POWER(cast(2 as bigint),30)<>POWER(cast(2 as bigint),30)
and i.rejetCode & POWER(cast(2 as bigint),7)<>POWER(cast(2 as bigint),7) -- date_creation
*/

-- Date
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),28)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(date_dernier_post_You,'1900-01-01')) = 0

/*
-- Date
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),28)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(date_dernier_post_You as datetime) < cast(date_creation as datetime) or cast(date_dernier_post_You as datetime) > cast(getdate() as dateTime))
and i.rejetCode & POWER(cast(2 as bigint),28)<>POWER(cast(2 as bigint),28)
and i.rejetCode & POWER(cast(2 as bigint),7)<>POWER(cast(2 as bigint),7) -- date_creation
*/

-- Date
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),9)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(datelastlogin,'1900-01-01')) = 0

/*
-- Date
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),9)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(datelastlogin as datetime) < dateadd(day,-1,cast(date_creation as datetime)) or cast(datelastlogin as datetime) > cast(getdate() as dateTime))
and i.rejetCode & POWER(cast(2 as bigint),9)<>POWER(cast(2 as bigint),9)
and i.rejetCode & POWER(cast(2 as bigint),7)<>POWER(cast(2 as bigint),7) -- date_creation
*/

-- Date
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),8)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISDATE(isnull(datemaj,'1900-01-01')) = 0

/* La date de mise à jour peut être légitimement antérieure à la date de création */
/*
-- Date
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),8)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and (cast(datemaj as datetime) < dateadd(day,-1,cast(date_creation as datetime)) or cast(datemaj as datetime) > cast(getdate() as dateTime))
and i.rejetCode & POWER(cast(2 as bigint),8)<>POWER(cast(2 as bigint),8)
and i.rejetCode & POWER(cast(2 as bigint),7)<>POWER(cast(2 as bigint),7) -- date_creation
*/

-- Entier
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),23)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISNUMERIC(isnull(dixit, '0')) = 0 

-- Entier
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),24)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISNUMERIC(isnull(partenaires, '0')) = 0  --Not mandatory anymore

-- Entier
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),36)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISNUMERIC(isnull(nb_acces_abo, '0')) = 0  --Not mandatory anymore

-- Entier
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),27)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISNUMERIC(isnull(nb_commentaires_articles, '0')) = 0 --Not mandatory anymore

-- Entier
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),31)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISNUMERIC(isnull(nb_evnmt_Etudiants, '0')) = 0 --Not mandatory anymore 

-- Entier
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),32)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISNUMERIC(isnull(nb_identification_SSO, '0')) = 0 --Not mandatory anymore

-- Entier
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),29)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISNUMERIC(isnull(nb_posts_You, '0')) = 0   --Not mandatory anymore

-- Entier
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),13)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISNUMERIC(isnull(genre, '0')) = 0 

-- Entier
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),33)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISNUMERIC(isnull(id_Leparisien, '0')) = 0 

-- Entier
update import.LPSSO_SSO set rejetCode = i.rejetCode | POWER(cast(2 as bigint),2)
from import.LPSSO_SSO i
where FichierTS = @FichierTS and LigneStatut = 0
and ISNUMERIC(isnull(id_SSO, 'a')) = 0 

update import.LPSSO_SSO set RejetCode = RejetCode/2 where RejetCode<>0 and FichierTS = @FichierTS

update import.LPSSO_SSO set LigneStatut = case when RejetCode = 0 then 0 else 1 end where FichierTS = @FichierTS 

insert into rejet.LPSSO_SSO select * from import.LPSSO_SSO where RejetCode != 0 and FichierTS = @FichierTS 

END
