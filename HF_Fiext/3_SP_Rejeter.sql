USE [AmauryVUC]
GO

/****** Object:  StoredProcedure [import].[rejeterHF_Fiext]    Script Date: 20.03.2015 15:59:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

Alter proc [import].[rejeterHF_Fiext] @FichierTS nvarchar(255) 
as 

begin 

set nocount on 

update import.HF_Fiext set FichierTS = @FichierTS where FichierTS is null

if OBJECT_ID('tempdb..#T_Rejets') is not null
	drop table #T_Rejets

select * into #T_Rejets from import.HF_Fiext where FichierTS = @FichierTS and LigneStatut<>99

update #T_Rejets set LigneStatut=0 where LigneStatut<>0 
update #T_Rejets set rejetCode=0 where rejetCode<>0 

set dateformat dmy
---Date validation
update #T_Rejets set rejetCode = i.rejetCode | POWER(cast(2 as bigint),6)
from #T_Rejets i
where FichierTS = @FichierTS and i.LigneStatut<>99 
and isdate(coalesce(i.DATE_NAISSANCE, '01/01/1900')) = 0 

update #T_Rejets set rejetCode = i.rejetCode | POWER(cast(2 as bigint),17)
from #T_Rejets i
where FichierTS = @FichierTS and i.LigneStatut<>99 
and isdate(coalesce(i.DATE_STOP_ADRESSEPOSTAL, '01/01/1900')) = 0 

update #T_Rejets set rejetCode = i.rejetCode | POWER(cast(2 as bigint),22)
from #T_Rejets i
where FichierTS = @FichierTS and i.LigneStatut<>99 
and isdate(coalesce(i.DATE_ANCIENNETE, '01/01/1900')) = 0 

update #T_Rejets set rejetCode = i.rejetCode | POWER(cast(2 as bigint),23)
from #T_Rejets i
where FichierTS = @FichierTS and i.LigneStatut<>99 
and isdate(coalesce(i.DATE_MODIFICATION, '01/01/1900')) = 0 

---Date validation

--- fields not null
--marque_id
update #T_Rejets set rejetCode = i.rejetCode | POWER(cast(2 as bigint),25)
from #T_Rejets i
where FichierTS = @FichierTS and i.LigneStatut<>99 
and IsNumeric(marque_id)=0

update #T_Rejets set rejetCode = i.rejetCode | POWER(cast(2 as bigint),25)
from #T_Rejets i
where FichierTS = @FichierTS and i.LigneStatut<>99 
and Cast(case when isnumeric(i.marque_id)=0 then 0 else i.marque_id end as int)  not between 1 and 9 
and i.rejetCode & POWER(cast(2 as bigint),25)<>POWER(cast(2 as bigint),25)

--optin-M
update #T_Rejets set rejetCode = i.rejetCode | POWER(cast(2 as bigint),26)
from #T_Rejets i
where FichierTS = @FichierTS and i.LigneStatut<>99 
and IsNumeric(optin_m)=0

update #T_Rejets set rejetCode = i.rejetCode | POWER(cast(2 as bigint),26)
from #T_Rejets i
where FichierTS = @FichierTS and i.LigneStatut<>99 
and Cast(case when isnumeric(i.optin_m)=0 then 0 else i.optin_m end as int)  not in (0,1) 
and i.rejetCode & POWER(cast(2 as bigint),26)<>POWER(cast(2 as bigint),26)

--optin-p
update #T_Rejets set rejetCode = i.rejetCode | POWER(cast(2 as bigint),27)
from #T_Rejets i
where FichierTS = @FichierTS and i.LigneStatut<>99 
and IsNumeric(optin_p)=0

update #T_Rejets set rejetCode = i.rejetCode | POWER(cast(2 as bigint),27)
from #T_Rejets i
where FichierTS = @FichierTS and i.LigneStatut<>99 
and Cast(case when isnumeric(i.optin_p)=0 then 0 else i.optin_p end as int) not in (0,1) 
and i.rejetCode & POWER(cast(2 as bigint),27)<>POWER(cast(2 as bigint),27)

--source_id
update #T_Rejets set rejetCode = i.rejetCode | POWER(cast(2 as bigint),28)
from #T_Rejets i
where FichierTS = @FichierTS and i.LigneStatut<>99 
and IsNumeric(source_id)=0

update #T_Rejets set rejetCode = i.rejetCode | POWER(cast(2 as bigint),28)
from #T_Rejets i
where FichierTS = @FichierTS and i.LigneStatut<>99 
and Cast(case when isnumeric(i.source_id)=0 then 0 else i.source_id end as int) not in (101,102) 
and i.rejetCode & POWER(cast(2 as bigint),28)<>POWER(cast(2 as bigint),28)

--fichier_id
update #T_Rejets set rejetCode = i.rejetCode | POWER(cast(2 as bigint),29)
from #T_Rejets i
where FichierTS = @FichierTS and i.LigneStatut<>99 
and fichier_id is null

update #T_Rejets set LigneStatut = case when RejetCode = 0 then 0 else 1 end where FichierTS = @FichierTS and LigneStatut != 99 

insert into rejet.HF_Fiext select * from #T_Rejets where LigneStatut = 1 and FichierTS = @FichierTS 

create unique index idx01_ImportID on #T_Rejets (ImportID)

update a 
set LigneStatut=b.LigneStatut, RejetCode=b.RejetCode
from import.HF_Fiext a inner join #T_Rejets b on a.ImportID=b.ImportID

if OBJECT_ID('tempdb..#T_Rejets') is not null
	drop table #T_Rejets


end

GO


