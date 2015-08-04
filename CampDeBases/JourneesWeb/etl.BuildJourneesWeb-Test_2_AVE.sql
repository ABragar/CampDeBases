use AmauryVUC
go


ALTER PROCEDURE etl.BuildJourneesWeb
AS
BEGIN


	IF OBJECT_ID('tempdb..#T_JourneesWeb') IS NOT NULL
	    DROP TABLE #T_JourneesWeb
	
	CREATE TABLE #T_JourneesWeb
	(
		MasterID               INT NOT NULL
	   ,SiteID                 INT NOT NULL
	   ,DateVisite             DATE NOT NULL
	   ,NbVisites              INT NOT NULL DEFAULT 0
	   ,NbPagesVues            INT NOT NULL DEFAULT 0
	   ,NbPremiumPagesVues     INT NOT NULL DEFAULT 0
	   ,MoyenneDuree           FLOAT NOT NULL DEFAULT 0
	   ,CodeOS                 INT NULL
	   ,OrderOS                INT
	   ,OS                     NVARCHAR(255)
	   ,PremierVisite          DATETIME NOT NULL DEFAULT 0
	   ,DernierVisite          DATETIME NOT NULL DEFAULT 0
	   ,rowNum                 INT
	)
	
	INSERT INTO #T_JourneesWeb
	  (
	    MasterID
	   ,SiteID
	   ,DateVisite
	   ,NbVisites
	   ,NbPagesVues
	   ,NbPremiumPagesVues
	   ,MoyenneDuree
	   ,CodeOS
	   ,OrderOS
	   ,PremierVisite
	   ,DernierVisite
	   ,rowNum
	  )
	SELECT vw.MasterID
	      ,vw.SiteId
	      ,CAST(DateVisite AS DATE)  AS DateVisite
	      ,VisiteId                  AS NbVisites
	      ,PagesNb                   AS NbPagesVues
	      ,PagesPremiumNb            AS NbPremiumPagesVues
	      ,CAST(Duree AS FLOAT)    AS MoyenneDuree
	      ,codeOS
	      ,OrderOS = CASE 
	                      WHEN m.typeRef = N'OSTABLETTE' THEN 1
	                      WHEN m.typeRef = N'OSMOBILE' THEN 2
	                      ELSE 3
	                 END
	      ,DateVisite                AS PremierVisite
	      ,DateVisite                AS DernierVisite
	      ,ROW_NUMBER() OVER(
	           PARTITION BY MasterID
	          ,SiteId
	          ,DateVisite
	          ,FinVisite
	          ,Duree
	          ,PagesNb
	          ,PagesPremiumNb
	          ,XitiSession ORDER BY MasterID
	          ,SiteId
	          ,DateVisite
	          ,CASE 
	                WHEN m.typeRef = N'OSTABLETTE' THEN 1
	                WHEN m.typeRef = N'OSMOBILE' THEN 2
	                ELSE 3
	           END
	       )                            rowNum
	FROM   etl.VisitesWeb            AS vw
	       LEFT JOIN ref.Misc m
	            ON  vw.CodeOS = m.RefID
	where vw.DateVisite between N'20150601' and N'20150630'
	-- (8588193 row(s) affected)
	--(7828570 row(s) affected)
	--WHERE 
	-- NOT (
	--           vw.MasterID IS NULL
	--           OR vw.SiteId IS NULL
	--           OR vw.DateVisite IS NULL
	--       )
	--datevisite >= '20150601'
	--vw.MasterID = 461
	
	CREATE INDEX ix_masterId ON #T_JourneesWeb(MasterID)
	CREATE INDEX ix_siteId ON #T_JourneesWeb(SiteID)
	CREATE INDEX ix_DateVisite ON #T_JourneesWeb(DateVisite)   
	
	select top 1000 * from #T_JourneesWeb
	
	IF OBJECT_ID('tempdb..#T_JourneesWeb_OSDense') IS NOT NULL
	    DROP TABLE #T_JourneesWeb_OSDense
	
	SELECT vw.MasterID
	      ,vw.SiteId
	      ,DateVisite
	      ,COUNT(NbVisites)         AS NbVisites
	      ,SUM(NbPagesVues)         AS NbPagesVues
	      ,SUM(NbPremiumPagesVues)  AS NbPremiumPagesVues
	      ,SUM(CAST(MoyenneDuree AS FLOAT)) AS MoyenneDuree
	      ,vw.CodeOS
	      ,MIN(PremierVisite)       AS PremierVisite
	      ,MAX(DernierVisite)       AS DernierVisite
	      ,ROW_NUMBER() OVER(
	           PARTITION BY MasterID
	          ,SiteID
	          ,datevisite 
	          ORDER BY 
	          COUNT(NbVisites) DESC
	          ,SUM(NbPagesVues) DESC
	          ,SUM(CAST(MoyenneDuree AS FLOAT)) DESC
	          ,OrderOS
	          ,vw.CodeOS DESC
	       )                        AS OSDense
	       INTO #T_JourneesWeb_OSDense
	FROM   #T_JourneesWeb           AS vw
	WHERE  rowNum = 1 --delete doubles
	GROUP BY
	       MasterID
	      ,SiteId
	      ,DateVisite
	      ,vw.CodeOS
	      ,OrderOS
	-- (2443677 row(s) affected)
	--(2118792 row(s) affected)

	CREATE INDEX ix_masterId ON #T_JourneesWeb_OSDense(MasterID ,SiteID ,DateVisite)
	
	-- MasterID=1488	SiteID=496306
	
	select * from #T_JourneesWeb_OSDense a where a.MasterID=1488 and a.SiteID=496306

	
		select count(*) from
	(
	select COUNT(*) as N
			, a.MasterID
	      , a.SiteID
	      , a.DateVisite
	from #T_JourneesWeb_OSDense a
	group by a.MasterID
	      , a.SiteID
	      , a.DateVisite
	      ) as r1
	     where r1.N>1
	-- 14819
	--13149
	select top 1000 a.*
	from #T_JourneesWeb_OSDense a inner join (
	select COUNT(*) as N
			, a.MasterID
	      , a.SiteID
	      , a.DateVisite
	from #T_JourneesWeb_OSDense a
	group by a.MasterID
	      , a.SiteID
	      , a.DateVisite
	      ) as r1 on a.MasterID=r1.MasterID
	      and a.SiteID=r1.SiteID
	      and a.DateVisite=r1.DateVisite
	where r1.N>1
	order by a.MasterID,a.DateVisite,a.CodeOS

	select COUNT(*) from dbo.Typologie a where a.MasterID is null
	-- 0
	
	-- DROP TABLE #T_JourneesWeb
	
	select top 1000 * from #T_JourneesWeb_OSDense a
	order by a.MasterID asc, a.SiteID asc, a.DateVisite desc
	

	IF OBJECT_ID('tempdb..#T_JourneesWeb_aggregate') IS NOT NULL
	    DROP TABLE #T_JourneesWeb_aggregate
	
	SELECT J1.MasterId
	      ,J1.SiteId
	      ,J1.DateVisite
	      ,SUM(J1.NbVisites)           AS NbVisites
	      ,SUM(J1.NbPagesVues)         AS NbPagesVues
	      ,SUM(J1.NbPremiumPagesVues)  AS NbPremiumPagesVues
	      ,SUM(J1.MoyenneDuree) / SUM(J1.NbVisites) AS MoyenneDuree
	      ,MIN(J1.PremierVisite)       AS PremierVisite
	      ,MAX(J1.DernierVisite)       AS DernierVisite
	      ,J2.CodeOS                   AS CodeOS
	      ,NULL                        AS Marque
	      ,0                           AS NumericAbo
	      ,0                           AS OptinEditorial 
	       INTO #T_JourneesWeb_aggregate
	FROM   #T_JourneesWeb_OSDense J1
	       INNER JOIN #T_JourneesWeb_OSDense J2
	            ON  j2.OSDense = 1
	                AND j1.masterID = J2.MasterID
	                AND j1.SiteID = J2.SiteID
	                AND J1.DateVisite = J2.DateVisite
	GROUP BY
	       J1.MasterId
	      ,J1.SiteId
	      ,J1.DateVisite
	      ,J2.CodeOS 
