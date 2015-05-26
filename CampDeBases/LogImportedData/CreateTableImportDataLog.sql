GO
CREATE TABLE ImportDataStatistic
(
	TableName              NVARCHAR(100) --
   ,FichierTS                NVARCHAR(255) --File name
   ,Ajouts                 INT --add
   ,Modifications          INT --update
   ,Suppressions           INT --delete
   ,RejetAjouts            INT --add
   ,RejetModifications     INT --update
   ,RejetSuppressions      INT --delete
   ,TraitementDate         DATETIME NOT NULL DEFAULT GETDATE()
)
CREATE TYPE ImportDataStatisticType AS TABLE
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
