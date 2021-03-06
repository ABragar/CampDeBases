USE [AmauryVUC]
GO
/****** Object:  Table [etl].[VisitesWeb]    Script Date: 28/08/2015 12:03:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [etl].[VisitesWeb](
	[VisiteId] [int] IDENTITY(1,1) NOT NULL,
	[ProfilID] [int] NULL,
	[MasterID] [int] NULL,
	[SiteId] [int] NULL,
	[Duree] [int] NULL,
	[DateVisite] [datetime] NULL,
	[FinVisite] [datetime] NULL,
	[PagesNb] [int] NULL,
	[PagesPremiumNb] [int] NULL,
	[TraiteTop] [bit] NULL CONSTRAINT [DF_VisitesWeb_TraiteTop]  DEFAULT ((0)),
	[CodeOS] [int] NULL,
	[DeviceTYpe] [int] NULL,
	[XitiSession] [int] NULL,
	[TypeAbo] [int] NULL CONSTRAINT [dv_typeabo]  DEFAULT ((0)),
	[OptinEditorial] [int] NULL CONSTRAINT [dv_optineditorial]  DEFAULT ((0)),
 CONSTRAINT [PK__Visites_VWW] PRIMARY KEY CLUSTERED 
(
	[VisiteId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Index [IX_SQL_DV_VIDMIDSIDPNBPPNB]    Script Date: 28/08/2015 12:03:45 ******/
CREATE NONCLUSTERED INDEX [IX_SQL_DV_VIDMIDSIDPNBPPNB] ON [etl].[VisitesWeb]
(
	[DateVisite] ASC
)
INCLUDE ( 	[VisiteId],
	[MasterID],
	[SiteId],
	[PagesNb],
	[PagesPremiumNb],
	[FinVisite],
	[TypeAbo],
	[OptinEditorial]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_SQL_MID_VIDSIDDV]    Script Date: 28/08/2015 12:03:45 ******/
CREATE NONCLUSTERED INDEX [IX_SQL_MID_VIDSIDDV] ON [etl].[VisitesWeb]
(
	[MasterID] ASC
)
INCLUDE ( 	[VisiteId],
	[SiteId],
	[DateVisite]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