-- (2427532 row(s) affected) 0'07"
--(2104404 row(s) affected)	

SELECT 	   SUM(J1.NbVisites)           AS NbVisites
	      ,SUM(J1.NbPagesVues)         AS NbPagesVues
	      ,SUM(J1.NbPremiumPagesVues)  AS NbPremiumPagesVues
FROM #T_JourneesWeb_OSDense j1

SELECT 	   SUM(J1.NbVisites)           AS NbVisites
	      ,SUM(J1.NbPagesVues)         AS NbPagesVues
	      ,SUM(J1.NbPremiumPagesVues)  AS NbPremiumPagesVues
FROM #T_JourneesWeb_aggregate j1


select	2443677-2427532
-- 16145
-- ce qui est à peu près 14819
select	2118792-2104404	
--14388
	-- DROP TABLE #T_JourneesWeb_OSDense 

	CREATE INDEX ix_masterId ON #T_JourneesWeb_aggregate(MasterID)
	
	select top 1000 * from #T_JourneesWeb_aggregate


SELECT * FROM   #T_JourneesWeb_aggregate J
	       LEFT JOIN ref.SitesWeb AS sw
	            ON  sw.WebSiteID = J.SiteId
WHERE sw.Marque IS NULL

--(101315 row(s) affected) sw.Marque IS NULL

