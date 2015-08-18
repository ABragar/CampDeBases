
IF OBJECT_ID('etl.ChangementTypologieKeySet' ,'U') IS NOT NULL
    DROP TABLE etl.ChangementTypologieKeySet
GO	 
CREATE TABLE etl.ChangementTypologieKeySet
(
	ChangementId     INT PRIMARY KEY IDENTITY
   ,MasterID         INT NOT NULL
   ,MarqueID         INT NOT NULL
   ,TypoGR1          NVARCHAR(8)
)
GO

--CREATE UNIQUE INDEX idx_MasterMarqueGr1 ON etl.ChangementTypologieKeySet(MasterID, MarqueID, TypoGR1)

IF OBJECT_ID('etl.ChangementTypologieHistory' ,'U') IS NOT NULL
    DROP TABLE etl.ChangementTypologieHistory
 GO	 
CREATE TABLE etl.ChangementTypologieHistory
(
	ChangementId        INT NOT NULL   
   ,CurrTypologieID     INT NULL
   ,PrevTypologieID     INT NULL
   ,ChangeDate          DATE
   , CONSTRAINT FK_ChangementTypologieHistoryChangementId FOREIGN KEY (ChangementId) REFERENCES etl.ChangementTypologieKeySet(ChangementId) ON DELETE cascade 
)
GO


IF OBJECT_ID('etl.ChangementTypologieSliceLast' ,'U') IS NOT NULL
    DROP TABLE etl.ChangementTypologieSliceLast
 GO	 
CREATE TABLE etl.ChangementTypologieSliceLast
(
	ChangementId        INT NOT NULL 
   ,CurrTypologieID     INT NULL
   ,PrevTypologieID     INT NULL
   ,ChangeDate          DATE
   ,CONSTRAINT FK_ChangementTypologieSliceLastChangementId FOREIGN KEY (ChangementId) REFERENCES etl.ChangementTypologieKeySet(ChangementId) ON DELETE cascade
)
GO



--IF OBJECT_ID('export.PROB_ChangementTypologie' ,'U') IS NOT NULL
--    DROP TABLE export.PROB_ChangementTypologie
-- GO	 
--CREATE TABLE export.PROB_ChangementTypologie
--(
--	MasterID            INT NOT NULL
--   ,MarqueID            INT NOT NULL
--   ,CurrTypologieID     INT NULL
--   ,PrevTypologieID     INT NULL
--   ,TypoGR1				NVARCHAR(8)
--   ,ChangeDate          DATE
--)
--GO

--Set groups of typologie
ALTER VIEW etl.V_GroupOfTypologies
AS
SELECT GroupID
FROM   (VALUES('CSPG') ,('CSPP'),('CSNG'),('CSNP'),('CANG'),('CANP'),('CAPG'),('CAPP'),('PM'),('PG'),('OE'),('VI')) x(GroupID)

--Join typologies vs group
ALTER VIEW etl.V_TypologiesByGroup
AS
SELECT distinct TypoId AS TypologieID, GroupID
FROM  ref.typologie AS m
INNER JOIN etl.V_GroupOfTypologies ON m.Libelle LIKE GroupID+'%' 

SELECT * FROM ref.typologie