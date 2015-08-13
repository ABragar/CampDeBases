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
	   ,NumericAbo             INT
	   ,OptinEditorial         INT
	   ,rowNum                 INT
	)
	
-- for incremental run
DECLARE @startDate DATETIME = DATEADD(DAY,1,ISNULL((SELECT MAX(dateVisite)FROM dbo.JourneesWeb AS jw),'19000101'))
DECLARE @endDate DATETIME = [etl].[GetBeginOfDay](GETDATE())

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
	      ,CAST(DateVisite AS DATE)  AS DateVisite
	      ,VisiteId                  AS NbVisites
	      ,PagesNb                   AS NbPagesVues
	      ,PagesPremiumNb            AS NbPremiumPagesVues
	      ,CAST(Duree AS FLOAT)      AS MoyenneDuree
	      ,codeOS
	      ,OrderOS = CASE 
	                      WHEN m.typeRef = N'OSTABLETTE' THEN 1
	                      WHEN m.typeRef = N'OSMOBILE' THEN 2
	                      ELSE 3
	                 END
	      ,DateVisite                AS PremierVisite
	      ,DateVisite                AS DernierVisite
	      ,NumericAbo = CASE ISNULL(TypeAbo ,0)
	                         WHEN 1 THEN 1
	                         ELSE 0
	                    END
	      ,OptinEditorial = CASE ISNULL(OptinEditorial ,0)
	                             WHEN 1 THEN 1
	                             ELSE 0
	                        END
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
	WHERE  vw.DateVisite >= @startDate AND vw.DateVisite < @endDate
	
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
	
--	TRUNCATE TABLE dbo.JourneesWeb 
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
	   ,Appartenance
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
	      ,Appartenance
	FROM   #T_JourneesWeb_aggregate
	
	DROP TABLE #T_JourneesWeb_aggregate
END




 