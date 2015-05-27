USE AmauryVUC
GO

CREATE PROC stats.SaveStatisticTimestamp @TableName NVARCHAR(255) AS
BEGIN
	DECLARE @SqlCommand NVARCHAR(MAX) =
	        N'DECLARE @data stats.ImportDataStatisticType;
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
	                ,0
	                ,0
	                ,SUM(RA)
	                ,0
	                ,0
	          FROM   (
						SELECT COUNT(*)  AS A
						      ,0         AS RA
						      ,isnull(Timestamp,N''Fichier non renseigne'') as FichierTS
						FROM  ' + @TableName + 
	        '
						GROUP BY Timestamp
	                 )x GROUP BY FichierTS
	                 EXEC stats.MergeStatistic @data, @TableName
	                 '
	
	DECLARE @param NVARCHAR(255) =
	        N'@TableName NVARCHAR(255)'
	
	EXECUTE sp_executesql @SqlCommand
	       ,@Param
	       ,@TableName = @TableName
END