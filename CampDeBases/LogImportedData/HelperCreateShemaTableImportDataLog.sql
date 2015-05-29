/************************************************************
 * Code formatted by SoftTree SQL Assistant © v7.1.246
 * Time: 29.05.2015 14:08:10
 ************************************************************/

CREATE SCHEMA STATS

GO
CREATE TABLE STATS.ImportDataStatistic
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

ALTER TABLE STATS.ImportDataStatistic
ADD TIMESTAMPDATE DATETIME 

CREATE TYPE STATS.ImportDataStatisticType AS TABLE
(
    TableName NVARCHAR(100) --
   ,FichierTS NVARCHAR(255) --File name
   ,Ajouts INT --add
   ,Modifications INT --update
   ,Suppressions INT --delete
   ,RejetAjouts INT --add
   ,RejetModifications INT --update
   ,RejetSuppressions INT --delete
   ,TraitementDate DATETIME NOT NULL DEFAULT GETDATE()
)
