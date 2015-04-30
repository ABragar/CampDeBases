USE [Kayak]
GO

/****** Object:  Table [dbo].[DashboardValues]    Script Date: 04/28/2015 15:12:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DashboardValues](
	[Id] [uniqueidentifier] NOT NULL,
	[Owner] [uniqueidentifier] NOT NULL,
	[IdTemplate] [uniqueidentifier] NOT NULL,
	[SnapshotDate] [datetime] NOT NULL,
	[Periode] [nvarchar](50) NULL,
	[DebutPeriod] [date] NULL,
	[FinPeriod] [date] NULL,
	[LibellePeriode] [nvarchar](30) NULL,
 CONSTRAINT [PK_DashboardValues_1] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

/*
ALTER TABLE [dbo].[DashboardValues]  WITH CHECK ADD  CONSTRAINT [FK_DashboardValues_Users1] FOREIGN KEY([Owner])
REFERENCES [dbo].[Users] ([Id])
GO

ALTER TABLE [dbo].[DashboardValues] CHECK CONSTRAINT [FK_DashboardValues_Users1]
GO

*/
