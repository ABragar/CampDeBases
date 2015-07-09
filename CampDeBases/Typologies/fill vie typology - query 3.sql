USE AmauryVUC
GO
-- проверочная
IF OBJECT_ID('tempdb..#T_Visitors') IS NOT NULL
    DROP TABLE #T_Visitors
	
CREATE TABLE #T_Visitors
(
	MasterID       INT NULL
   ,SiteID         INT
   ,DateVisite     DATETIME
)
TRUNCATE TABLE #T_Visitors
GO

INSERT INTO #T_Visitors
  (
    MasterID
   ,SiteID
   ,DateVisite
  )
VALUES
  (10,548647,GETDATE()),
(10 ,498703 ,GETDATE()),
(11 ,529144 ,GETDATE())
--


IF OBJECT_ID('tempdb..#T_Vim') IS NOT NULL
    DROP TABLE #T_Vim
	
CREATE TABLE #T_Vim
(
	TypologieID      INT NOT NULL
   ,MasterID         INT NULL
   ,MarqueID         INT NULL
   ,Appartenance     INT NULL
)

TRUNCATE TABLE #T_Vim
GO

IF OBJECT_ID('tempdb..#T_Lignes_Typologies') IS NOT NULL
    DROP TABLE #T_Lignes_Typologies
	
CREATE TABLE #T_Lignes_Typologies
(
	TypologieID     INT NOT NULL
   ,MasterID        INT NULL
   ,MarqueID        INT NULL
)

TRUNCATE TABLE #T_Lignes_Typologies
GO

	--VI
	--VIMN 
;
WITH firstVisite AS (
         SELECT masterID
               ,marque
               ,sw.Appartenance
               ,MIN(vw.DateVisite)          minDateVisite
         FROM   etl.VisitesWeb           AS vw 
                --         FROM   #T_Visitors                      AS vw  --проверка
                
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

CREATE INDEX idx_masterID ON #T_Vim(MasterID)

; with VIE as (

           SELECT TypologieID
                 ,MasterID
                 ,MarqueID
           FROM   #T_Vim
           
           UNION ALL
           SELECT DISTINCT CASE 
                                WHEN x.marqueID <> v1.MarqueID THEN 89 --VIE
                                ELSE v1.TypologieID --VIM
                           END AS Typologie
                 ,v1.MasterID
                 ,x.MarqueID
           FROM   #T_Vim v1
                  
                  CROSS APPLY (
               SELECT Marque        AS MarqueID
                     ,sw.Appartenance
               FROM   ref.SitesWeb  AS sw
               WHERE  sw.Appartenance = v1.Appartenance
                      AND sw.Marque NOT IN (SELECT MarqueID
                                            FROM   #T_Vim v2
                                            WHERE  v2.masterID = v1.masterId)
               GROUP BY
                      sw.Marque
                     ,sw.Appartenance
           ) x
           INNER JOIN dbo.LienAvecMarques L
                       ON  l.MasterID = v1.MasterID
                           AND l.MarqueID = x.MarqueID
       )

select * from VIE as a where MasterID in (
select distinct MasterID from (
SELECT COUNT(*) as N, a.MasterID, a.TypologieID FROM VIE as a where a.TypologieID=86
and a.MarqueID not in (2,6)
group by a.MasterID, a.TypologieID
having COUNT(*)>1
) as r1
)
order by a.MasterID, a.MarqueID

-- select * from dbo.LienAvecMarques a where a.MasterID=2984953 and a.MarqueID=1 /* 1=Adrénaline */
-- (0 row(s) affected)


