USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [import].[PublierSDVP_Contrats]    Script Date: 13.05.2015 16:43:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [import].[PublierSDVP_Contrats] @FichierTS nvarchar(255)
-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 21/11/2013
-- Description:	Alimentation de la table brut.Contrats_Abos et dbo.Abonnements
-- à partir des fichiers SDVP_Contrats 
-- en utilisant ref.CatalogueAbonnements
-- Modification date: 28/07/2014
-- Modifications : 
-- Regroupement par 6 champs : 
-- CTRCODSOC
-- CTRNUMABO
-- CTRCODTIT
-- CTRCODOFF
-- CTROPTOFF
-- CTRCODPRV
-- =============================================
as
begin

set nocount on

-- Publication des données de la table SDVP_Contrats

declare @SourceID int

select @SourceID = 3 -- SDVP

set dateformat dmy

if OBJECT_ID('tempdb..#T_Lignes_SDVP_Contrats') is not null
	drop table #T_Lignes_SDVP_Contrats

create table #T_Lignes_SDVP_Contrats -- c'est pour alimenter brut.Contrats_Abos
(
ProfilID int null
, OriginalID nvarchar(255) null
, CTRCODSOC nvarchar(8) not null
, CTRCODTAR nvarchar(8) not null
, CTRCODOFF nvarchar(8) not null
, CTRCODPRV nvarchar(32) not null
, CTRCODTIT nvarchar(8) not null
, CTROPTOFF nvarchar(8) not null
, CTRNUMABO nvarchar(18) not null
, CTRNUMCTR nvarchar(8) not null
, CatalogueAbosID int null
, SouscriptionAboDate datetime null
, DebutAboDate datetime null
, FinAboDate datetime null
, ExAboSouscrNb int not null default(0)
, NbreSouscr int not null default(0)
, RemiseAbo decimal(10,2) null
, MontantAbo decimal(10,2) null 
, Devise nvarchar(16) null
, PremierNumeroServi int null
, DernierNumeroServi int null
, DatePremierNumeroServi datetime null
, DateDernierNumeroServi datetime null
, Fidelite nvarchar(8) null
, ModeExpedition nvarchar(8) null
, CodeExpID int null
, SuspensionAbo bit not null default(0)
, MotifFinAbo nvarchar(8) null
, MotifFinAboID int null
, MotifProlongation nvarchar(8) null
, MotifProlonAboID int null
, AnnulationDate datetime null
, ReaboDate datetime null
, OrigineAbo nvarchar(20) null
, ProvenanceID int null
, ModeSouscription nvarchar(20) null
, CampagneID int null
, ModePaiement nvarchar(20) null
, CodeReglementID int null
, ValiditeCB datetime null
, ContratID int not null identity (1,1)
, CTRNUMGCP nvarchar(18) null	-- Champ technique pour le calcul de StatutAbo
, CTRNUMFIN nvarchar(18) null	-- Champ technique pour le calcul de StatutAbo
, DateFinParutions datetime null	-- Champ technique pour le calcul de StatutAbo
, ActionID int null
, Rejet bit not null default(0)
, ImportID int null
)


insert #T_Lignes_SDVP_Contrats
(
ProfilID
, CTRCODSOC
, CTRCODTAR
, CTRCODOFF
, CTRCODPRV
, CTRCODTIT
, CTROPTOFF
, CTRNUMABO
, CTRNUMCTR
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, ExAboSouscrNb
, NbreSouscr
, RemiseAbo
, MontantAbo
, Devise
, PremierNumeroServi
, DernierNumeroServi
, DatePremierNumeroServi
, DateDernierNumeroServi
, Fidelite
, ModeExpedition
, SuspensionAbo
, MotifFinAbo
, MotifProlongation
, AnnulationDate
, ReaboDate
, OrigineAbo
, ModeSouscription
, ModePaiement
, ValiditeCB
, CTRNUMGCP
, CTRNUMFIN
, DateFinParutions
, ActionID
, ImportID
)
select
null as ProfilID
, a.CTRCODSOC
, a.CTRCODTAR
, a.CTRCODOFF
, a.CTRCODPRV
, a.CTRCODTIT
, a.CTROPTOFF
, a.CTRNUMABO
, a.CTRNUMCTR
, a.CRTDATDLL as SouscriptionAboDate
, null as DebutAboDate
, a.CTRDATANN as FinAboDate
, cast(a.CTRNBRABO as int) as ExAboSouscrNb
, cast(a.CTRNBRSOU as int) as NbreSouscr
, cast(a.CTRREMABO as decimal(10,2)) as RemiseAbo
, null as MontantAbo -- sera récupéré de RefTarifs
, N'EUR' as Devise
, a.CTRNUMDEB as PremierNumeroServi
, a.CTRNUMDNS DernierNumeroServi
, a.CTRDATPNO DatePremierNumeroServi
, a.CTRDATDNP DateDernierNumeroServi
, a.CTRFID Fidelite
, null as ModeExpedition -- sera récupéré de ModeExpedition
, 0 as SuspensionAbo -- sera récupéré des suspensions en cours
, a.CTRMOTFIN as MotifFinAbo
, a.CTRMOTPRO as MotifProlongation
, a.CTRDATANN as AnnulationDate
, a.CTRDATREA as ReaboDate
, a.CTRCODPRV as OrigineAbo
, a.CTRCODCAM as ModeSouscription
, null as ModePaiement -- sera récupéré de RefOffOptTit
, null as ValiditeCB -- sera récupéré de RefCBValidites
, a.CTRNUMGCP
, a.CTRNUMFIN
, null as DateFinParutions -- sera calculée selon la règle à partir de SDVP_RefParutions
, cast(a.ActionID as int) as ActionID
, a.ImportID
from import.SDVP_Contrats a
where a.FichierTS=@FichierTS
and a.LigneStatut=0

create index idx_01_T_Lignes_SDVP_Contrats on #T_Lignes_SDVP_Contrats (CTRCODSOC,CTRCODTAR,CTRCODOFF,CTRCODTIT,CTROPTOFF)
create index idx_02_T_Lignes_SDVP_Contrats on #T_Lignes_SDVP_Contrats (CTRCODSOC,CTRCODTIT)

-- Retirer les "Erreurs opératrice"
delete a
from #T_Lignes_SDVP_Contrats a
inner join ref.MotifFinAbo b 
on a.CTRCODSOC=b.CodeSociete
and a.CTRCODTIT=b.CodeTitre
and a.MotifFinAbo=b.CodeMotif
where b.Libelle=N'ERREUR OPERATRICE'

update a
set ModePaiement=b.OTICODRGT
from #T_Lignes_SDVP_Contrats a inner join import.SDVP_RefOffOptTit b
on a.CTRCODSOC=b.OTICODSOC
and a.CTRCODTAR=b.OTICODTAR
and a.CTRCODOFF=b.OTICODOFF
and a.CTRCODTIT=b.OTITITOPT
and a.CTROPTOFF=b.OTIOPT 

update a
set CodeReglementID=c.CodeReglementID
from #T_Lignes_SDVP_Contrats a
inner join ref.CodeReglement b 
on a.ModePaiement=b.CodeRgt
inner join ref.CodeReglementCompress c
on b.Libelle=c.Libelle

update a
set CampagneID=b.CampagneID
from #T_Lignes_SDVP_Contrats a inner join ref.Campagnes b 
on a.CTRCODSOC=b.CodeSociete
and a.ModeSouscription=b.CodeCampagne

update a
set DebutAboDate=cast(b.PARDAT as datetime)
from #T_Lignes_SDVP_Contrats a inner join import.SDVP_RefParutions b 
on a.CTRCODSOC=b.PARCODSOC
and a.CTRCODTIT=b.PARCODTIT
and a.PremierNumeroServi=b.PARNUMPAR

update #T_Lignes_SDVP_Contrats
set DernierNumeroServi=null
where DernierNumeroServi=0

update a
set DateFinParutions=cast(b.PARDAT as datetime)
from #T_Lignes_SDVP_Contrats a inner join import.SDVP_RefParutions b 
on a.CTRCODSOC=b.PARCODSOC
and a.CTRCODTIT=b.PARCODTIT
and coalesce(a.DernierNumeroServi,a.CTRNUMGCP,a.CTRNUMFIN)=b.PARNUMPAR

update #T_Lignes_SDVP_Contrats
set FinAboDate=coalesce(FinAboDate,DateFinParutions)


update a
set MotifFinAboID=d.MotFinID
from #T_Lignes_SDVP_Contrats a
inner join ref.MotifFinAbo b 
on a.CTRCODSOC=b.CodeSociete
and a.CTRCODTIT=b.CodeTitre
and a.MotifFinAbo=b.CodeMotif
inner join ref.MotifFinAboTransco c on b.Libelle=c.LibelleOrig
inner join ref.MotifFinAboCompress d on c.MotFinID=d.MotFinID

