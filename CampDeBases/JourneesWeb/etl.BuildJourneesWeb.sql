 ALTER PROCEDURE etl.BuildJourneesWeb
	@FirstRun TINYINT = 0
AS
BEGIN
	IF OBJECT_ID('tempdb..#T_NewVisites') IS NOT NULL
	    DROP TABLE #T_NewVisites
	CREATE TABLE #T_NewVisites
	(
		MasterID       INT NOT NULL
	   ,SiteID         INT NOT NULL
	   ,DateVisite     DATE NOT NULL
	)
	
	INSERT INTO #T_NewVisites
	  (
	    MasterID
	   ,SiteID
	   ,DateVisite
	  )
	SELECT masterId
	      ,SiteId
	      ,CAST(DateVisite AS DATE)  AS DateVisite
	FROM   etl.VisitesWeb AS vw 
	WHERE  vw.TraiteTop =1	AND vw.SiteId=40086
	GROUP BY
	       masterId
	      ,SiteId
	      ,CAST(DateVisite AS DATE) 
	
	CREATE INDEX ix_MasterSiteID on #T_NewVisites(MasterID, SiteID)


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
	   ,NumericAbo             INT
	   ,OptinEditorial         INT
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
	   ,NumericAbo
	   ,OptinEditorial
	   ,rowNum
	  )
	SELECT vw.MasterID
	      ,vw.SiteId
	      ,CAST(vw.DateVisite AS DATE)  AS DateVisite
	      ,VisiteId                     AS NbVisites
	      ,PagesNb                      AS NbPagesVues
	      ,PagesPremiumNb               AS NbPremiumPagesVues
	      ,CAST(Duree AS FLOAT)         AS MoyenneDuree
	      ,codeOS
	      ,OrderOS = CASE 
	                      WHEN m.typeRef = N'OSTABLETTE' THEN 1
	                      WHEN m.typeRef = N'OSMOBILE' THEN 2
	                      ELSE 3
	                 END
	      ,vw.DateVisite                AS PremierVisite
	      ,vw.DateVisite                AS DernierVisite
	      ,NumericAbo = CASE ISNULL(TypeAbo ,0)
	                         WHEN 1 THEN 1
	                         ELSE 0
	                    END
	      ,OptinEditorial = CASE ISNULL(OptinEditorial ,0)
	                             WHEN 1 THEN 1
	                             ELSE 0
	                        END
	      ,ROW_NUMBER() OVER(
	           PARTITION BY vw.MasterID
	          ,vw.SiteId
	          ,vw.DateVisite
	          ,FinVisite
	          ,Duree
	          ,PagesNb
	          ,PagesPremiumNb
	          ,XitiSession ORDER BY vw.MasterID
	          ,vw.SiteId
	          ,vw.DateVisite
	          ,CASE 
	                WHEN m.typeRef = N'OSTABLETTE' THEN 1
	                WHEN m.typeRef = N'OSMOBILE' THEN 2
	                ELSE 3
	           END
	       )                               rowNum
	FROM   etl.VisitesWeb               AS vw  
	       INNER JOIN #T_NewVisites     AS tnv
	            ON  vw.MasterID = tnv.MasterID
	                AND vw.SiteId = tnv.SiteID
	                AND CAST(vw.DateVisite AS DATE) = tnv.DateVisite
	       LEFT JOIN ref.Misc m
	            ON  vw.CodeOS = m.RefID
	
	
	CREATE INDEX ix_masterId ON #T_JourneesWeb(MasterID)
	CREATE INDEX ix_siteId ON #T_JourneesWeb(SiteID)
	CREATE INDEX ix_DateVisite ON #T_JourneesWeb(DateVisite)       
	
	IF OBJECT_ID('tempdb..#T_JourneesWeb_OSDense') IS NOT NULL
	    DROP TABLE #T_JourneesWeb_OSDense
	
	SELECT vw.MasterID
	      ,vw.SiteId
	      ,DateVisite
	      ,COUNT(NbVisites)         AS NbVisites
	      ,SUM(CASE WHEN vw.CodeOS IS NOT NULL THEN 1 ELSE 0 END) as	NbVisitesMobile
	      ,SUM(NbPagesVues)         AS NbPagesVues
		  ,SUM(CASE WHEN vw.CodeOS IS NOT NULL THEN NbPagesVues ELSE 0 END) AS NbPagesVuesMobile	      
	      ,SUM(NbPremiumPagesVues)  AS NbPremiumPagesVues
	      ,SUM(CAST(MoyenneDuree AS FLOAT)) AS MoyenneDuree
	      ,vw.CodeOS
	      ,MIN(PremierVisite)       AS PremierVisite
	      ,MAX(DernierVisite)       AS DernierVisite
	      ,MAX(vw.NumericAbo)       AS NumericAbo
	      ,MAX(vw.OptinEditorial)   AS OptinEditorial
	      ,ROW_NUMBER() OVER(
	           PARTITION BY MasterID
	          ,SiteID
	          ,datevisite ORDER BY COUNT(NbVisites) DESC
	          ,OrderOS
	          ,vw.CodeOS DESC
	          ,SUM(NbPagesVues) DESC
	          ,SUM(CAST(MoyenneDuree AS FLOAT)) DESC
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
	      ,SUM(J1.NbVisitesMobile)     AS NbVisitesMobile
	      ,SUM(J1.NbPagesVues)         AS NbPagesVues
		  ,SUM(J1.NbPagesVuesMobile)   AS NbPagesVuesMobile
		  ,SUM(J1.NbPremiumPagesVues)  AS NbPremiumPagesVues
	      ,SUM(J1.MoyenneDuree) / SUM(J1.NbVisites) AS MoyenneDuree
	      ,MIN(J1.PremierVisite)       AS PremierVisite
	      ,MAX(J1.DernierVisite)       AS DernierVisite
	      ,J2.CodeOS                   AS CodeOS
	      ,COUNT(DISTINCT isnull(J1.CodeOS,0))	   AS MultiOS
	      ,NULL                        AS Appartenance
	      ,MAX(J1.NumericAbo)          AS NumericAbo
	      ,MAX(J1.OptinEditorial)      AS OptinEditorial 
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
	
	----Appartenance
	UPDATE a
	SET    a.Appartenance = b.Appartenance
	FROM   #T_JourneesWeb_aggregate a
	       INNER JOIN ref.SitesWeb b
	            ON  a.SiteID = b.WebSiteID
         
	                MERGE dbo.JourneesWeb AS t
	                USING
	                (
	                    SELECT --aw.ActiviteWebID
							   ROW_NUMBER()	OVER(ORDER BY J.masterID)
	                          ,J.MasterId
	                          ,J.SiteID
	                          ,J.DateVisite
	                          ,J.NbVisites
	                          ,J.NbPagesVues
	                          ,J.NbPremiumPagesVues
	                          ,ROUND(J.MoyenneDuree ,0) AS MoyenneDuree
	                          ,J.CodeOS
	                          ,J.NumericAbo
	                          ,J.OptinEditorial
	                          ,J.PremierVisite
	                          ,J.DernierVisite
	                          ,J.Appartenance
	                          ,MultiOS = CASE WHEN J.MultiOS > 1 THEN 1 ELSE 0 END
							  ,J.NbVisitesMobile
 							  ,J.NbPagesVuesMobile
	                    FROM   #T_JourneesWeb_aggregate J
	                           --JOIN dbo.ActiviteWeb AS aw
	                           --     ON  aw.MasterID = J.masterID
	                           --         AND aw.SiteWebID = j.siteId
	                ) AS s(
	                    ActiviteWebID
	                   ,MasterID
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
	                   ,Appartenance
	                   ,MultiOS
	                   ,NbVisitesMobile
	                   ,NbPagesVuesMobile
	                )
	            ON  s.MasterID = t.MasterID
	                AND s.SiteId = t.SiteID
	                AND s.DateVisite = t.DateVisite 
	                    WHEN matched THEN
	
	UPDATE 
	SET    NbVisites = s.NbVisites
	      ,NbPagesVues = s.NbPagesVues
	      ,NbPremiumPagesVues = s.NbPremiumPagesVues
	      ,MoyenneDuree = s.MoyenneDuree
	      ,CodeOSPrincipal = s.CodeOS
	      ,NumericAbo = s.NumericAbo
	      ,OptinEditorial = s.OptinEditorial
	      ,PremierVisite = s.PremierVisite
	      ,DernierVisite = s.DernierVisite
	      ,Appartenance = s.Appartenance
	      ,MultiOS = s.MultiOS
		  ,NbVisitesMobile = s.NbVisitesMobile
	      ,NbPagesVuesMobile = s.NbPagesVuesMobile
	      
	       WHEN NOT MATCHED THEN
	
	INSERT 
	  (
	    ActiviteWebID
	   ,MasterID
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
	   ,Appartenance
	   ,MultiOS
	   ,NbVisitesMobile
	   ,NbPagesVuesMobile
	  )
	VALUES
	  (
	    s.ActiviteWebID
	   ,s.MasterId
	   ,s.SiteID
	   ,s.DateVisite
	   ,s.NbVisites
	   ,s.NbPagesVues
	   ,s.NbPremiumPagesVues
	   ,s.MoyenneDuree
	   ,s.CodeOS
	   ,s.NumericAbo
	   ,s.OptinEditorial
	   ,s.PremierVisite
	   ,s.DernierVisite
	   ,s.Appartenance
	   ,s.MultiOS
	   ,s.NbVisitesMobile
	   ,s.NbPagesVuesMobile
	   
	  );
	
	DROP TABLE #T_JourneesWeb_aggregate
END

 