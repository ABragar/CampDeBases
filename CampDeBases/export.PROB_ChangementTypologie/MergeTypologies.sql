IF OBJECT_ID('export.PROB_ChangementTypologie' ,'U') IS NOT NULL
    DROP TABLE export.PROB_ChangementTypologie
 GO	
CREATE TABLE export.PROB_ChangementTypologie
(
	MasterID            INT NOT NULL
   ,MarqueID            INT NOT NULL
   ,CurrTypologieID     INT NULL
   ,PrevTypologieID     INT NULL
   ,ChangeDate          DATE
)
GO

ALTER PROC etl.PROB_ChangementTypologie AS
BEGIN
	SET NOCOUNT ON
	DECLARE @curDate DATE = CAST(GETDATE() AS DATE)
	        
	        MERGE export.PROB_ChangementTypologie AS e
	        USING (
	            SELECT MasterID,MarqueID, TypologieID
	            FROM   Typologie
	            WHERE  MasterID IS NOT NULL
	        ) t ON (t.MasterID = e.masterId AND t.MarqueID = e.marqueId)
	        WHEN MATCHED AND t.TypologieID <> e.CurrTypologieID THEN
	UPDATE 
	SET    e.PrevTypologieID = e.CurrTypologieID
	      ,e.CurrTypologieID = t.TypologieID
	      ,ChangeDate = @curDate
	       WHEN NOT MATCHED THEN
	
	INSERT 
	  (
	    MasterID
	   ,MarqueID
	   ,CurrTypologieID
	   ,PrevTypologieID
	   ,ChangeDate
	  )
	VALUES
	  (
	    MasterId
	   ,MarqueId
	   ,TypologieID
	   ,NULL
	   ,@curDate
	  )
	WHEN NOT MATCHED BY SOURCE THEN
	UPDATE 
	SET    e.PrevTypologieID = e.CurrTypologieID
	      ,e.CurrTypologieID = NULL
	      ,ChangeDate = @curDate;
END


--EXEC etl.PROB_ChangementTypologie

--SELECT * FROM export.PROB_ChangementTypologie