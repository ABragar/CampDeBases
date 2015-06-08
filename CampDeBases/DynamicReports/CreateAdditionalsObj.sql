
--CREATE TABLE report.StatsWebSessions
--(
--	MasterID             INT NOT NULL
--   ,SessionsDate         DATE
--   ,SessionsCount        INT
--   ,SessionsDuration     INT
--   ,SiteId               NVARCHAR(255)
--   ,PagesQty             INT
--   ,OS                   NVARCHAR(255)
--   ,CompanyID            NVARCHAR(255)
--)

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



 