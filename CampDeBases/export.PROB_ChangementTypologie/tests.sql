EXEC etl.ChangeInTypologiesMixed '20150817'

SELECT * FROM dbo.Typologie AS t

SELECT * FROM brut.Contacts AS c		 
SELECT * FROM [brut].[ConsentementsEmail]		
SELECT * from [dbo].[ConsentementsEmail]

SELECT * FROM etl.ChangementTypologieSliceLast AS ctsl

SELECT * FROM etl.ChangementTypologieKeySet AS ctks	WHERE masterId IS NULL

SELECT * FROM brut.Contacts AS c

SELECT * FROM dbo.Contacts AS c

SELECT * FROM dbo.ConsentementsEmail AS ce

SELECT * FROM brut.Contacts AS c
WHERE c.MasterID = 1222806

SELECT * FROM dbo.Typologie AS t
WHERE t.MasterID = 1222806

SELECT * FROM etl.ChangementTypologieSliceLast AS ctsl
JOIN etl.ChangementTypologieKeySet AS ctks ON ctks.ChangementId = ctsl.ChangementId
WHERE ctks.MasterID = 1222806

SELECT * FROM etl.ChangementTypologieHistory AS cth
WHERE cth.ChangementId = 2532395
ORDER BY cth.ChangeDate

SELECT ctsl.ChangeDate, COUNT(ctsl.ChangementId)
FROM etl.ChangementTypologieSliceLast AS ctsl
GROUP BY ctsl.ChangeDate

select  rT.Code, rT.Libelle, rM.Valeur,  T.* from Typologie T 
inner join ref.Typologie rT on T.TypologieID = rT.TypoID
inner join ref.Misc rM on rM.CodeValN = T.MarqueID and rM.Typeref = 'MARQUE'
where MasterID = 1222806


SELECT * FROM etl.ChangementTypologieKeySet AS ctks
 WHERE ctks.MasterID = 1222806
 
 SELECT * FROM ref.Typologie AS t