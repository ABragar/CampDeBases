USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [import].[PublierPVL_Utilisateur_EQ]    Script Date: 29.04.2015 17:40:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc [import].[PublierPVL_Utilisateur_EQ] @FichierTS nvarchar(255)
as

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 24/10/2014
-- Description:	Alimentation des tables : 
--								
--								brut.ConsentementsEmail 
-- à partir des fichiers AccountReport de VEL : PVL_Utilisateur de l'Equipe
-- Modification date: 18/11/2014
-- Modifications : n'alimenter que brut.ConsentementsEmail
-- Modification date: 15/12/2014
-- Modifications : Récupération des lignes invalides à cause de ClientUserID
-- =============================================

begin

set nocount on

declare @SourceID int

set @SourceID=10 -- PVL

declare @Marque int

select @Marque=(case when @FichierTS like N'%EQ%' then 7 when @FichierTS like N'%LP%' then 6 end)

select @Marque=7 -- en attendant la mise en place des noms des fichiers, on met d'office marque l'Equipe 

create table #T_Trouver_ProfilID
(
ProfileID int null
, EmailAddress nvarchar(255) null
, ClientUserId nvarchar(16) null
, iRecipientId nvarchar(16) null
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
select a.RejetCode, a.ImportID, a.FichierTS from import.PVL_Utilisateur a
inner join import.NEO_CusCompteEFR b on a.ClientUserId=b.sIdCompte
where a.RejetCode & power(cast(2 as bigint),42)=power(cast(2 as bigint),42)
and b.LigneStatut<>1

update a
set RejetCode=a.RejetCode-power(cast(2 as bigint),42)
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

if @Marque=7
begin

update a 
set iRecipientId=r1.iRecipientId
from #T_Trouver_ProfilID a inner join 
(select RANK() over (partition by b.sIdCompte order by cast(b.ActionID as int) desc, b.ImportID desc) as N1
, b.sIdCompte
, b.iRecipientId
from import.NEO_CusCompteEFR b  
where b.LigneStatut<>1)
as r1 on a.ClientUserId=r1.sIdCompte
where r1.N1=1

update a 
set ProfileID=b.ProfilID
from #T_Trouver_ProfilID a inner join brut.Contacts b on a.iRecipientId=b.OriginalID and b.SourceID=1

end

delete b 
from #T_Trouver_ProfilID a
inner join #T_Recup b on a.ImportID=b.ImportID
where a.ProfileID is null

delete #T_Trouver_ProfilID where ProfileID is null

update b set IDclientVEL=a.ClientUserId 
, StatutCompteVEL=( case a.AccountStatus when N'Activated' then 1 when N'Closed' then 2 end ) 
-- rajouter les deux autres statuts ("inactif", "mauvais payeur") quand ils seront connus
from #T_Trouver_ProfilID a inner join brut.Contacts b on a.ProfileID=b.ProfilID and b.SourceID=1

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
a.ProfileID
, a.ProfileID
, a.EmailAddress
, @ContenuID as ContenuID
, case when a.NoMarketingInformation=N'False' then 1 else -1 end as Valeur
, coalesce(a.CreateDate,a.LastUpdated,getdate()) as ConsentementDate
from #T_Trouver_ProfilID a
where a.ProfileID is not null
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
