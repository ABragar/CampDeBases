USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [export].[Bcp_ATOS_ConsentEmails]    Script Date: 08/19/2015 11:10:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc [export].[Bcp_ATOS_ConsentEmails]
as

select distinct N'"' as SeparateurInitial 
, e.ActionID 
, a.ConsentementID
, a.MasterID
, a.ContenuID
, replace(a.Email, '"', '""""') as Email
, convert(nvarchar(10),a.ConsentementDate,103) as ConsentementDate
, convert(nvarchar(10),a.DernierClickDate,103) as DernierClickDate
, convert(nvarchar(10),a.DernierEnvoiDate,103) as DernierEnvoiDate
, convert(nvarchar(10),a.DerniereOuvertureDate,103) as DerniereOuvertureDate
, convert(nvarchar(10),a.ClicksNb) as ClicksNb
, convert(nvarchar(10),a.EnvoisNb) as EnvoisNb
, convert(nvarchar(10),a.OuverturesNb) as OuverturesNb
, convert(nvarchar(10),a.ClicksTx) as ClicksTx
, convert(nvarchar(10),a.ReactionsTx) as ReactionsTx
, convert(nvarchar(10),a.OuverturesTx) as OuverturesTx
, a.Valeur
from dbo.ConsentementsEmail a 
inner join ref.Contenus b on a.ContenuID=b.ContenuID
inner join brut.ConsentementsEmail c on a.Email=c.Email and a.ContenuID=c.ContenuID and a.Valeur=c.Valeur
inner join brut.Contacts d on c.ProfilID=d.ProfilID
inner join export.ActionID_ATOS_ConsentEmails e on a.ConsentementID=e.ConsentementID
where b.TypeContenu=3
and d.SourceID in (1,2,4,5,6)


