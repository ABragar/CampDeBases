--select * from ref.Misc a where a.TypeRef=N'STATUTABOVEL'

SELECT * FROM Abonnements AS a 
INNER JOIN ref.CatalogueAbonnements AS ca ON a.CatalogueAbosID = ca.CatalogueAbosID AND ca.Recurrent=1	
WHERE a.SubscriptionStatusID = 4
order by finabodate


SELECT * FROM [dbo].[Contacts]	  
SELECT * FROM [dbo].[ContactsOS]			   
SELECT * FROM [dbo].[Contenus]

Select * From sysobjects --Where NAME LIKE '%niveau%'
ORDER BY name
select * FROM [dbo].[ActiviteWeb]

select OBJECT_SCHEMA_NAME(Tab.object_id) AS chema,[Tab].name 
from sys.tables [Tab]
	inner join sys.columns [Col] on [Tab].[object_id] = [Col].[object_id]
Where col.NAME LIKE '%niveau%'

SELECT OBJECT_NAME(1561772621)
SELECT OBJECT_SCHEMA_NAME(1561772621)

SELECT * FROM syscolumns AS s 
Where NAME LIKE '%web%'

SELECT * FROM etl.Xiti_Pages

SELECT * FROM ref.Misc AS m		 

SELECT * FROM [import].[Xiti_Pages]	
SELECT * FROM [import].[Xiti_Sessions]	 
SELECT * FROM [import].[Xiti_Sites]	

SELECT * FROM [ref].[SitesWeb]	
 SELECT * FROM [dbo].[ActiviteWeb]

SELECT aw.MasterID, sw.WebSiteNom, aw.InscriptionDate, aw.DerniereVisiteDate,
       aw.VisitesNb
FROM [dbo].[ActiviteWeb] aw
LEFT JOIN ref.SitesWeb AS sw ON SitewebId = sw.WebSiteID
WHERE DerniereConnexAbonnesDate IS NOT NULL

DECLARE @D DATETIME2
 
select DATEADD(microsecond,-1,CAST ('20150430' AS DATETIME2))

SELECT * FROM report.RefPeriodeOwnerDB_Num

	         SELECT CAST(a.DebutPeriod AS DATETIME) AS DebutPeriod
	               ,CAST(DATEADD(DAY ,1 ,a.FinPeriod) AS DATETIME) AS FinPeriod
	         FROM   report.RefPeriodeOwnerDB_Num a
	         
	         SELECT Cast(3/5 AS FLOAT)
	         
select * from ref.SitesWeb a where a.WebSiteNom like N'%Premium%'

SELECT * FROM Contacts AS c

SELECT * FROM dbo.ActiviteWeb
;


select * from report.RefPeriodeOwnerDB_Num


SELECT * FROM [dbo].[SessionsPremium]

SELECT * FROM OPENROWSET('Microsoft.Jet.OLEDB.4.0',
'Excel 12.0;Database=D:\Projects\Camp de bases\SessionsPremium_15000_2.xls', 'SELECT * FROM [Feuil1$]')

SELECT * into #t FROM OPENROWSET('Microsoft.Jet.OLEDB.4.0', 'Excel 12.0;Database=D:\Projects\Camp de bases\SessionsPremium_15000_2.xls','select * from [Feuil1$]')

Select * INTO #g FROM OPENROWSET('Microsoft.Jet.OLEDB.4.0', 
'Excel 12.0;Database=D:\Projects\Camp de bases\SessionsPremium_15000_2.xls ;HDR=YES', 'SELECT * FROM [Feuil1$]');

--D:\Projects\Camp de bases\SessionsPremium_15000_1.xlsx

