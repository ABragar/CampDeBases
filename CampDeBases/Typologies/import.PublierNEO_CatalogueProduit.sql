USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [import].[PublierNEO_CatalogueProduit]    Script Date: 09.07.2015 15:36:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [import].[PublierNEO_CatalogueProduit] @FichierTS nvarchar(255)
as

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 05/11/2013
-- Description:	Alimentation de la table ref.CatalogueProduits
-- à partir des fichiers NEO_CatalogueProduit, NEO_TypeProduit
-- Il n'y a pas de @FichierTS, puisque les deux tables sont alimentées en annule et remplace 
-- Et NEO_CusAchats, on utilise la totalité des lignes valides
-- Modification date: 
-- Modifications :
-- =============================================

begin

set nocount on

-- Publication des données des tables NEO_CatalogueProduit et NEO_TypeProduit

declare @SourceID int

select @SourceID = 1 -- Neolane / L'Equipe

declare @MarqueEquipe int 

select @MarqueEquipe=CodeValN from ref.Misc 
where TypeRef=N'MARQUE'
and Valeur=N'L''Équipe'

-- Création de table temporaire

if OBJECT_ID('tempdb..#T_CatalogueProduits') is not null
	drop table #T_CatalogueProduits
	
create table #T_CatalogueProduits
(
OriginalID nvarchar(255) null
, SourceID int null
, PrixUnitaire decimal(10,4) null
, Devise nvarchar(16) null
, NomProduit nvarchar(255) null
, CategorieProduit nvarchar(255) null
, Marque int null
)


if OBJECT_ID('tempdb..#T_PrixUnitaires_Brut') is not null
	drop table #T_PrixUnitaires_Brut
	
create table #T_PrixUnitaires_Brut
(
OriginalID nvarchar(255) null
, PrixUnitaire decimal(10,4) null
, Devise nvarchar(16) null
, CategorieProduit nvarchar(255) null
, DateAchat datetime null
)

set dateformat ymd

insert #T_PrixUnitaires_Brut
(
OriginalID
, CategorieProduit
, PrixUnitaire
, DateAchat
, Devise
)
select a.sCodeProd
, a.sType_produit
, cast(a.dPrixUnitaire as decimal(10,4))
, cast(a.tsDateCommande as datetime) 
, a.sDevise
from import.NEO_CusAchats a
where a.sType_produit<>N'QUOTIDIEN'
and a.sType_produit not like N'PREMIUM%'
and a.sType_produit not like N'MAGNUS%'
and LigneStatut<>1 -- uniquement des lignes valides, publiées ou non

insert #T_PrixUnitaires_Brut
(
OriginalID
, CategorieProduit
, PrixUnitaire
, DateAchat
, Devise
)
select a.sType_produit
, a.sType_produit
, cast(a.dMontantCommande as decimal(10,4))
, cast(a.tsDateCommande as datetime) 
, a.sDevise
from import.NEO_CusAchats a
where a.sType_produit like N'PREMIUM%'
and LigneStatut<>1 -- uniquement des lignes valides, publiées ou non

if OBJECT_ID('tempdb..#T_PrixUnitaires') is not null
	drop table #T_PrixUnitaires
	
create table #T_PrixUnitaires
(
OriginalID nvarchar(255) null
, CategorieProduit nvarchar(255) null
, PrixUnitaire decimal(10,4) null
, Devise nvarchar(16) null
, DateAchat datetime null
)

-- On ne prend que le dernier achat en date pour chaque produit
insert #T_PrixUnitaires
(
OriginalID
, CategorieProduit
, PrixUnitaire
, Devise
, DateAchat
)
select distinct a.OriginalID
, a.CategorieProduit
, a.PrixUnitaire
, a.Devise
, a.DateAchat 
from #T_PrixUnitaires_Brut a inner join 
(select RANK() over (partition by b.OriginalID order by b.DateAchat desc, b.PrixUnitaire desc ) as N1 -- on prend la date la plus récente, le prix le plus élevé à la même date
, b.OriginalID
, b.CategorieProduit
, b.PrixUnitaire
, b.Devise
, b.DateAchat
from #T_PrixUnitaires_Brut b
) as r1 on a.OriginalID=r1.OriginalID and a.DateAchat=r1.DateAchat and a.PrixUnitaire=r1.PrixUnitaire and a.Devise=r1.Devise and a.CategorieProduit=r1.CategorieProduit
where N1=1

truncate table #T_PrixUnitaires_Brut

insert #T_PrixUnitaires_Brut
(
OriginalID
, CategorieProduit
, PrixUnitaire
, DateAchat
, Devise
)
select a.sCodeProd+N'_'+a.sTypeAboQuoti -- Code produit sera comme QUOTI_1, QUOTI_16, QUOTI_20
, a.sType_produit
, cast(a.dPrixUnitaire as decimal(10,4))
, cast(a.tsDateCommande as datetime) 
, a.sDevise
from import.NEO_CusAchats a inner join import.NEO_TypeAbosQuoti b on a.sTypeAboQuoti=b.sTypeAboQuoti
where a.sType_produit=N'QUOTIDIEN' and b.sDuree=N'1' and b.sUniteTps=N'jours' -- les achats unitaires des quotidiens
and a.LigneStatut<>1 -- uniquement des lignes valides, publiées ou non