update a
set a.MotifProlongation=c.MotifProlonID
from #T_Lignes_SDVP_Contrats a 
inner join ref.MotifProlongationAbo b 
on a.CTRCODSOC=b.CodeSociete
and a.CTRCODTIT=b.CodeTitre
and a.MotifProlongation=b.CodeMotif
inner join ref.MotifProlonCompress c on b.Libelle=c.Libelle


update a
set ProvenanceID=b.ProvenanceID
from #T_Lignes_SDVP_Contrats a inner join ref.Provenances b
on left(a.OrigineAbo,LEN(b.CodeProvenance))=b.CodeProvenance

update a
set ProvenanceID=b.ProvenanceID
from #T_Lignes_SDVP_Contrats a inner join ref.Provenances b
on b.CodeProvenance=N'AUT' -- à ceux qui n'ont pas de correspondance, on attribue le code "AUTRES"
where a.ProvenanceID is null

update #T_Lignes_SDVP_Contrats
set ModeExpedition=r1.EXPMODEXP
from #T_Lignes_SDVP_Contrats a inner join 
(select RANK() over (partition by c.EXPCODSOC,c.EXPCODTIT,c.EXPNUMABO,c.EXPNUMCTR order by cast(c.EXPDATFIN as datetime) desc,newid()) as N1
, c.EXPCODSOC,c.EXPCODTIT,c.EXPNUMABO,c.EXPNUMCTR,c.EXPMODEXP from dbo.ModeExpedition c
) as r1
on a.CTRCODSOC=r1.EXPCODSOC
and a.CTRCODTIT=r1.EXPCODTIT
and a.CTRNUMABO=r1.EXPNUMABO
and a.CTRNUMCTR=r1.EXPNUMCTR
where N1=1

update a
set CodeExpID=c.CodeExpID
from #T_Lignes_SDVP_Contrats a inner join ref.CodeExpedition b 
on a.CTRCODSOC=b.CodeSociete
and a.CTRCODTIT=b.CodeTitre
and a.ModeExpedition=b.CodeExp
inner join ref.CodeExpCompress c
on case when b.Libelle=N'SOUS-FILM' then N'SOUS FILM' else b.Libelle end = c.Libelle

update a
set CatalogueAbosID=b.CatalogueAbosID
from #T_Lignes_SDVP_Contrats a inner join ref.CatalogueAbonnements b
on a.CTRCODSOC=b.CodeSociete
and a.CTRCODTAR=b.CodeTarif
and a.CTRCODOFF=b.CodeOffre
and a.CTRCODTIT=b.CodeTitreOption
and a.CTROPTOFF=b.CodeOption


delete #T_Lignes_SDVP_Contrats where CatalogueAbosID is null

-- --------- Calcul du Montant d'abonnement ----------

update a
set MontantAbo=(b.MontantAbo*a.ExAboSouscrNb)*(1-(cast(a.RemiseAbo as float)/100))
from #T_Lignes_SDVP_Contrats a inner join ref.CatalogueAbonnements b on a.CatalogueAbosID=b.CatalogueAbosID


/*
-- Chercher le tarif dans import.SDVP_RefTarifs
-- Modif PHTO sur les remises
update a
set MontantAbo=
case when c.TARDUR=N'999' then (cast(c.TARMNTTTC as numeric(10,2))*a.ExAboSouscrNb) * (1- (cast(isnull(a.RemiseAbo, 0.0) as float)/100))
	when c.TARDUR<>N'999' and abs((cast(a.NbreSouscr as float) / cast(coalesce(c.TARDUR,N'1') as float) )-cast(case when (cast(a.NbreSouscr as int) / cast(coalesce(c.TARDUR,N'1') as int))=0 then 1 else cast(a.NbreSouscr as int) / cast(coalesce(c.TARDUR,N'1') as int) end as float))<0.2 then
((cast(c.TARMNTTTC as numeric(10,2))*a.ExAboSouscrNb) * (case when (cast(cast(a.NbreSouscr as float) / cast(coalesce(c.TARDUR,N'1') as float)  as int))=0 then 1 else cast(cast(a.NbreSouscr as float) / cast(coalesce(c.TARDUR,N'1') as float)  as int) end)
	* (1- (cast(isnull(a.RemiseAbo, 0.0) as float)/100)))
	else null
end
from #T_Lignes_SDVP_Contrats a inner join import.SDVP_RefOffOptTit b
on a.CTRCODSOC=b.OTICODSOC
and a.CTRCODTAR=b.OTICODTAR
and a.CTRCODOFF=b.OTICODOFF
and a.CTRCODTIT=b.OTITITOPT
and a.CTROPTOFF=b.OTIOPT
inner join import.SDVP_RefTarifs c 
on b.OTISOCOPT=c.TARCODSOC
and b.OTITITOPT=c.TARCODTIT
and b.OTICODTAR=c.TARCODTAR
where a.DebutAboDate between cast(c.TARDATDEB as datetime) and cast(c.TARDATFIN as datetime)

-- Mais on peut avoir des doublons en petit nombre dans import.SDVP_RefTarifs
-- On va donc dédoublonner des tarifs et corriger les lignes affectées

-- Lignes affectées 

if OBJECT_ID('tempdb..#T_ContratID') is not null
	drop table #T_ContratID
	
create table #T_ContratID (N int not null, ContratID int not null)

insert #T_ContratID (N, ContratID)
select COUNT(*) as N,ContratID
from #T_Lignes_SDVP_Contrats a inner join import.SDVP_RefOffOptTit b
on a.CTRCODSOC=b.OTICODSOC
and a.CTRCODTAR=b.OTICODTAR
and a.CTRCODOFF=b.OTICODOFF
and a.CTRCODTIT=b.OTITITOPT
and a.CTROPTOFF=b.OTIOPT
inner join import.SDVP_RefTarifs c 
on b.OTISOCOPT=c.TARCODSOC
and b.OTITITOPT=c.TARCODTIT
and b.OTICODTAR=c.TARCODTAR
where a.DebutAboDate between cast(c.TARDATDEB as datetime) and cast(c.TARDATFIN as datetime)
group by ContratID
having COUNT(*)>1

create index idx_01_ContratID on #T_ContratID (ContratID)
create index idx_01_ContratID on #T_Lignes_SDVP_Contrats (ContratID)

if OBJECT_ID('tempdb..#T_ImportID') is not null
	drop table #T_ImportID

create table #T_ImportID (ImportID int not null)

insert #T_ImportID (ImportID)
select distinct c.ImportID
from brut.Contrats_Abos a inner join import.SDVP_RefOffOptTit b
on a.CTRCODSOC=b.OTICODSOC
and a.CTRCODTAR=b.OTICODTAR
and a.CTRCODOFF=b.OTICODOFF
and a.CTRCODTIT=b.OTITITOPT
and a.CTROPTOFF=b.OTIOPT
inner join import.SDVP_RefTarifs c 
on b.OTISOCOPT=c.TARCODSOC
and b.OTITITOPT=c.TARCODTIT
and b.OTICODTAR=c.TARCODTAR
inner join #T_ContratID d on a.ContratID=d.ContratID
where a.DebutAboDate between cast(c.TARDATDEB as datetime) and cast(c.TARDATFIN as datetime)

if OBJECT_ID('tempdb..#T_SDVP_RefTarifs_EnDouble') is not null
	drop table #T_SDVP_RefTarifs_EnDouble

select a.* into #T_SDVP_RefTarifs_EnDouble from import.SDVP_RefTarifs a inner join #T_ImportID b on a.ImportID=b.ImportID

if OBJECT_ID('tempdb..#T_SDVP_RefTarifs_Uniques') is not null
	drop table #T_SDVP_RefTarifs_Uniques
	
-- Dédoublonner les tarifs

select c.* into #T_SDVP_RefTarifs_Uniques from #T_SDVP_RefTarifs_EnDouble c
inner join (
select RANK() over (partition by d.TARCODSOC,d.TARCODTAR,d.TARCODTIT order by cast(TARMNTTTC as numeric(10,2)) asc, newid()) as N1
, d.TARCODSOC
, d.TARCODTAR
, d.TARCODTIT
, d.TARDATDEB
, d.TARDATFIN
, d.TARJOUSER
, d.TARLIBTAR
from import.SDVP_RefTarifs d) as r1 on 
c.TARCODSOC=r1.TARCODSOC
and c.TARCODTAR=r1.TARCODTAR
and c.TARCODTIT=r1.TARCODTIT
and c.TARDATDEB=r1.TARDATDEB
and c.TARDATFIN=r1.TARDATFIN
and c.TARJOUSER=r1.TARJOUSER
where r1.N1=1

-- Mettre à jour le montant dans les lignes affectées

create index idx_01_RefTarifs_Uniques on #T_SDVP_RefTarifs_Uniques(TARCODSOC,TARCODTIT,TARCODTAR)

-- Modif PHTO sur les remises
-- Modif AVE : application de la règle sur le ratio CTRNBRSOU / TARDUR

update a
set MontantAbo=
case when c.TARDUR=N'999' then (cast(c.TARMNTTTC as numeric(10,2))*a.ExAboSouscrNb) * (1- (cast(isnull(a.RemiseAbo, 0.0) as float)/100))
	when c.TARDUR<>N'999' and abs((cast(a.NbreSouscr as float) / cast(coalesce(c.TARDUR,N'1') as float) )-cast(case when (cast(a.NbreSouscr as int) / cast(coalesce(c.TARDUR,N'1') as int))=0 then 1 else cast(a.NbreSouscr as int) / cast(coalesce(c.TARDUR,N'1') as int) end as float))<0.2 then
((cast(c.TARMNTTTC as numeric(10,2))*a.ExAboSouscrNb) * (case when (cast(cast(a.NbreSouscr as float) / cast(coalesce(c.TARDUR,N'1') as float)  as int))=0 then 1 else cast(cast(a.NbreSouscr as float) / cast(coalesce(c.TARDUR,N'1') as float)  as int) end)
	* (1- (cast(isnull(a.RemiseAbo, 0.0) as float)/100)))
	else null
end
from #T_Lignes_SDVP_Contrats a inner join import.SDVP_RefOffOptTit b
on a.CTRCODSOC=b.OTICODSOC
and a.CTRCODTAR=b.OTICODTAR
and a.CTRCODOFF=b.OTICODOFF
and a.CTRCODTIT=b.OTITITOPT
and a.CTROPTOFF=b.OTIOPT
inner join #T_SDVP_RefTarifs_Uniques c 
on b.OTISOCOPT=c.TARCODSOC
and b.OTITITOPT=c.TARCODTIT
and b.OTICODTAR=c.TARCODTAR
inner join #T_ContratID d on a.ContratID=d.ContratID
where a.DebutAboDate between cast(c.TARDATDEB as datetime) and cast(c.TARDATFIN as datetime)

drop index idx_01_ContratID on #T_Lignes_SDVP_Contrats

if OBJECT_ID('tempdb..#T_ContratID') is not null
	drop table #T_ContratID

if OBJECT_ID('tempdb..#T_ImportID') is not null
	drop table #T_ImportID

if OBJECT_ID('tempdb..#T_SDVP_RefTarifs_EnDouble') is not null
	drop table #T_SDVP_RefTarifs_EnDouble
	
if OBJECT_ID('tempdb..#T_SDVP_RefTarifs_Uniques') is not null
	drop table #T_SDVP_RefTarifs_Uniques

*/
-- --------- ----------

