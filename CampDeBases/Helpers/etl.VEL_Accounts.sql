use AmauryVUC
go

if object_id(N'etl.VEL_Accounts') is not null
	drop table etl.VEL_Accounts

create table etl.VEL_Accounts
(
ClientUserId nvarchar(18) null
, ProfilID int null
, EmailAddress nvarchar(255) null
, SourceID int null
, Valid bit not null default(0)
)
go

create index idx01_VEL_Accounts_ClientUserId on etl.VEL_Accounts (ClientUserId)
go
create index idx02_VEL_Accounts_ProfilID on etl.VEL_Accounts (ProfilID)
go


