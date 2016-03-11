USE [AmauryVUC]
GO

/****** Object:  Table [rejet].[LPPROSP_Prospects]    Script Date: 17.10.2015 10:31:54 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [rejet].[LPPROSP_Prospects](
	[RejetCode] [bigint] NULL,
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
	[optin_newsletter_thematique_ile_de_france] [nvarchar](3) NULL,
	[optin_newsletter_thematique_paris] [nvarchar](3) NULL,
	[optin_newsletter_thematique_seine_et_marne] [nvarchar](3) NULL,
	[optin_newsletter_thematique_yvelines] [nvarchar](3) NULL,
	[optin_newsletter_thematique_essonne] [nvarchar](3) NULL,
	[optin_newsletter_thematique_hauts_de_seine] [nvarchar](3) NULL,
	[optin_newsletter_thematique_seine_st_denis] [nvarchar](3) NULL,
	[optin_newsletter_thematique_val_de_marne] [nvarchar](3) NULL,
	[optin_newsletter_thematique_val_oise] [nvarchar](3) NULL,
	[optin_newsletter_thematique_oise] [nvarchar](3) NULL,
	[optin_newsletter_thematique_medias_people] [nvarchar](3) NULL,
	[optin_newsletter_thematique_tv] [nvarchar](3) NULL,
	[optin_newsletter_thematique_environnement] [nvarchar](3) NULL,
	[LigneStatut] [int] NULL,
	[FichierTS] [nvarchar](255) NULL,
	[ImportID] [int] NULL
	
) ON [PRIMARY]

GO


