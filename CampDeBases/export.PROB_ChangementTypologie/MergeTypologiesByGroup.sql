--ALTER PROC etl.PROB_ChangementTypologie AS
--BEGIN
--	SET NOCOUNT ON
	DECLARE @curDate DATE = '20150805'
	        MERGE export.PROB_ChangementTypologie AS s 
	        USING (
	            SELECT t.MasterID, t.MarqueID, t.TypologieID, tg.GroupID as	TypoGR1
	            FROM   dbo.Typologie_05082015 t
	            INNER JOIN etl.V_TypologiesByGroup tg ON t.TypologieID = tg.TypologieID
	        ) t ON (t.MasterID = s.masterId AND t.MarqueID = s.marqueId AND t.TypoGR1 = s.TypoGR1  )
	WHEN MATCHED AND t.TypologieID <> s.CurrTypologieID THEN 
	UPDATE 
	SET    s.PrevTypologieID = s.CurrTypologieID
	      ,s.CurrTypologieID = t.TypologieID
	      ,ChangeDate = @curDate
	       WHEN NOT MATCHED THEN
	INSERT 
	  (
	    MasterID
	   ,MarqueID
	   ,CurrTypologieID
	   ,PrevTypologieID
	   ,TypoGR1
	   ,ChangeDate
	  )
	VALUES
	  (
	    MasterId
	   ,MarqueId
	   ,TypologieID
	   ,NULL
	   ,TypoGR1
	   ,@curDate
	  )
	WHEN NOT MATCHED BY SOURCE THEN
	UPDATE 
	SET    s.PrevTypologieID = s.CurrTypologieID
	      ,s.CurrTypologieID = NULL
	      ,ChangeDate = @curDate;
--END

--TRUNCATE TABLE export.PROB_ChangementTypologie

