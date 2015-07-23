-- add new optin field
ALTER TABLE import.LPPROSP_Prospects
ADD optin_news_them_psg NVARCHAR(3)
GO

ALTER TABLE import.Prospects_Cumul
ADD optin_news_them_psg NVARCHAR(3)
GO


--first init optin_news_them_psg
insert brut.ConsentementsEmail
(
ProfilID
, MasterID
, Email
, ContenuID
, Valeur
, ConsentementDate
)
select
c.ProfilID
,c.ProfilID
, LEFT(t.email_courant,128)
,rc.ContenuID --,58
,1 as Valeur
,coalesce(date_souscr_nl_thematique,getdate()) as ConsentementDate
from import.LPPROSP_Prospects t
inner join ref.Contenus rc on rc.NomContenu=N'optin_news_them_psg'
inner join brut.Contacts c 
on t.email_courant=c.OriginalID 
and c.SourceID = 4
WHERE optin_news_them_psg = 1
