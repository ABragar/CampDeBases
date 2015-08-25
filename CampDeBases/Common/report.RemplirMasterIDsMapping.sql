/****** Object:  StoredProcedure [report].[RemplirMasterIDsMapping]    Script Date: 19/08/2015 16:23:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [report].[RemplirMasterIDsMapping] AS
BEGIN
	--SET NOCOUNT ON;
	TRUNCATE TABLE report.StatsMasterIDsMapping
	INSERT INTO report.StatsMasterIDsMapping
	  (
	    MasterID
	   ,ClientID
	   ,SiteID
	   ,MarqueId
	  )
	SELECT vw.MasterID
	      ,cast(c.OriginalID AS NVARCHAR(18))
	      ,vw.SiteId
	      ,Marque
	FROM   etl.VisitesWeb            AS vw
	       INNER JOIN brut.Contacts  AS c
	            ON  vw.MasterID = c.MasterID
	       INNER JOIN ref.SitesWeb   AS sw
	            ON  vw.SiteId = sw.WebSiteID
	GROUP BY vw.MasterID, c.OriginalID, vw.SiteId, sw.Marque	            	
END

GO
