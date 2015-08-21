USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [etl].[BuildConsentementsEmail]    Script Date: 08/19/2015 10:27:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc [etl].[BuildConsentementsEmail]
as

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 12/11/2013
-- Description:	Alimentation de la table dbo.ConsentementsEmail
-- à partir de la teble brut.ConsentementsEmail
-- Modification date: 06/05/2014
-- Modifications : Propagation des Hard Bounces
-- =============================================

begin

set nocount on

/*
Valeur :
1	= Opt-in
-1	= Opt-out
-2	= Suspension
-4	= Hard bounce
*/

-- Propager Hard Bounces dans brut.ConsentementsEmail avec Valeur=-4

update b 
set Valeur=-4
from brut.Emails a inner join brut.ConsentementsEmail b on a.Email=b.Email
where a.HardBounceDate is not null 
and b.Valeur > 0

update bCE
set DesaboDate = S.Desabodate
, Valeur = -1
from brut.ConsentementsEmail bCE
inner join 
(	select email, bCE.contenuid, min(consentementdate) as Desabodate  from brut.ConsentementsEmail bCE
	--inner join ref.Contenus rC on rC.ContenuID = bCE.ContenuID 
	where valeur = -1
	group by email, bCE.contenuid
) S on bCE.Email = S.Email and bCE.ContenuID = S.ContenuID and bCE.Valeur != -1 and bCE.DesaboDate is null



if OBJECT_ID(N'tempdb..#T_ConsentementsEmail') is not null
	drop table #T_ConsentementsEmail

create table #T_ConsentementsEmail
(
ProfilID int not null
, MasterID int null
, Email nvarchar(255) null
, ContenuID int not null
, Valeur int not null
, ConsentementDate datetime null
)

insert #T_ConsentementsEmail
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
, null as MasterID
, a.Email
, a.ContenuID
, a.Valeur
, a.ConsentementDate
from brut.ConsentementsEmail a
where a.ModifieTop=1

create index idx01_ProfilID on #T_ConsentementsEmail (ProfilID)
create index idx02_Email on #T_ConsentementsEmail (Email)

delete #T_ConsentementsEmail
from #T_ConsentementsEmail a inner join brut.Emails b on a.Email=b.ValeurOrigine
where b.Statut<>0 -- les adresses e-mail invalides

update a
set MasterID=b.MasterID
from #T_ConsentementsEmail a inner join brut.Contacts b on a.ProfilID=b.ProfilID

if OBJECT_ID(N'tempdb..#T_Optin') is not null
	drop table #T_Optin
	
create table #T_Optin
(
MasterID int null
, Email nvarchar(255) null
, ContenuID int not null
, Valeur int not null
, ConsentementDate datetime null
)

insert #T_Optin
(
MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate 
)
select distinct 
a.MasterID
, a.Email
, a.ContenuID
, a.Valeur
, a.ConsentementDate 
from #T_ConsentementsEmail a
where a.Valeur=1

create index idx01_MasterID on #T_Optin (MasterID)
create index idx02_Email on #T_Optin (Email)
create index idx03_ConsentementDate on #T_Optin (ConsentementDate)
create index idx04_ContenuID on #T_Optin (ContenuID)

if OBJECT_ID(N'tempdb..#T_Optout') is not null
	drop table #T_Optout

create table #T_Optout
(
MasterID int null
, Email nvarchar(255) null
, ContenuID int not null
, Valeur int not null
, ConsentementDate datetime null
)

insert #T_Optout
(
MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate 
)
select distinct
a.MasterID
, a.Email
, a.ContenuID
, a.Valeur
, a.ConsentementDate 
from #T_ConsentementsEmail a
where a.Valeur<>1

create index idx01_MasterID on #T_Optout (MasterID)
create index idx02_Email on #T_Optout (Email)
create index idx03_ConsentementDate on #T_Optout (ConsentementDate)
create index idx04_ContenuID on #T_Optout (ContenuID)

if OBJECT_ID(N'tempdb..#T_ConsentementsEmail') is not null
	drop table #T_ConsentementsEmail

if OBJECT_ID(N'tempdb..#T_Optout_Dernier') is not null
	drop table #T_Optout_Dernier
	
create table #T_Optout_Dernier
(
MasterID int null
, Email nvarchar(255) null
, ContenuID int not null
, Valeur int not null
, ConsentementDate datetime null
)