update a
set ValiditeCB=cast(b.DATE_FIN_VALIDITE as datetime)
from #T_Lignes_SDVP_Contrats a inner join dbo.RefCBValidites b
on a.CTRCODSOC=b.CODE_SOCIETE
and a.CTRCODTIT=b.CODE_TITRE
and a.CTRNUMABO=b.NUMERO_ABONNE
and a.CTRNUMCTR=b.NUMCTR


if OBJECT_ID('tempdb..#T_OriginalID') is not null
	drop table #T_OriginalID

create table #T_OriginalID 
(
OriginalID nvarchar(255) null
, CTRNUMABO nvarchar(18) null
, CTRCODSOC nvarchar(8) null
, ADRNUMINF nvarchar(18) null
, ProfilID int null
)

insert #T_OriginalID
(
OriginalID
, CTRNUMABO
, CTRCODSOC
, ADRNUMINF
, ProfilID
)
select distinct
b.CODE_EDITEUR+N'-'+b.ADRNUMABO+N'-'+b.ADRNUMINF+N'-'+b.ADRTYPADR as OriginalID
, a.CTRNUMABO
, a.CTRCODSOC
, b.ADRNUMINF
, null as ProfilID
from #T_Lignes_SDVP_Contrats a 
inner join import.SDVP_Adresses b 
on a.CTRNUMABO=b.ADRNUMABO 
and a.CTRCODSOC=b.CODE_EDITEUR
where b.LigneStatut=99
and b.ActionID<>N'3'

create index idx_01_T_OriginalID on #T_OriginalID (OriginalID)

update a
set ProfilID=b.ProfilID
from #T_OriginalID a inner join brut.Contacts b
on a.OriginalID=b.OriginalID
and b.SourceID=@SourceID

drop index idx_01_T_OriginalID on #T_OriginalID

create index idx_02_T_OriginalID on #T_OriginalID (CTRNUMABO, CTRCODSOC)
create index idx_03_T_Lignes_SDVP_Contrats on #T_Lignes_SDVP_Contrats (CTRNUMABO, CTRCODSOC)

