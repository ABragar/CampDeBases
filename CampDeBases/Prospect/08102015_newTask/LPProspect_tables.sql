USE [AmauryVUC]
GO

/****** Object:  Table [import].[LPPROSP_Prospects]    Script Date: 07/10/2015 17:43:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [import].[LPPROSP_Prospects](
	[RejetCode] [bigint] NOT NULL CONSTRAINT [DF__LPPROSP_P__Rejet__44952D46]  DEFAULT ((0)),
	[datejoin] [nvarchar](32) NULL,
	[email_origine] [nvarchar](255) NULL,
	[email_courant] [nvarchar](255) NULL,
	[username] [nvarchar](255) NULL,
	[civilite] [nvarchar](16) NULL,
	[nom] [nvarchar](255) NULL,
	[prenom] [nvarchar](255) NULL,
	[date_de_naissance] [nvarchar](32) NULL,
	[adresse] [nvarchar](255) NULL,
	[code_postal] [nvarchar](16) NULL,
	[ville] [nvarchar](255) NULL,
	[pays] [nvarchar](255) NULL,
	[telephone_particulier] [nvarchar](255) NULL,
	[optin_leparisien] [nvarchar](3) NULL,
	[optin_partenaire] [nvarchar](3) NULL,
	[optin_newsletter] [nvarchar](3) NULL,
	[optin_alerte] [nvarchar](3) NULL,
	[optin_aujourdhui_etudiant] [nvarchar](3) NULL,
	[date_souscrip_optin_leparisien] [nvarchar](32) NULL,
	[date_resil_optin_leparisien] [nvarchar](32) NULL,
	[date_souscrip_optin_partenaire] [nvarchar](32) NULL,
	[date_resil_optin_partenaire] [nvarchar](32) NULL,
	[date_souscrip_optin_newsletter] [nvarchar](32) NULL,
	[date_resil_optin_newsletter] [nvarchar](32) NULL,
	[date_souscrip_optin_alerte] [nvarchar](32) NULL,
	[date_resil_optin_alerte] [nvarchar](32) NULL,
	[date_souscr_optin_auj_etudiant] [nvarchar](32) NULL,
	[date_resil_optin_auj_etudiant] [nvarchar](32) NULL,
	[date_modif_profil] [nvarchar](32) NULL,
	[source_recrutement] [nvarchar](255) NULL,
	[source_detail_jc] [nvarchar](255) NULL,
	[marque_mobile] [nvarchar](255) NULL,
	[modele_mobile] [nvarchar](255) NULL,
	[optin_news_them_laparisienne] [nvarchar](3) NULL,
	[optin_news_them_politique] [nvarchar](3) NULL,
	[optin_news_them_psg] [nvarchar](3) NULL,
	[optin_news_them_loisirs] [nvarchar](3) NULL,
	[date_souscr_nl_thematique] [nvarchar](32) NULL,
	[date_resiliation_nl_thematique] [nvarchar](32) NULL,
	[LigneStatut] [int] NOT NULL CONSTRAINT [DF__LPPROSP_P__Ligne__4589517F]  DEFAULT ((0)),
	[FichierTS] [nvarchar](255) NULL,
	[ImportID] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]

GO

/****** Object:  Table [import].[Prospects_Cumul]    Script Date: 07/10/2015 17:43:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [import].[Prospects_Cumul](
	[RejetCode] [bigint] NOT NULL CONSTRAINT [DF__Prospects__Rejet__0682EC34]  DEFAULT ((0)),
	[datejoin] [nvarchar](32) NULL,
	[email_origine] [nvarchar](255) NULL,
	[email_courant] [nvarchar](255) NULL,
	[username] [nvarchar](255) NULL,
	[civilite] [nvarchar](16) NULL,
	[nom] [nvarchar](255) NULL,
	[prenom] [nvarchar](255) NULL,
	[date_de_naissance] [nvarchar](32) NULL,
	[adresse] [nvarchar](255) NULL,
	[code_postal] [nvarchar](16) NULL,
	[ville] [nvarchar](255) NULL,
	[pays] [nvarchar](255) NULL,
	[telephone_particulier] [nvarchar](255) NULL,
	[optin_leparisien] [nvarchar](3) NULL,
	[optin_partenaire] [nvarchar](3) NULL,
	[optin_newsletter] [nvarchar](3) NULL,
	[optin_alerte] [nvarchar](3) NULL,
	[optin_aujourdhui_etudiant] [nvarchar](3) NULL,
	[date_souscrip_optin_leparisien] [nvarchar](32) NULL,
	[date_resil_optin_leparisien] [nvarchar](32) NULL,
	[date_souscrip_optin_partenaire] [nvarchar](32) NULL,
	[date_resil_optin_partenaire] [nvarchar](32) NULL,
	[date_souscrip_optin_newsletter] [nvarchar](32) NULL,
	[date_resil_optin_newsletter] [nvarchar](32) NULL,
	[date_souscrip_optin_alerte] [nvarchar](32) NULL,
	[date_resil_optin_alerte] [nvarchar](32) NULL,
	[date_souscr_optin_auj_etudiant] [nvarchar](32) NULL,
	[date_resil_optin_auj_etudiant] [nvarchar](32) NULL,
	[date_modif_profil] [nvarchar](32) NULL,
	[source_recrutement] [nvarchar](255) NULL,
	[source_detail_jc] [nvarchar](255) NULL,
	[marque_mobile] [nvarchar](255) NULL,
	[modele_mobile] [nvarchar](255) NULL,
	[optin_news_them_laparisienne] [nvarchar](3) NULL,
	[optin_news_them_politique] [nvarchar](3) NULL,
	[optin_news_them_psg] [nvarchar](3) NULL,
	[optin_news_them_loisirs] [nvarchar](3) NULL,
	[date_souscr_nl_thematique] [nvarchar](32) NULL,
	[date_resiliation_nl_thematique] [nvarchar](32) NULL,
	[ModifieTop] [bit] NOT NULL CONSTRAINT [DF__Prospects__Modif__0777106D]  DEFAULT ((0)),
	[LigneStatut] [int] NOT NULL CONSTRAINT [DF__Prospects__Ligne__086B34A6]  DEFAULT ((0)),
	[FichierTS] [nvarchar](255) NULL,
	[ImportID] [int] IDENTITY(1,1) NOT NULL,
	[ModifOptin] [bit] NOT NULL CONSTRAINT [DF__Prospects__Modif__37661AB1]  DEFAULT ((0)),
	[ModifProfil] [bit] NOT NULL CONSTRAINT [DF__Prospects__Modif__385A3EEA]  DEFAULT ((0))
) ON [PRIMARY]

GO


