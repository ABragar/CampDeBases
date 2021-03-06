USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [import].[PublierPVL_Utilisateur_LP]    Script Date: 03/23/2015 18:16:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter proc [import].[PublierPVL_Utilisateur_LP] @FichierTS nvarchar(255)
as

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 23/03/2015
-- Description:	Alimentation des tables : 
--								
--								brut.ConsentementsEmail 
-- à partir des fichiers AccountReport de VEL : PVL_Utilisateur
-- Modification date: 18/11/2014
-- Modifications : n'alimenter que brut.ConsentementsEmail
-- Modification date: 15/12/2014
-- Modifications : Récupération des lignes invalides à cause de EmailAddress
-- Modification date: 25/03/2015
-- Modifications : LP
-- =============================================

begin

set nocount on

declare @SourceID int

set @SourceID=10 -- PVL

declare @Marque int

select @Marque=(case when @FichierTS like N'%EQ%' then 7 when @FichierTS like N'%LP%' then 6 end)

select @Marque=6 -- en attendant la mise en place des noms des fichiers, on met d'office marque Le Parisien
-- CETTE PROCEDURE EST SPECIFIQUE AU PARISEN

create table #T_Trouver_ProfilID
(
ProfilID int null
, EmailAddress nvarchar(255) null
, ClientUserId nvarchar(16) null
, NoMarketingInformation nvarchar(16) null
, AccountStatus nvarchar(20) null
, CreateDate datetime null
, LastUpdated datetime null
, ImportID int null
)

set dateformat dmy

insert #T_Trouver_ProfilID
(
EmailAddress
, ClientUserId
, AccountStatus
, NoMarketingInformation
, CreateDate
, LastUpdated
, ImportID
)
select 
a.EmailAddress
, a.ClientUserId
, a.AccountStatus
, coalesce(a.NoMarketingInformation,N'False')
, cast(a.CreateDate as datetime)
, cast(a.LastUpdated as datetime)
, a.ImportID
from import.PVL_Utilisateur a
where a.FichierTS=@FichierTS
and a.LigneStatut=0

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
select distinct a.RejetCode, a.ImportID, a.FichierTS from import.PVL_Utilisateur a
inner join import.SSO_Cumul b on a.EmailAddress=b.email_courant
where a.RejetCode & power(cast(2 as bigint),2)=power(cast(2 as bigint),2)

insert #T_Recup
(
RejetCode
, ImportID
, FichierTS
)
select distinct a.RejetCode, a.ImportID, a.FichierTS from import.PVL_Utilisateur a
inner join brut.Emails b on a.EmailAddress=b.Email
where a.RejetCode & power(cast(2 as bigint),2)=power(cast(2 as bigint),2)

update a
set RejetCode=a.RejetCode-power(cast(2 as bigint),2)
from #T_Recup a

update a 
set RejetCode=b.RejetCode
from import.PVL_Utilisateur a
inner join #T_Recup b on a.ImportID=b.ImportID

update a 
set LigneStatut=0
from import.PVL_Utilisateur a
inner join #T_Recup b on a.ImportID=b.ImportID
where b.RejetCode=0

update a 
set RejetCode=b.RejetCode
from rejet.PVL_Utilisateur a
inner join #T_Recup b on a.ImportID=b.ImportID

insert #T_FTS (FichierTS)
select distinct FichierTS from #T_Recup

delete a from #T_Recup a
where a.RejetCode<>0

delete a 
from rejet.PVL_Utilisateur a
inner join #T_Recup b on a.ImportID=b.ImportID

-- Fin de récup

insert #T_Trouver_ProfilID
(
EmailAddress
, ClientUserId
, AccountStatus
, NoMarketingInformation
, CreateDate
, LastUpdated
, ImportID
)
select 
a.EmailAddress
, a.ClientUserId
, a.AccountStatus
, a.NoMarketingInformation
, cast(a.CreateDate as datetime)
, cast(a.LastUpdated as datetime)
, a.ImportID
from import.PVL_Utilisateur a
inner join #T_Recup b on a.ImportID=b.ImportID
where a.LigneStatut=0


