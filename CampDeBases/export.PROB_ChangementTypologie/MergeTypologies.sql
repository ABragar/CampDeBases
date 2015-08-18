ALTER PROC etl.PROB_ChangementTypologie AS
BEGIN
	SET NOCOUNT ON
	DECLARE @curDate DATE = GETDATE()
	
	MERGE etl.ChangementTypologieKeySet AS s 
	        USING (
	            SELECT t.MasterID, t.MarqueID, tg.GroupID as	TypoGR1
	            FROM   dbo.Typologie t
	            INNER JOIN etl.V_TypologiesByGroup tg ON t.TypologieID = tg.TypologieID
	            GROUP BY t.MasterID, t.MarqueID, tg.GroupID
	        ) t ON (t.MasterID = s.masterId AND t.MarqueID = s.marqueId AND t.TypoGR1 = s.TypoGR1)
	WHEN NOT MATCHED THEN
	INSERT 
	  (
	    MasterID
	   ,MarqueID
	   ,TypoGR1
	  )
	VALUES
	  (
	    MasterId
	   ,MarqueId
	   ,TypoGR1
	  );

	IF OBJECT_ID('tempdb..#tmpHistory' ,'U') IS NOT NULL
    DROP TABLE #tmpHistory

	CREATE TABLE #tmpHistory
(
	ChangementId        INT NOT NULL   
   ,CurrTypologieID     INT NULL
   ,PrevTypologieID     INT NULL
   ,ChangeDate          DATE
)
	
	INSERT into #tmpHistory 
	SELECT changeset.ChangementId, changeset.CurrTypologieID,changeset.PrevTypologieID, changeset.ChangeDate
	from
	(
	        MERGE etl.ChangementTypologieSliceLast AS s 
	        USING (
	            SELECT ChangementId, t.TypologieID
	            FROM   dbo.Typologie t
	            INNER JOIN etl.V_TypologiesByGroup tg ON t.TypologieID = tg.TypologieID
	            INNER JOIN etl.ChangementTypologieKeySet k ON k.masterID = t.masterId AND k.MarqueId = t.marqueID AND k.TypoGR1 = tg.GroupID 
	        ) t ON (t.ChangementId = s.ChangementId)
	WHEN MATCHED AND t.TypologieID <> s.CurrTypologieID THEN
	UPDATE 
	SET    s.PrevTypologieID = s.CurrTypologieID
	      ,s.CurrTypologieID = t.TypologieID
	      ,ChangeDate = @curDate
	WHEN NOT MATCHED THEN
	INSERT 
	  (
	   ChangementId
	   ,CurrTypologieID
	   ,PrevTypologieID
	   ,ChangeDate
	  )
	VALUES
	  (
	    ChangementId
	   ,TypologieID
	   ,NULL
	   ,@curDate
	  )
	WHEN NOT MATCHED BY SOURCE THEN
	UPDATE 
	SET    s.PrevTypologieID = s.CurrTypologieID
	      ,s.CurrTypologieID = NULL
	      ,ChangeDate = @curDate
	OUTPUT $action, DELETED.ChangementId, DELETED.CurrTypologieID, DELETED.PrevTypologieID, DELETED.ChangeDate) AS changeset(Action, ChangementId, CurrTypologieID, PrevTypologieID, ChangeDate)
	WHERE Action = 'UPDATE'
	;

INSERT INTO etl.ChangementTypologieHistory (ChangementId, CurrTypologieID, PrevTypologieID, ChangeDate)
SELECT ChangementId, CurrTypologieID,PrevTypologieID, ChangeDate
FROM #tmpHistory


END

