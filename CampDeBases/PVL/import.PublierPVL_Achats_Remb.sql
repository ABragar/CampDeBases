USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [import].[PublierPVL_Achats_Remb]    Script Date: 22.04.2015 10:21:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [import].[PublierPVL_Achats_Remb] @FichierTS nvarchar(255)
as

-- =============================================
-- Author:		Anatoli VELITCHKO
-- Creation date: 28/11/2014
-- Description:	Remboursements des achats dans dbo.AchatALActe
-- et des abonnements dans dbo.Abonnements
-- a partir des fichiers DailyOrderReport de VEL : PVL_Achats 
-- ou OrderStatus=Refunded
-- Modification date: 15/12/2014
-- Modifications : Recuperation des lignes invalides a cause de ClientUserID
-- =============================================

begin

set nocount on

declare @SourceID int

set @SourceID=10 -- PVL

if OBJECT_ID(N'tempdb..#T_Refunds') is not null
	drop table #T_Refunds

create table #T_Refunds
(
OrderID_Refund nvarchar(18) null
, AccountID nvarchar(18) null
, ClientUserId nvarchar(18) null
, Description_Refund nvarchar(255) null
, OrderID_Abo nvarchar(18) null
, GrossAmount decimal(10,2) null
, AchatID int null
, AbonnementID int null
, ImportID int null
)

insert #T_Refunds
(
OrderID_Refund
, AccountID
, ClientUserId
, Description_Refund
, GrossAmount
, ImportID
)
select a.OrderID
, a.AccountID
, a.ClientUserId
, a.Description
, cast(a.GrossAmount as decimal(10,2)) as GrossAmount
, a.ImportID
from import.PVL_Achats a
where a.FichierTS=@FichierTS
and a.LigneStatut=0
and a.OrderStatus=N'Refunded'
and a.Description like N'Refund Amount on Order:%'

-- Recuperer les lignes rejetees a cause de ClientUserId absent de CusCompteEFR
-- mais dont le sIdCompte est arrive depuis dans CusCompteEFR

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
and a.OrderStatus=N'Refunded'
and a.Description like N'Refund Amount on Order:%'
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


insert #T_Refunds
(
OrderID_Refund
, AccountID
, ClientUserId
, Description_Refund
, GrossAmount
, ImportID
)
select a.OrderID
, a.AccountID
, a.ClientUserId
, a.Description
, cast(a.GrossAmount as decimal(10,2)) as GrossAmount
, a.ImportID
from import.PVL_Achats a inner join #T_Recup b on a.ImportID=b.ImportID
where a.LigneStatut=0
and a.OrderStatus=N'Refunded'
and a.Description like N'Refund Amount on Order:%'


update a
set OrderID_Abo=ltrim(substring(a.Description_Refund
	, charindex(N':',a.Description_Refund,1)+1
	, case when charindex(N'(',a.Description_Refund,1)>charindex(N':',a.Description_Refund,1)
		then charindex(N'(',a.Description_Refund,1)-charindex(N':',a.Description_Refund,1)-1
		else 18 end))
from #T_Refunds a

update a
set AchatID=b.AchatID
from #T_Refunds a inner join dbo.AchatsALActe b on a.OrderID_Abo=b.OrderID

update a
set AbonnementID=b.AbonnementID
from #T_Refunds a inner join dbo.Abonnements b on a.OrderID_Abo=b.OrderID

update a
set MontantAchat=a.MontantAchat-b.GrossAmount
	, StatutAchat=2 -- Refunded
	, ModifieTop=1
from dbo.AchatsALActe a inner join #T_Refunds b on a.AchatID=b.AchatID

update a
set MontantAbo=a.MontantAbo-b.GrossAmount
	, ModifieTop=1
from dbo.Abonnements a inner join #T_Refunds b on a.AbonnementID=b.AbonnementID

update a
set LigneStatut=99
from import.PVL_Achats a inner join #T_Refunds b on a.ImportID=b.ImportID
where ( b.AbonnementID is not null or b.AchatID is not null )
and a.LigneStatut=0

if object_id(N'tempdb..#T_Recup') is not null
	drop table #T_Recup
	
if OBJECT_ID(N'tempdb..#T_Refunds') is not null
	drop table #T_Refunds
	
declare @FTS nvarchar(255)
declare @S nvarchar(1000)

declare c_fts cursor for select FichierTS from #T_FTS

open c_fts

fetch c_fts into @FTS

while @@FETCH_STATUS=0
begin

--set @S=N'EXECUTE [QTSDQF].[dbo].[RejetsStats] ''95940C81-C7A7-4BD9-A523-445A343A9605'', ''PVL_Achats'', N'''+@FTS+N''' ; '

--IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_Achats'))
--	execute (@S) 

fetch c_fts into @FTS
end

close c_fts
deallocate c_fts

--IF (EXISTS(SELECT NULL FROM sys.tables t INNER JOIN sys.[schemas] s ON s.SCHEMA_ID = t.SCHEMA_ID WHERE s.name='import' AND t.Name = 'PVL_Achats'))
--	EXECUTE [QTSDQF].[dbo].[RejetsStats] '95940C81-C7A7-4BD9-A523-445A343A9605', 'PVL_Achats', @FichierTS

end