-- Trouver le ProfilID

-- On retrouve le ProfilID dans brut.Contacts en passant par import.SSO_Cumul
-- ainsi on retrouve la plupart des ProfilID

update a
set ProfilID=c.ProfilID
from #T_Trouver_ProfilID a inner join import.SSO_Cumul b on a.EmailAddress=b.email_courant
inner join brut.Contacts c on b.email_origine=c.OriginalID and c.SourceID=2

-- Pour le reste, on passe par brut.Emails de différentes sources
if object_id(N'tempdb..#T_BrutSourceID') is not null
	drop table #T_BrutSourceID

create table #T_BrutSourceID
(
ProfilID int null
, EmailAddress nvarchar(255) null
, SourceID int null
)

-- SourceID = 2 : LP SSO

insert #T_BrutSourceID
(
ProfilID
, EmailAddress
, SourceID
)
select c.ProfilID
, a.EmailAddress
, c.SourceID 
from #T_Trouver_ProfilID a 
inner join brut.Emails b on a.EmailAddress=b.Email
inner join brut.Contacts c on b.ProfilID=c.ProfilID and c.SourceID=2
where a.ProfilID is null

update a
set ProfilID=r1.ProfilID
from #T_Trouver_ProfilID a 
inner join brut.Emails b on a.EmailAddress=b.Email
inner join (
select rank() over (partition by c.EmailAddress order by c.ProfilID asc) as N1
, c.ProfilID
from #T_BrutSourceID c
) as r1 on b.ProfilID=r1.ProfilID 
where a.ProfilID is null
and r1.N1=1


-- SourceID = 4 : LP Prospects

truncate table #T_BrutSourceID

insert #T_BrutSourceID
(
ProfilID
, EmailAddress
, SourceID
)
select c.ProfilID
, a.EmailAddress
, c.SourceID 
from #T_Trouver_ProfilID a 
inner join brut.Emails b on a.EmailAddress=b.Email
inner join brut.Contacts c on b.ProfilID=c.ProfilID and c.SourceID=4
where a.ProfilID is null

update a
set ProfilID=r1.ProfilID
from #T_Trouver_ProfilID a 
inner join brut.Emails b on a.EmailAddress=b.Email
inner join (
select rank() over (partition by c.EmailAddress order by c.ProfilID asc) as N1
, c.ProfilID
from #T_BrutSourceID c
) as r1 on b.ProfilID=r1.ProfilID 
where a.ProfilID is null
and r1.N1=1

-- SourceID = 3 : SDVP (DCS)

truncate table #T_BrutSourceID

insert #T_BrutSourceID
(
ProfilID
, EmailAddress
, SourceID
)
select c.ProfilID
, a.EmailAddress
, c.SourceID 
from #T_Trouver_ProfilID a 
inner join brut.Emails b on a.EmailAddress=b.Email
inner join brut.Contacts c on b.ProfilID=c.ProfilID and c.SourceID=3
where a.ProfilID is null

update a
set ProfilID=r1.ProfilID
from #T_Trouver_ProfilID a 
inner join brut.Emails b on a.EmailAddress=b.Email
inner join (
select rank() over (partition by c.EmailAddress order by c.ProfilID asc) as N1
, c.ProfilID
from #T_BrutSourceID c
) as r1 on b.ProfilID=r1.ProfilID 
where a.ProfilID is null
and r1.N1=1

-- SourceID = 1 : Neolane
-- (il ne doit pas y en avoir, en théorie)

truncate table #T_BrutSourceID

insert #T_BrutSourceID
(
ProfilID
, EmailAddress
, SourceID
)
select c.ProfilID
, a.EmailAddress
, c.SourceID 
from #T_Trouver_ProfilID a 
inner join brut.Emails b on a.EmailAddress=b.Email
inner join brut.Contacts c on b.ProfilID=c.ProfilID and c.SourceID=1
where a.ProfilID is null

