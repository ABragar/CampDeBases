	
ALTER VIEW etl.V_TypologieTransitions
AS
SELECT IdFrom,IdTo
FROM   (VALUES(90,86) ) x(IdFrom,IdTo)

--,(10,11)

SELECT * FROM etl.V_TypologieTransitions

 

--SELECT * FROM etl.V_TypologiesByGroup
--пишем какую то-выборку. Если понимаем что классификация не устраивает, меняем 	etl.V_GroupOfTypologies, без изменения запроса.
SELECT t.*, g.groupId 
FROM Typologie AS t
INNER JOIN etl.V_TypologiesByGroup g on	t.TypologieID = g.typologieId

SELECT * FROM  etl.V_TypologiesByGroup

--BULK INSERT dbo.Typologie_05082015
--FROM 'D:\Projects\Camp de bases\dboTypologie_05-08-2015.csv' WITH (FIELDTERMINATOR =';',ROWTERMINATOR = '\n'); --FORMATFILE='C:\t_floatformat-c-xml.xml'
--GO
----(9603700 row(s) affected)


SELECT * FROM dbo.Typologie_04082015 AS t_04082015
INNER JOIN dbo.Typologie AS t ON 
t.MasterID = t_04082015.MasterID
AND t.MarqueID = t_04082015.MarqueID
AND t.TypologieID = t_04082015.TypologieID
--(402462 row(s) affected)

SELECT COUNT(*) FROM dbo.Typologie AS t	  --419535

SELECT TOP 0 * INTO dbo.Typologie_05082015
FROM dbo.Typologie AS t

SELECT * FROM etl.V_TypologiesByGroup


SELECT t.MasterID, t.MarqueID, t.TypologieID, tg.GroupID as	TypoGR1
	            FROM   dbo.Typologie_05082015 t
	            INNER JOIN etl.V_TypologiesByGroup tg ON t.TypologieID = tg.TypologieID 
	            WHERE  MasterID IS NOT NULL


SELECT * FROM ref.typologie	

SELECT * FROM dbo.Typologie_04082015 AS t
WHERE masterId = 72618

SELECT * FROM dbo.Typologie_05082015 AS t
WHERE masterId = 72618          