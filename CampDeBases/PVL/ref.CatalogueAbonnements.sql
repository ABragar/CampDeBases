USE [AmauryVUC]
GO

/****** Object:  Table [ref].[CatalogueAbonnements]    Script Date: 01/11/2016 16:18:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [ref].[CatalogueAbonnements](
	[CatalogueAbosID] [int] IDENTITY(1,1) NOT NULL,
	[OriginalID] [nvarchar](255) NULL,
	[SourceID] [int] NULL,
	[MontantAbo] [decimal](10, 2) NULL,
	[FormuleAbo] [nvarchar](255) NULL,
	[TitreID] [int] NULL,
	[OffreAbo] [nvarchar](255) NULL,
	[OptionOffreAbo] [nvarchar](255) NULL,
	[DureeAbo] [int] NULL,
	[SupportAbo] [int] NULL,
	[Marque] [int] NULL,
	[Couple] [nvarchar](8) NULL,
	[BGroups] [varbinary](200) NULL,
	[Recurrent] [bit] NOT NULL,
	[isCouple] [bit] NULL,
	[Appartenance] [int] NULL,
	[CodeOffre] [nvarchar](8) NULL,
	[CodeTarif] [nvarchar](8) NULL,
	[CodeOption] [nvarchar](8) NULL,
	[CodeSociete] [nvarchar](8) NULL,
	[CodeTitreOption] [nvarchar](8) NULL,
	[PrixInitial] [decimal](10, 2) NULL,
	[PmtConso] [bit] NOT NULL,
	[PmtPosteriori] [bit] NOT NULL,
	[TaciteReconduction] [int] NULL,
	[DureeLibre] [bit] NOT NULL,
	[ServiceGroup] [nvarchar](255) NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [ref].[CatalogueAbonnements] ADD  DEFAULT ((0)) FOR [Recurrent]
GO

ALTER TABLE [ref].[CatalogueAbonnements] ADD  DEFAULT ((0)) FOR [PmtConso]
GO

ALTER TABLE [ref].[CatalogueAbonnements] ADD  DEFAULT ((0)) FOR [PmtPosteriori]
GO

ALTER TABLE [ref].[CatalogueAbonnements] ADD  DEFAULT ((0)) FOR [DureeLibre]
GO


