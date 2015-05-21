DROP TABLE ImportDataStatistic
GO
CREATE TABLE ImportDataStatistic
(
	TableName              NVARCHAR(100) --
   ,Fichier                NVARCHAR(255) --File name
   ,Ajouts                 INT --add
   ,Modifications          INT --update
   ,Suppressions           INT --delete
   ,RejetAjouts            INT --add
   ,RejetModifications     INT --update
   ,RejetSuppressions      INT --delete
   ,TraitementDate         DATETIME NOT NULL DEFAULT GETDATE()
)
