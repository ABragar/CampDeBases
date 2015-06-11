IF EXISTS (
       SELECT *
       FROM   sysobjects
       WHERE  id = OBJECT_ID(N'etl.GetBeginOfDay')
              AND xtype IN (N'FN' ,N'IF' ,N'TF')
   )
    DROP FUNCTION etl.GetBeginOfDay
    GO
CREATE FUNCTION etl.GetBeginOfDay
(
	@d DATETIME
)
RETURNS DATETIME
AS
BEGIN
	RETURN CONVERT(DATETIME ,CONVERT(VARCHAR ,@d ,101))
END
GO




IF EXISTS (
       SELECT *
       FROM   sysobjects
       WHERE  id = OBJECT_ID(N'etl.GetEndOfDay')
              AND xtype IN (N'FN' ,N'IF' ,N'TF')
   )
    DROP FUNCTION etl.GetEndOfDay
GO
CREATE FUNCTION etl.GetEndOfDay
(
	@d DATETIME
)
RETURNS DATETIME
AS
BEGIN
	RETURN CONVERT(DATETIME ,CONVERT(VARCHAR ,@d ,101) + ' 23:59:59')
END
GO




IF EXISTS (
       SELECT *
       FROM   sysobjects
       WHERE  id = OBJECT_ID(N'etl.GetEndOfWeek')
              AND xtype IN (N'FN' ,N'IF' ,N'TF')
   )
    DROP FUNCTION etl.GetEndOfWeek
GO
CREATE FUNCTION etl.GetEndOfWeek
(
	@d DATETIME
)
RETURNS DATETIME
AS
BEGIN
	DECLARE @res DATETIME
	;
	WITH num(n) AS(
	         SELECT 0 
	         UNION ALL
	         SELECT n + 1
	         FROM   num
	         WHERE  n < 6
	     ),
	     dat AS (
	         SELECT DATEADD(dd ,n ,CAST(@d AS DATE)) AS DAY
	         FROM   num
	     )
	
	SELECT @res = DAY
	FROM   dat
	WHERE  DATEPART(dw ,DAY) = (8 -@@DATEFIRST) % 7
	
	RETURN @res
END
GO



IF EXISTS (
       SELECT *
       FROM   sysobjects
       WHERE  id = OBJECT_ID(N'etl.GetBeginOfMonth')
              AND xtype IN (N'FN' ,N'IF' ,N'TF')
   )
    DROP FUNCTION etl.GetBeginOfMonth
GO
CREATE FUNCTION etl.GetBeginOfMonth
(
	@d DATETIME
)
RETURNS DATETIME
AS
BEGIN
	DECLARE @res DATETIME
	SELECT @res = DATEADD(DAY ,1 -DAY(@d) ,@d)
	RETURN @res
END
GO



IF EXISTS (
       SELECT *
       FROM   sysobjects
       WHERE  id = OBJECT_ID(N'etl.GetEndOfMonth')
              AND xtype IN (N'FN' ,N'IF' ,N'TF')
   )
    DROP FUNCTION etl.GetEndOfMonth
GO
CREATE FUNCTION etl.GetEndOfMonth
(
	@d DATETIME
)
RETURNS DATETIME
AS
BEGIN
	DECLARE @res DATETIME
	SELECT @res = DATEADD(MONTH ,1 ,DATEADD(DAY ,1 -DAY(@d) ,@d)) -1
	RETURN @res
END
GO



IF EXISTS (
       SELECT *
       FROM   sysobjects
       WHERE  id            = OBJECT_ID(N'report.StatsWebSessions')
              AND xtype     = N'U'
   )
    DROP TABLE report.StatsWebSessions

CREATE TABLE report.StatsWebSessions
(
	MasterID          INT NOT NULL
   ,SessionsCount     INT
   ,Period            NVARCHAR(4)
   ,Sуries            NVARCHAR(255)
   ,SуriesSort        INT
   ,periodType        NVARCHAR(1) NOT NULL -- J S M
   ,Appartenance      INT
)


