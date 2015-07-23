use AmauryVUC
go

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
                INNER JOIN ref.SitesWeb  AS sw
                     ON  vw.SiteId = sw.WebSiteID
         WHERE  masterId IS NOT NULL
         GROUP BY
                vw.MasterID
               ,marque
               ,Appartenance
         HAVING MIN(vw.DateVisite) >= DATEADD(MONTH ,-1 ,GETDATE())
     )
,VIM AS (
SELECT 86      AS TypologieID
      ,masterID
      ,marque  AS MarqueID
      ,Appartenance
FROM   firstVisite
GROUP BY
       masterID
      ,marque
      ,Appartenance
)
,VIE AS 
(
SELECT CASE 
            WHEN x.marqueID <> VIM.MarqueID THEN 89 --VIE
            ELSE VIM.TypologieID						--VIM
       END  AS Typologie
      ,MasterID
      ,x.MarqueID
FROM   VIM
       CROSS APPLY (
    SELECT Marque        AS MarqueID
    ,sw.Appartenance
    FROM   ref.SitesWeb  AS sw
    WHERE  sw.Appartenance = VIM.Appartenance
    GROUP BY
           sw.Marque, sw.Appartenance
)              x
)
select * from VIE as a where MasterID in (
select distinct MasterID from (
SELECT COUNT(*) as N, a.MasterID, a.Typologie FROM VIE as a where a.Typologie=86
and a.MarqueID not in (2,6)
group by a.MasterID, a.Typologie
having COUNT(*)>1
) as r1
)
order by a.MasterID, a.MarqueID
