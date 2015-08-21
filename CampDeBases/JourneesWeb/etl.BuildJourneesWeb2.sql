ALTER PROCEDURE etl.BuildJourneesWeb2
	@FirstRun TINYINT = 0
AS
BEGIN
	
       update V set TraiteTop = 0
       from etl.VisitesWeb V
       inner join etl.VisitesWeb V1 on V.MasterID = V1.MasterID and V.SiteId = V1.SiteId and cast(V.DateVisite as date) = cast(V1.DateVisite as date)
       where V1.TraiteTop = 0 and V.TraiteTop = 1



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
	       LEFT JOIN ref.Misc m
	            ON  vw.CodeOS = m.RefID
	WHERE vw.TraiteTop = 0
	
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
	      ,SUM(J1.NbPagesVues)         AS NbPagesVues
	      ,SUM(J1.NbPremiumPagesVues)  AS NbPremiumPagesVues
	      ,SUM(J1.MoyenneDuree) / SUM(J1.NbVisites) AS MoyenneDuree
	      ,MIN(J1.PremierVisite)       AS PremierVisite
	      ,MAX(J1.DernierVisite)       AS DernierVisite
	      ,J2.CodeOS                   AS CodeOS
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
	
	--Appartenance
	UPDATE a
	SET    a.Appartenance = b.Appartenance
	FROM   #T_JourneesWeb_aggregate a
	       INNER JOIN ref.SitesWeb b
	            ON  a.SiteID = b.WebSiteID
	                
	                
	                MERGE dbo.JourneesWeb AS t
	                USING
	                (
	                    SELECT aw.ActiviteWebID
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
	                    FROM   #T_JourneesWeb_aggregate J
	                           INNER JOIN dbo.ActiviteWeb AS aw
	                                ON  aw.MasterID = J.masterID
	                                    AND aw.SiteWebID = j.siteId
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
	  );
	
	DROP TABLE #T_JourneesWeb_aggregate
END
 