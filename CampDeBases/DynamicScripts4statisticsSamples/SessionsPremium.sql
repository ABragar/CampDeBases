USE [AmauryVUC]
GO
/****** Object:  Table [dbo].[SessionsPremium]    Script Date: 09/06/2015 12:13:36 ******/
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
	[TraiteTop] [bit] NULL DEFAULT ((0))
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_MID_OS]    Script Date: 09/06/2015 12:13:37 ******/
CREATE NONCLUSTERED INDEX [IX_MID_OS] ON [dbo].[SessionsPremium]
(
	[MasterID] ASC
)
INCLUDE ( 	[CodeMobileOS],
	[CodeTabletteOS],
	[AutreOS]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_MID_SID]    Script Date: 09/06/2015 12:13:37 ******/
CREATE NONCLUSTERED INDEX [IX_MID_SID] ON [dbo].[SessionsPremium]
(
	[MasterID] ASC,
	[SiteWebID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_PID]    Script Date: 09/06/2015 12:13:37 ******/
CREATE NONCLUSTERED INDEX [IX_PID] ON [dbo].[SessionsPremium]
(
	[ProfilID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
