USE AmauryVUC
GO

/****** Object:  Table report.RefGraphDashboard_Num    Script Date: 04/20/2015 18:11:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

if object_id(N'report.RefGraphDashboard_Num') is not null
	drop table report.RefGraphDashboard_Num
go


CREATE TABLE report.RefGraphDashboard_Num
(
	IdGraph int NOT NULL,
	NomGraph nvarchar(255) NULL,
	Rubrique nvarchar(255) NULL
)

GO


