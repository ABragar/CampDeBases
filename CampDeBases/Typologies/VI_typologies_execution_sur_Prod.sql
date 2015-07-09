use AmauryVUC
go

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
-- (14723 row(s) affected)
-- 0'11

--VIMA       
;WITH firstVisite as (SELECT masterID,marque, MAX(vw.DateVisite) maxDateVisite
FROM etl.VisitesWeb AS vw
INNER JOIN ref.SitesWeb AS sw
                       ON  vw.SiteId = sw.WebSiteID
WHERE  masterId IS NOT NULL
GROUP BY vw.MasterID,marque
HAVING MAX(vw.DateVisite) >= DATEADD(MONTH ,-6 ,GETDATE()) AND MAX(vw.DateVisite) < DATEADD(MONTH ,-1 ,GETDATE()))
, xxx AS (
SELECT vw.masterID, marque, DateVisite
FROM etl.VisitesWeb vw
INNER JOIN firstVisite f ON f.masterID = vw.MasterID AND maxDateVisite = vw.DateVisite 
)       
SELECT masterID, marque FROM xxx
GROUP BY masterID, marque      
-- (136570 row(s) affected)
-- 0'15" 

--VIMI       
;WITH firstVisite as (SELECT masterID,marque, MAX(vw.DateVisite) MaxDateVisite
FROM etl.VisitesWeb AS vw
INNER JOIN ref.SitesWeb AS sw
                       ON  vw.SiteId = sw.WebSiteID
WHERE  masterId IS NOT NULL
GROUP BY vw.MasterID,marque
HAVING MAX(vw.DateVisite) < DATEADD(MONTH ,-6 ,GETDATE()))
, xxx AS (
SELECT vw.masterID, marque, DateVisite
FROM etl.VisitesWeb vw
INNER JOIN firstVisite f ON f.masterID = vw.MasterID AND maxDateVisite = vw.DateVisite 
)       
SELECT masterID, marque FROM xxx
GROUP BY masterID, marque
-- (234385 row(s) affected)
-- 0'23"
       
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
-- (14490 row(s) affected)
-- 0'10"

--VIEA       
; WITH firstVisite as (SELECT masterID,Appartenance, MAX(vw.DateVisite) maxDateVisite
FROM etl.VisitesWeb AS vw
INNER JOIN ref.SitesWeb AS sw
                       ON  vw.SiteId = sw.WebSiteID
WHERE  masterId IS NOT NULL
GROUP BY vw.MasterID,Appartenance
HAVING MAX(vw.DateVisite) >= DATEADD(MONTH ,-6 ,GETDATE()) AND MAX(vw.DateVisite) < DATEADD(MONTH ,-1 ,GETDATE()))
, xxx AS (
SELECT vw.masterID, Appartenance, DateVisite
FROM etl.VisitesWeb vw
INNER JOIN firstVisite f ON f.masterID = vw.MasterID AND maxDateVisite = vw.DateVisite 
)       
SELECT masterID, Appartenance FROM xxx
GROUP BY masterID, Appartenance 
-- (135978 row(s) affected)
-- 0'17"      

--VIEI       
; WITH firstVisite as (SELECT masterID,Appartenance, MAX(vw.DateVisite) MaxDateVisite
FROM etl.VisitesWeb AS vw
INNER JOIN ref.SitesWeb AS sw
                       ON  vw.SiteId = sw.WebSiteID
WHERE  masterId IS NOT NULL
GROUP BY vw.MasterID,Appartenance
HAVING MAX(vw.DateVisite) < DATEADD(MONTH ,-6 ,GETDATE()))
, xxx AS (
SELECT vw.masterID, Appartenance, DateVisite
FROM etl.VisitesWeb vw
INNER JOIN firstVisite f ON f.masterID = vw.MasterID AND maxDateVisite = vw.DateVisite 
)       
SELECT masterID, Appartenance FROM xxx
GROUP BY masterID, Appartenance
-- (233906 row(s) affected)
-- 0'23"


