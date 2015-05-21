/************************************************************
 * Code formatted by SoftTree SQL Assistant © v7.1.246
 * Time: 20.05.2015 17:59:14
 ************************************************************/

--import.SDVP_Adresses
USE AmauryVUC
GO

ALTER PROC sp_SaveStatisticWithActionID @TableName NVARCHAR(255) AS
BEGIN
	IF OBJECT_ID('tempdb..#tmp') IS NOT NULL
	    DROP TABLE #tmp
	
	CREATE TABLE #tmp
	(
		TableName              NVARCHAR(100) --
	   ,FichierTS              NVARCHAR(255) --File name
	   ,Ajouts                 INT --add
	   ,Modifications          INT --update
	   ,Suppressions           INT --delete
	   ,RejetAjouts            INT --add
	   ,RejetModifications     INT --update
	   ,RejetSuppressions      INT --delete
	   ,TraitementDate         DATETIME NOT NULL DEFAULT GETDATE()
	)
	
	DECLARE @SqlCommand NVARCHAR(MAX) =
	        N'INSERT #tmp
	            (
	              TableName
	             ,FichierTS
	             ,Ajouts
	             ,Modifications
	             ,Suppressions
	             ,RejetAjouts
	             ,RejetModifications
	             ,RejetSuppressions
	            )
	          SELECT @TableName
	                ,FichierTS
	                ,A
	                ,M
	                ,D
	                ,RA
	                ,RM
	                ,RD
	          FROM   (
	                     SELECT SUM(A)     A
	                           ,SUM(M)     M
	                           ,SUM(D)     D
	                           ,0          RA
	                           ,0          RM
	                           ,0          RD
	                           ,FichierTS
	                     FROM   (
	                                SELECT A = (CASE WHEN actionID = 1 THEN 1 ELSE 0 END)
	                                      ,M = (CASE WHEN actionID = 2 THEN 1 ELSE 0 END)
	                                      ,D = (CASE WHEN actionID = 3 THEN 1 ELSE 0 END)
	                                      ,ActionID
	                                      ,FichierTS
	                                FROM   ' + @TableName +
	        '
	                                WHERE  RejetCode = 0
	                            )          x
	                     GROUP BY
	                            FichierTS
	                     
	                     UNION ALL
	                     SELECT 0
	                           ,0
	                           ,0
	                           ,SUM(A)
	                           ,SUM(M)
	                           ,SUM(D)
	                           ,FichierTS
	                     FROM   (
	                                SELECT A = (CASE WHEN actionID = 1 THEN 1 ELSE 0 END)
	                                      ,M = (CASE WHEN actionID = 2 THEN 1 ELSE 0 END)
	                                      ,D = (CASE WHEN actionID = 3 THEN 1 ELSE 0 END)
	                                      ,ActionID
	                                      ,FichierTS
	                                FROM   ' + @TableName +
	        '
	                                WHERE  RejetCode <> 0
	                            ) x
	                     GROUP BY
	                            FichierTS
	                 )x'
	
	DECLARE @param NVARCHAR(255) =
	        N'@TableName NVARCHAR(255)'
	
	EXECUTE sp_executesql @SqlCommand
	       ,@Param
	       ,@TableName = @TableName
	
	
	SELECT *
	FROM   #tmp t
	       LEFT JOIN ImportDataStatistic s
	            ON  t.TableName = s.TableName
	                AND t.FichierTS = s.FichierTS
	                AND s.FichierTS IS NULL  
	
END