update a
set ProfilID=b.ProfilID
from #T_Lignes_SDVP_Contrats a 
inner join 
(select RANK() over (partition by CTRNUMABO,CTRCODSOC order by cast(ADRNUMINF as int) asc,newid()) as N1 -- on prend le plus récent : ADRNUMINF va en descendant, 999 étant le plus ancien
, CTRNUMABO
, CTRCODSOC
, ProfilID
from #T_OriginalID )  as b 
on a.CTRNUMABO=b.CTRNUMABO 
and a.CTRCODSOC=b.CTRCODSOC
where N1=1
and b.ProfilID is not null

drop index idx_03_T_Lignes_SDVP_Contrats on #T_Lignes_SDVP_Contrats

delete #T_Lignes_SDVP_Contrats where ProfilID is null

-- Alimenter la table brut.Contrats_Abos

delete b 
from #T_Lignes_SDVP_Contrats a inner join brut.Contrats_Abos b
on a.CTRCODSOC=b.CTRCODSOC
and a.CTRCODTIT=b.CTRCODTIT
and a.CTRNUMABO=b.CTRNUMABO
and a.CTRNUMCTR=b.CTRNUMCTR
and b.SourceID=@SourceID -- SDVP
and a.ActionID=3 -- Suppression des lignes ActionID=3 

update b 
set 
ProfilID=a.ProfilID
, CTRCODTAR=a.CTRCODTAR
, CTRCODOFF=a.CTRCODOFF
, CTRCODPRV=a.CTRCODPRV
, CTRCODTIT=a.CTRCODTIT
, CTROPTOFF=a.CTROPTOFF
, CTRNUMABO=a.CTRNUMABO
, CTRNUMCTR=a.CTRNUMCTR
, CatalogueAbosID=a.CatalogueAbosID
, SouscriptionAboDate=a.SouscriptionAboDate
, DebutAboDate=a.DebutAboDate
, FinAboDate=a.FinAboDate
, ExAboSouscrNb=a.ExAboSouscrNb
, RemiseAbo=a.RemiseAbo
, MontantAbo=a.MontantAbo
, Devise=a.Devise
, PremierNumeroServi=a.PremierNumeroServi
, DernierNumeroServi=a.DernierNumeroServi
, DatePremierNumeroServi=a.DatePremierNumeroServi
, DateDernierNumeroServi=a.DateDernierNumeroServi
, Fidelite=a.Fidelite
, ModeExpedition=a.CodeExpID
, SuspensionAbo=a.SuspensionAbo
, MotifFinAbo=a.MotifFinAboID
, MotifProlongation=a.MotifProlonAboID
, AnnulationDate=a.AnnulationDate
, ReaboDate=a.ReaboDate
, OrigineAbo=a.ProvenanceID
, ModeSouscription=a.CampagneID
, ModePaiement=a.CodeReglementID
, ValiditeCB=a.ValiditeCB
, CTRNUMGCP=a.CTRNUMGCP
, CTRNUMFIN=a.CTRNUMFIN
, DateFinParutions=a.DateFinParutions
, ModifieTop=1 -- Pour prendre en compte les modifications
from #T_Lignes_SDVP_Contrats a inner join brut.Contrats_Abos b
on a.CTRCODSOC=b.CTRCODSOC
and a.CTRCODTIT=b.CTRCODTIT
and a.CTRNUMABO=b.CTRNUMABO
and a.CTRNUMCTR=b.CTRNUMCTR
and b.SourceID=@SourceID -- SDVP
and a.ActionID=1 -- Modification des lignes ActionID=1 si déjà insérées

insert brut.Contrats_Abos
(
ProfilID
, SourceID
, CTRCODSOC
, CTRCODTAR
, CTRCODOFF
, CTRCODPRV
, CTRCODTIT
, CTROPTOFF
, CTRNUMABO
, CTRNUMCTR
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, ExAboSouscrNb
, RemiseAbo
, MontantAbo
, Devise
, PremierNumeroServi
, DernierNumeroServi
, DatePremierNumeroServi
, DateDernierNumeroServi
, Fidelite
, ModeExpedition
, SuspensionAbo
, MotifFinAbo
, MotifProlongation
, AnnulationDate
, ReaboDate
, OrigineAbo
, ModeSouscription
, ModePaiement
, ValiditeCB
, CTRNUMGCP
, CTRNUMFIN
, DateFinParutions
)
select 
a.ProfilID
, @SourceID -- SDVP
, a.CTRCODSOC
, a.CTRCODTAR
, a.CTRCODOFF
, a.CTRCODPRV
, a.CTRCODTIT
, a.CTROPTOFF
, a.CTRNUMABO
, a.CTRNUMCTR
, a.CatalogueAbosID
, a.SouscriptionAboDate
, a.DebutAboDate
, a.FinAboDate
, a.ExAboSouscrNb
, a.RemiseAbo
, a.MontantAbo
, a.Devise
, a.PremierNumeroServi
, a.DernierNumeroServi
, a.DatePremierNumeroServi
, a.DateDernierNumeroServi
, a.Fidelite
, a.CodeExpID
, a.SuspensionAbo
, a.MotifFinAboID
, a.MotifProlonAboID
, a.AnnulationDate
, a.ReaboDate
, a.ProvenanceID
, a.CampagneID
, a.CodeReglementID
, a.ValiditeCB
, a.CTRNUMGCP
, a.CTRNUMFIN
, a.DateFinParutions
from #T_Lignes_SDVP_Contrats a left outer join brut.Contrats_Abos b
on a.CTRCODSOC=b.CTRCODSOC
and a.CTRCODTAR=b.CTRCODTAR
and a.CTRCODOFF=b.CTRCODOFF
and a.CTRCODTIT=b.CTRCODTIT
and a.CTROPTOFF=b.CTROPTOFF
and a.CTRNUMABO=b.CTRNUMABO
and a.CTRNUMCTR=b.CTRNUMCTR
and coalesce(a.SouscriptionAboDate,N'01-01-1900')=coalesce(b.SouscriptionAboDate,N'01-01-1900')
and a.DebutAboDate=b.DebutAboDate
and coalesce(a.FinAboDate,N'01-01-1900')=coalesce(b.FinAboDate,N'01-01-1900')
where a.CTRCODSOC is not null
and b.CTRCODSOC is null
and a.ActionID=1 -- Ajout
order by a.ProfilID,a.CTRCODTIT,cast(a.CTRNUMCTR as int)

update b 
set 
ProfilID=a.ProfilID
, CTRCODTAR=a.CTRCODTAR
, CTRCODOFF=a.CTRCODOFF
, CTRCODPRV=a.CTRCODPRV
, CTRCODTIT=a.CTRCODTIT
, CTROPTOFF=a.CTROPTOFF
, CTRNUMABO=a.CTRNUMABO
, CTRNUMCTR=a.CTRNUMCTR
, CatalogueAbosID=a.CatalogueAbosID
, SouscriptionAboDate=a.SouscriptionAboDate
, DebutAboDate=a.DebutAboDate
, FinAboDate=a.FinAboDate
, ExAboSouscrNb=a.ExAboSouscrNb
, RemiseAbo=a.RemiseAbo
, MontantAbo=a.MontantAbo
, Devise=a.Devise
, PremierNumeroServi=a.PremierNumeroServi
, DernierNumeroServi=a.DernierNumeroServi
, DatePremierNumeroServi=a.DatePremierNumeroServi
, DateDernierNumeroServi=a.DateDernierNumeroServi
, Fidelite=a.Fidelite
, ModeExpedition=a.CodeExpID
, SuspensionAbo=a.SuspensionAbo
, MotifFinAbo=a.MotifFinAboID
, MotifProlongation=a.MotifProlonAboID
, AnnulationDate=a.AnnulationDate
, ReaboDate=a.ReaboDate
, OrigineAbo=a.ProvenanceID
, ModeSouscription=a.CampagneID
, ModePaiement=a.CodeReglementID
, ValiditeCB=a.ValiditeCB
, CTRNUMGCP=a.CTRNUMGCP
, CTRNUMFIN=a.CTRNUMFIN
, DateFinParutions=a.DateFinParutions
, ModifieTop=1 -- Pour prendre en compte les modifications
from #T_Lignes_SDVP_Contrats a inner join brut.Contrats_Abos b
on a.CTRCODSOC=b.CTRCODSOC
and a.CTRCODTIT=b.CTRCODTIT
and a.CTRNUMABO=b.CTRNUMABO
and a.CTRNUMCTR=b.CTRNUMCTR
and b.SourceID=@SourceID -- SDVP
and a.ActionID=2 -- Modification
-- prendre la dernière modification s'il y en a plusieurs
inner join (
select RANK() over (partition by  
a.CTRCODSOC
, a.CTRCODTIT
, a.CTRNUMABO
, a.CTRNUMCTR
order by a.ImportID desc) as N1
, a.CTRCODSOC
, a.CTRCODTIT
, a.CTRNUMABO
, a.CTRNUMCTR
, a.ImportID
from #T_Lignes_SDVP_Contrats a
where a.ActionID=2 ) as r1 on a.ImportID=r1.ImportID
where r1.N1=1

-- On n'a plus besoin de #T_Lignes_SDVP_Contrats, le reste se fait à partir de brut.Contrats_Abos

if OBJECT_ID('tempdb..#T_Lignes_SDVP_Contrats') is not null
	drop table #T_Lignes_SDVP_Contrats

-- Maintenant, il faudra fabriquer les lignes dbo.Abonnements à partir des lignes de brut.Contrats_Abos
-- On crée une table temporaire avec les lignes nouvellement insérées dans brut.Contrats_Abos

if OBJECT_ID('tempdb..#T_Brut_Contrats') is not null
	drop table #T_Brut_Contrats

create table #T_Brut_Contrats 
(
ContratID int not null
, MasterAboID int null -- = AbonnementID de abo.Abonnements
, ProfilID int not null
, CTRCODSOC nvarchar(8) not null
, CTRCODTAR nvarchar(8) not null
, CTRCODOFF nvarchar(8) not null
, CTRCODPRV nvarchar(32) not null
, CTRCODTIT nvarchar(8) not null
, CTROPTOFF nvarchar(8) not null
, CTRNUMABO nvarchar(18) not null
, CTRNUMCTR nvarchar(8) not null
, CatalogueAbosID int null
, SouscriptionAboDate datetime null
, DebutAboDate datetime null
, FinAboDate datetime null
, ExAboSouscrNb int not null default(0)
, RemiseAbo decimal(10,2) null
, MontantAbo decimal(10,2) null 
, Devise nvarchar(16) null
, PremierNumeroServi int null
, DernierNumeroServi int null
, DatePremierNumeroServi datetime null
, DateDernierNumeroServi datetime null
, Fidelite nvarchar(8) null
, ModeExpedition int null
, SuspensionAbo bit not null default(0)
, MotifFinAbo int null
, MotifProlongation int null
, AnnulationDate datetime null
, ReaboDate datetime null
, OrigineAbo int null
, ModeSouscription int null
, ModePaiement int null
, ValiditeCB datetime null
, ModifieTop bit not null 
, SupprimeTop bit not null 
, CTRNUMGCP nvarchar(18) null	-- Champ technique pour le calcul de StatutAbo
, CTRNUMFIN nvarchar(18) null	-- Champ technique pour le calcul de StatutAbo
, DateFinParutions datetime null	-- Champ technique pour le calcul de StatutAbo
)

insert #T_Brut_Contrats
(
ContratID
, MasterAboID
, ProfilID
, CTRCODSOC
, CTRCODTAR
, CTRCODOFF
, CTRCODPRV
, CTRCODTIT
, CTROPTOFF
, CTRNUMABO
, CTRNUMCTR
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, ExAboSouscrNb
, RemiseAbo
, MontantAbo
, Devise
, PremierNumeroServi
, DernierNumeroServi
, DatePremierNumeroServi
, DateDernierNumeroServi
, Fidelite
, ModeExpedition
, SuspensionAbo
, MotifFinAbo
, MotifProlongation
, AnnulationDate
, ReaboDate
, OrigineAbo
, ModeSouscription
, ModePaiement
, ValiditeCB
, ModifieTop
, SupprimeTop
, CTRNUMGCP
, CTRNUMFIN
, DateFinParutions
)
select 
ContratID
, MasterAboID
, ProfilID
, CTRCODSOC
, CTRCODTAR
, CTRCODOFF
, CTRCODPRV
, CTRCODTIT
, CTROPTOFF
, CTRNUMABO
, CTRNUMCTR
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, ExAboSouscrNb
, RemiseAbo
, MontantAbo
, Devise
, PremierNumeroServi
, DernierNumeroServi
, DatePremierNumeroServi
, DateDernierNumeroServi
, Fidelite
, ModeExpedition
, SuspensionAbo
, MotifFinAbo
, MotifProlongation
, AnnulationDate
, ReaboDate
, OrigineAbo
, ModeSouscription
, ModePaiement
, ValiditeCB
, ModifieTop
, SupprimeTop
, CTRNUMGCP
, CTRNUMFIN
, DateFinParutions
from brut.Contrats_Abos
where ModifieTop=1 -- Lignes nouvellement insérées ou modifiées
and SourceID=@SourceID -- Données SDVP

create index ind_01_T_Brut_Contrats on #T_Brut_Contrats (ProfilID, CTRCODSOC, CTRCODTIT)

-- Une table temporaire avec les lignes de brut.Contrats_Abos pour les agréger en un seul abonnement
-- S'aliment en deux temps : avec les nouvelles lignes, ensuite les anciennes qui leur correspondent

if OBJECT_ID('tempdb..#T_Abonnements_Brut') is not null
	drop table #T_Abonnements_Brut
	
create table #T_Abonnements_Brut
(
ContratID int null
, MasterAboID int null
, ProfilID int null				-- Champ de regroupement
, CTRCODSOC nvarchar(8) null	-- Champ de regroupement
, CTRCODTIT nvarchar(8) null	-- Champ de regroupement
, CTRNUMCTR int null -- cast as int, c'est important
, CTRCODOFF nvarchar(8) not null -- Champ de regroupement
, CTRCODPRV nvarchar(32) not null -- Champ de regroupement
, CTROPTOFF nvarchar(8) not null -- Champ de regroupement
, CatalogueAbosID int null
, SouscriptionAboDate datetime null
, DebutAboDate datetime null
, FinAboDate datetime null
, ExAboSouscrNb int null
, RemiseAbo decimal(10,2) null
, MontantAbo decimal(10,2) null
, Devise nvarchar(8) null
, PremierNumeroServi int null
, DernierNumeroServi int null
, DatePremierNumeroServi datetime null
, DateDernierNumeroServi datetime null
, Fidelite nvarchar(8) null
, ModeExpedition int null
, SuspensionAbo bit null
, MotifFinAbo int null
, MotifProlongation int null
, AnnulationDate datetime null
, ReaboDate datetime null
, OrigineAbo int null -- dernière ou première ?
, ModeSouscription int null
, ModePaiement int null
, ValiditeCB datetime null
, ModifieTop bit null
, SupprimeTop bit null
, CTRNUMGCP nvarchar(18) null	-- Champ technique pour le calcul de StatutAbo
, CTRNUMFIN nvarchar(18) null	-- Champ technique pour le calcul de StatutAbo
, DateFinParutions datetime null	-- Champ technique pour le calcul de StatutAbo
, NumAbonne int null
, NomAbo nvarchar(255) null
)

insert #T_Abonnements_Brut
(
ContratID
, MasterAboID
, ProfilID
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CTRNUMCTR
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, ExAboSouscrNb
, RemiseAbo
, MontantAbo
, Devise
, PremierNumeroServi
, DernierNumeroServi
, DatePremierNumeroServi
, DateDernierNumeroServi
, Fidelite
, ModeExpedition
, SuspensionAbo
, MotifFinAbo
, MotifProlongation
, AnnulationDate
, ReaboDate
, OrigineAbo
, ModeSouscription
, ModePaiement
, ValiditeCB
, ModifieTop
, SupprimeTop
, CTRNUMGCP
, CTRNUMFIN
, DateFinParutions
, NumAbonne
, NomAbo
)
select
 a.ContratID
, a.MasterAboID
, a.ProfilID
, a.CTRCODSOC
, a.CTRCODTIT
, a.CTRCODOFF
, a.CTRCODPRV
, a.CTROPTOFF
, cast(a.CTRNUMCTR as int)
, a.CatalogueAbosID
, a.SouscriptionAboDate
, a.DebutAboDate
, a.FinAboDate
, a.ExAboSouscrNb
, a.RemiseAbo
, a.MontantAbo
, a.Devise
, a.PremierNumeroServi
, a.DernierNumeroServi
, a.DatePremierNumeroServi
, a.DateDernierNumeroServi
, a.Fidelite
, a.ModeExpedition
, a.SuspensionAbo
, a.MotifFinAbo
, a.MotifProlongation
, a.AnnulationDate
, a.ReaboDate
, a.OrigineAbo
, a.ModeSouscription
, a.ModePaiement
, a.ValiditeCB
, a.ModifieTop
, a.SupprimeTop
, a.CTRNUMGCP
, a.CTRNUMFIN
, a.DateFinParutions
, cast(a.CTRNUMABO as int)
, null as NomAbo
from #T_Brut_Contrats a

-- On trouve le dernier profil de chaque abonnement

if OBJECT_ID('tempdb..#T_TrouverProfil') is not null
	drop table #T_TrouverProfil

create table #T_TrouverProfil
(
CTRNUMABO int null
, CTRCODSOC nvarchar(8) null
, CTRCODTIT nvarchar(8) null
, CTRCODOFF nvarchar(8) null
, CTRCODPRV nvarchar(32) null
, CTROPTOFF nvarchar(8) null
, CTRNUMCTR_MAX int null
, ProfilID int null
)

insert #T_TrouverProfil
(
CTRNUMABO
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CTRNUMCTR_MAX
)
select NumAbonne
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, max(CTRNUMCTR)
from #T_Abonnements_Brut
group by NumAbonne
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF

create index idx01_T_Abonnements_Brut on #T_Abonnements_Brut (NumAbonne
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CTRNUMCTR)

