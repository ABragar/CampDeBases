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
	             SELECT 'J-' + CAST(n AS NVARCHAR) AS namePeriod
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