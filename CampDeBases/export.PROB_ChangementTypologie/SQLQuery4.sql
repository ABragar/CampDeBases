	DECLARE @curDate DATE = '20150805'
	        
	        MERGE export.PROB_ChangementTypologie AS s 
	        USING (
	            --
	            SELECT t.MasterID, t.MarqueID, t.TypologieID, tg.GroupID as	TypoGR1, tt.IdFrom, tt.idTo
	            FROM   dbo.Typologie_05082015 t
	            JOIN etl.V_TypologiesByGroup tg ON t.TypologieID = tg.TypologieID
	            left JOIN etl.V_TypologieTransitions  tt ON t.TypologieID = tt.IdTo
--	            order BY masterID  
				--(9603700 row(s) affected)														
	        ) t ON (t.MasterID = s.masterId AND t.MarqueID = s.marqueId AND (t.TypoGR1 = s.TypoGR1 OR (t.idfrom is not null and t.idto is not null and t.TypoGR1 != s.TypoGR1 and s.CurrTypologieID = t.IdFrom AND t.TypologieID = t.idTo)))  
	WHEN MATCHED AND (t.TypologieID <> s.CurrTypologieID)  
	THEN 
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


SELECT COUNT(*) FROM export.PROB_ChangementTypologie
--9586000
SELECT COUNT(*)	FROM dbo.Typologie_05082015
--9603700

SELECT 9603700-9586000
--17700 
SELECT MasterID, TypologieId,MarqueID, Appartenance FROM dbo.Typologie_04082015
INTERSECT
SELECT MasterID, TypologieId,MarqueID, Appartenance FROM dbo.Typologie_05082015
--(9572266 row(s) affected)

SELECT MasterID, TypologieId,MarqueID, Appartenance FROM dbo.Typologie_04082015
EXCEPT
SELECT MasterID, TypologieId,MarqueID, Appartenance FROM dbo.Typologie_05082015
--(13734 row(s) affected)

SELECT MasterID, TypologieId,MarqueID, Appartenance FROM dbo.Typologie_05082015
EXCEPT
SELECT MasterID, TypologieId,MarqueID, Appartenance FROM dbo.Typologie_04082015
--(31434 row(s) affected)

SELECT 31434 + 13734 + 9572266
--9617434 