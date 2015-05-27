-- delete from ImportDataStatistic
USE AmauryVUC

EXEC stats.RefreshStatistic


SELECT * FROM stats.ImportDataStatistic	order by TraitementDate Desc, FichierTS, TableName