--(2003089 row(s) affected)	00'31''	IJ
--(2104404 row(s) affected) 00'32'' LJ
--(101315 row(s) affected) sw.Marque IS NULL

	--Numeric
	UPDATE J
	SET    Marque = sw.Marque
	      ,NumericAbo = CASE 
	                         WHEN i.AbonnementID IS NULL THEN 0
	                         ELSE 1
	                    END
	FROM   #T_JourneesWeb_aggregate J
	       INNER JOIN ref.SitesWeb AS sw
	            ON  sw.WebSiteID = J.SiteId
	       OUTER APPLY (
	    SELECT TOP 1 a.AbonnementID
	          ,a.DebutAboDate
	          ,a.FinAboDate
	    FROM   dbo.Abonnements a
	           INNER JOIN ref.CatalogueAbonnements AS ca
	                ON  a.AbonnementID = ca.CatalogueAbosID
	                    AND ca.SupportAbo = 1
	    WHERE  a.MasterID = J.MasterId
	           AND sw.Marque = a.Marque
	           AND J.DateVisite BETWEEN a.DebutAboDate AND a.FinAboDate
	) i
	-- (2427532 row(s) affected)
	-- 0'43"
	
	-- (2003089 row(s) affected)
	-- 01'36''
	
	--(2003089 row(s) affected) IJ 01'01''
	
SELECT * , Marque = sw.Marque
	FROM   #T_JourneesWeb_aggregate J
	       LEFT JOIN ref.SitesWeb AS sw
	            ON  sw.WebSiteID = J.SiteId
WHERE sw.Marque IS NULL


