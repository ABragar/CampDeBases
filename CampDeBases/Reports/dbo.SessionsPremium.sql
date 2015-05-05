USE [AmauryVUC]
GO

/****** Object:  Table [dbo].[SessionsPremium]    Script Date: 05/05/2015 10:22:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[SessionsPremium](
	[ProfilID] [int] NULL,
	[MasterID] [int] NULL,
	[SiteWebID] [int] NULL,
	[DateVisite] [date] NULL,
	[CodeMobileOS] [int] NULL,
	[CodeTabletteOS] [int] NULL,
	[AutreOS] [nvarchar](255) NULL,
	[TraiteTop] [bit] NULL
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[SessionsPremium] ADD  DEFAULT ((0)) FOR [TraiteTop]
GO