create index idx01_T_TrouverProfil on #T_TrouverProfil (CTRNUMABO
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CTRNUMCTR_MAX)

update a
set ProfilID=b.ProfilID
from #T_TrouverProfil a 
inner join #T_Abonnements_Brut b 
on a.CTRCODSOC=b.CTRCODSOC
and a.CTRNUMABO=b.NumAbonne
and a.CTRCODTIT=b.CTRCODTIT
and a.CTRCODOFF=b.CTRCODOFF
and a.CTRCODPRV=b.CTRCODPRV
and a.CTROPTOFF=b.CTROPTOFF
and a.CTRNUMCTR_MAX=b.CTRNUMCTR

update b
set ProfilID=b.ProfilID
from #T_TrouverProfil a 
inner join #T_Abonnements_Brut b 
on a.CTRCODSOC=b.CTRCODSOC
and a.CTRNUMABO=b.NumAbonne
and a.CTRCODTIT=b.CTRCODTIT
and a.CTRCODOFF=b.CTRCODOFF
and a.CTRCODPRV=b.CTRCODPRV
and a.CTROPTOFF=b.CTROPTOFF
where a.ProfilID<>b.ProfilID

if OBJECT_ID('tempdb..#T_TrouverProfil') is not null
	drop table #T_TrouverProfil

if OBJECT_ID('tempdb..#T_TrouverAncLignes') is not null
	drop table #T_TrouverAncLignes

create table #T_TrouverAncLignes
(
CTRNUMABO int null
, CTRCODSOC nvarchar(8) null
, CTRCODTIT nvarchar(8) null
, CTRCODOFF nvarchar(8) null
, CTRCODPRV nvarchar(32) null
, CTROPTOFF nvarchar(8) null
, ProfilID int null
)

insert #T_TrouverAncLignes 
(
CTRNUMABO
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, ProfilID
)
select distinct CTRNUMABO
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, ProfilID
from #T_Brut_Contrats

insert #T_Abonnements_Brut
(
ContratID
, MasterAboID
, ProfilID
, CTRCODSOC
, CTRCODTIT
, CTRNUMCTR
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, ExAboSouscrNb
, RemiseAbo
, MontantAbo
, Devise
, PremierNumeroServi
, DernierNumeroServi
, DatePremierNumeroServi
, DateDernierNumeroServi
, Fidelite
, ModeExpedition
, SuspensionAbo
, MotifFinAbo
, MotifProlongation
, AnnulationDate
, ReaboDate
, OrigineAbo
, ModeSouscription
, ModePaiement
, ValiditeCB
, ModifieTop
, SupprimeTop
, CTRNUMGCP
, CTRNUMFIN
, DateFinParutions
, NumAbonne
, NomAbo
)
select
 a.ContratID