insert #T_Optout_Dernier
(
MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate 
)
select distinct  
a.MasterID
, a.Email
, a.ContenuID
, a.Valeur
, a.ConsentementDate 
from #T_Optout a 
inner join ( select RANK() over (partition by b.MasterID,b.Email,b.ContenuID order by b.ConsentementDate desc) as N1 
, b.MasterID
, b.Email
, b.ContenuID
, b.Valeur
, b.ConsentementDate 
from #T_Optout b ) as r1 
on a.MasterID=r1.MasterID
and a.Email=r1.Email
and a.ContenuID=r1.ContenuID
and a.Valeur=r1.Valeur
and a.ConsentementDate=r1.ConsentementDate
where r1.N1=1

create index idx01_MasterID on #T_Optout_Dernier (MasterID)
create index idx02_Email on #T_Optout_Dernier (Email)
create index idx03_ConsentementDate on #T_Optout_Dernier (ConsentementDate)
create index idx04_ContenuID on #T_Optout_Dernier (ContenuID)

if OBJECT_ID(N'tempdb..#T_Optout') is not null
	drop table #T_Optout

delete a
from #T_Optin a 
inner join #T_Optout_Dernier b on a.MasterID=b.MasterID
and a.Email=b.Email
and a.ContenuID=b.ContenuID
and a.ConsentementDate<=b.ConsentementDate

delete a
from  #T_Optout_Dernier a 
inner join #T_Optin b on a.MasterID=b.MasterID
and a.Email=b.Email
and a.ContenuID=b.ContenuID
and a.ConsentementDate<b.ConsentementDate

if OBJECT_ID(N'tempdb..#T_Insert_CE') is not null
	drop table #T_Insert_CE

create table #T_Insert_CE
(
MasterID int null
, Email nvarchar(255) null
, ContenuID int not null
, Valeur int not null
, ConsentementDate datetime null
)

insert #T_Insert_CE
(
MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate 
)
select distinct  
a.MasterID
, a.Email
, a.ContenuID
, a.Valeur
, a.ConsentementDate 
from #T_Optin a 
inner join ( select RANK() over (partition by b.MasterID,b.Email,b.ContenuID order by b.ConsentementDate asc) as N1 
, b.MasterID
, b.Email
, b.ContenuID
, b.Valeur
, b.ConsentementDate 
from #T_Optin b ) as r1 
on a.MasterID=r1.MasterID
and a.Email=r1.Email
and a.ContenuID=r1.ContenuID
and a.Valeur=r1.Valeur
and a.ConsentementDate=r1.ConsentementDate
where r1.N1=1

create index idx01_MasterID on #T_Insert_CE (MasterID)
create index idx02_Email on #T_Insert_CE (Email)
create index idx03_ConsentementDate on #T_Insert_CE (ConsentementDate)
create index idx04_ContenuID on #T_Insert_CE (ContenuID)


if OBJECT_ID(N'tempdb..#T_Optin') is not null
	drop table #T_Optin
	
insert dbo.ConsentementsEmail
(
MasterID
, Email
, ContenuID
, ConsentementDate
, Valeur
)
select 
a.MasterID
, a.Email
, a.ContenuID
, a.ConsentementDate
, a.Valeur
from #T_Insert_CE a left outer join dbo.ConsentementsEmail b
on a.MasterID=b.MasterID
and a.Email=b.Email
and a.ContenuID=b.ContenuID
where a.MasterID is not null
and b.MasterID is null
	
insert dbo.ConsentementsEmail
(
MasterID
, Email
, ContenuID
, ConsentementDate
, Valeur
)
select distinct
a.MasterID
, a.Email
, a.ContenuID
, a.ConsentementDate
, a.Valeur
from #T_Optout_Dernier a left outer join dbo.ConsentementsEmail b
on a.MasterID=b.MasterID
and a.Email=b.Email
and a.ContenuID=b.ContenuID
where a.MasterID is not null
and b.MasterID is null

update b
set ConsentementDate=a.ConsentementDate, Valeur=a.Valeur
from #T_Optout_Dernier a inner join dbo.ConsentementsEmail b 
on a.MasterID=b.MasterID
and a.Email=b.Email
and a.ContenuID=b.ContenuID
and b.Valeur=1
where a.ConsentementDate>=b.ConsentementDate

update b
set ConsentementDate=a.ConsentementDate, Valeur=a.Valeur
from #T_Insert_CE a inner join dbo.ConsentementsEmail b 
on a.MasterID=b.MasterID
and a.Email=b.Email
and a.ContenuID=b.ContenuID
where a.ConsentementDate>b.ConsentementDate
and b.Valeur not in (1,-4)

if OBJECT_ID(N'tempdb..#T_Optout_Dernier') is not null
	drop table #T_Optout_Dernier
	
if OBJECT_ID(N'tempdb..#T_Insert_CE') is not null
	drop table #T_Insert_CE
	
update CE set EmailDomaine = bE.EmailDomaine
from ConsentementsEmail CE inner join brut.Emails bE on CE.Email = bE.ValeurOrigine 
where CE.EmailDomaine is null


-- Purge

insert into export.ActionID_ATOS_ConsentEmails
select 3, ConsentementID
from ConsentementsEmail where ConsentementID in
(select ce.ConsentementID from consentementsemail ce 
left join brut.ConsentementsEmail bCE on ce.MasterID = bCE.MasterID and cE.Email = bCE.Email and cE.ContenuID = bCE.ContenuID 
where bCE.MasterID is null -- 3539
)

delete from consentementsemail  
where ConsentementID in
(select ce.ConsentementID from consentementsemail ce 
left join brut.ConsentementsEmail bCE on ce.MasterID = bCE.MasterID and cE.Email = bCE.Email and cE.ContenuID = bCE.ContenuID 
where bCE.MasterID is null -- 3539
)


-- Données Dashboard

insert into report.PressionQuoti_DBN_1 (jour, appartenance, typecontenu, optinsNb)
select getdate() as jour, M.Appartenance, C.TypeContenu, count(distinct MasterID) as optinsNb
from ConsentementsEmail CE
inner join ref.Contenus C on CE.ContenuID = C.ContenuID
inner join ref.Misc M on typeref = 'MARQUE' and M.CodeValN = C.MarqueID 
where C.TypeContenu in (2,3) and CE.Valeur = 1
group by M.Appartenance, C.TypeContenu

insert into report.PressionQuoti_DBN_1 (jour, appartenance, typecontenu, optinsNb)
select getdate() as jour, 3, C.TypeContenu, count(distinct MasterID) as optinsNb
from ConsentementsEmail CE
inner join ref.Contenus C on CE.ContenuID = C.ContenuID
where C.TypeContenu in (2,3) and CE.Valeur = 1
group by C.TypeContenu


end
