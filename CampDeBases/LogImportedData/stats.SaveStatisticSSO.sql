USE AmauryVUC
GO
 
CREATE PROC stats.SaveStatisticSSO @TableName NVARCHAR(255) AS
BEGIN
	DECLARE @CumulTableName NVARCHAR(255)
	DECLARE @RejetTableName NVARCHAR(255)
	IF @TableName=N'import.LPPROSP_Prospects'
		BEGIN
			SET @CumulTableName = N'import.Prospects_Cumul'
			SET @RejetTableName = N'rejet.LPPROSP_Prospects'
		END
	ELSE
	IF @TableName=N'Import.LPSSO_SSO'
		BEGIN
			SET @CumulTableName = N'import.SSO_Cumul'
			SET @RejetTableName = N'rejet.LPSSO_SSO'
		END
	ELSE RETURN;
	
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
						      ,isnull(FichierTS,N''Fichier non renseigne'') as FichierTS
						FROM  '+ @CumulTableName+'
						WHERE  RejetCode = 0
						GROUP BY
						       FichierTS
						
						UNION ALL
						
						SELECT 0
						      ,COUNT(*)
						      ,isnull(FichierTS,N''Fichier non renseigne'') as FichierTS
						FROM   '+ @RejetTableName+'
						WHERE  RejetCode <> 0
						GROUP BY
						       FichierTS
	                 )x GROUP BY FichierTS
	                 EXEC stats.MergeStatistic @data, @TableName
	                 '
	
	DECLARE @param NVARCHAR(255) =
	        N'@TableName NVARCHAR(255)'
	
	EXECUTE sp_executesql @SqlCommand
	       ,@Param
	       ,@TableName = @TableName
END

