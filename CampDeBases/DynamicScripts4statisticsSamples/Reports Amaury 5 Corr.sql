use AmauryVUC
go

-- CAUSES DE RESILIATIONS
-- Nombre de résiliations par cause

; with s as (
 select AbonnementID from dbo.Abonnements
 )
 
 , m as (
select a.AbonnementID
, a.FinAboDate
, a.ReaboDate
, a.MotifFinAbo
, d.Mois
from report.AboStats a 
inner join s on a.AbonnementID=s.AbonnementID 
cross join report.DouzeDerniersMois d
)


, n as (
select m.Mois
, m.AbonnementID
, b.MotFinID as MotifFinAbo
from m
inner join ref.MotifFinAboCompress b on (case when m.MotifFinAbo is null and m.FinAboDate is not null and (m.ReaboDate is null or m.ReaboDate<m.FinAboDate) then 5 else m.MotifFinAbo end)= b.MotFinID
where m.FinAboDate>=m.Mois and m.FinAboDate<DATEADD(month,1,m.Mois) 

)

-- select * from n as m where m.MotifFinAbo is null and m.FinAboDate is not null and m.ReaboDate is null

, p as (
select n.Mois
, sum(case when n.MotifFinAbo=1 then 1 else 0 end) as AccesLogistique
, sum(case when n.MotifFinAbo=2 then 1 else 0 end) as Annulation7Jours
, sum(case when n.MotifFinAbo=3 then 1 else 0 end) as Autre
, sum(case when n.MotifFinAbo=4 then 1 else 0 end) as ProblemePerso
, sum(case when n.MotifFinAbo=5 then 1 else 0 end) as EcheanceNonReabo
, sum(case when n.MotifFinAbo=6 then 1 else 0 end) as FausseAnnul
, sum(case when n.MotifFinAbo=7 then 1 else 0 end) as ProblemePaiement
, sum(case when n.MotifFinAbo=8 then 1 else 0 end) as Produit
, sum(case when n.MotifFinAbo=9 then 1 else 0 end) as SansMotif
from n
group by n.Mois
)

, t as (
select 
p.Mois
, p.AccesLogistique
, p.Annulation7Jours
, p.Autre
, p.ProblemePerso
, p.EcheanceNonReabo
, p.FausseAnnul
, p.ProblemePaiement
, p.Produit
, p.SansMotif
from p
)

select * from t order by Mois
-- 0'01"