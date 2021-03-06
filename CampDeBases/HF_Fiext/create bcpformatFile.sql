USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [import].[GenererFMT_UTF16LE]    Script Date: 20.03.2015 14:45:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER proc [import].[GenererFMT_UTF16LE] (@NomSchema nvarchar(32), @NomTable nvarchar(32))
as

begin

if OBJECT_ID(N'tempdb..#T_FMT') is not null
	drop table #T_FMT

create table #T_FMT (S nvarchar(max) null, N int null)

declare @NLignes int
select @NLignes=COUNT(*) from sys.sysobjects a inner join sys.schemas b on a.uid=b.schema_id
inner join sys.syscolumns c on a.id=c.id
and b.name=@NomSchema
and a.name=@NomTable
and c.name not in (N'RejetCode',N'LigneStatut',N'FichierTS',N'ImportID')

insert #T_FMT (S,N)
select N'10.0' as S, 0 as N
union 
select cast(@NLignes+1 as nvarchar) as S, 1 as N
union
select N'1 SQLCHAR 0 0 "\"\0" 0 Skip French_CI_AS', 2 as N
union
select CAST(c.colid as nvarchar)
	+NCHAR(9)+N'SQLNCHAR'
	+NCHAR(9)+N'0'
	+NCHAR(9)+CAST(c.length as nvarchar)
	+NCHAR(9)+ case when c.colid=@NLignes+1 then N'"\"\0\r\0\n\0"' else N'"\"\0;\0\"\0"' end
	+NCHAR(9)+CAST(c.colid as nvarchar)
	+NCHAR(9)+c.name+NCHAR(9)+NCHAR(9)+N'French_CI_AS' as S, c.colid as N
from sys.sysobjects a inner join sys.schemas b on a.uid=b.schema_id
inner join sys.syscolumns c on a.id=c.id
and b.name=@NomSchema
and a.name=@NomTable
and c.name not in (N'RejetCode',N'LigneStatut',N'FichierTS',N'ImportID')

select S from #T_FMT order by N

-- return 0

select 
N'bcp AmauryVUC.'
+ @NomSchema
+ N'.'
+ @NomTable
+ N' in "C:\Users\anatoli.velitchko\Documents\SQL Server Management Studio\Projects\Amaury\data\Ventes en ligne\Load\'
+ N''
+ @NomTable -- +case when @NomTable in (N'ModeExpedition',N'RefCBValidites') then N'-30092013' else N'-25092013' end
+ '-31072014'
+ N'.csv" -f "C:\Users\anatoli.velitchko\Documents\SQL Server Management Studio\Projects\Amaury\fmt\PVL\'
+ @NomTable
+ N'.fmt"' 
+ ' -e "C:\Users\anatoli.velitchko\Documents\SQL Server Management Studio\Projects\Amaury\data\Ventes en ligne\bcperror\'
+ @NomTable
+ N'.err"'
+ N' -T -F2 -S BO1'

end