SELECT * FROM ref.SitesWeb AS sw
	
	select i.AbonnementID, CASE 
	                         WHEN i.AbonnementID IS NULL THEN 0
	                         ELSE 1
	                    END as NumericAbo
	                     	FROM   #T_JourneesWeb_aggregate J
	       LEFT JOIN ref.SitesWeb AS sw
	            ON  sw.WebSiteID = J.SiteId
	       OUTER APPLY (
	    SELECT TOP 1 a.AbonnementID
	          ,a.DebutAboDate
	          ,a.FinAboDate
	    FROM   dbo.Abonnements a
	           LEFT JOIN ref.CatalogueAbonnements AS ca
	                ON  a.AbonnementID = ca.CatalogueAbosID
	                    AND ca.SupportAbo = 1
	    WHERE  a.MasterID = 528192J.MasterId
	           AND sw.Marque = a.Marque
	           AND J.DateVisite BETWEEN a.DebutAboDate AND a.FinAboDate
	) i
		where J.MasterID=528192
	and J.SiteID=496306
	and J.DateVisite=N'2015-06-16'
	AND i.AbonnementID IS NOT null
	-- AbonnementID=23158148, NumericAbo=1
		
	select * from dbo.Abonnements a inner join ref.CatalogueAbonnements b on a.CatalogueAbosID=b.CatalogueAbosID
	where a.AbonnementID=21786004--23158148
	-- SupportAbo=2 Papier
	-- => erreur
	SELECT * FROM ref.CatalogueAbonnements
	WHERE catalogueabosid = 5802
	
	DROP TABLE #T_JourneesWeb_aggregate_ABR 
	select * into #T_JourneesWeb_aggregate_ABR from #T_JourneesWeb_aggregate a
	-- (2427532 row(s) affected)
	--(2104404 row(s) affected)
	
	select COUNT(*) as N, a.NumericAbo from #T_JourneesWeb_aggregate a
	group by a.NumericAbo
	-- Résultat requête ABR :
	--	2044211	0
	--	383321	1
--1883165	0
--221239	1
SELECT 2047861+379671
	
	-- Résultat requête AVE :
	--	2047861	0
	--	379671	1
	
	update a set a.Marque=null,a.NumericAbo=0 from #T_JourneesWeb_aggregate a
	-- 0'13"
	
	update a 
	set a.Marque=b.Marque 
	from #T_JourneesWeb_aggregate a inner join ref.SitesWeb b on a.SiteID=b.WebSiteID
	-- (2427532 row(s) affected)
	-- 0'07"
	--(2003089 row(s) affected)
	
	update a 
	set a.NumericAbo=1
	from #T_JourneesWeb_aggregate a 
	inner join dbo.Abonnements b on a.MasterID=b.MasterID and a.Marque=b.Marque
	inner join ref.CatalogueAbonnements c on b.CatalogueAbosID=c.CatalogueAbosID
	where c.SupportAbo=1 -- Numérique
	and a.DateVisite between b.DebutAboDate and b.FinAboDate
	-- (379671 row(s) affected)
	-- 0'03"
	--(218315 row(s) affected)
	 SELECT * FROM #T_JourneesWeb_aggregate
	 SELECT * FROM 
	select COUNT(*) from #T_JourneesWeb_aggregate_ABR a where a.Marque is null
	-- 0
	
	select COUNT(*) from #T_JourneesWeb_aggregate a inner join #T_JourneesWeb_aggregate_ABR b 
	on a.MasterID=b.MasterID
	and a.SiteID=b.SiteID
	and a.DateVisite=b.DateVisite
	where a.Marque<>b.Marque
	-- 0
	
	select COUNT(*) from #T_JourneesWeb_aggregate a inner join #T_JourneesWeb_aggregate_ABR b 
	on a.MasterID=b.MasterID
	and a.SiteID=b.SiteID
	and a.DateVisite=b.DateVisite
	where a.NumericAbo<>b.NumericAbo
	-- 3650	  2924
	
	select * from #T_JourneesWeb_aggregate a inner join #T_JourneesWeb_aggregate_ABR b 
	on a.MasterID=b.MasterID
	and a.SiteID=b.SiteID
	and a.DateVisite=b.DateVisite
	where a.NumericAbo<>b.NumericAbo
	
	select a.NumericAbo, c.SupportAbo, *  
	from #T_JourneesWeb_aggregate a 
	inner join dbo.Abonnements b on a.MasterID=b.MasterID and a.Marque=b.Marque
	inner join ref.CatalogueAbonnements c on b.CatalogueAbosID=c.CatalogueAbosID
	where /* c.SupportAbo=1 -- Numérique
	and */ a.DateVisite between b.DebutAboDate and b.FinAboDate
	and a.MasterID=528192
	and a.SiteID=496306
	and a.DateVisite=N'2015-06-16'
	-- NumericAbo	SupportAbo
	--	0			2
	
	select a.NumericAbo, c.SupportAbo, *  
	from #T_JourneesWeb_aggregate_ABR a 
	inner join dbo.Abonnements b on a.MasterID=b.MasterID and a.Marque=b.Marque
	inner join ref.CatalogueAbonnements c on b.CatalogueAbosID=c.CatalogueAbosID
	where /* c.SupportAbo=1 -- Numérique
	and */ a.DateVisite between b.DebutAboDate and b.FinAboDate
	and a.MasterID=528192
	and a.SiteID=496306
	and a.DateVisite=N'2015-06-16'
	-- NumericAbo	SupportAbo
	--	1			2
	-- => erreur
	
