USE [AmauryVUC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [import].[PublierPVL_CatalogueOffres] @FichierTS nvarchar(255)
as

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 21/10/2014
-- Description:	Alimentation de la table ref.CatalogueProduits et ref.CatalogueAbonnements
-- à partir des fichiers CatalogueOffres de VEL : PVL_CatalogueOffres
-- Modification date: 
-- Modifications :
-- =============================================

begin

set nocount on

-- On suppose que la table PVL_CatalogueOffres est alimentée en annule/remplace

declare @SourceID int

set @SourceID=10 -- PVL

-- 1) Alimentation de ref.CatalogueProduits

if object_id(N'#T_CatProduits') is not null
	drop table #T_CatProduits

create table #T_CatProduits 
(
OriginalID nvarchar(255) null
, SourceID int null
, PrixUnitaire decimal(10,4) null
, Devise nvarchar(16) null
, NomProduit nvarchar(255) null
, CategorieProduit nvarchar(255) null
, Marque int null
)

insert #T_CatProduits 
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
a.IdentifiantOffre as OriginalID
, @SourceID
, cast(a.PrixOffre as decimal(10,4)) as PrixUnitaire
, N'EUR' as Devise
, a.NomOffre as NomProduit
, a.TypeProduit as CategorieProduit
, 7 as Marque -- L'Equipe
from import.PVL_CatalogueOffres a
where a.FichierTS=@FichierTS
and a.LigneStatut=0
and a.TypeOffre<>N'Abonnements'

update a
set PrixUnitaire=0.00
from #T_CatProduits a 
where a.PrixUnitaire is null

update b 
set PrixUnitaire=a.PrixUnitaire
, Devise=a.Devise
, NomProduit=a.NomProduit
, CategorieProduit=a.CategorieProduit
, Marque=a.Marque
from #T_CatProduits a
inner join ref.CatalogueProduits b
on a.OriginalID=b.OriginalID
and a.SourceID=b.SourceID

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
select
a.OriginalID
, a.SourceID
, a.PrixUnitaire
, a.Devise
, a.NomProduit
, a.CategorieProduit
, a.Marque
from #T_CatProduits a
left outer join ref.CatalogueProduits b
on a.OriginalID=b.OriginalID
and a.SourceID=b.SourceID
where a.OriginalID is not null
and b.OriginalID is null

if object_id(N'#T_CatProduits') is not null
	drop table #T_CatProduits

-- est-ce qu'on va gérer des suppressions des produits ?

-- 2) Alimentation de ref.CatalogueAbonnements

if object_id(N'#T_CatAbos') is not null
	drop table #T_CatAbos

create table #T_CatAbos
(
OriginalID nvarchar(255) null
, SourceID int null
, MontantAbo decimal(10,2) null 
, PrixInitial decimal(10,2) null
, TitreID int null
, OffreAbo nvarchar(255) null
, SupportAbo int null
, Marque int null
, Recurrent bit not null default(0)
, isCouple bit not null default(0)
)

insert #T_CatAbos
(
OriginalID
, SourceID
, MontantAbo
, PrixInitial
, OffreAbo
, Marque
, Recurrent
)
select distinct
a.IdentifiantOffre as OriginalID
, @SourceID
, cast(a.PrixOffre as decimal(10,2)) as MontantAbo
, cast(a.PrixOffre as decimal(10,2)) as PrixInitial
, a.NomOffre as OffreAbo
, 7 as Marque -- L'Equipe
, case when a.TypeProduit=N'Abonnement à tacite reconduction' then 1 else 0 end as Recurrent
from import.PVL_CatalogueOffres a
where a.FichierTS=@FichierTS
and a.LigneStatut=0
and a.TypeOffre=N'Abonnements'

update a
set TitreID=b.CodeValN
from #T_CatAbos a cross join ref.Misc b where b.TypeRef=N'TITREPRESSE' and b.Valeur=N'L''Équipe Numérique'

update a
set SupportAbo=b.CodeValN
from #T_CatAbos a cross join ref.Misc b where b.TypeRef=N'SUPPORTABO' and b.Valeur=N'Numérique'

update a
set MontantAbo=0.00
from #T_CatAbos a
where a.MontantAbo is null

update a
set PrixInitial=MontantAbo
from #T_CatAbos a
where a.PrixInitial is null

update b
set MontantAbo=a.MontantAbo
, PrixInitial=a.PrixInitial
, OffreAbo=a.OffreAbo
, Recurrent=a.Recurrent
from #T_CatAbos a
inner join ref.CatalogueAbonnements b
on a.OriginalID=b.OriginalID
and a.SourceID=b.SourceID 

insert ref.CatalogueAbonnements
(
OriginalID
, SourceID
, MontantAbo
, TitreID
, OffreAbo
, SupportAbo
, Marque
, Recurrent
, isCouple
, PrixInitial
)
select a.OriginalID
, a.SourceID
, a.MontantAbo
, a.TitreID
, a.OffreAbo
, a.SupportAbo
, a.Marque
, a.Recurrent
, a.isCouple
, a.PrixInitial
from #T_CatAbos a
left outer join ref.CatalogueAbonnements b 
on a.OriginalID=b.OriginalID
and a.SourceID=b.SourceID  
where a.OriginalID is not null 
and b.OriginalID is null

if object_id(N'#T_CatAbos') is not null
	drop table #T_CatAbos
	
update a
set LigneStatut=99
from import.PVL_CatalogueOffres a
where a.FichierTS=@FichierTS
and a.LigneStatut=0

	/********** AUTOCALCULATE REJECTSTATS **********/
	IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_CatalogueOffres'))
		EXECUTE [QTSDQF].[dbo].[RejetsStats] '95940C81-C7A7-4BD9-A523-445A343A9605', 'PVL_CatalogueOffres', @FichierTS

end
