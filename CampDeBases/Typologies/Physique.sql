use AmauryVUC
go

alter table ref.CatalogueProduits add Physique bit not null default (0)
go

UPDATE cp
SET Physique = 1
FROM ref.CatalogueProduits cp
INNER JOIN etl.TRANSCO AS t 
	ON cp.CategorieProduit = t.Origine 
	AND t.TranscoCode=N'ORIGINEACHAT' 
	and t.SourceId=N'1' 
	AND t.Destination=N'Physique'
where cp.SourceID=1
-- (42917 row(s) affected)

UPDATE a
SET Physique = 1
FROM ref.CatalogueProduits a
WHERE coalesce(a.CategorieProduit,N'')<>N'NUM'
and a.SourceID=3
-- (6 row(s) affected)

go







