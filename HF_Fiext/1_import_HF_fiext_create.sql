USE [AmauryVUC]
GO

/****** Object:  Table [import].[NEO_NmsDelivery]    Script Date: 20.03.2015 14:29:19 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [import].[HF_fiext](
	[RejetCode] [bigint] NOT NULL,

	RAISON_SOCIALE [nvarchar](255) NULL,
	CIVILITE [nvarchar](255) NULL,
	PRENOM [nvarchar](255) NULL,
	NOM [nvarchar](255) NULL,
	GENRE	[nvarchar](255) NULL,
	DATE_NAISSANCE	[nvarchar](255) NULL,
	CATEGORIE_SOCIOPRO	[nvarchar](255) NULL,
	TYPE_HABITATION	[nvarchar](255) NULL,
	ADRESSE1	[nvarchar](255) NULL,
	ADRESSE2	[nvarchar](255) NULL,
	ADRESSE3	[nvarchar](255) NULL,
	ADRESSE4	[nvarchar](255) NULL,
	CODE_POSTAL	[nvarchar](255) NULL,
	COMMUNE	[nvarchar](255) NULL,
	PAYS	[nvarchar](255) NULL,
	STOP_ADRESSE_POSTAL	[nvarchar](255) NULL,
	DATE_STOP_ADRESSEPOSTAL	[nvarchar](255) NULL,
	TEL_FIXE	[nvarchar](255) NULL,
	STOP_TEL_FIXE	[nvarchar](255) NULL,
	TEL_MOBILE	[nvarchar](255) NULL,
	STOP_TEL_MOBILE	[nvarchar](255) NULL,
	DATE_ANCIENNETE	[nvarchar](255) NULL,
	DATE_MODIFICATION	[nvarchar](255) NULL,
	EMAIL	[nvarchar](255) NULL,
	MARQUE_ID	[nvarchar](255) NULL,
	OPTIN_M	[nvarchar](255) NULL,
	OPTIN_P	[nvarchar](255) NULL,
	SOURCE_ID	[nvarchar](255) NULL,
	FICHIER_ID [nvarchar](255) NULL,

	[LigneStatut] [int] NOT NULL,
	[FichierTS] [nvarchar](255) NULL,
	[ImportID] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]

GO

ALTER TABLE [import].[HF_fiext] ADD  DEFAULT ((0)) FOR [RejetCode]
GO

ALTER TABLE [import].[HF_fiext] ADD  DEFAULT ((0)) FOR [LigneStatut]
GO


