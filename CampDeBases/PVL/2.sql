SELECT * FROM ref.Sources

WHERE MarqueID = 3

select * from ref.Misc a where a.TypeRef=N'STATUTCOMPTEVEL'

select * from ref.Misc a where a.TypeRef=N'TYPECTNU'

select * from ref.Misc a where a.TypeRef=N'MARQUE'
select * from ref.Misc a where a.TypeRef=N'MARQUE' and a.CodeValN=3

select * from ref.Contenus a where a.MarqueID=3 and a.TypeContenu=2

DECLARE @x INT
set @x = etl.GetMarqueID(N'France Football')

select etl.GetContenuID(@x,N'Commercial')
select * from ref.Contenus a where a.MarqueID=3

select * from ref.Misc a where a.TypeRef=N'TYPECTNU'

select * from brut.ConsentementsEmail