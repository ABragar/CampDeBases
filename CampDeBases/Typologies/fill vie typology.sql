/************************************************************
 * Code formatted by SoftTree SQL Assistant © v7.2.338
 * Time: 09.07.2015 13:25:13
 ************************************************************/

USE AmauryVUC
GO
IF OBJECT_ID('tempdb..#T_Vim') IS NOT NULL
    DROP TABLE #T_Vim
	
CREATE TABLE #T_Vim
(
	TypologieID      INT NOT NULL
   ,MasterID         INT NULL
   ,MarqueID         INT NULL
   ,Appartenance     INT NULL
)

IF OBJECT_ID('tempdb..#T_Vie') IS NOT NULL
    DROP TABLE #T_Vie
	
CREATE TABLE #T_Vie
(
	TypologieID     INT NOT NULL
   ,MasterID        INT NULL
   ,MarqueID        INT NULL
)

	--VI
	--VIMN 
;
WITH firstVisite AS (
         SELECT masterID
               ,marque
               ,sw.Appartenance
               ,MIN(vw.DateVisite)          minDateVisite
         FROM   etl.VisitesWeb           AS vw
                INNER JOIN ref.SitesWeb  AS sw
                     ON  vw.SiteId = sw.WebSiteID
         WHERE  masterId IS NOT NULL
         GROUP BY
                vw.MasterID
               ,marque
               ,Appartenance
         HAVING MIN(vw.DateVisite) >= DATEADD(MONTH ,-1 ,GETDATE())
     )

INSERT INTO #T_Vim
  (
    TypologieID
   ,MasterID
   ,MarqueID
   ,Appartenance
  )
SELECT 86      AS TypologieID
      ,masterID
      ,marque  AS MarqueID
      ,Appartenance
FROM   firstVisite
GROUP BY
       masterID
      ,marque
      ,Appartenance

	--VIMA
;
WITH ACTIVE AS (
         SELECT masterID
               ,marque
               ,sw.Appartenance
               ,MAX(vw.DateVisite)          maxDateVisite
         FROM   etl.VisitesWeb           AS vw
                INNER JOIN ref.SitesWeb  AS sw
                     ON  vw.SiteId = sw.WebSiteID
         WHERE  masterId IS NOT NULL
         GROUP BY
                vw.MasterID
               ,marque
               ,sw.Appartenance
         HAVING MAX(vw.DateVisite) >= DATEADD(MONTH ,-6 ,GETDATE())
         AND MAX(vw.DateVisite) < DATEADD(MONTH ,-1 ,GETDATE())
     )

INSERT INTO #T_Vim
  (
    TypologieID
   ,MasterID
   ,MarqueID
   ,Appartenance
  )
SELECT 87      AS TypologieID
      ,masterID
      ,marque  AS MarqueID
      ,Appartenance
FROM   ACTIVE
GROUP BY
       masterID
      ,marque
      ,Appartenance
	
	--VIMI       
;
WITH inactive AS (
         SELECT masterID
               ,marque
               ,sw.Appartenance
               ,MAX(vw.DateVisite)          MaxDateVisite
         FROM   etl.VisitesWeb           AS vw
                INNER JOIN ref.SitesWeb  AS sw
                     ON  vw.SiteId = sw.WebSiteID
         WHERE  masterId IS NOT NULL
         GROUP BY
                vw.MasterID
               ,marque
               ,sw.Appartenance
         HAVING MAX(vw.DateVisite) < DATEADD(MONTH ,-6 ,GETDATE())
     )

INSERT INTO #T_Vim
  (
    TypologieID
   ,MasterID
   ,MarqueID
   ,Appartenance
  )
SELECT 88      AS TypologieID
      ,masterID
      ,marque  AS MarqueID
      ,Appartenance
FROM   inactive
GROUP BY
       masterID
      ,marque
      ,Appartenance

CREATE INDEX idx_masterID ON #T_Vim(MasterID)
GO

INSERT INTO #T_Vie
  (
    TypologieID
   ,MasterID
   ,MarqueID
  )
SELECT DISTINCT CASE 
                     WHEN x.marqueID <> v1.MarqueID THEN v1.TypologieID + 3 --VIE
                     ELSE v1.TypologieID --VIM
                END AS Typologie
      ,v1.MasterID
      ,x.MarqueID
FROM   #T_Vim v1
       CROSS APPLY (
    SELECT CodeValN  AS MarqueID
          ,sw.Appartenance
    FROM   ref.Misc  AS sw
    WHERE  TypeRef = N'MARQUE'
           AND sw.Appartenance = v1.Appartenance
           AND sw.CodeValN NOT IN (SELECT MarqueID
                                   FROM   #T_Vim v2
                                   WHERE  v2.masterID = v1.masterId)
    GROUP BY
           sw.CodeValN
          ,sw.Appartenance
) x
INNER JOIN dbo.LienAvecMarques L
            ON  l.MasterID = v1.MasterID
                AND l.MarqueID = x.MarqueID


--90 A
DELETE t2
FROM   #T_Vie t1
       INNER JOIN #T_Vie t2
            ON  t1.MasterID = t2.MasterID
                AND t1.marqueId = t2.marqueId
                AND t1.TypologieID = 90
                AND t2.TypologieID IN (89 ,91)

--89
DELETE t2
FROM   #T_Vie t1
       INNER JOIN #T_Vie t2
            ON  t1.MasterID = t2.MasterID
                AND t1.marqueId = t2.marqueId
                AND t1.TypologieID = 89
                AND t2.TypologieID = 91


INSERT INTO #T_Lignes_Typologies
  (
    TypologieID
   ,MasterID
   ,MarqueID
  )
SELECT tv.TypologieID
      ,tv.MasterID
      ,tv.MarqueID
FROM   #T_Vim AS tv

INSERT INTO #T_Lignes_Typologies
  (
    TypologieID
   ,MasterID
   ,MarqueID
  )
SELECT tv.TypologieID
      ,tv.MasterID
      ,tv.MarqueID
FROM   #T_Vie AS tv