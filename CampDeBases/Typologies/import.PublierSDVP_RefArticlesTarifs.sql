USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [import].[PublierSDVP_RefArticlesTarifs]    Script Date: 09.07.2015 16:13:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [import].[PublierSDVP_RefArticlesTarifs] @FichierTS nvarchar(255)
as

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 05/11/2013
-- Description:	Alimentation de la table ref.CatalogueProduits
-- à partir des fichiers SDVP_RefArticles et SDVP_RefArticleTarifs
-- Il n'y a pas de @FichierTS, puisque les deux tables sont alimentées en annule et remplace 
-- Modification date: 09/07/2015
-- Modification by: Andrey Bragar
-- Modifications : add filling field [Physique] in [ref].[CatalogueProduits]
-- Modification date: 
-- Modifications :
-- =============================================

begin

set nocount on

-- Publication des données des tables SDVP_RefArticles et SDVP_RefArticleTarifs

declare @SourceID int

select @SourceID = 3 -- SDVP

-- Création de table temporaire

if OBJECT_ID('tempdb..#T_CatalogueProduits') is not null
	drop table #T_CatalogueProduits
	
create table #T_CatalogueProduits
(
OriginalID nvarchar(255) null
, SourceID int null
, PrixUnitaire decimal(10,4) null
, NomProduit nvarchar(255) null
, CategorieProduit nvarchar(255) null
, CodeSociete nvarchar(8) null
, Marque int NULL
, Physique BIT NOT NULL DEFAULT(0)
)

insert #T_CatalogueProduits
(
OriginalID
, SourceID
, PrixUnitaire
, NomProduit
, CategorieProduit
, CodeSociete
, Marque
)
select 
a.TARCODART
,@SourceID
,CAST(TARHTV as decimal(10,4)) as PrixUnitaire
,b.ARTLIBLNG
,b.ARTTYPPRO
,b.ARTCODSOC as CodeSociete
,null as Marque -- renseigné plus tard
from import.SDVP_RefArticleTarifs a 
inner join import.SDVP_RefArticles b 
on a.TARCODART=b.ARTCODART 
and a.TARCODSOC=b.ARTCODSOC
where a.LigneStatut = 0
and b.LigneStatut = 0

update a
set Marque=b.CodeValN
from #T_CatalogueProduits a inner join ref.Misc b 
on b.Valeur=case a.CodeSociete 
		when N'AF' then N'Aujourd''hui en France' 
		when N'LP' then N'Le Parisien'
		when N'EQ' then N'L''Équipe'
		else N'' end 
and b.TypeRef=N'MARQUE'

-- Physique
UPDATE a
SET Physique = 1
FROM #T_CatalogueProduits a
WHERE coalesce(a.CategorieProduit,N'')=N'NUM'

create index idx01_T_CatalogueProduits on #T_CatalogueProduits (OriginalID, SourceID, Marque) 

insert ref.CatalogueProduits
(
OriginalID
, SourceID
, PrixUnitaire
, Devise
, NomProduit
, CategorieProduit
, Marque
, Physique
)
select distinct
t.OriginalID
, t.SourceID
, t.PrixUnitaire
, N'EUR' as Devise
, t.NomProduit
, t.CategorieProduit
, t.Marque
, Physique
from #T_CatalogueProduits t 
left outer join ref.CatalogueProduits a 
on t.OriginalID=a.OriginalID
and t.SourceID=a.SourceID
and t.Marque=a.Marque
where a.OriginalID is null
and t.OriginalID is not null

update a
set PrixUnitaire=t.PrixUnitaire
	, CategorieProduit=t.CategorieProduit
from #T_CatalogueProduits t 
inner join ref.CatalogueProduits a 
on t.OriginalID=a.OriginalID
and t.SourceID=a.SourceID
and t.Marque=a.Marque
and (a.PrixUnitaire<>t.PrixUnitaire or a.CategorieProduit<>t.CategorieProduit)

if OBJECT_ID('tempdb..#T_CatalogueProduits') is not null
	drop table #T_CatalogueProduits
	
update import.SDVP_RefArticleTarifs 
set LigneStatut=99
where LigneStatut=0

update import.SDVP_RefArticles
set LigneStatut=99
where LigneStatut=0

end
