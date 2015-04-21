use AmauryVUC
go

alter proc etl.RemplirVEL_Accounts @FichierTS nvarchar(255)
as

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 01/04/2015
-- Description:	Alimentation de la table etl.VEL_Accounts
-- à partir des fichiers Accounts de VEL : PVL_Utilisateur du Parisien
-- Modification date: 
-- Modifications : 
-- =============================================

begin

set nocount on

-- Cette procédure est spécifique au Parisien

if object_id(N'tempdb..#T_VEL_Accounts') is not null
	drop table #T_VEL_Accounts

create table #T_VEL_Accounts
(
ClientUserId nvarchar(18) null
, ProfilID int null
, EmailAddress nvarchar(255) null
, SourceID int null
, Valid bit not null default(0)
)

insert #T_VEL_Accounts
(
ClientUserId
, EmailAddress
)
select distinct a.ClientUserId
, a.EmailAddress
from import.PVL_Utilisateur a 
where a.FichierTS=@FichierTS
and a.RejetCode & POWER(cast(2 as bigint),2)<>POWER(cast(2 as bigint),2)

update a
set ProfilID=c.ProfilID, SourceID=c.SourceID, Valid=1
from #T_VEL_Accounts a inner join import.SSO_Cumul b on a.EmailAddress=b.email_courant
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
from #T_VEL_Accounts a 
inner join brut.Emails b on a.EmailAddress=b.Email
inner join brut.Contacts c on b.ProfilID=c.ProfilID and c.SourceID=2
where a.ProfilID is null

update a
set ProfilID=r1.ProfilID, SourceID=r1.SourceID, Valid=1
from #T_VEL_Accounts a 
inner join brut.Emails b on a.EmailAddress=b.Email
inner join (
select rank() over (partition by c.EmailAddress order by c.ProfilID asc) as N1
, c.ProfilID
, c.SourceID
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
from #T_VEL_Accounts a 
inner join brut.Emails b on a.EmailAddress=b.Email
inner join brut.Contacts c on b.ProfilID=c.ProfilID and c.SourceID=4
where a.ProfilID is null

update a
set ProfilID=r1.ProfilID, SourceID=r1.SourceID, Valid=1
from #T_VEL_Accounts a 
inner join brut.Emails b on a.EmailAddress=b.Email
inner join (
select rank() over (partition by c.EmailAddress order by c.ProfilID asc) as N1
, c.ProfilID
, c.SourceID
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
from #T_VEL_Accounts a 
inner join brut.Emails b on a.EmailAddress=b.Email
inner join brut.Contacts c on b.ProfilID=c.ProfilID and c.SourceID=3 and left(c.OriginalID,2) in (N'AF',N'LP')
where a.ProfilID is null

update a
set ProfilID=r1.ProfilID, SourceID=r1.SourceID, Valid=1
from #T_VEL_Accounts a 
inner join brut.Emails b on a.EmailAddress=b.Email
inner join (
select rank() over (partition by c.EmailAddress order by c.ProfilID asc) as N1
, c.ProfilID
, c.SourceID
from #T_BrutSourceID c
) as r1 on b.ProfilID=r1.ProfilID 
where a.ProfilID is null
and r1.N1=1

insert etl.VEL_Accounts
(
ClientUserId
, ProfilID
, EmailAddress
, SourceID
, Valid
)
select 
a.ClientUserId
, a.ProfilID
, a.EmailAddress
, a.SourceID
, a.Valid
from #T_VEL_Accounts a 
left join etl.VEL_Accounts b
on a.ClientUserId=b.ClientUserId
where a.Valid=1
and a.ClientUserId is not null
and b.ClientUserId is null

if object_id(N'tempdb..#T_VEL_Accounts') is not null
	drop table #T_VEL_Accounts

end
go