select 2427532-2427532
-- 0

	select top 1000 * from #T_JourneesWeb_aggregate

	-- OptinEditorial from brut.ConsentementsEmail
	
	select * from #T_JourneesWeb_aggregate a
	where a.MasterID=2910021 and a.SiteID=492987 and a.DateVisite=N'2015-06-04'
	
	select * from #T_JourneesWeb_OSDense a
	where a.MasterID=2910021 and a.SiteID=492987 and a.DateVisite=N'2015-06-04'
	
	select * from #T_JourneesWeb a
	where a.MasterID=2910021 and a.SiteID=492987 and a.DateVisite=N'2015-06-04'
	
	select sum(cast(a.MoyenneDuree as float))/COUNT(*) from #T_JourneesWeb a
	where a.MasterID=2910021 and a.SiteID=492987 and a.DateVisite=N'2015-06-04'
	-- 65,25
	
update #T_JourneesWeb_aggregate
SET OptinEditorial = 0	

	UPDATE J
	SET    OptinEditorial     = ISNULL(x2.OptinEditorial ,0)
	FROM   #T_JourneesWeb_aggregate J
	       OUTER APPLY (
	    SELECT 1 AS OptinEditorial
	    WHERE  1              = ANY(
	               SELECT valeur
	               FROM   (
	                          SELECT masterID
	                                ,ce.ContenuID
	                                ,ConsentementDate
	                                ,valeur
	                                ,ROW_NUMBER() OVER(
	                                     PARTITION BY masterId
	                                    ,ce.ContenuId ORDER BY ConsentementDate 
	                                     DESC
	                                     ,ce.Valeur ASC
	                                 ) N
	                          --FROM   brut.ConsentementsEmail ce
	                          --       INNER JOIN ref.Contenus cn
	                          --            ON  cn.TypeContenu = 1
	                          --                AND ce.ContenuID = cn.ContenuID
	                          --                AND cn.MarqueID = J.Marque
                              FROM brut.V_NewsletterContenu AS ce
	                          WHERE  ce.MasterID = J.MasterID
	                                 AND J.DateVisite > ConsentementDate
	                                 AND ce.MarqueID = J.Marque
	                      ) x1
	               WHERE  N = 1
	           )
	) AS x2
--01'47''  --1037360
SELECT count(*) FROM  #T_JourneesWeb_aggregate J WHERE j.OptinEditorial = 1



select * 
INTO #T_JourneesWeb_aggregate_2v
FROM #T_JourneesWeb_aggregate



--v2

UPDATE J 
SET j.OptinEditorial = 0 
FROM #T_JourneesWeb_aggregate AS j

