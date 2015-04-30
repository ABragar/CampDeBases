USE AmauryVUC
GO

/****** Object:  Table report.RefPeriodeOwnerDB_Num    Script Date: 04/27/2015 18:39:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

if object_id(N'report.RefPeriodeOwnerDB_Num') is not null
	drop table report.RefPeriodeOwnerDB_Num
go

CREATE TABLE report.RefPeriodeOwnerDB_Num
(
	LigneID int IDENTITY(1,1) NOT NULL,
	IdPeriode uniqueidentifier NOT NULL,
	Periode nvarchar(30) NULL,
	Editeur nvarchar(8) NULL,
	IdOwner uniqueidentifier NOT NULL,
	IdTemplate uniqueidentifier NOT NULL,
	SnapshotDate datetime NULL,
	DebutPeriod date NULL,
	FinPeriod date NULL
) 
GO