, a.MasterAboID
, b.ProfilID -- Si le ProfilID a changé, il est remplacé par le nouveau dans toutes les lignes de l'abonnement, nouvelles et anciennes
, a.CTRCODSOC
, a.CTRCODTIT
, cast(a.CTRNUMCTR as int)
, a.CTRCODOFF
, a.CTRCODPRV
, a.CTROPTOFF
, a.CatalogueAbosID
, a.SouscriptionAboDate
, a.DebutAboDate
, a.FinAboDate
, a.ExAboSouscrNb
, a.RemiseAbo
, a.MontantAbo
, a.Devise
, a.PremierNumeroServi
, a.DernierNumeroServi
, a.DatePremierNumeroServi
, a.DateDernierNumeroServi
, a.Fidelite
, a.ModeExpedition
, a.SuspensionAbo
, a.MotifFinAbo
, a.MotifProlongation
, a.AnnulationDate
, a.ReaboDate
, a.OrigineAbo
, a.ModeSouscription
, a.ModePaiement
, a.ValiditeCB
, a.ModifieTop
, a.SupprimeTop
, a.CTRNUMGCP
, a.CTRNUMFIN
, a.DateFinParutions
, cast(a.CTRNUMABO as int)
, null as NomAbo
from  brut.Contrats_Abos a inner join #T_TrouverAncLignes b
on cast(a.CTRNUMABO as int)=b.CTRNUMABO
-- L'abonnement est le sextet CTRCODSOC, CTRNUMABO, CTRCODTIT, CTRCODOFF, CTRCODPRV, CTROPTOFF et il peut changer de ProfilID
and a.CTRCODSOC=b.CTRCODSOC
and a.CTRCODTIT=b.CTRCODTIT
and a.CTRCODOFF=b.CTRCODOFF
and a.CTRCODPRV=b.CTRCODPRV
and a.CTROPTOFF=b.CTROPTOFF
and a.ModifieTop=0 -- les anciennes lignes qui appartiennent aux mêmes abonnements que les nouvelles

-- A partir d'ici, on est sûr que ProfilID = (CTRNUMABO,CTRCODSOC), et ProfilID+CTRCODSOC+CTRCODTIT+CTRCODOFF+CTRCODPRV+CTROPTOFF=1 Abonnement


if OBJECT_ID('tempdb..#T_TrouverAncLignes') is not null
	drop table #T_TrouverAncLignes
	

create index ind_01_T_Abonnements_Brut on #T_Abonnements_Brut (ProfilID)
create index ind_02_T_Abonnements_Brut on #T_Abonnements_Brut (CatalogueAbosID)
create index ind_03_T_Abonnements_Brut on #T_Abonnements_Brut (ProfilID, CTRCODSOC, CTRCODTIT,CTRCODOFF,CTRCODPRV,CTROPTOFF)


update a
set NomAbo=b.OffreAbo+N' '+b.OptionOffreAbo
from #T_Abonnements_Brut a inner join ref.CatalogueAbonnements b on a.CatalogueAbosID=b.CatalogueAbosID

-- On n'aura plus besoin de la table #T_Brut_Contrats

if OBJECT_ID('tempdb..#T_Brut_Contrats') is not null
	drop table #T_Brut_Contrats
	
-- C'est à partir d'abonnements brut que nous allons déterminer les fusions et coupures
-- dans une autre table temporaire : #T_Abo_Fusion_Coupure

if OBJECT_ID('tempdb..#T_Abo_Fusion_Coupure') is not null
	drop table #T_Abo_Fusion_Coupure

create table #T_Abo_Fusion_Coupure
(
ContratID int not null
, MasterAboID int null
, ProfilID int null				-- Champ de regroupement
, CTRCODSOC nvarchar(8) null	-- Champ de regroupement
, CTRCODTIT nvarchar(8) null	-- Champ de regroupement
, CTRNUMCTR int null -- cast as int, c'est important
, CTRCODOFF nvarchar(8) not null -- Champ de regroupement
, CTRCODPRV nvarchar(32) not null -- Champ de regroupement
, CTROPTOFF nvarchar(8) not null -- Champ de regroupement
, CatalogueAbosID int null
, DebutAboDate datetime null
, FinAboDate datetime null
, SeraMasterOuPas int null -- est-ce que ce contrat sera Master ou non
, NOrder int null
)

insert #T_Abo_Fusion_Coupure
(
ContratID
, MasterAboID
, ProfilID
, CTRCODSOC
, CTRCODTIT
, CTRNUMCTR
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CatalogueAbosID
, DebutAboDate
, FinAboDate
, NOrder
)
select
ContratID
, MasterAboID
, ProfilID
, CTRCODSOC
, CTRCODTIT
, CTRNUMCTR
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CatalogueAbosID
, DebutAboDate
, FinAboDate
, RANK() over (partition by ProfilID,CTRCODTIT order by CTRNUMCTR) as NOrder
from #T_Abonnements_Brut
order by ProfilID,CTRCODTIT,CTRNUMCTR