UPDATE J
SET    OptinEditorial = 1
FROM   #T_JourneesWeb_aggregate_2v J
       INNER JOIN (
                SELECT *
                FROM   (
                           SELECT J.*
                                 ,ce.Valeur
                                 ,ROW_NUMBER() OVER(
                                      PARTITION BY J.masterId
                                     ,j.siteID
                                     ,j.DateVisite
                                     ,ce.ContenuId ORDER BY ConsentementDate 
                                      DESC
                                     ,ce.Valeur ASC
                                  ) N
                           FROM   #T_JourneesWeb_aggregate_2v J
                                  INNER JOIN brut.V_NewsletterContenu AS ce
                                       ON  ce.MasterID = J.MasterId
                                           AND J.DateVisite > ce.ConsentementDate
                                           AND ce.MarqueID = J.Marque
                       ) x
                WHERE  N = 1
            )xxx
            ON  xxx.MasterId = j.MasterId
                AND xxx.SiteId = j.SiteId
                AND xxx.DateVisite = j.DateVisite
WHERE  xxx.valeur = 1
--01'01''
SELECT COUNT(*)
FROM #T_JourneesWeb_aggregate_2v
WHERE OptinEditorial = 1
--1037812 - 1v
--1037512 - 2v	

--SELECT 1037812 - 1037512 --300

SELECT j1.MasterID, j1.SiteId, J1.dateVisite, j1.marque, j1.OptinEditorial, j2.OptinEditorial 
FROM   #T_JourneesWeb_aggregate j1
       INNER JOIN #T_JourneesWeb_aggregate_2v j2
            ON  j1.masterID = j2.masterId
                AND j1.siteId = j2.siteID
                AND j1.dateVisite = j2.dateVisite
                AND j1.OptinEditorial <> j2.OptinEditorial
--where j1.masterId = 10181774                
ORDER BY J1.masterId
--(401 row(s) affected)


--SELECT * FROM  #T_JourneesWeb_aggregate  WHERE 	OptinEditorial = 1




SELECT ce.Valeur, ce.ConsentementDate, ce.ContenuID, cn.MarqueID, J.MAsterId, SiteId, DateVisite
FROM   #T_JourneesWeb_aggregate AS J
       INNER JOIN brut.ConsentementsEmail ce
            ON  ce.MasterID = J.MasterID
                AND J.DateVisite > ConsentementDate
       INNER JOIN ref.Contenus cn
            ON  cn.TypeContenu = 1
                AND ce.ContenuID = cn.ContenuID
                AND cn.MarqueID = J.Marque
WHERE  j.OptinEditorial = 1
--AND ce.MasterID = 10442
AND dateVisite = N'2015-06-15'
ORDER BY J.MasterID, SiteID, DateVisite, ce.ConsentementDate DESC
--(1037747 row(s) affected)
--(1224473 row(s) affected) 	

SELECT * FROM ref.Contenus AS c WHERE c.MarqueID = 7
	
	TRUNCATE TABLE dbo.JourneesWeb
	INSERT INTO dbo.JourneesWeb
	  (
	    MasterID
	   ,SiteID
	   ,DateVisite
	   ,NbVisites
	   ,NbPagesVues
	   ,NbPremiumPagesVues
	   ,MoyenneDuree
	   ,CodeOSPrincipal
	   ,NumericAbo
	   ,OptinEditorial
	   ,PremierVisite
	   ,DernierVisite
	  )
	SELECT MasterId
	      ,SiteID
	      ,DateVisite
	      ,NbVisites
	      ,NbPagesVues
	      ,NbPremiumPagesVues
	      ,MoyenneDuree
	      ,CodeOS
	      ,NumericAbo
	      ,OptinEditorial
	      ,PremierVisite
	      ,DernierVisite
	FROM   #T_JourneesWeb_aggregate
	
	DROP TABLE #T_JourneesWeb_aggregate
END




 