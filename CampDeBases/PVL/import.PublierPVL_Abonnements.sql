USE [AmauryVUC]

GO
/****** Object:  StoredProcedure [import].[PublierPVL_Abonnements]    Script Date: 22.04.2015 17:42:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [import].[PublierPVL_Abonnements] @FichierTS nvarchar(255)
as

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 29/10/2014
-- Description:	Alimentation de la table dbo.Abonnements
-- à partir des fichiers DailyOrderReport de VEL : PVL_Abonnements
-- Modification date: 15/12/2014
-- Modifications : Récupération des lignes invalides à cause de ClientUserID
-- =============================================

begin

set nocount on

-- On suppose que la table PVL_CatalogueOffres est alimentée en annule/remplace

declare @SourceID int
declare @SourceID_Contact int

set @SourceID=10 -- PVL
set @SourceID_Contact=1 -- Neolane, car on ne crée pas de contacts PVL spécifiques : on transcode vers Neolane


-- Alimentation de dbo.Abonnements

if OBJECT_ID('tempdb..#T_Abos') is not null
	drop table #T_Abos

create table #T_Abos
(
 ProfilID int null
, SourceID int null
, Marque int null
, ClientUserID nvarchar(18) null
, iRecipientID nvarchar(18) null
, OriginalID nvarchar(255) null -- Code produit d'origine
, CatalogueAbosID int null -- Référence de produit dans le catalogue
, NomAbo nvarchar(255) null -- Libellé du catalogue
, OrderDate datetime null
, ServiceID nvarchar(18) null
, SouscriptionAboDate datetime null
, DebutAboDate datetime null
, FinAboDate datetime null
, ExAboSouscrNb int not null default(0)
, RemiseAbo decimal(10,2) null
, MontantAbo decimal(10,2) null 
, Devise nvarchar(16) null
, Recurrent bit null
, SubscriptionStatus nvarchar(255) null
, SubscriptionStatusID int null
, ServiceGroup nvarchar(255) null
, IsTrial bit null
-- les champs suivants seront alimentés à partir de la table Orders
, OrderID nvarchar(16) null
, ProductDescription nvarchar(255) null
, MethodePaiement nvarchar(24) null
, CodePromo nvarchar(24) null
, Provenance nvarchar(255) null
, CommercialId nvarchar(255) null
, SalonId nvarchar(255) null
, ModePmtHorsLigne nvarchar(255) null
, ImportID int null
, Reprise bit not null default(0)
)

set dateformat dmy

insert #T_Abos
(
 ProfilID
, SourceID
, Marque
, ClientUserID
, OriginalID
, CatalogueAbosID
, NomAbo
, OrderDate
, ServiceID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, ExAboSouscrNb
, RemiseAbo
, MontantAbo
, Devise
, Recurrent
, SubscriptionStatus
, SubscriptionStatusID
, ServiceGroup
, IsTrial
, ImportID
)
select 
null as ProfilID
, @SourceID
, null as Marque
, a.ClientUserID
, a.ServiceId as OriginalID
, null as CatalogueAbosID
, null as NomAbo
, cast(a.SubscriptionLastUpdated as datetime) as OrderDate
, a.ServiceID
, cast(a.SubscriptionCreated as datetime) as SouscriptionAboDate
, cast(a.SubscriptionLastUpdated as datetime) as DebutAboDate
, a.ServiceExpiry as FinAboDate
, 1 as ExAboSouscrNb
, 0 as RemiseAbo
, a.ExplicitPrice as MontantAbo
, a.ExplicitCurrency as Devise
, null as Recurrent
, a.SubscriptionStatus
, cast(a.SubscriptionStatusID as int) as SubscriptionStatusID
, a.ServiceGroup
, case when a.IsTrial=N'True' then 1 else 0 end
, a.ImportID
from import.PVL_Abonnements a
where a.FichierTS=@FichierTS
and a.LigneStatut=0
and a.SubscriptionStatusID=N'2' -- Active Subscription

-- Récupérer les lignes réjetées à cause de ClientUserId absent de CusCompteEFR
-- mais dont le sIdCompte est arrivé depuis dans CusCompteEFR

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
select a.RejetCode, a.ImportID, a.FichierTS from import.PVL_Abonnements a
inner join import.NEO_CusCompteEFR b on a.ClientUserId=b.sIdCompte
where a.RejetCode & power(cast(2 as bigint),14)=power(cast(2 as bigint),14)
and b.LigneStatut<>1

update a
set RejetCode=a.RejetCode-power(cast(2 as bigint),14)
from #T_Recup a

update a 
set RejetCode=b.RejetCode
from import.PVL_Abonnements a
inner join #T_Recup b on a.ImportID=b.ImportID

update a 
set LigneStatut=0
from import.PVL_Abonnements a
inner join #T_Recup b on a.ImportID=b.ImportID
where b.RejetCode=0

update a 
set RejetCode=b.RejetCode
from rejet.PVL_Abonnements a
inner join #T_Recup b on a.ImportID=b.ImportID

insert #T_FTS (FichierTS)
select distinct FichierTS from #T_Recup

delete a from #T_Recup a
where a.RejetCode<>0

delete a 
from rejet.PVL_Abonnements a
inner join #T_Recup b on a.ImportID=b.ImportID

insert #T_Abos
(
 ProfilID
, SourceID
, Marque
, ClientUserID
, OriginalID
, CatalogueAbosID
, NomAbo
, OrderDate
, ServiceID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, ExAboSouscrNb
, RemiseAbo
, MontantAbo
, Devise
, Recurrent
, SubscriptionStatus
, SubscriptionStatusID
, ServiceGroup
, IsTrial
, ImportID
)
select 
null as ProfilID
, @SourceID
, null as Marque
, a.ClientUserID
, a.ServiceId as OriginalID
, null as CatalogueAbosID
, null as NomAbo
, cast(a.SubscriptionLastUpdated as datetime) as OrderDate
, a.ServiceID
, cast(a.SubscriptionCreated as datetime) as SouscriptionAboDate
, cast(a.SubscriptionLastUpdated as datetime) as DebutAboDate
, a.ServiceExpiry as FinAboDate
, 1 as ExAboSouscrNb
, 0 as RemiseAbo
, a.ExplicitPrice as MontantAbo
, a.ExplicitCurrency as Devise
, null as Recurrent
, a.SubscriptionStatus
, cast(a.SubscriptionStatusID as int) as SubscriptionStatusID
, a.ServiceGroup
, case when a.IsTrial=N'True' then 1 else 0 end
, a.ImportID
from import.PVL_Abonnements a inner join #T_Recup b on a.ImportID=b.ImportID
where a.LigneStatut=0
and a.SubscriptionStatusID=N'2' -- Active Subscription


update a
set OrderID=b.OrderID
from #T_Abos a inner join import.PVL_Achats b 
on a.ServiceId=b.ServiceID 
and a.ClientUserID=b.ClientUserId
and a.OrderDate between dateadd(minute,-1,cast(b.OrderDate as datetime)) 
and dateadd(minute,1,cast(b.OrderDate as datetime))
where b.LigneStatut<>1
and b.ProductType=N'Service'
and b.OrderStatus<>N'Refunded'

update a 
set ProductDescription=b.Description
, MethodePaiement=b.PaymentMethod
, CodePromo=b.ActivationCode
, Provenance=b.Provenance
, CommercialId=b.IdentifiantDuCommercial
, SalonId=b.IdentifiantDuSalon
, ModePmtHorsLigne=b.DetailModePaiementHorsLigne
from #T_Abos a
inner join import.PVL_Achats b on a.OrderID=b.OrderID

update a 
set iRecipientId=r1.iRecipientId
from #T_Abos a inner join 
(select RANK() over (partition by b.sIdCompte order by cast(b.ActionID as int) desc, b.ImportID desc) as N1
, b.sIdCompte
, b.iRecipientId
from import.NEO_CusCompteEFR b  
where b.LigneStatut<>1)
as r1 on a.ClientUserId=r1.sIdCompte
where r1.N1=1

update a
set ProfilID=b.ProfilID
from #T_Abos a inner join brut.Contacts b 
on a.iRecipientID=b.OriginalID 
and b.SourceID=@SourceID_Contact

delete b from #T_Abos a inner join #T_Recup b on a.ImportID=b.ImportID
where a.ProfilID is null

delete #T_Abos where ProfilID is null

update a
set CatalogueAbosID=b.CatalogueAbosID
, NomAbo=b.OffreAbo
, Marque=b.Marque
, Recurrent=b.Recurrent
from #T_Abos a inner join ref.CatalogueAbonnements b 
on a.OriginalID=b.OriginalID 
and a.SourceID=b.SourceID

delete b from #T_Abos a inner join #T_Recup b on a.ImportID=b.ImportID
where a.CatalogueAbosID is null

delete #T_Abos where CatalogueAbosID is null

-- ici, les abonnements doivent se cumuler, plusieurs lignes du même client et même titre en une ligne.
-- donc, il faut une table comme #T_Abos_Agreg
-- En outre, il faut gérer les remboursements dans les Achats

-- Donc, il faut de toute façon utiliser les deux tables : PVL_Abonnements et PVL_Achats

-- et comment ? - en utilisant la table brut.Contrats_Abos
-- comme je l'utilise pour Neolane

insert brut.Contrats_Abos
(
ProfilID
, SourceID
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, MontantAbo
, ExAboSouscrNb
, Devise
, Recurrent
, ClientUserId
, ServiceGroup
, IsTrial
, OrderID
, ProductDescription
, MethodePaiement
, CodePromo
, Provenance
, CommercialId
, SalonId
, ModePmtHorsLigne
, SubscriptionStatusID
)
select 
ProfilID
, SourceID
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, MontantAbo
, ExAboSouscrNb
, Devise
, Recurrent
, ClientUserId
, ServiceGroup
, IsTrial
, OrderID
, ProductDescription
, MethodePaiement
, CodePromo
, Provenance
, CommercialId
, SalonId
, ModePmtHorsLigne
, SubscriptionStatusID
from #T_Abos

-- donc, dans la table brut.Contrats_Abos ajouter aussi les champs de SubscriptionStatus ? - non, pas besoin
-- le statut, on calcule de toute façon par rapport à la date de fin
-- par contre, ici, on pourrait gérer les remboursements 


if OBJECT_ID('tempdb..#T_Brut_Abos') is not null
	drop table #T_Brut_Abos

create table #T_Brut_Abos
(
ContratID int not null
, MasterAboID int null -- = AbonnementID de abo.Abonnements
, ProfilID int not null
, SourceID int null
, CatalogueAbosID int null
, SouscriptionAboDate datetime null
, DebutAboDate datetime null
, FinAboDate datetime null
, MontantAbo decimal(10,2)
, ExAboSouscrNb int null
, Devise nvarchar(16) null
, Recurrent bit null
, ContratID_Regroup int null
, ClientUserId nvarchar(18) null
, ServiceGroup nvarchar(255) null
, IsTrial bit null
, OrderID nvarchar(16) null
, ProductDescription nvarchar(255) null
, MethodePaiement nvarchar(24) null
, CodePromo nvarchar(24) null
, Provenance nvarchar(255) null
, CommercialId nvarchar(255) null
, SalonId nvarchar(255) null
, ModePmtHorsLigne nvarchar(255) null
, SubscriptionStatusID int null
)

insert #T_Brut_Abos 
(
ContratID
, MasterAboID 
, ProfilID
, SourceID
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, MontantAbo
, ExAboSouscrNb
, Devise
, Recurrent
, ClientUserId
, ServiceGroup
, IsTrial
, OrderID
, ProductDescription
, MethodePaiement
, CodePromo
, Provenance
, CommercialId
, SalonId
, ModePmtHorsLigne
, SubscriptionStatusID
)
select 
a.ContratID
, a.MasterAboID 
, a.ProfilID
, a.SourceID
, a.CatalogueAbosID
, a.SouscriptionAboDate
, a.DebutAboDate
, a.FinAboDate
, a.MontantAbo
, a.ExAboSouscrNb
, a.Devise
, a.Recurrent
, a.ClientUserId
, a.ServiceGroup
, a.IsTrial
, OrderID
, ProductDescription
, MethodePaiement
, CodePromo
, Provenance
, CommercialId
, SalonId
, ModePmtHorsLigne
, SubscriptionStatusID
from brut.Contrats_Abos a
where a.ModifieTop=1 -- Les lignes qui viennent d'être insérées
and a.SourceID=@SourceID -- PVL
and a.Recurrent=1

create index ind_01_T_Brut_Abos on #T_Brut_Abos (ProfilID, CatalogueAbosID)

insert #T_Brut_Abos
(
ContratID
, MasterAboID 
, ProfilID
, SourceID
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, MontantAbo
, ExAboSouscrNb
, Devise
, Recurrent
, ClientUserId
, ServiceGroup
, IsTrial
, OrderID
, ProductDescription
, MethodePaiement
, CodePromo
, Provenance
, CommercialId
, SalonId
, ModePmtHorsLigne
, SubscriptionStatusID
)
select 
a.ContratID
, a.MasterAboID 
, a.ProfilID
, a.SourceID
, a.CatalogueAbosID
, a.SouscriptionAboDate
, a.DebutAboDate
, a.FinAboDate
, a.MontantAbo
, a.ExAboSouscrNb
, a.Devise
, a.Recurrent
, a.ClientUserId
, a.ServiceGroup
, a.IsTrial
, a.OrderID
, a.ProductDescription
, a.MethodePaiement
, a.CodePromo
, a.Provenance
, a.CommercialId
, a.SalonId
, a.ModePmtHorsLigne
, a.SubscriptionStatusID
from brut.Contrats_Abos a inner join #T_Brut_Abos b 
on a.ProfilID=b.ProfilID
and a.CatalogueAbosID=b.CatalogueAbosID
where a.ModifieTop=0 -- Les lignes anciennes du même profil, abonnements récurrents
and a.SourceID=@SourceID -- PVL
and a.Recurrent=1

create table #T_Abo_Fusion
(
N1 int null
, ContratID int null
, ProfilID int null
, CatalogueAbosID int null
, DebutAboDate datetime null
, FinAboDate datetime null
, DatePrevFin datetime null
, Ddiff int null
, ContratID_Regroup int null
)

insert #T_Abo_Fusion
(
N1
, ContratID
, ProfilID
, CatalogueAbosID
, DebutAboDate
, FinAboDate
)
select
RANK() over (partition by ProfilID,CatalogueAbosID order by SouscriptionAboDate asc,DebutAboDate asc,newid()) as N1 
, ContratID
, ProfilID
, CatalogueAbosID
, DebutAboDate
, FinAboDate
from #T_Brut_Abos

update a set DatePrevFin=b.FinAboDate
from #T_Abo_Fusion a 
left outer join #T_Abo_Fusion b 
on a.ProfilID=b.ProfilID 
and a.CatalogueAbosID=b.CatalogueAbosID 
and b.N1=a.N1-1

update #T_Abo_Fusion set ContratID_Regroup=ContratID where DatePrevFin is null and ContratID_Regroup is null 

update #T_Abo_Fusion set Ddiff=DATEDIFF(day,DatePrevFin,DebutAboDate) where DatePrevFin is not null

update #T_Abo_Fusion set ContratID_Regroup=ContratID where Ddiff>181 and ContratID_Regroup is null

declare @R as int

select @R = 1

while (@R>0)
begin

update a set ContratID_Regroup=b.ContratID_Regroup
from #T_Abo_Fusion a inner join #T_Abo_Fusion b on a.ProfilID=b.ProfilID 
and a.CatalogueAbosID=b.CatalogueAbosID 
and b.N1=a.N1-1
where a.ContratID_Regroup is null
and a.DDiff<=181 -- Intervalle ne doit pas être supérieur à 6 mois pour qu'on considère l'abonnement non interrompu
and b.ContratID_Regroup is not null
select @R=@@ROWCOUNT

end

update a
set ContratID_Regroup=b.ContratID_Regroup
from #T_Brut_Abos a 
inner join #T_Abo_Fusion b 
on a.ContratID=b.ContratID

if OBJECT_ID('tempdb..#T_Abos_MinMax') is not null
	drop table #T_Abos_MinMax

create table #T_Abos_MinMax 
(
ProfilID int null
, CatalogueAbosID int null
, ContratID_Regroup int null
, ContratID_Min int null
, DebutAboDate_Min datetime null
, DebutAboDate_Max datetime null
, MontantAbo_Sum decimal(10,2) null
)

insert #T_Abos_MinMax
(
ProfilID
, CatalogueAbosID
, ContratID_Regroup
, ContratID_Min
, DebutAboDate_Min
, DebutAboDate_Max
, MontantAbo_Sum
)
select 
a.ProfilID
, a.CatalogueAbosID
, ContratID_Regroup
, min(a.ContratID) as ContratID_Min
, min(a.DebutAboDate) as DebutAboDate_Min
, max(a.DebutAboDate) as DebutAboDate_Max
, sum(a.MontantAbo) as MontantAbo_Sum
from #T_Brut_Abos a
group by a.ProfilID
, a.CatalogueAbosID
, a.ContratID_Regroup

create index ind_01_T_Abos_MinMax on #T_Abos_MinMax (ProfilID, CatalogueAbosID)


update a
set MasterAboID=b.ContratID_Min
from #T_Brut_Abos a 
inner join #T_Abos_MinMax b 
on a.ContratID_Regroup=b.ContratID_Regroup
and a.ProfilID=b.ProfilID
and a.CatalogueAbosID=b.CatalogueAbosID

if OBJECT_ID('tempdb..#T_Abos_Agreg') is not null
	drop table #T_Abos_Agreg

create table #T_Abos_Agreg
(
MasterAboID int null -- = AbonnementID de abo.Abonnements
, ProfilID int not null
, MasterID int null
, SourceID int null
, Marque int null
, CatalogueAbosID int null
, SouscriptionAboDate datetime null
, DebutAboDate datetime null
, FinAboDate datetime null
, MontantAbo decimal(10,2)
, ExAboSouscrNb int null
, Devise nvarchar(16) null
, Recurrent bit null
, ContratID_Regroup int null
, ClientUserId nvarchar(18) null
, ServiceGroup nvarchar(255) null
, IsTrial bit null
, OrderID nvarchar(16) null
, ProductDescription nvarchar(255) null
, MethodePaiement nvarchar(24) null
, CodePromo nvarchar(24) null
, Provenance nvarchar(255) null
, CommercialId nvarchar(255) null
, SalonId nvarchar(255) null
, ModePmtHorsLigne nvarchar(255) null
, SubscriptionStatusID int null
)

insert #T_Abos_Agreg
(
MasterAboID
, ProfilID
, SourceID
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, MontantAbo
, ExAboSouscrNb
, Devise
, Recurrent
, ContratID_Regroup
, ClientUserId
, ServiceGroup
, IsTrial
, OrderID
, ProductDescription
, MethodePaiement
, CodePromo
, Provenance
, CommercialId
, SalonId
, ModePmtHorsLigne
, SubscriptionStatusID
)
select distinct
b.ContratID_Min as MasterAboID 
, a.ProfilID
, a.SourceID
, a.CatalogueAbosID
, a.SouscriptionAboDate
, a.DebutAboDate
, a.FinAboDate
, b.MontantAbo_Sum
, a.ExAboSouscrNb
, a.Devise
, a.Recurrent
, a.ContratID_Regroup
, a.ClientUserId
, a.ServiceGroup
, a.IsTrial
, a.OrderID
, a.ProductDescription
, a.MethodePaiement
, a.CodePromo
, a.Provenance
, a.CommercialId
, a.SalonId
, a.ModePmtHorsLigne
, a.SubscriptionStatusID
from #T_Brut_Abos a inner join #T_Abos_MinMax b 
on a.ProfilID=b.ProfilID
and a.CatalogueAbosID=b.CatalogueAbosID
and a.DebutAboDate=b.DebutAboDate_Max
and a.ContratID_Regroup=b.ContratID_Regroup

-- Mettre à jour les informations avec la dernière valeur renseignée et non celle de la dernière ligne dans le temps

-- le valeurs sont : SubscriptionStatusID

-- ProductDescription
-- MethodePaiement
-- CodePromo
-- Provenance
-- CommercialId
-- SalonId
-- ModePmtHorsLigne

update a 
set ProductDescription=b.ProductDescription
from #T_Abos_Agreg a inner join (
select 
a.ProfilID
, a.CatalogueAbosID
, a.ContratID_Regroup
, a.ProductDescription
, rank() over (partition by a.ProfilID
, a.CatalogueAbosID
, a.ContratID_Regroup order by a.DebutAboDate desc) as N1
from #T_Brut_Abos a
where a.ProductDescription is not null
) as b 
on a.ProfilID=b.ProfilID
and a.CatalogueAbosID=b.CatalogueAbosID
and a.MasterAboID=b.ContratID_Regroup
where b.N1=1

update a 
set MethodePaiement=b.MethodePaiement
from #T_Abos_Agreg a inner join (
select 
a.ProfilID
, a.CatalogueAbosID
, a.ContratID_Regroup
, a.MethodePaiement
, rank() over (partition by a.ProfilID
, a.CatalogueAbosID
, a.ContratID_Regroup order by a.DebutAboDate desc) as N1
from #T_Brut_Abos a
where a.MethodePaiement is not null
) as b 
on a.ProfilID=b.ProfilID
and a.CatalogueAbosID=b.CatalogueAbosID
and a.MasterAboID=b.ContratID_Regroup
where b.N1=1

update a 
set CodePromo=b.CodePromo
from #T_Abos_Agreg a inner join (
select 
a.ProfilID
, a.CatalogueAbosID
, a.ContratID_Regroup
, a.CodePromo
, rank() over (partition by a.ProfilID
, a.CatalogueAbosID
, a.ContratID_Regroup order by a.DebutAboDate desc) as N1
from #T_Brut_Abos a
where a.CodePromo is not null
) as b 
on a.ProfilID=b.ProfilID
and a.CatalogueAbosID=b.CatalogueAbosID
and a.MasterAboID=b.ContratID_Regroup
where b.N1=1

update a 
set Provenance=b.Provenance
from #T_Abos_Agreg a inner join (
select 
a.ProfilID
, a.CatalogueAbosID
, a.ContratID_Regroup
, a.Provenance
, rank() over (partition by a.ProfilID
, a.CatalogueAbosID
, a.ContratID_Regroup order by a.DebutAboDate desc) as N1
from #T_Brut_Abos a
where a.Provenance is not null
) as b 
on a.ProfilID=b.ProfilID
and a.CatalogueAbosID=b.CatalogueAbosID
and a.MasterAboID=b.ContratID_Regroup
where b.N1=1

update a 
set CommercialId=b.CommercialId
from #T_Abos_Agreg a inner join (
select 
a.ProfilID
, a.CatalogueAbosID
, a.ContratID_Regroup
, a.CommercialId
, rank() over (partition by a.ProfilID
, a.CatalogueAbosID
, a.ContratID_Regroup order by a.DebutAboDate desc) as N1
from #T_Brut_Abos a
where a.CommercialId is not null
) as b 
on a.ProfilID=b.ProfilID
and a.CatalogueAbosID=b.CatalogueAbosID
and a.MasterAboID=b.ContratID_Regroup
where b.N1=1

update a 
set SalonId=b.SalonId
from #T_Abos_Agreg a inner join (
select 
a.ProfilID
, a.CatalogueAbosID
, a.ContratID_Regroup
, a.SalonId
, rank() over (partition by a.ProfilID
, a.CatalogueAbosID
, a.ContratID_Regroup order by a.DebutAboDate desc) as N1
from #T_Brut_Abos a
where a.SalonId is not null
) as b 
on a.ProfilID=b.ProfilID
and a.CatalogueAbosID=b.CatalogueAbosID
and a.MasterAboID=b.ContratID_Regroup
where b.N1=1

update a 
set ModePmtHorsLigne=b.ModePmtHorsLigne
from #T_Abos_Agreg a inner join (
select 
a.ProfilID
, a.CatalogueAbosID
, a.ContratID_Regroup
, a.ModePmtHorsLigne
, rank() over (partition by a.ProfilID
, a.CatalogueAbosID
, a.ContratID_Regroup order by a.DebutAboDate desc) as N1
from #T_Brut_Abos a
where a.ModePmtHorsLigne is not null
) as b 
on a.ProfilID=b.ProfilID
and a.CatalogueAbosID=b.CatalogueAbosID
and a.MasterAboID=b.ContratID_Regroup
where b.N1=1

-- Eliminer les doublons éventuels dans #T_Abos_Agreg
-- Les doublons sont possibles si deux lignes ont la même date de début

delete a
from #T_Abos_Agreg a inner join (select RANK() over (partition by MasterAboID,DebutAboDate order by coalesce(b.FinAboDate,N'01-01-2078') desc, NEWID()) as N1
, b.MasterAboID
, b.DebutAboDate
, coalesce(b.FinAboDate,N'01-01-2078') as FinAboDate
from #T_Abos_Agreg b ) as r1 
	on a.MasterAboID=r1.MasterAboID 
	and cast(a.DebutAboDate as date)=cast(r1.DebutAboDate as date) -- on élimine ceux qui commencent le même jour, et pas seulement à la seconde près
	and coalesce(a.FinAboDate,N'01-01-2078')=r1.FinAboDate
where N1>1

-- Gérer 1 mois entre les dates de fin et date de début des abonnements récurrents 

update a
set DebutAboDate=b.DebutAboDate
		, SouscriptionAboDate=b.SouscriptionAboDate
from #T_Abos_Agreg a 
inner join #T_Brut_Abos b
on a.ProfilID=b.ProfilID
and a.CatalogueAbosID=b.CatalogueAbosID
inner join #T_Abos_MinMax c
on b.ProfilID=c.ProfilID
and b.CatalogueAbosID=c.CatalogueAbosID
and b.DebutAboDate=c.DebutAboDate_Min
and a.ContratID_Regroup=c.ContratID_Regroup


if OBJECT_ID('tempdb..#T_Abos_MinMax') is not null
	drop table #T_Abos_MinMax

-- Propager MasterAboID dans brut :

update a
set MasterAboID=b.MasterAboID
from brut.Contrats_Abos a inner join #T_Brut_Abos b
on a.ContratID=b.ContratID
where a.ModifieTop=1

if OBJECT_ID('tempdb..#T_Brut_Abos') is not null
	drop table #T_Brut_Abos

update a
set MasterAboID=a.ContratID
from brut.Contrats_Abos a where a.MasterAboID is null
and a.ModifieTop=1
and SourceID=@SourceID 

-- Insérer dans #T_Abos_Agreg les lignes des abonnements non-récurrents

insert #T_Abos_Agreg
(
MasterAboID
, ProfilID
, SourceID
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, MontantAbo
, ExAboSouscrNb
, Devise
, Recurrent
, ContratID_Regroup
, ClientUserId
, ServiceGroup
, IsTrial
, OrderID
, ProductDescription
, MethodePaiement
, CodePromo
, Provenance
, CommercialId
, SalonId
, ModePmtHorsLigne
, SubscriptionStatusID
)
select 
a.ContratID 
, a.ProfilID
, a.SourceID
, a.CatalogueAbosID
, a.SouscriptionAboDate
, a.DebutAboDate
, a.FinAboDate
, a.MontantAbo
, a.ExAboSouscrNb
, a.Devise
, a.Recurrent
, a.ContratID as ContratID_Regroup
, a.ClientUserId
, a.ServiceGroup
, a.IsTrial
, a.OrderID
, a.ProductDescription
, a.MethodePaiement
, a.CodePromo
, a.Provenance
, a.CommercialId
, a.SalonId
, a.ModePmtHorsLigne
, a.SubscriptionStatusID
from brut.Contrats_Abos a
where ModifieTop=1 -- Les lignes qui viennent d'être insérées
and SourceID=@SourceID -- Neolane
and a.Recurrent=0 -- Abonnements non-récurrents

-- Renseigner la marque

update a
set Marque=b.Marque
from #T_Abos_Agreg a inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID

create index ind_03_T_Abonnements_Agreg on #T_Abos_Agreg (MasterAboID)

update #T_Abos_Agreg
set MasterID=ProfilID
where MasterID is null

-- Renseigner = metrre à jour le SubscriptionStatusID avec le statut dernier en date qui peut ne pas être "Active Subscription"

if object_id(N'tempdb..#T_AboStatut') is not null
	drop table #T_AboStatut

create table #T_AboStatut
(
SubscriptionId nvarchar(16) null
, ServiceID nvarchar(16) null
, SubscriptionCreated datetime null
, SubscriptionLastUpdated datetime null
, SubscriptionStatusID int null
, SubscriptionStatus nvarchar(255) null
, AccountId	nvarchar(16) null
, ClientUserId nvarchar(16) null
, ServiceExpiry datetime null
)

insert #T_AboStatut
(
SubscriptionId
, ServiceID
, SubscriptionCreated
, SubscriptionLastUpdated
, SubscriptionStatusID
, SubscriptionStatus
, AccountId
, ClientUserId
, ServiceExpiry
)
select 
a.SubscriptionId
, a.ServiceID
, cast(a.SubscriptionCreated as datetime) as SubscriptionCreated
, cast(a.SubscriptionLastUpdated as datetime) as SubscriptionLastUpdated
, cast(a.SubscriptionStatusID as int) as SubscriptionStatusID
, a.SubscriptionStatus
, a.AccountId
, a.ClientUserId
, cast(a.ServiceExpiry as datetime) as ServiceExpiry
from import.PVL_Abonnements a 
where a.LigneStatut<>1

if object_id(N'tempdb..#T_AboDernierStatut') is not null
	drop table #T_AboDernierStatut

create table #T_AboDernierStatut
(
SubscriptionId nvarchar(16) null
, ServiceID nvarchar(16) null
, SubscriptionCreated datetime null
, SubscriptionLastUpdated datetime null
, SubscriptionStatusID int null
, SubscriptionStatus nvarchar(255) null
, AccountId	nvarchar(16) null
, ClientUserId nvarchar(16) null
, ServiceExpiry datetime null
, iRecipientId nvarchar(18) null
, ProfilID int null
, CatalogueAbosID int null
)

set dateformat dmy

insert #T_AboDernierStatut
(
SubscriptionId
, ServiceID
, SubscriptionCreated
, SubscriptionLastUpdated
, SubscriptionStatusID
, SubscriptionStatus
, AccountId
, ClientUserId
, ServiceExpiry
)
select 
a.SubscriptionId
, a.ServiceID
, a.SubscriptionCreated
, a.SubscriptionLastUpdated
, a.SubscriptionStatusID
, a.SubscriptionStatus
, a.AccountId
, a.ClientUserId
, a.ServiceExpiry
from #T_AboStatut a inner join (
select 
rank() over (partition by a.SubscriptionId order by a.SubscriptionLastUpdated desc) as N1
, SubscriptionId
, SubscriptionLastUpdated
from #T_AboStatut a 
) as r1 on a.SubscriptionId=r1.SubscriptionId and a.SubscriptionLastUpdated=r1.SubscriptionLastUpdated
and r1.N1=1

if object_id(N'tempdb..#T_AboStatut') is not null
	drop table #T_AboStatut

update a 
set iRecipientId=r1.iRecipientId
from #T_AboDernierStatut a inner join 
(select RANK() over (partition by b.sIdCompte order by cast(b.ActionID as int) desc, b.ImportID desc) as N1
, b.sIdCompte
, b.iRecipientId
from import.NEO_CusCompteEFR b  
where b.LigneStatut<>1)
as r1 on a.ClientUserId=r1.sIdCompte
where r1.N1=1


update a
set ProfilID=b.ProfilID
from #T_AboDernierStatut a inner join brut.Contacts b 
on a.iRecipientID=b.OriginalID 
and b.SourceID=@SourceID_Contact


delete #T_AboDernierStatut where ProfilID is null

update a
set CatalogueAbosID=b.CatalogueAbosID
from #T_AboDernierStatut a inner join ref.CatalogueAbonnements b 
on a.ServiceID=b.OriginalID 
and b.SourceID=@SourceID

delete #T_AboDernierStatut where CatalogueAbosID is null

create index idx01_T_AboDernierStatut on #T_AboDernierStatut (ProfilID)
create index idx02_T_AboDernierStatut on #T_AboDernierStatut (CatalogueAbosID)
create index idx03_T_AboDernierStatut on #T_AboDernierStatut (SubscriptionCreated)

update a 
set SubscriptionStatusID=b.SubscriptionStatusID
, FinAboDate=( case when a.FinAboDate<b.ServiceExpiry then a.FinAboDate else b.ServiceExpiry end )
from #T_Abos_Agreg a inner join #T_AboDernierStatut b 
on a.ProfilID=b.ProfilID
and a.CatalogueAbosID=b.CatalogueAbosID
and a.SouscriptionAboDate=b.SubscriptionCreated
where a.SubscriptionStatusID<>b.SubscriptionStatusID

-- Stocker les lignes dans etl.Abos_Agreg_PVL 
-- en attendant que la procédure etl.InsertAbonnements_Agreg les déverse dans dbo.Abonnements

delete a -- on supprime les lignes que l'on va remplacer
from etl.Abos_Agreg_PVL a inner join #T_Abos_Agreg b on a.MasterAboID=b.MasterAboID

insert etl.Abos_Agreg_PVL 
(
 MasterAboID
, ProfilID
, MasterID
, SourceID
, Marque
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, MontantAbo
, ExAboSouscrNb
, Devise
, Recurrent
, ContratID_Regroup
, ClientUserId
, ServiceGroup
, IsTrial
, OrderID
, AboDescription
, MethodePaiement
, CodePromo
, Provenance
, CommercialId
, SalonId
, ModePmtHorsLigne
, SubscriptionStatusID
)
select  MasterAboID
, ProfilID
, MasterID
, SourceID
, Marque
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, MontantAbo
, ExAboSouscrNb
, Devise
, Recurrent
, ContratID_Regroup
, ClientUserId
, ServiceGroup
, IsTrial
, OrderID
, ProductDescription
, MethodePaiement
, CodePromo
, Provenance
, CommercialId
, SalonId
, ModePmtHorsLigne
, SubscriptionStatusID
from #T_Abos_Agreg

update brut.Contrats_Abos
set ModifieTop=0
where ModifieTop=1 -- Alimentations successives sans build ; normalement, cela doit être fait par la procédure FinTraitement

update a
set LigneStatut=99
from import.PVL_Abonnements a
where a.FichierTS=@FichierTS
and a.LigneStatut=0
and a.SubscriptionStatusID=N'2'

update a
set LigneStatut=99
from import.PVL_Abonnements a inner join #T_Recup b on a.ImportID=b.ImportID
where a.LigneStatut=0
and a.SubscriptionStatusID=N'2'

update a
set LigneStatut=99
from import.PVL_Achats a inner join #T_Abos_Agreg b on a.OrderID=b.OrderID
where a.LigneStatut=0
and a.ProductType=N'Service'
and a.OrderStatus<>N'Refunded'

if object_id(N'tempdb..#T_Recup') is not null
	drop table #T_Recup
	
if object_id(N'tempdb..#T_Abos_Agreg') is not null
	drop table #T_Abos_Agreg
	
declare @FTS nvarchar(255)
declare @S nvarchar(1000)

declare c_fts cursor for select FichierTS from #T_FTS

open c_fts

fetch c_fts into @FTS

while @@FETCH_STATUS=0
begin

set @S=N'EXECUTE [QTSDQF].[dbo].[RejetsStats] ''95940C81-C7A7-4BD9-A523-445A343A9605'', ''PVL_Abonnements'', N'''+@FTS+N''' ; '

IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_Abonnements'))
	execute (@S) 

fetch c_fts into @FTS
end

close c_fts
deallocate c_fts


	/********** AUTOCALCULATE REJECTSTATS **********/
	IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_Abonnements'))
		EXECUTE [QTSDQF].[dbo].[RejetsStats] '95940C81-C7A7-4BD9-A523-445A343A9605', 'PVL_Abonnements', @FichierTS


end