--Abonents W1 with CTRCODOFF = NP1 and CTROPTOFF in (18 , 2) merge to one
UPDATE a
SET CTROPTOFF = lastCTRoptOFF
FROM #T_Abo_Fusion_Coupure a
	INNER JOIN (SELECT *, row_number() over (PARTITION BY MasterAboID
	,ProfilID
	,CTRCODSOC
	,CTRCODTIT
	,CTRCODOFF
	, CTRCODPRV order by norder desc) i, CTRoptOFF lastCTRoptOFF
		FROM #T_Abo_Fusion_Coupure) x ON a.MasterAboID = x.MasterAboID AND a.ProfilID = x.ProfilID AND a.CTRCODTIT = x.CTRCODTIT AND a.CTRCODPRV = x.CTRCODPRV
WHERE
x.i = 1
and a.CTRCODTIT=N'W1'
AND a.CTRCODOFF = N'NP1'
AND a.CTROPTOFF IN (N'2',N'18')

/*
update a
set MasterAboID=r1.ContratID from #T_Abo_Fusion_Coupure a inner join (
select min(ContratID) as ContratID,ProfilID,CTRCODTIT from #T_Abo_Fusion_Coupure group by ProfilID,CTRCODTIT
) as r1 on a.ContratID=r1.ContratID
where a.MasterAboID is null 
*/

-- on prend directement les lignes avec NOrder=1, qui correspond au min(CTRNUMCTR) et qui doit correspondre au min(ContratID) - normalement, mais pas toujours

update #T_Abo_Fusion_Coupure set MasterAboID=ContratID where NOrder=1

declare @r4 int
declare @r5 int
declare @r6 int
set @r4=1
set @r5=1
set @r6=1

while not (@r4=0 and @r5=0 and @r6=0)
begin

update a 
set MasterAboID=b.MasterAboID
from #T_Abo_Fusion_Coupure a inner join #T_Abo_Fusion_Coupure b 
on a.ProfilID=b.ProfilID
and a.CTRCODTIT=b.CTRCODTIT
and a.CTRCODOFF=b.CTRCODOFF
and a.CTRCODPRV=b.CTRCODPRV
and a.CTROPTOFF=b.CTROPTOFF
and a.NOrder=b.NOrder+1
where a.MasterAboID is null
and b.MasterAboID is not null
and not
( dateadd(month,-6,a.DebutAboDate)>coalesce(b.FinAboDate,N'31-12-2078') )
set @r4=@@rowcount

update a 
set MasterAboID=a.ContratID
from #T_Abo_Fusion_Coupure a inner join #T_Abo_Fusion_Coupure b 
on a.ProfilID=b.ProfilID
and a.CTRCODTIT=b.CTRCODTIT
and a.CTRCODOFF=b.CTRCODOFF
and a.CTRCODPRV=b.CTRCODPRV
and a.CTROPTOFF=b.CTROPTOFF
and a.NOrder=b.NOrder+1
where a.MasterAboID is null
and b.MasterAboID is not null
and ( dateadd(month,-6,a.DebutAboDate)>coalesce(b.FinAboDate,N'31-12-2078') )
set @r5=@@rowcount

update a 
set MasterAboID=a.ContratID
from #T_Abo_Fusion_Coupure a inner join #T_Abo_Fusion_Coupure b 
on ( a.ProfilID=b.ProfilID
and a.CTRCODTIT=b.CTRCODTIT  )
and not (a.CTRCODOFF=b.CTRCODOFF
and a.CTRCODPRV=b.CTRCODPRV
and a.CTROPTOFF=b.CTROPTOFF )
and a.NOrder=b.NOrder+1
where a.MasterAboID is null
and b.MasterAboID is not null
set @r6=@@rowcount

end



-- #T_Contrat_MinMax - table temporaire des agrégations
-- Elle servira de jointure avec la première et la dernière lignes de contrat de chaque abonnement
-- et fournira les sommes des montants et de remises

-- Puisque j'ai déjà MasterAboID dans #T_Abo_Fusion_Coupure, je pourrais regrouper directement par MasterAboID

update a
set MasterAboID=b.MasterAboID,  CTROPTOFF = b.CTROPTOFF
from #T_Abonnements_Brut a inner join #T_Abo_Fusion_Coupure b on a.ContratID=b.ContratID

update a
set MasterAboID=b.MasterAboID
from brut.Contrats_Abos a inner join #T_Abonnements_Brut b on a.ContratID=b.ContratID

if OBJECT_ID('tempdb..#T_Abo_Fusion_Coupure') is not null
	drop table #T_Abo_Fusion_Coupure

if OBJECT_ID('tempdb..#T_Contrat_MinMax') is not null
	drop table #T_Contrat_MinMax

create table #T_Contrat_MinMax 
(
ProfilID int null
--, CatalogueAbosID int null
, CTRCODSOC nvarchar(8) null
, CTRCODTIT nvarchar(8) null
, CTRCODOFF nvarchar(8) null
, CTRCODPRV nvarchar(32) null
, CTROPTOFF nvarchar(8) null
, CTRNUMCTR_MIN int null
, CTRNUMCTR_MAX int null
, MasterAboID int null
, RemiseAbo_Sum decimal(10,2) null
, MontantAbo_Sum decimal(10,2) null
)

insert #T_Contrat_MinMax 
(
ProfilID
--, CatalogueAbosID
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CTRNUMCTR_MIN
, CTRNUMCTR_MAX
, MasterAboID
, RemiseAbo_Sum
, MontantAbo_Sum
)
select 
ProfilID
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, MIN(CTRNUMCTR) as CTRNUMCTR_MIN
, MAX(CTRNUMCTR) as CTRNUMCTR_MAX
, MasterAboID
, SUM(coalesce(RemiseAbo,0.00)) as RemiseAbo_Sum
, SUM(coalesce(MontantAbo,0.00)) as MontantAbo_Sum
from #T_Abonnements_Brut
group by ProfilID
-- , CatalogueAbosID
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, MasterAboID

create index ind_01_T_Contrat_MinMax on #T_Contrat_MinMax (ProfilID, CTRCODSOC, CTRCODTIT, CTRCODOFF, CTRCODPRV, CTROPTOFF)

-- Table temporaire agrégée où il n'y aura qu'une ligne par abonnement
-- Après divers enrichissements, elle alimentera la table dbo.Abonnements

if OBJECT_ID('tempdb..#T_Abonnements_Agreg') is not null
	drop table #T_Abonnements_Agreg
	
create table #T_Abonnements_Agreg
(
ContratID int null
, MasterID int null -- sera récupéré le cas échéant de dbo.Abonnement 
, MasterAboID int null
, ProfilID int null -- Champ de regroupement
, CTRCODSOC nvarchar(8) null -- Champ de regroupement
, CTRCODTIT nvarchar(8) null -- Champ de regroupement
, CTRCODOFF nvarchar(8) null -- Champ de regroupement
, CTRCODPRV nvarchar(32) null -- Champ de regroupement
, CTROPTOFF nvarchar(8) null -- Champ de regroupement
, CTRNUMCTR int null -- cast as int, c'est important
, Marque int null
, CatalogueAbosID int null
, SouscriptionAboDate datetime null
, DebutAboDate datetime null
, FinAboDate datetime null
, ExAboSouscrNb int null
, RemiseAbo decimal(10,2) null
, MontantAbo decimal(10,2) null
, Devise nvarchar(8) null
, PremierNumeroServi int null
, DernierNumeroServi int null
, DatePremierNumeroServi datetime null
, DateDernierNumeroServi datetime null
, Fidelite nvarchar(8) null
, ModeExpedition int null
, SuspensionAbo bit null
, MotifFinAbo int null
, MotifProlongation int null
, AnnulationDate datetime null
, ReaboDate datetime null
, OrigineAbo int null -- dernière 
, ModeSouscription int null
, ModePaiement int null
, ValiditeCB datetime null
, ModifieTop bit null
, SupprimeTop bit null
, CTRNUMGCP nvarchar(18) null	-- Champ technique pour le calcul de StatutAbo
, CTRNUMFIN nvarchar(18) null	-- Champ technique pour le calcul de StatutAbo
, DateFinParutions datetime null	-- Champ technique pour le calcul de StatutAbo
, NumAbonne int null
, NomAbo nvarchar(255) null
)

insert #T_Abonnements_Agreg
(
ContratID
, MasterAboID
, ProfilID
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CTRNUMCTR
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, ExAboSouscrNb
, RemiseAbo
, MontantAbo
, Devise
, PremierNumeroServi
, DernierNumeroServi
, DatePremierNumeroServi
, DateDernierNumeroServi
, Fidelite
, ModeExpedition
, SuspensionAbo
, MotifFinAbo
, MotifProlongation
, AnnulationDate
, ReaboDate
, OrigineAbo
, ModeSouscription
, ModePaiement
, ValiditeCB
, ModifieTop
, SupprimeTop
, CTRNUMGCP
, CTRNUMFIN
, DateFinParutions
, NumAbonne
, NomAbo
)
select
 a.ContratID
, b.MasterAboID
, a.ProfilID
, a.CTRCODSOC
, a.CTRCODTIT
, a.CTRCODOFF
, a.CTRCODPRV
, a.CTROPTOFF
, a.CTRNUMCTR
, a.CatalogueAbosID
, a.SouscriptionAboDate
, a.DebutAboDate
, a.FinAboDate
, a.ExAboSouscrNb
, b.RemiseAbo_Sum as RemiseAbo
, b.MontantAbo_Sum as RemiseAbo
, a.Devise
, a.PremierNumeroServi
, a.DernierNumeroServi
, a.DatePremierNumeroServi
, a.DateDernierNumeroServi
, a.Fidelite
, a.ModeExpedition
, a.SuspensionAbo
, a.MotifFinAbo
, a.MotifProlongation
, a.AnnulationDate
, a.ReaboDate
, a.OrigineAbo
, a.ModeSouscription
, a.ModePaiement
, a.ValiditeCB
, a.ModifieTop
, a.SupprimeTop
, a.CTRNUMGCP
, a.CTRNUMFIN
, a.DateFinParutions
, a.NumAbonne
, a.NomAbo
from #T_Abonnements_Brut a 
inner join #T_Contrat_MinMax b 
on a.ProfilID=b.ProfilID
and a.CTRCODSOC=b.CTRCODSOC
and a.CTRCODTIT=b.CTRCODTIT
and a.CTRCODOFF=b.CTRCODOFF
and a.CTRCODPRV=b.CTRCODPRV
and a.CTROPTOFF=b.CTROPTOFF
and a.CTRNUMCTR=b.CTRNUMCTR_MAX -- On prend la ligne la plus récente car il y a plus à récupérer
and a.MasterAboID=b.MasterAboID
-- CatalogueAbosID est pris sur la dernière ligne, plus récente
-- Même avec le regroupement par 6 champs, cette règle reste applicable

-- Ici, éliminer les doublons au niveau de MasterAboID 

create index ind_01_T_Abonnements_Agreg on #T_Abonnements_Agreg (ProfilID,CTRCODSOC,CTRCODTIT)
-- create index ind_02_T_Abonnements_Agreg on #T_Abonnements_Agreg (CatalogueAbosID)

-- Maintenant, récupérer ce qui nous est nécessaire de la 1ère ligne, par jointure avec #T_Contrat_MinMax : 
-- SouscriptionAboDate,DebutAboDate,PremierNumeroServi,DatePremierNumeroServi

update a
set DebutAboDate=c.DebutAboDate
	, PremierNumeroServi=c.PremierNumeroServi
	, DatePremierNumeroServi=c.DatePremierNumeroServi
from #T_Abonnements_Agreg a 
inner join #T_Contrat_MinMax b 
on a.ProfilID=b.ProfilID
and a.CTRCODSOC=b.CTRCODSOC
and a.CTRCODTIT=b.CTRCODTIT
and a.CTRCODOFF=b.CTRCODOFF
and a.CTRCODPRV=b.CTRCODPRV
and a.CTROPTOFF=b.CTROPTOFF
and a.MasterAboID=b.MasterAboID
inner join #T_Abonnements_Brut c 
on b.ProfilID=c.ProfilID
and b.CTRCODSOC=c.CTRCODSOC
and b.CTRCODTIT=c.CTRCODTIT
and b.CTRCODOFF=c.CTRCODOFF
and b.CTRCODPRV=c.CTRCODPRV
and b.CTROPTOFF=c.CTROPTOFF
and b.CTRNUMCTR_MIN=c.CTRNUMCTR
and b.MasterAboID=b.MasterAboID


-- Prendre la SouscriptionAboDate la plus ancienne renséignée
update a
set SouscriptionAboDate=r1.SouscriptionAboDate
from #T_Abonnements_Agreg a inner join (
select rank() over (partition by b.MasterAboID order by b.SouscriptionAboDate asc, newid()) as N1 
, b.MasterAboID
, b.SouscriptionAboDate
, b.ProfilID
, b.CTRCODSOC
, b.CTRCODTIT
, b.CTRCODOFF
, b.CTRCODPRV
, b.CTROPTOFF
, b.CTRNUMABO
from brut.Contrats_Abos b where b.SourceID=@SourceID and b.SouscriptionAboDate is not null
) as r1 on a.NumAbonne=r1.CTRNUMABO
and a.CTRCODSOC=r1.CTRCODSOC
and a.CTRCODTIT=r1.CTRCODTIT
and a.CTRCODOFF=r1.CTRCODOFF
and a.CTRCODPRV=r1.CTRCODPRV
and a.CTROPTOFF=r1.CTROPTOFF
and a.MasterAboID=r1.MasterAboID
where r1.N1=1

