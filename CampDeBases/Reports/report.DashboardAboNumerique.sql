USE AmauryVUC
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

if object_id(N'report.DashboardAboNumerique') is not null
	drop table report.DashboardAboNumerique
go

CREATE TABLE report.DashboardAboNumerique
(
	Id int IDENTITY(1,1) NOT NULL,
	Periode nvarchar(255) NULL,
	IdPeriode uniqueidentifier NULL,
	IdOwner uniqueidentifier NULL,
	IdTemplate uniqueidentifier NULL,
	SnapshotDate datetime NULL,
	IdGraph int NULL,
	Editeur nvarchar(8) NULL,
	Libelle nvarchar(255) NULL,
	NumOrdre int NULL,
	ValeurInt int NULL,
	ValeurDate datetime NULL,
	ValeurFloat float NULL,
	ValeurChar nvarchar(255) NULL
) 

GO


