USE [AmauryVUC]
GO

/****** Object:  StoredProcedure [import].[PublierPVL_Achats]    Script Date: 20.04.2015 17:22:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE proc [import].[PublierPVL_Achats] @FichierTS nvarchar(255)
as

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 28/10/2014
-- Description:	Alimentation de la table dbo.AchatALActe
-- à partir des fichiers DailyOrderReport de VEL : PVL_Achats
-- Modification date: 15/12/2014
-- Modifications : Récupération des lignes invalides à cause de ClientUserID
-- =============================================

begin

set nocount on

-- On suppose que la table PVL_CatalogueOffres est alimentée en annule/remplace

declare @SourceID int
declare @SourceID_Contact int

set @SourceID=10 -- PVL
set @SourceID_Contact=1 -- Neolane

if OBJECT_ID('tempdb..#T_Achats') is not null
	drop table #T_Achats
	
create table #T_Achats
(
 ProfilID int null
, ClientUserID nvarchar(18) null
, OriginalID nvarchar(255) null -- Code produit d'origine
, ProduitID int null -- Référence de produit dans le catalogue
, SourceID int null
, Marque int null
, NomProduit nvarchar(255) null
, AchatDate datetime null
, ExProdNb int null
, Reduction decimal(10,2) null
, MontantAchat decimal(10,2) null
, OrderID int null
, ProductDescription nvarchar(255) null
, MethodePaiement nvarchar(24) null
, CodePromo nvarchar(24) null
, Provenance nvarchar(255) null
, CommercialId nvarchar(255) null
, SalonId nvarchar(255) null
, ModePmtHorsLigne nvarchar(255) null
, iRecipientId nvarchar(18) null
, ImportID int null
)

set dateformat dmy

insert #T_Achats
(
ProfilID
, ClientUserID
, OriginalID
, ProduitID
, SourceID
, Marque
, NomProduit
, AchatDate
, ExProdNb
, Reduction
, MontantAchat
, OrderID
, ProductDescription
, MethodePaiement
, CodePromo
, Provenance
, CommercialId
, SalonId
, ModePmtHorsLigne
, ImportID
)
select
null as ProfilID
, a.ClientUserId
, a.ContentItemId
, null as ProduitID
, @SourceID
, null as Marque
, null as NomProduit
, cast(a.OrderDate as datetime) as AchatDate
, 1 as ExProdNb
, 0 as Reduction
, a.GrossAmount as MontantAchat
, a.OrderID
, a.Description
, a.PaymentMethod
, a.ActivationCode as CodePromo
, a.Provenance
, a.IdentifiantDuCommercial as CommercialId
, a.IdentifiantDuSalon as SalonId
, a.DetailModePaiementHorsLigne as ModePmtHorsLigne
, a.ImportID
from import.PVL_Achats a
where a.FichierTS=@FichierTS
and a.LigneStatut=0
and a.ProductType<>N'Service'
and a.OrderStatus=N'Completed'

-- Récupérer les lignes réjetées à cause de ClientUserId absent de CusCompteEFR
-- mais dont le sIdCompte est arrivé depuis dans CusCompteEFR

-- La table #T_FTS servira au recalcul des statistiques 

if object_id(N'tempdb..#T_FTS') is not null
	drop table #T_FTS

create table #T_FTS
(
FichierTS nvarchar(255) null
)

if object_id(N'tempdb..#T_Recup') is not null
	drop table #T_Recup

create table #T_Recup
(
RejetCode bigint not null
, ImportID int not null
, FichierTS nvarchar(255) null
)

insert #T_Recup
(
RejetCode
, ImportID
, FichierTS
)
select a.RejetCode, a.ImportID, a.FichierTS from import.PVL_Achats a
inner join import.NEO_CusCompteEFR b on a.ClientUserId=b.sIdCompte
where a.RejetCode & power(cast(2 as bigint),3)=power(cast(2 as bigint),3)
and b.LigneStatut<>1

update a
set RejetCode=a.RejetCode-power(cast(2 as bigint),3)
from #T_Recup a

update a 
set RejetCode=b.RejetCode
from import.PVL_Achats a
inner join #T_Recup b on a.ImportID=b.ImportID

update a 
set LigneStatut=0
from import.PVL_Achats a
inner join #T_Recup b on a.ImportID=b.ImportID
where b.RejetCode=0

update a 
set RejetCode=b.RejetCode
from rejet.PVL_Achats a
inner join #T_Recup b on a.ImportID=b.ImportID

insert #T_FTS (FichierTS)
select distinct FichierTS from #T_Recup

delete a from #T_Recup a
where a.RejetCode<>0

delete a 
from rejet.PVL_Achats a
inner join #T_Recup b on a.ImportID=b.ImportID

insert #T_Achats
(
ProfilID
, ClientUserID
, OriginalID
, ProduitID
, SourceID
, Marque
, NomProduit
, AchatDate
, ExProdNb
, Reduction
, MontantAchat
, OrderID
, ProductDescription
, MethodePaiement
, CodePromo
, Provenance
, CommercialId
, SalonId
, ModePmtHorsLigne
, ImportID
)
select
null as ProfilID
, a.ClientUserId
, a.ContentItemId
, null as ProduitID
, @SourceID
, null as Marque
, null as NomProduit
, cast(a.OrderDate as datetime) as AchatDate
, 1 as ExProdNb
, 0 as Reduction
, a.GrossAmount as MontantAchat
, a.OrderID
, a.Description
, a.PaymentMethod
, a.ActivationCode as CodePromo
, a.Provenance
, a.IdentifiantDuCommercial as CommercialId
, a.IdentifiantDuSalon as SalonId
, a.DetailModePaiementHorsLigne as ModePmtHorsLigne
, a.ImportID
from import.PVL_Achats a inner join #T_Recup b on a.ImportID=b.ImportID
where a.LigneStatut=0
and a.ProductType<>N'Service'
and a.OrderStatus=N'Completed'

update a
set ProduitID=b.ProduitID
	, Marque=b.Marque
	, NomProduit=b.NomProduit
from #T_Achats a inner join ref.CatalogueProduits b on a.OriginalID=b.OriginalID and b.SourceID=@SourceID


update a 
set iRecipientId=r1.iRecipientId
from #T_Achats a inner join 
(select RANK() over (partition by b.sIdCompte order by cast(b.ActionID as int) desc, b.ImportID desc) as N1
, b.sIdCompte
, b.iRecipientId
from import.NEO_CusCompteEFR b  
where b.LigneStatut<>1)
as r1 on a.ClientUserId=r1.sIdCompte
where r1.N1=1

update a
set ProfilID=b.ProfilID
from #T_Achats a inner join brut.Contacts b 
on a.iRecipientID=b.OriginalID 
and b.SourceID=@SourceID_Contact

delete b from #T_Achats a inner join #T_Recup b on a.ImportID=b.ImportID
where a.ProfilID is null

delete a from #T_Achats a
where a.ProfilID is null

insert dbo.AchatsALActe
(
ProfilID
, MasterID
, ProduitID
, SourceID
, Marque
, NomProduit
, AchatDate
, ExProdNb
, Reduction
, MontantAchat
, OrderID
, ClientUserId
, ProductDescription
, MethodePaiement
, CodePromo
, Provenance
, CommercialId
, SalonId
, ModePmtHorsLigne
, StatutAchat
, Appartenance
)
select 
a.ProfilID
, a.ProfilID as MasterID
, a.ProduitID
, a.SourceID
, a.Marque
, a.NomProduit
, a.AchatDate
, a.ExProdNb
, a.Reduction
, a.MontantAchat
, a.OrderID
, a.ClientUserID
, a.ProductDescription
, a.MethodePaiement
, a.CodePromo
, a.Provenance
, a.CommercialId
, a.SalonId
, a.ModePmtHorsLigne
, 1 as StatutAchat -- Completed
, c.Appartenance
from #T_Achats a inner join ref.Misc c on a.Marque=c.CodeValN and c.TypeRef=N'MARQUE'
left outer join dbo.AchatsALActe b
on a.ProfilID=b.ProfilID
and a.ProduitID=b.ProduitID
and a.AchatDate=b.AchatDate
where a.ProfilID is not null
and b.ProfilID is null

update a 
set LigneStatut=99
from import.PVL_Achats a inner join #T_Achats b on a.ImportID=b.ImportID
where a.FichierTS=@FichierTS
and a.LigneStatut=0
and a.ProductType<>N'Service'
and a.OrderStatus=N'Completed'

update a 
set LigneStatut=99
from import.PVL_Achats a inner join #T_Recup b on a.ImportID=b.ImportID
where a.LigneStatut=0
and a.ProductType<>N'Service'
and a.OrderStatus=N'Completed'


if OBJECT_ID('tempdb..#T_Achats') is not null
	drop table #T_Achats
	
if object_id(N'tempdb..#T_Recup') is not null
	drop table #T_Recup
	
declare @FTS nvarchar(255)
declare @S nvarchar(1000)

declare c_fts cursor for select FichierTS from #T_FTS

open c_fts

fetch c_fts into @FTS

while @@FETCH_STATUS=0
begin

set @S=N'EXECUTE [QTSDQF].[dbo].[RejetsStats] ''95940C81-C7A7-4BD9-A523-445A343A9605'', ''PVL_Achats'', N'''+@FTS+N''' ; '

IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_Achats'))
	execute (@S) 

fetch c_fts into @FTS
end

close c_fts
deallocate c_fts


		/********** AUTOCALCULATE REJECTSTATS **********/
	IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_Achats'))
		EXECUTE [QTSDQF].[dbo].[RejetsStats] '95940C81-C7A7-4BD9-A523-445A343A9605', 'PVL_Achats', @FichierTS


end

GO


