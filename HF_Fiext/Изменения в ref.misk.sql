
declare @f nvarchar(255)
set @f = N'D:\Projects\Camp de bases\FIEXT-18112014.csv'
--exec [import].[rejeterHF_Fiext] @f

EXEC import.publierHF_Fiext @f

----select 1 where cast(N'a' as int)=1 and 1=2

--if OBJECT_ID('tempdb..#T_Rejets') is not null
--	drop table #T_Rejets

--select * into #T_Rejets from import.HF_Fiext where FichierTS = @FichierTS and LigneStatut<>99

----source_id
--update #T_Rejets set rejetCode = i.rejetCode | POWER(cast(2 as bigint),28)
--from #T_Rejets i
--where i.LigneStatut<>99 
--and IsNumeric(source_id)=0
---- (55 row(s) affected)

--select * from #T_Rejets i where i.rejetCode & POWER(cast(2 as bigint),28)<>POWER(cast(2 as bigint),28)
---- (4890 row(s) affected)

--select count(*),i.source_id from #T_Rejets i where i.rejetCode & POWER(cast(2 as bigint),28)<>POWER(cast(2 as bigint),28)
--group by i.source_id


--update #T_Rejets set rejetCode = i.rejetCode | POWER(cast(2 as bigint),28)
--from #T_Rejets i inner join (select i.importid from #T_Rejets i
--where i.LigneStatut<>99 
--and i.rejetCode & POWER(cast(2 as bigint),28)<>POWER(cast(2 as bigint),28)
--) as r1 on i.ImportID=r1.ImportID
--where Cast(case when isnumeric(i.source_id)=0 then 0 else i.source_id end as int) not in (101,102) 

select * from ref.Misc a
where a.TypeRef=N'MARQUE'

select * from ref.Misc a
where a.TypeRef=N'TYPECTNU'

select * from ref.Misc a
where a.TypeRef=N'CSP'


select * from ref.Contenus a

insert into ref.misc (TypeRef, CodeValN, Valeur) values ('SOUSSOURCE',101,'PROSPECT'),('SOUSSOURCE',102, 'CONCOURS')

select * from [import].[RejetCodeDetail] (N'HF_Fiext' , 436338688)
