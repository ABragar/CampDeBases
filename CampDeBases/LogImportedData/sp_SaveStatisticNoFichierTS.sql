USE AmauryVUC
GO

ALTER PROC sp_SaveStatisticNoFichierTS @TableName NVARCHAR(255) AS
BEGIN
	PRINT @TableName
	--DECLARE @SqlCommand NVARCHAR(MAX) =
	--        N'DECLARE @data ImportDataStatisticType;
	--        INSERT @data
	--            (
	--              TableName
	--             ,FichierTS
	--             ,Ajouts
	--             ,Modifications
	--             ,Suppressions
	--             ,RejetAjouts
	--             ,RejetModifications
	--             ,RejetSuppressions
	--            )
	--          SELECT @TableName as TableName
	--                ,FichierTS
	--                ,SUM(A)
	--                ,0
	--                ,0
	--                ,SUM(RA)
	--                ,0
	--                ,0
	--          FROM   (
	--					SELECT COUNT(*)  AS A
	--					      ,0         AS RA
	--					      ,N''Fichier non renseigne'' as FichierTS
	--					FROM  '+ @TableName+'
	--					WHERE  RejetCode = 0
						
	--					UNION ALL
						
	--					SELECT 0
	--					      ,COUNT(*)
	--					      ,N''Fichier non renseigne'' as FichierTS
	--					FROM   '+ @TableName+'
	--					WHERE  RejetCode <> 0
	--                 )x GROUP BY FichierTS
	--                 EXEC sp_MergeStatistic @data, @TableName
	--                 '
	
	--DECLARE @param NVARCHAR(255) =
	--        N'@TableName NVARCHAR(255)'
	
	--EXECUTE sp_executesql @SqlCommand
	--       ,@Param
	--       ,@TableName = @TableName
END