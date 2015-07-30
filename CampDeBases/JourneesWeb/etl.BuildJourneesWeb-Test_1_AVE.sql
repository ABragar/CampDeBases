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
	   ,MoyenneDuree           INT NOT NULL DEFAULT 0
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
	      ,CAST(Duree AS DECIMAL)    AS MoyenneDuree
	      ,codeOS
	      ,OrderOS = CASE 
	                      WHEN m.typeRef = N'OSTABLETTE' THEN 1
	                      WHEN m.typeRef = N'OSMOBILE' THEN 2
	                      ELSE 3
	                 END
	      ,DateVisite AS PremierVisite
	      ,DateVisite AS DernierVisite
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
	       ) rowNum
	FROM   etl.VisitesWeb AS vw
	       LEFT JOIN ref.Misc m
	            ON  vw.CodeOS = m.RefID
	WHERE  /* NOT (
	           vw.MasterID IS NULL
	           OR vw.SiteId IS NULL
	           OR vw.DateVisite IS NULL
	       ) 
	AND */ vw.DateVisite between '20150601' and '20150627'
	-- (7737015 row(s) affected)
	
	select * from #T_JourneesWeb
	
	select COUNT(*) from etl.VisitesWeb AS vw 
	WHERE   (
	           vw.MasterID IS NULL
	           OR vw.SiteId IS NULL
	           OR vw.DateVisite IS NULL
	       )
	       -- 0
	       
	--AND vw.MasterID = 10626
	
	select max(a.DateVisite) from #T_JourneesWeb a
	-- 2015-07-28
	
	CREATE INDEX ix_masterId ON #T_JourneesWeb(MasterID)
	CREATE INDEX ix_siteId ON #T_JourneesWeb(SiteID)
	CREATE INDEX ix_DateVisite ON #T_JourneesWeb(DateVisite)       
	
	IF OBJECT_ID('tempdb..#T_JourneesWeb_OSDense') IS NOT NULL
	    DROP TABLE #T_JourneesWeb_OSDense
	
	SELECT vw.MasterID
	      ,vw.SiteId
	      ,DateVisite
	      ,COUNT(NbVisites)         AS NbVisites
	      ,SUM(NbPagesVues)         AS NbPagesVues
	      ,SUM(NbPremiumPagesVues)  AS NbPremiumPagesVues
	      ,SUM(CAST(MoyenneDuree AS DECIMAL)) AS MoyenneDuree
	      ,vw.CodeOS
	      ,vw.OrderOS
	      ,MIN(PremierVisite)       AS PremierVisite
	      ,MAX(DernierVisite)       AS DernierVisite
	      ,RANK() OVER(
	           PARTITION BY MasterID
	          ,SiteID
	          ,datevisite ORDER BY COUNT(NbVisites) DESC
	          ,SUM(NbPagesVues) DESC
	          ,AVG(CAST(MoyenneDuree AS DECIMAL)) DESC
	          ,vw.OrderOS ASC
	       )                        AS OSDense
--	       INTO #T_JourneesWeb_OSDense
	FROM   #T_JourneesWeb           AS vw
	WHERE  rowNum = 1 --delete doubles
	--AND masterID = 276969 AND vw.SiteID = 492987
	GROUP BY
	       MasterID
	      ,SiteId
	      ,DateVisite
	      ,vw.CodeOS
	      ,vw.OrderOS
	-- (2200194 row(s) affected)
	
	select top 1000 *
	from #T_JourneesWeb_OSDense a
	order by a.MasterID,a.DateVisite,a.CodeOS
	
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
	     -- 13390
	     
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
	
	CREATE INDEX ix_masterId ON #T_JourneesWeb_OSDense(MasterID, SiteID, DateVisite)
	
	-- DROP TABLE #T_JourneesWeb
	
	select avg(cast(a.MoyenneDuree as float)) from #T_JourneesWeb a 
	where a.MasterID=5776
	and a.SiteID=496306
	and a.DateVisite=N'2015-06-17'
	-- 1,5
	
	select avg(cast(a.MoyenneDuree as float)) from #T_JourneesWeb_OSDense a 
	where a.MasterID=5776
	and a.SiteID=496306
	and a.DateVisite=N'2015-06-17'
	-- 2,6363635
	
	IF OBJECT_ID('tempdb..#T_JourneesWeb_aggregate') IS NOT NULL
	    DROP TABLE #T_JourneesWeb_aggregate
	--
	SELECT J1.MasterId
	      ,J1.SiteId
	      ,J1.DateVisite
	      ,SUM(J1.NbVisites)           AS NbVisites
	      ,SUM(J1.NbPagesVues)         AS NbPagesVues
	      ,SUM(J1.NbPremiumPagesVues)  AS NbPremiumPagesVues
	      ,SUM(J1.MoyenneDuree)/SUM(J1.NbVisites)        AS MoyenneDuree
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
	
	--CREATE INDEX ix_masterId ON #T_JourneesWeb_aggregate(MasterID)
	--CREATE INDEX ix_siteId ON #T_JourneesWeb_aggregate(SiteID)
	--CREATE INDEX ix_DateVisite ON #T_JourneesWeb_aggregate(DateVisite)
	

	
	DROP TABLE #T_JourneesWeb_OSDense 
	
	--Numeric
	UPDATE J
	SET    Marque = sw.Marque
	      ,NumericAbo = CASE 
	                         WHEN i.AbonnementID IS NULL THEN 0
	                         ELSE 1
	                    END
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
	    WHERE  a.MasterID = J.MasterId
	           AND sw.Marque = a.Marque
	           AND J.DateVisite BETWEEN a.DebutAboDate AND a.FinAboDate
	) i
	
	-- OptinEditorial
	UPDATE J
	SET    OptinEditorial = CASE 
	                             WHEN xxx.valeur = 1 THEN 1
	                             ELSE 0
	                        END
	FROM   #T_JourneesWeb_aggregate J
	       OUTER APPLY (
	    SELECT TOP 1 ce.*
	    FROM   brut.ConsentementsEmail AS ce
	           LEFT JOIN ref.Contenus cn
	                ON  cn.TypeContenu = 1
	                    AND ce.ContenuID = cn.ContenuID
	                    AND cn.MarqueID = J.Marque
	    WHERE  J.DateVisite > ce.ConsentementDate
	           AND ce.MasterID = J.MasterID
	) xxx
	
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


  