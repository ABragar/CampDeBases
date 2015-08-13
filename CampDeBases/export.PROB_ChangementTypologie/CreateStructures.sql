IF OBJECT_ID('export.PROB_ChangementTypologie' ,'U') IS NOT NULL
    DROP TABLE export.PROB_ChangementTypologie
 GO	 
CREATE TABLE export.PROB_ChangementTypologie
(
	MasterID            INT NOT NULL
   ,MarqueID            INT NOT NULL
   ,CurrTypologieID     INT NULL
   ,PrevTypologieID     INT NULL
   ,TypoGR1				NVARCHAR(8)
   ,ChangeDate          DATE
)
GO

--Set groups of typologie
ALTER VIEW etl.V_GroupOfTypologies
AS
SELECT GroupID
FROM   (VALUES('CSPG') ,('CSPP'),('CSNG'),('CSNP'),('CANG'),('CANP'),('CAPG'),('CAPP'),('PM'),('PG'),('OE'),('VI'),('VI')) x(GroupID)

--Join typologies vs group
ALTER VIEW etl.V_TypologiesByGroup
AS
SELECT distinct TypoId AS TypologieID, GroupID
FROM  ref.typologie AS m
INNER JOIN etl.V_GroupOfTypologies ON m.Libelle LIKE GroupID+'%' 

SELECT * FROM ref.typologie