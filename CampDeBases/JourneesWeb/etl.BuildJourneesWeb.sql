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
	          ,datevisite ORDER BY COUNT(NbVisites) DESC
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
	
	CREATE INDEX ix_masterId ON #T_JourneesWeb_OSDense(MasterID ,SiteID ,DateVisite)
	
	DROP TABLE #T_JourneesWeb

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
	
	DROP TABLE #T_JourneesWeb_OSDense 

	CREATE INDEX ix_masterId ON #T_JourneesWeb_aggregate(MasterID)

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

	-- OptinEditorial from brut.ConsentementsEmail
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
	                                 ) N
	                          FROM   brut.ConsentementsEmail ce
	                                 INNER JOIN ref.Contenus cn
	                                      ON  cn.TypeContenu = 1
	                                          AND ce.ContenuID = cn.ContenuID
	                                          AND cn.MarqueID = J.Marque
	                          WHERE  ce.MasterID = J.MasterID
	                                 AND J.DateVisite > ConsentementDate
	                      ) x1
	               WHERE  N = 1
	           )
	) AS x2
	
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




 