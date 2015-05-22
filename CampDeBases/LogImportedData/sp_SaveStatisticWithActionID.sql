/************************************************************
 * Code formatted by SoftTree SQL Assistant © v7.1.246
 * Time: 21.05.2015 12:38:50
 ************************************************************/

--import.SDVP_Adresses
USE AmauryVUC
GO

ALTER PROC [dbo].[sp_SaveStatisticWithActionID] @TableName NVARCHAR(255) AS
BEGIN	DECLARE @SqlCommand NVARCHAR(MAX) =
	        N'DECLARE @data ImportDataStatisticType;
	        INSERT @data
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
	          SELECT @TableName as TableName
	                ,FichierTS
	                ,SUM(A)
	                ,SUM(M)
	                ,SUM(D)
	                ,SUM(RA)
	                ,SUM(RM)
	                ,SUM(RD)
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
	                                      , isnull(FichierTS,N''Fichier non renseigne'') as FichierTS
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
	                                      , isnull(FichierTS,N''Fichier non renseigne'') as FichierTS
	                                FROM   ' + @TableName +
	        '
	                                WHERE  RejetCode <> 0
	                            ) x
	                     GROUP BY
	                            FichierTS
	                 )x GROUP BY FichierTS
	                 
	                 EXEC sp_MergeStatistic @data, @TableName
	                 
	                 '
	
	DECLARE @param NVARCHAR(255) =
	        N'@TableName NVARCHAR(255)'
	
	EXECUTE sp_executesql @SqlCommand
	       ,@Param
	       ,@TableName = @TableName

END