-- Prendre la ReaboDate la plus récente renseignée
update a
set ReaboDate=r1.ReaboDate
from #T_Abonnements_Agreg a inner join (
select rank() over (partition by b.MasterAboID order by b.ReaboDate desc, newid()) as N1 
, b.MasterAboID
, b.ProfilID
, b.CTRCODSOC
, b.CTRCODTIT
, b.CTRCODOFF
, b.CTRCODPRV
, b.CTROPTOFF
, b.ReaboDate
, b.CTRNUMABO
from brut.Contrats_Abos b where b.SourceID =@SourceID and b.ReaboDate is not null) as r1 on a.NumAbonne=r1.CTRNUMABO
and a.CTRCODSOC=r1.CTRCODSOC
and a.CTRCODTIT=r1.CTRCODTIT
and a.CTRCODOFF=r1.CTRCODOFF
and a.CTRCODPRV=r1.CTRCODPRV
and a.CTROPTOFF=r1.CTROPTOFF
and a.MasterAboID=r1.MasterAboID
where r1.N1=1

-- Prendre le ModeExpedition le plus récent renseigné
update a
set ModeExpedition=r1.ModeExpedition
from #T_Abonnements_Agreg a inner join (
select rank() over (partition by b.MasterAboID order by cast(b.CTRNUMCTR as int) desc, newid()) as N1 
, b.MasterAboID
, b.ProfilID
, b.CTRCODSOC
, b.CTRCODTIT
, b.CTRCODOFF
, b.CTRCODPRV
, b.CTROPTOFF
, b.CTRNUMABO
, b.ModeExpedition
from brut.Contrats_Abos b where b.SourceID =@SourceID and b.ModeExpedition is not null) as r1 on a.NumAbonne=r1.CTRNUMABO
and a.CTRCODSOC=r1.CTRCODSOC
and a.CTRCODTIT=r1.CTRCODTIT
and a.CTRCODOFF=r1.CTRCODOFF
and a.CTRCODPRV=r1.CTRCODPRV
and a.CTROPTOFF=r1.CTROPTOFF
and a.MasterAboID=r1.MasterAboID
where r1.N1=1


-- Renseigner la marque

update a
set Marque=b.Marque
from #T_Abonnements_Agreg a inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID

create index ind_03_T_Abonnements_Agreg on #T_Abonnements_Agreg (MasterAboID)

-- A présent, on peut alimenter la table etl.Abos_Agreg_SDVP

update a
set MasterID=a.MasterID -- afin de ne par perdre MasterID de la ligne dbo.Abonnements existante
from #T_Abonnements_Agreg a inner join dbo.Abonnements b on a.MasterAboID=b.AbonnementID

update #T_Abonnements_Agreg
set MasterID=ProfilID
where MasterID is  null

-- Sauvegarder la table #T_Abonnements_Agreg dans etl.Abos_Agreg_SDVP
-- Son contenu sera déversé dans dbo.Abonnements 
-- par la procédure etl.InsertAbonnements_Agreg dans le cadre du process commun

-- Supprimer les doublons dans #T_Abonnements_Agreg

delete a
from #T_Abonnements_Agreg a inner join 
(select rank() over (partition by a.MasterAboID order by a.ContratID) as N1
, a.MasterAboID, a.ContratID
from #T_Abonnements_Agreg a
inner join
(
select COUNT(*) as N, a.MasterAboID from #T_Abonnements_Agreg a group by a.MasterAboID having COUNT(*)>1
) as r1 on a.MasterAboID=r1.MasterAboID
) as r2 on a.ContratID=r2.ContratID
where r2.N1>1

delete a -- on supprime les lignes que l'on va remplacer
from etl.Abos_Agreg_SDVP a inner join #T_Abonnements_Agreg b on a.MasterAboID=b.MasterAboID

insert etl.Abos_Agreg_SDVP
(
ContratID
, MasterID
, MasterAboID
, ProfilID
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CTRNUMCTR
, Marque
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, ExAboSouscrNb
, RemiseAbo
, MontantAbo
, Devise
, PremierNumeroServi
, DernierNumeroServi
, DatePremierNumeroServi
, DateDernierNumeroServi
, Fidelite
, ModeExpedition
, SuspensionAbo
, MotifFinAbo
, MotifProlongation
, AnnulationDate
, ReaboDate
, OrigineAbo
, ModeSouscription
, ModePaiement
, ValiditeCB
, ModifieTop
, SupprimeTop
, CTRNUMGCP
, CTRNUMFIN
, DateFinParutions
, NumAbonne
, NomAbo
)
select 
a.ContratID
, a.MasterID
, a.MasterAboID
, a.ProfilID
, a.CTRCODSOC
, a.CTRCODTIT
, a.CTRCODOFF
, a.CTRCODPRV
, a.CTROPTOFF
, a.CTRNUMCTR
, a.Marque
, a.CatalogueAbosID
, a.SouscriptionAboDate
, a.DebutAboDate
, a.FinAboDate
, a.ExAboSouscrNb
, a.RemiseAbo
, a.MontantAbo
, a.Devise
, a.PremierNumeroServi
, a.DernierNumeroServi
, a.DatePremierNumeroServi
, a.DateDernierNumeroServi
, a.Fidelite
, a.ModeExpedition
, a.SuspensionAbo
, a.MotifFinAbo
, a.MotifProlongation
, a.AnnulationDate
, a.ReaboDate
, a.OrigineAbo
, a.ModeSouscription
, a.ModePaiement
, a.ValiditeCB
, a.ModifieTop
, a.SupprimeTop
, a.CTRNUMGCP
, a.CTRNUMFIN
, a.DateFinParutions
, a.NumAbonne
, a.NomAbo
from #T_Abonnements_Agreg a


if OBJECT_ID('tempdb..#T_ConsentementsAbos') is not null
	drop table #T_ConsentementsAbos

if OBJECT_ID('tempdb..#T_Abonnements_Agreg') is not null
	drop table #T_Abonnements_Agreg

if OBJECT_ID('tempdb..#T_Contrat_MinMax') is not null
	drop table #T_Contrat_MinMax

-- Contrats BOX (Mode d'expédition : ABONNEMENT DIFFUSEUR)
-- Mise en quarantaine des contacts

/* update a
set QuarantaineTop=1
from brut.Contacts a 
inner join dbo.Abonnements b on a.ProfilID=b.ProfilID
inner join ref.CodeExpedition c
on b.ModeExpedition=c.CodeExpID
where c.CodeExp=N'09'*/
/*
update a
set QuarantaineTop=1
from brut.Contacts a 
inner join dbo.Abonnements b on a.ProfilID=b.ProfilID
inner join ref.CodeExpCompress c
on b.ModeExpedition=c.CodeExpID
where c.Libelle=N'ABONNEMENT DIFFUSEUR'
*/

update import.SDVP_Contrats
set LigneStatut=99
where FichierTS=@FichierTS
and LigneStatut=0


update brut.Contrats_Abos
set ModifieTop=0
where ModifieTop=1 -- Alimentations successives sans build ; normalement, cela doit être fait par la procédure FinTraitement

                /********** AUTOCALCULATE REJECTSTATS **********/
                IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'SDVP_Contrats'))
                               EXECUTE [QTSDQF].[dbo].[RejetsStats] '95940C81-C7A7-4BD9-A523-445A343A9605', 'SDVP_Contrats', @FichierTS


end