IF EXISTS (
       SELECT *
       FROM   sysobjects
       WHERE  id            = OBJECT_ID(N'report.StatsVolumetrieSessions')
              AND xtype     = N'U'
   )
    DROP TABLE report.StatsVolumetrieSessions

CREATE TABLE report.StatsVolumetrieSessions
(
	MasterID          INT NOT NULL
   ,SessionsCount     INT
   ,PagesVues         INT
   ,Period            NVARCHAR(4)
   ,periodType        NVARCHAR(1) NOT NULL -- J S M
   ,Category          NVARCHAR(255)
   ,Gr                NVARCHAR(255)
   ,Marque            INT
   ,Appartenance      INT
)

IF EXISTS (
       SELECT *
       FROM   sysobjects
       WHERE  id            = OBJECT_ID(N'report.StatsMasterIDsMapping')
              AND xtype     = N'U'
   )
    DROP TABLE report.StatsMasterIDsMapping

CREATE TABLE report.StatsMasterIDsMapping
(
	MasterID     INT NOT NULL
   ,ClientID     NVARCHAR(18)
   ,SiteID       NVARCHAR(18)
   ,MarqueId     INT
)
CREATE INDEX IX_StatsMasterIDsMapping_ClientIDSiteID 
    ON report.StatsMasterIDsMapping (ClientID ,SiteID);

GO

ALTER FUNCTION report.GetPeriodsList
(
	@d     DATE
   ,@p     NVARCHAR(1)
)
RETURNS @res TABLE (
            namePeriod NVARCHAR(255)
           ,StartPeriod DATETIME
           ,EndPeriod DATETIME
        )
AS

BEGIN
	IF @p = N'J'
	BEGIN
	    WITH num(n) AS(
	             SELECT 0 
	             UNION ALL
	             SELECT n + 1
	             FROM   num
	             WHERE  n < 6
	         )
	         ,dat AS (
	             SELECT n
	             FROM   num
	         )
	         ,periods AS (
	             SELECT 'J-' + CAST(n + 1 AS NVARCHAR) AS namePeriod
	                   ,etl.GetBeginOfDay(DATEADD(DAY ,-n ,@d)) StartPeriod
	                   ,etl.GetEndOfDay(DATEADD(DAY ,-n ,@d)) EndPeriod
	             FROM   dat
	         )
	    
	    INSERT @res
	    SELECT *
	    FROM   periods AS p;
	END
	
	IF @p = N'S'
	BEGIN
	    WITH num(n) AS(
	             SELECT 0 
	             UNION ALL
	             SELECT n + 1
	             FROM   num
	             WHERE  n < 11
	         )
	         ,dat AS (
	             SELECT n
	             FROM   num
	         )
	         ,periods AS (
	             SELECT 'S-' + CAST(n AS NVARCHAR) AS namePeriod
	                   ,DATEADD(DAY ,-6 ,etl.GetEndOfWeek(DATEADD(week ,-n ,@d))) 
	                    StartPeriod
	                   ,etl.GetEndOfDay(etl.GetEndOfWeek(DATEADD(week ,-n ,CAST(@d AS DATETIME)))) 
	                    EndPeriod
	             FROM   dat
	         )
	    
	    INSERT @res
	    SELECT *
	    FROM   periods AS p;
	END
	
	IF @p = N'M'
	BEGIN
	    WITH num(n) AS(
	             SELECT 0 
	             UNION ALL
	             SELECT n + 1
	             FROM   num
	             WHERE  n < 11
	         )
	         ,dat AS (
	             SELECT n
	             FROM   num
	         )
	         ,periods AS (
	             SELECT 'M-' + CAST(n AS NVARCHAR) AS namePeriod
	                   ,etl.GetBeginOfMonth(DATEADD(MONTH ,-n ,@d)) AS 
	                    StartPeriod
	                   ,etl.GetEndOfMonth(DATEADD(MONTH ,-n ,@d)) AS EndPeriod
	             FROM   dat
	         )
	    
	    INSERT @res
	    SELECT *
	    FROM   periods AS p;
	END
	
	RETURN
END
GO

 
 