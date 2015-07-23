--VIMN 
;WITH firstVisite as (SELECT masterID,marque, MIN(vw.DateVisite) minDateVisite
FROM etl.VisitesWeb AS vw
INNER JOIN ref.SitesWeb AS sw
                       ON  vw.SiteId = sw.WebSiteID
WHERE  masterId IS NOT NULL
GROUP BY vw.MasterID,marque
HAVING MIN(vw.DateVisite) >= DATEADD(MONTH ,-1 ,GETDATE()))
, xxx AS (
SELECT vw.masterID, marque, DateVisite
FROM etl.VisitesWeb vw
INNER JOIN firstVisite f ON f.masterID = vw.MasterID AND minDateVisite = vw.DateVisite 
)       
SELECT masterID, marque FROM xxx
GROUP BY masterID, marque

--VIMA       
;WITH firstVisite as (SELECT masterID,marque, MAX(vw.DateVisite) maxDateVisite
FROM etl.VisitesWeb AS vw
INNER JOIN ref.SitesWeb AS sw
                       ON  vw.SiteId = sw.WebSiteID
WHERE  masterId IS NOT NULL
GROUP BY vw.MasterID,marque
HAVING MAX(vw.DateVisite) >= DATEADD(MONTH ,-6 ,GETDATE()) AND MAX(vw.DateVisite) <= DATEADD(MONTH ,-1 ,GETDATE()))
, xxx AS (
SELECT vw.masterID, marque, DateVisite
FROM etl.VisitesWeb vw
INNER JOIN firstVisite f ON f.masterID = vw.MasterID AND maxDateVisite = vw.DateVisite 
)       
SELECT masterID, marque FROM xxx
GROUP BY masterID, marque       

--VIMI       
;WITH firstVisite as (SELECT masterID,marque, MAX(vw.DateVisite) MaxDateVisite
FROM etl.VisitesWeb AS vw
INNER JOIN ref.SitesWeb AS sw
                       ON  vw.SiteId = sw.WebSiteID
WHERE  masterId IS NOT NULL
GROUP BY vw.MasterID,marque
HAVING MAX(vw.DateVisite) <= DATEADD(MONTH ,-6 ,GETDATE()))
, xxx AS (
SELECT vw.masterID, marque, DateVisite
FROM etl.VisitesWeb vw
INNER JOIN firstVisite f ON f.masterID = vw.MasterID AND maxDateVisite = vw.DateVisite 
)       
SELECT masterID, marque FROM xxx
GROUP BY masterID, marque
       
--VIEN       
;WITH firstVisite as (SELECT masterID,Appartenance, MIN(vw.DateVisite) minDateVisite
FROM etl.VisitesWeb AS vw
INNER JOIN ref.SitesWeb AS sw
                       ON  vw.SiteId = sw.WebSiteID
WHERE  masterId IS NOT NULL
GROUP BY vw.MasterID,Appartenance
HAVING MIN(vw.DateVisite) >= DATEADD(MONTH ,-1 ,GETDATE()))
, xxx AS (
SELECT vw.masterID, Appartenance, DateVisite
FROM etl.VisitesWeb vw
INNER JOIN firstVisite f ON f.masterID = vw.MasterID AND minDateVisite = vw.DateVisite 
)       
SELECT masterID, Appartenance FROM xxx
GROUP BY masterID, Appartenance

--VIEA       
;WITH firstVisite as (SELECT masterID,Appartenance, MAX(vw.DateVisite) maxDateVisite
FROM etl.VisitesWeb AS vw
INNER JOIN ref.SitesWeb AS sw
                       ON  vw.SiteId = sw.WebSiteID
WHERE  masterId IS NOT NULL
GROUP BY vw.MasterID,Appartenance
HAVING MAX(vw.DateVisite) >= DATEADD(MONTH ,-6 ,GETDATE()) AND MAX(vw.DateVisite) <= DATEADD(MONTH ,-1 ,GETDATE()))
, xxx AS (
SELECT vw.masterID, Appartenance, DateVisite
FROM etl.VisitesWeb vw
INNER JOIN firstVisite f ON f.masterID = vw.MasterID AND maxDateVisite = vw.DateVisite 
)       
SELECT masterID, Appartenance FROM xxx
GROUP BY masterID, Appartenance       

--VIEI       
;WITH firstVisite as (SELECT masterID,Appartenance, MAX(vw.DateVisite) MaxDateVisite
FROM etl.VisitesWeb AS vw
INNER JOIN ref.SitesWeb AS sw
                       ON  vw.SiteId = sw.WebSiteID
WHERE  masterId IS NOT NULL
GROUP BY vw.MasterID,Appartenance
HAVING MAX(vw.DateVisite) <= DATEADD(MONTH ,-6 ,GETDATE()))
, xxx AS (
SELECT vw.masterID, Appartenance, DateVisite
FROM etl.VisitesWeb vw
INNER JOIN firstVisite f ON f.masterID = vw.MasterID AND maxDateVisite = vw.DateVisite 
)       
SELECT masterID, Appartenance FROM xxx
GROUP BY masterID, Appartenance