insert #T_PrixUnitaires
(
OriginalID
, CategorieProduit
, PrixUnitaire
, Devise
, DateAchat
)
select distinct a.OriginalID
, a.CategorieProduit
, a.PrixUnitaire
, a.Devise
, a.DateAchat 
from #T_PrixUnitaires_Brut a inner join 
(select RANK() over (partition by b.OriginalID order by b.PrixUnitaire desc, b.DateAchat desc ) as N1 -- on prend d'abord le prix le plus élevé, pour ne pas prendre des 0 s'il y a des 1
, b.OriginalID
, b.CategorieProduit
, b.PrixUnitaire
, b.Devise
, b.DateAchat
from #T_PrixUnitaires_Brut b
) as r1 on a.OriginalID=r1.OriginalID and a.DateAchat=r1.DateAchat and a.PrixUnitaire=r1.PrixUnitaire and a.Devise=r1.Devise and a.CategorieProduit=r1.CategorieProduit
where N1=1

create index idx01_T_PrixUnitaires on #T_PrixUnitaires (OriginalID)

insert #T_CatalogueProduits
(
OriginalID
, SourceID
, PrixUnitaire
, Devise
, NomProduit
, CategorieProduit
, Marque
)
select 
a.iProduitId
,@SourceID
,c.PrixUnitaire
,c.Devise
,a.sLibelle
,b.sType_produit
,@MarqueEquipe -- Marque est toujours l'Equipe
from import.NEO_CatalogueProduit a 
inner join import.NEO_TypeProduit b -- c'est inutile, si l'on ne veut filtrer par NEO_TypeProduit
on a.sType_produit=b.sType_produit 
left outer join #T_PrixUnitaires c -- on ne trouve pas tous les prix ici
on a.iProduitId=c.OriginalID
where a.LigneStatut = 0
and b.LigneStatut = 0

create index idx01_T_CatalogueProduits on #T_CatalogueProduits (OriginalID, SourceID, Marque) 

-- On complète les prix en provenance de CusAchats par les prix du catalogue, si le prix est absent de CusAchats
update #T_CatalogueProduits
set PrixUnitaire=cast(b.dPrixUnitaire as decimal(10,4))
	, Devise=N'EUR' -- Devise par défaut, car non renseignée dans import.NEO_CatalogueProduit
from #T_CatalogueProduits a inner join import.NEO_CatalogueProduit b on a.OriginalID=b.iProduitId and a.CategorieProduit=b.sType_produit
where b.LigneStatut=0
and a.PrixUnitaire is null 

-- Les produits qui ne sont pas dans import.NEO_CatalogueProduit, mais qui sont dans import.NEO_CusAchats,
-- on les insère à partir de la table #T_PrixUnitaires, en mettant NomProduit = sCodeProd (OriginalID)

insert #T_CatalogueProduits
(
OriginalID
, SourceID
, PrixUnitaire
, Devise
, NomProduit
, CategorieProduit
, Marque
)
select
a.OriginalID
, @SourceID
, a.PrixUnitaire
, a.Devise
, a.OriginalID -- fait office du nom de produit
, a.CategorieProduit
, @MarqueEquipe -- Marque est toujours l'Equipe
from #T_PrixUnitaires a
left outer join #T_CatalogueProduits b
on  a.OriginalID=b.OriginalID
where a.OriginalID is not null
and b.OriginalID is null

-- Insérer le tout dans la table ref.CatalogueProduits, en différentiel

insert ref.CatalogueProduits
(
OriginalID
, SourceID
, PrixUnitaire
, Devise
, NomProduit
, CategorieProduit
, Marque
)
select distinct
t.OriginalID
, t.SourceID
, t.PrixUnitaire
, t.Devise
, t.NomProduit
, t.CategorieProduit
, t.Marque
from #T_CatalogueProduits t 
left outer join ref.CatalogueProduits a 
on t.OriginalID=a.OriginalID
and t.SourceID=a.SourceID
and t.Marque=a.Marque
where a.OriginalID is null
and t.OriginalID is not null


update a
set PrixUnitaire=t.PrixUnitaire
	, Devise=t.Devise
	, CategorieProduit=t.CategorieProduit
from #T_CatalogueProduits t 
inner join ref.CatalogueProduits a 
on t.OriginalID=a.OriginalID
and t.SourceID=a.SourceID
and t.Marque=a.Marque
and (a.PrixUnitaire<>t.PrixUnitaire or a.CategorieProduit<>t.CategorieProduit)

if OBJECT_ID('tempdb..#T_CatalogueProduits') is not null
	drop table #T_CatalogueProduits
	
if OBJECT_ID('tempdb..#T_PrixUnitaires_Brut') is not null
	drop table #T_PrixUnitaires_Brut
	
if OBJECT_ID('tempdb..#T_PrixUnitaires') is not null
	drop table #T_PrixUnitaires
	
update import.NEO_CatalogueProduit
set LigneStatut=99
where LigneStatut=0

update import.NEO_TypeProduit
set LigneStatut=99
where LigneStatut=0

end
