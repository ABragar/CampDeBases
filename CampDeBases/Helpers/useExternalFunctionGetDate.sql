Create ASSEMBLY CLRFunctions FROM 'D:\Projects\SQLUserDefineFunction\SQLUserDefineFunction\bin\Debug\SQLUserDefineFunction.dll' 
go


CREATE FUNCTION dbo.RegexMatch(@text nvarchar(max), @regExp NVARCHAR(max))
RETURNS bit WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME CLRFunctions.[UserDefineFunction.UserDefinedFunctions].RegexMatch
go
CREATE FUNCTION dbo.RegexGetDate(@text nvarchar(max), @regExp NVARCHAR(max))
RETURNS NVARCHAR(MAX) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME CLRFunctions.[UserDefineFunction.UserDefinedFunctions].RegexGetDate
go

DECLARE @ddmmyyyy NVARCHAR(max) = N'(0[1-9]|1[0-9]|2[0-9]|3[01])(0[1-9]|1[012])[0-9]{4}' 
DECLARE @yyyy_mm_dd NVARCHAR(max) = N'[0-9]{4}-(0[1-9]|1[012])-(0[1-9]|1[0-9]|2[0-9]|3[01])'
DECLARE @yyyymmdd NVARCHAR(max)  = N'[0-9]{4}(0[1-9]|1[012])(0[1-9]|1[0-9]|2[0-9]|3[01])' 
DECLARE @dd_mm_yyyy NVARCHAR(max) = N'(0[1-9]|1[0-9]|2[0-9]|3[01])-(0[1-9]|1[012])-[0-9]{4}' 

SELECT *
      ,TS = CASE 
                 WHEN ISDATE(ReturnedValue) = 1 THEN CAST(ReturnedValue AS DATETIME)
            END
FROM   (
           SELECT *
                 ,COALESCE(
                      dbo.RegexGetDate(FichierTs ,@ddmmyyyy)
                     ,dbo.RegexGetDate(FichierTs ,@yyyy_mm_dd)
                     ,dbo.RegexGetDate(FichierTs ,@yyyymmdd)
                     ,dbo.RegexGetDate(FichierTs ,@dd_mm_yyyy)
                  ) AS ReturnedValue
           FROM   STATS.ImportDataStatistic
       ) i
