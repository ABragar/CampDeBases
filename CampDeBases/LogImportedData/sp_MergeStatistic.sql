USE AmauryVUC
GO

ALTER PROC sp_MergeStatistic(
                                @Data ImportDataStatisticType READONLY
                               ,@TableName NVARCHAR(255)
                            ) AS
BEGIN
	MERGE INTO ImportDataStatistic AS targ 
	USING @Data AS sourc 
	ON sourc.TableName = targ.TableName
	   AND sourc.FichierTS = targ.FichierTS
	   AND targ.TableName = @TableName
	WHEN MATCHED THEN 
	UPDATE  
	SET targ.Ajouts = sourc.Ajouts
	    ,targ.Modifications = sourc.Modifications
	    ,targ.Suppressions = sourc.Suppressions
	    ,targ.RejetAjouts = sourc.RejetAjouts
	    ,targ.RejetModifications = sourc.RejetModifications
	    ,targ.RejetSuppressions = sourc.RejetSuppressions
	    ,targ.TraitementDate = sourc.TraitementDate 
	
	WHEN NOT MATCHED BY TARGET THEN 
	INSERT  
	( 
	   TableName
	  ,FichierTS
	  ,Ajouts
	  ,Modifications
	  ,Suppressions
	  ,RejetAjouts
	  ,RejetModifications
	  ,RejetSuppressions
	  ,TraitementDate 
	) 
	VALUES 
	( 
	   sourc.TableName
	  ,sourc.FichierTS
	  ,sourc.Ajouts
	  ,sourc.Modifications
	  ,sourc.Suppressions
	  ,sourc.RejetAjouts
	  ,sourc.RejetModifications
	  ,sourc.RejetSuppressions
	  ,sourc.TraitementDate 
	) 
	
	WHEN NOT MATCHED BY SOURCE AND targ.TableName = @TableName THEN 
	UPDATE 
	SET    targ.Ajouts = 0
	      ,targ.Modifications = 0
	      ,targ.Suppressions = 0
	      ,targ.RejetAjouts = 0
	      ,targ.RejetModifications = 0
	      ,targ.RejetSuppressions = 0
	      ,targ.TraitementDate = GETDATE()
	;
END