update a
set ProfilID=r1.ProfilID
from #T_Trouver_ProfilID a 
inner join brut.Emails b on a.EmailAddress=b.Email
inner join (
select rank() over (partition by c.EmailAddress order by c.ProfilID asc) as N1
, c.ProfilID
from #T_BrutSourceID c
) as r1 on b.ProfilID=r1.ProfilID 
where a.ProfilID is null
and r1.N1=1

delete b 
from #T_Trouver_ProfilID a
inner join #T_Recup b on a.ImportID=b.ImportID
where a.ProfilID is null

delete #T_Trouver_ProfilID where ProfilID is null

update b set IDclientVEL=a.ClientUserId 
, StatutCompteVEL=( case a.AccountStatus when N'Activated' then 1 when N'Closed' then 2 end ) 
-- rajouter les deux autres statuts ("inactif", "mauvais payeur") quand ils seront connus
from #T_Trouver_ProfilID a inner join brut.Contacts b on a.ProfilID=b.ProfilID

-- LienAvecMarque : StatutCompteVEL int

-- brut.ConsentementsEmail

if object_id(N'tempdb..#T_ConsEmail') is not null
	drop table #T_ConsEmail

create table #T_ConsEmail
(
ProfilID int not null
, MasterID int null
, Email nvarchar(255) not null
, ContenuID int null
, Valeur int null
, ConsentementDate datetime null
)

declare @ContenuID int

select @ContenuID=( case @Marque when 7 then 50 when 6 then 51 end )

insert #T_ConsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select distinct
a.ProfilID
, a.ProfilID
, a.EmailAddress
, @ContenuID as ContenuID
, case when a.NoMarketingInformation=N'False' then 1 else -1 end as Valeur
, coalesce(a.CreateDate,a.LastUpdated,getdate()) as ConsentementDate
from #T_Trouver_ProfilID a
where a.ProfilID is not null
and coalesce(a.EmailAddress,N'')<>N''

insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select distinct 
a.ProfilID
, a.MasterID
, a.Email
, a.ContenuID
, a.Valeur
, a.ConsentementDate
from #T_ConsEmail a 
left outer join brut.ConsentementsEmail b 
on a.ProfilID=b.ProfilID
and a.Email=b.Email
and a.ContenuID=b.ContenuID
and (a.Valeur=b.Valeur or b.Valeur=-4)
where a.ProfilID is not null
and b.ProfilID is null

-- dbo.LienAvecMarques

update import.PVL_Utilisateur 
set LigneStatut=99
where FichierTS=@FichierTS
and LigneStatut=0

update a
set LigneStatut=99
from import.PVL_Utilisateur a inner join #T_Recup b on a.ImportID=b.ImportID
where a.LigneStatut=0

if object_id(N'tempdb..#T_Recup') is not null
	drop table #T_Recup

if object_id(N'tempdb..#T_ConsEmail') is not null
	drop table #T_ConsEmail

if object_id(N'tempdb..#T_Trouver_ProfilID') is not null
	drop table #T_Trouver_ProfilID
	
declare @FTS nvarchar(255)
declare @S nvarchar(1000)

declare c_fts cursor for select FichierTS from #T_FTS

open c_fts

fetch c_fts into @FTS

while @@FETCH_STATUS=0
begin

--set @S=N'EXECUTE [QTSDQF].[dbo].[RejetsStats] ''95940C81-C7A7-4BD9-A523-445A343A9605'', ''PVL_Utilisateur'', N'''+@FTS+N''' ; '

--IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_Utilisateur'))
--	execute (@S) 

fetch c_fts into @FTS
end

close c_fts
deallocate c_fts


	/********** AUTOCALCULATE REJECTSTATS **********/
	--IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_Utilisateur'))
	--	EXECUTE [QTSDQF].[dbo].[RejetsStats] '95940C81-C7A7-4BD9-A523-445A343A9605', 'PVL_Utilisateur', @FichierTS




end
