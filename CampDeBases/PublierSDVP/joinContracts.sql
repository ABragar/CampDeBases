--select * from #T_Brut_Contrats a
select * from #T_Abonnements_Brut
select * from #T_TrouverProfil
select * from #T_TrouverAncLignes
select * from #T_Abonnements_Brut

if OBJECT_ID('tempdb..#T_Brut_Contrats') is not null
	drop table #T_Brut_Contrats

create table #T_Brut_Contrats 
(
ContratID int not null
, MasterAboID int null -- = AbonnementID de abo.Abonnements
, ProfilID int not null
, CTRCODSOC nvarchar(8) not null
, CTRCODTAR nvarchar(8) not null
, CTRCODOFF nvarchar(8) not null
, CTRCODPRV nvarchar(32) not null
, CTRCODTIT nvarchar(8) not null
, CTROPTOFF nvarchar(8) not null
, CTRNUMABO nvarchar(18) not null
, CTRNUMCTR nvarchar(8) not null
, CatalogueAbosID int null
, SouscriptionAboDate datetime null
, DebutAboDate datetime null
, FinAboDate datetime null
, ExAboSouscrNb int not null default(0)
, RemiseAbo decimal(10,2) null
, MontantAbo decimal(10,2) null 
, Devise nvarchar(16) null
, PremierNumeroServi int null
, DernierNumeroServi int null
, DatePremierNumeroServi datetime null
, DateDernierNumeroServi datetime null
, Fidelite nvarchar(8) null
, ModeExpedition int null
, SuspensionAbo bit not null default(0)
, MotifFinAbo int null
, MotifProlongation int null
, AnnulationDate datetime null
, ReaboDate datetime null
, OrigineAbo int null
, ModeSouscription int null
, ModePaiement int null
, ValiditeCB datetime null
, ModifieTop bit not null 
, SupprimeTop bit not null 
, CTRNUMGCP nvarchar(18) null	-- Champ technique pour le calcul de StatutAbo
, CTRNUMFIN nvarchar(18) null	-- Champ technique pour le calcul de StatutAbo
, DateFinParutions datetime null	-- Champ technique pour le calcul de StatutAbo
)

insert #T_Brut_Contrats
(
ContratID
, MasterAboID
, ProfilID
, CTRCODSOC
, CTRCODTAR
, CTRCODOFF
, CTRCODPRV
, CTRCODTIT
, CTROPTOFF
, CTRNUMABO
, CTRNUMCTR
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, ExAboSouscrNb
, RemiseAbo
, MontantAbo
, Devise
, PremierNumeroServi
, DernierNumeroServi
, DatePremierNumeroServi
, DateDernierNumeroServi
, Fidelite
, ModeExpedition
, SuspensionAbo
, MotifFinAbo
, MotifProlongation
, AnnulationDate
, ReaboDate
, OrigineAbo
, ModeSouscription
, ModePaiement
, ValiditeCB
, ModifieTop
, SupprimeTop
, CTRNUMGCP
, CTRNUMFIN
, DateFinParutions
)
select 
ContratID
, MasterAboID
, ProfilID
, CTRCODSOC
, CTRCODTAR
, CTRCODOFF
, CTRCODPRV
, CTRCODTIT
, CTROPTOFF
, CTRNUMABO
, CTRNUMCTR
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, ExAboSouscrNb
, RemiseAbo
, MontantAbo
, Devise
, PremierNumeroServi
, DernierNumeroServi
, DatePremierNumeroServi
, DateDernierNumeroServi
, Fidelite
, ModeExpedition
, SuspensionAbo
, MotifFinAbo
, MotifProlongation
, AnnulationDate
, ReaboDate
, OrigineAbo
, ModeSouscription
, ModePaiement
, ValiditeCB
, ModifieTop
, SupprimeTop
, CTRNUMGCP
, CTRNUMFIN
, DateFinParutions
from brut.Contrats_Abos
where ModifieTop=1 -- Lignes nouvellement inserees ou modifiees
and SourceID=3 -- Donnees SDVP

create index ind_01_T_Brut_Contrats on #T_Brut_Contrats (ProfilID, CTRCODSOC, CTRCODTIT)

-- Une table temporaire avec les lignes de brut.Contrats_Abos pour les agreger en un seul abonnement
-- S'aliment en deux temps : avec les nouvelles lignes, ensuite les anciennes qui leur correspondent

if OBJECT_ID('tempdb..#T_Abonnements_Brut') is not null
	drop table #T_Abonnements_Brut
	
create table #T_Abonnements_Brut
(
ContratID int null
, MasterAboID int null
, ProfilID int null				-- Champ de regroupement
, CTRCODSOC nvarchar(8) null	-- Champ de regroupement
, CTRCODTIT nvarchar(8) null	-- Champ de regroupement
, CTRNUMCTR int null -- cast as int, c'est important
, CTRCODOFF nvarchar(8) not null -- Champ de regroupement
, CTRCODPRV nvarchar(32) not null -- Champ de regroupement
, CTROPTOFF nvarchar(8) not null -- Champ de regroupement
, CatalogueAbosID int null
, SouscriptionAboDate datetime null
, DebutAboDate datetime null
, FinAboDate datetime null
, ExAboSouscrNb int null
, RemiseAbo decimal(10,2) null
, MontantAbo decimal(10,2) null
, Devise nvarchar(8) null
, PremierNumeroServi int null
, DernierNumeroServi int null
, DatePremierNumeroServi datetime null
, DateDernierNumeroServi datetime null
, Fidelite nvarchar(8) null
, ModeExpedition int null
, SuspensionAbo bit null
, MotifFinAbo int null
, MotifProlongation int null
, AnnulationDate datetime null
, ReaboDate datetime null
, OrigineAbo int null -- derniere ou premiere ?
, ModeSouscription int null
, ModePaiement int null
, ValiditeCB datetime null
, ModifieTop bit null
, SupprimeTop bit null
, CTRNUMGCP nvarchar(18) null	-- Champ technique pour le calcul de StatutAbo
, CTRNUMFIN nvarchar(18) null	-- Champ technique pour le calcul de StatutAbo
, DateFinParutions datetime null	-- Champ technique pour le calcul de StatutAbo
, NumAbonne int null
, NomAbo nvarchar(255) null
)

insert #T_Abonnements_Brut
(
ContratID
, MasterAboID
, ProfilID
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CTRNUMCTR
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, ExAboSouscrNb
, RemiseAbo
, MontantAbo
, Devise
, PremierNumeroServi
, DernierNumeroServi
, DatePremierNumeroServi
, DateDernierNumeroServi
, Fidelite
, ModeExpedition
, SuspensionAbo
, MotifFinAbo
, MotifProlongation
, AnnulationDate
, ReaboDate
, OrigineAbo
, ModeSouscription
, ModePaiement
, ValiditeCB
, ModifieTop
, SupprimeTop
, CTRNUMGCP
, CTRNUMFIN
, DateFinParutions
, NumAbonne
, NomAbo
)
select
 a.ContratID
, a.MasterAboID
, a.ProfilID
, a.CTRCODSOC
, a.CTRCODTIT
, a.CTRCODOFF
, a.CTRCODPRV
, a.CTROPTOFF
, cast(a.CTRNUMCTR as int)
, a.CatalogueAbosID
, a.SouscriptionAboDate
, a.DebutAboDate
, a.FinAboDate
, a.ExAboSouscrNb
, a.RemiseAbo
, a.MontantAbo
, a.Devise
, a.PremierNumeroServi
, a.DernierNumeroServi
, a.DatePremierNumeroServi
, a.DateDernierNumeroServi
, a.Fidelite
, a.ModeExpedition
, a.SuspensionAbo
, a.MotifFinAbo
, a.MotifProlongation
, a.AnnulationDate
, a.ReaboDate
, a.OrigineAbo
, a.ModeSouscription
, a.ModePaiement
, a.ValiditeCB
, a.ModifieTop
, a.SupprimeTop
, a.CTRNUMGCP
, a.CTRNUMFIN
, a.DateFinParutions
, cast(a.CTRNUMABO as int)
, null as NomAbo
from #T_Brut_Contrats a

-- On trouve le dernier profil de chaque abonnement

if OBJECT_ID('tempdb..#T_TrouverProfil') is not null
	drop table #T_TrouverProfil

create table #T_TrouverProfil
(
CTRNUMABO int null
, CTRCODSOC nvarchar(8) null
, CTRCODTIT nvarchar(8) null
, CTRCODOFF nvarchar(8) null
, CTRCODPRV nvarchar(32) null
, CTROPTOFF nvarchar(8) null
, CTRNUMCTR_MAX int null
, ProfilID int null
)
SELECT * FROM #T_TrouverProfil
insert #T_TrouverProfil
(
CTRNUMABO
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CTRNUMCTR_MAX
)
select NumAbonne
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, max(CTRNUMCTR)
from #T_Abonnements_Brut
group by NumAbonne
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF

create index idx01_T_Abonnements_Brut on #T_Abonnements_Brut (NumAbonne
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CTRNUMCTR)

create index idx01_T_TrouverProfil on #T_TrouverProfil (CTRNUMABO
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CTRNUMCTR_MAX)

update a
set ProfilID=b.ProfilID
from #T_TrouverProfil a 
inner join #T_Abonnements_Brut b 
on a.CTRCODSOC=b.CTRCODSOC
and a.CTRNUMABO=b.NumAbonne
and a.CTRCODTIT=b.CTRCODTIT
and a.CTRCODOFF=b.CTRCODOFF
and a.CTRCODPRV=b.CTRCODPRV
and a.CTROPTOFF=b.CTROPTOFF
and a.CTRNUMCTR_MAX=b.CTRNUMCTR

update b
set ProfilID=b.ProfilID
from #T_TrouverProfil a 
inner join #T_Abonnements_Brut b 
on a.CTRCODSOC=b.CTRCODSOC
and a.CTRNUMABO=b.NumAbonne
and a.CTRCODTIT=b.CTRCODTIT
and a.CTRCODOFF=b.CTRCODOFF
and a.CTRCODPRV=b.CTRCODPRV
and a.CTROPTOFF=b.CTROPTOFF
where a.ProfilID<>b.ProfilID

if OBJECT_ID('tempdb..#T_TrouverProfil') is not null
	drop table #T_TrouverProfil

if OBJECT_ID('tempdb..#T_TrouverAncLignes') is not null
	drop table #T_TrouverAncLignes

create table #T_TrouverAncLignes
(
CTRNUMABO int null
, CTRCODSOC nvarchar(8) null
, CTRCODTIT nvarchar(8) null
, CTRCODOFF nvarchar(8) null
, CTRCODPRV nvarchar(32) null
, CTROPTOFF nvarchar(8) null
, ProfilID int null
)

insert #T_TrouverAncLignes 
(
CTRNUMABO
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, ProfilID
)
select distinct CTRNUMABO
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, ProfilID
from #T_Brut_Contrats


insert #T_Abonnements_Brut
(
ContratID
, MasterAboID
, ProfilID
, CTRCODSOC
, CTRCODTIT
, CTRNUMCTR
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, ExAboSouscrNb
, RemiseAbo
, MontantAbo
, Devise
, PremierNumeroServi
, DernierNumeroServi
, DatePremierNumeroServi
, DateDernierNumeroServi
, Fidelite
, ModeExpedition
, SuspensionAbo
, MotifFinAbo
, MotifProlongation
, AnnulationDate
, ReaboDate
, OrigineAbo
, ModeSouscription
, ModePaiement
, ValiditeCB
, ModifieTop
, SupprimeTop
, CTRNUMGCP
, CTRNUMFIN
, DateFinParutions
, NumAbonne
, NomAbo
)
select
 a.ContratID
, a.MasterAboID
, b.ProfilID -- Si le ProfilID a change, il est remplace par le nouveau dans toutes les lignes de l'abonnement, nouvelles et anciennes
, a.CTRCODSOC
, a.CTRCODTIT
, cast(a.CTRNUMCTR as int)
, a.CTRCODOFF
, a.CTRCODPRV
, a.CTROPTOFF
, a.CatalogueAbosID
, a.SouscriptionAboDate
, a.DebutAboDate
, a.FinAboDate
, a.ExAboSouscrNb
, a.RemiseAbo
, a.MontantAbo
, a.Devise
, a.PremierNumeroServi
, a.DernierNumeroServi
, a.DatePremierNumeroServi
, a.DateDernierNumeroServi
, a.Fidelite
, a.ModeExpedition
, a.SuspensionAbo
, a.MotifFinAbo
, a.MotifProlongation
, a.AnnulationDate
, a.ReaboDate
, a.OrigineAbo
, a.ModeSouscription
, a.ModePaiement
, a.ValiditeCB
, a.ModifieTop
, a.SupprimeTop
, a.CTRNUMGCP
, a.CTRNUMFIN
, a.DateFinParutions
, cast(a.CTRNUMABO as int)
, null as NomAbo
from  brut.Contrats_Abos a inner join #T_TrouverAncLignes b
on cast(a.CTRNUMABO as int)=b.CTRNUMABO
-- L'abonnement est le sextet CTRCODSOC, CTRNUMABO, CTRCODTIT, CTRCODOFF, CTRCODPRV, CTROPTOFF et il peut changer de ProfilID
and a.CTRCODSOC=b.CTRCODSOC
and a.CTRCODTIT=b.CTRCODTIT
and a.CTRCODOFF=b.CTRCODOFF
and a.CTRCODPRV=b.CTRCODPRV
and a.CTROPTOFF=b.CTROPTOFF
and a.ModifieTop=0 -- les anciennes lignes qui appartiennent aux memes abonnements que les nouvelles



-- A partir d'ici, on est sur que ProfilID = (CTRNUMABO,CTRCODSOC), et ProfilID+CTRCODSOC+CTRCODTIT+CTRCODOFF+CTRCODPRV+CTROPTOFF=1 Abonnement


if OBJECT_ID('tempdb..#T_TrouverAncLignes') is not null
	drop table #T_TrouverAncLignes
	

create index ind_01_T_Abonnements_Brut on #T_Abonnements_Brut (ProfilID)
create index ind_02_T_Abonnements_Brut on #T_Abonnements_Brut (CatalogueAbosID)
create index ind_03_T_Abonnements_Brut on #T_Abonnements_Brut (ProfilID, CTRCODSOC, CTRCODTIT,CTRCODOFF,CTRCODPRV,CTROPTOFF)


update a
set NomAbo=b.OffreAbo+N' '+b.OptionOffreAbo
from #T_Abonnements_Brut a inner join ref.CatalogueAbonnements b on a.CatalogueAbosID=b.CatalogueAbosID

-- On n'aura plus besoin de la table #T_Brut_Contrats

if OBJECT_ID('tempdb..#T_Brut_Contrats') is not null
	drop table #T_Brut_Contrats
	
-- C'est a partir d'abonnements brut que nous allons determiner les fusions et coupures
-- dans une autre table temporaire : #T_Abo_Fusion_Coupure


create table #T_Abo_Fusion_Coupure
(
ContratID int not null
, MasterAboID int null
, ProfilID int null				-- Champ de regroupement
, CTRCODSOC nvarchar(8) null	-- Champ de regroupement
, CTRCODTIT nvarchar(8) null	-- Champ de regroupement
, CTRNUMCTR int null -- cast as int, c'est important
, CTRCODOFF nvarchar(8) not null -- Champ de regroupement
, CTRCODPRV nvarchar(32) not null -- Champ de regroupement
, CTROPTOFF nvarchar(8) not null -- Champ de regroupement
, CatalogueAbosID int null
, DebutAboDate datetime null
, FinAboDate datetime null
, SeraMasterOuPas int null -- est-ce que ce contrat sera Master ou non
, NOrder int NULL
)

insert #T_Abo_Fusion_Coupure
(
ContratID
, MasterAboID
, ProfilID
, CTRCODSOC
, CTRCODTIT
, CTRNUMCTR
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CatalogueAbosID
, DebutAboDate
, FinAboDate
, NOrder
)
select
ContratID
, MasterAboID
, ProfilID
, CTRCODSOC
, CTRCODTIT
, CTRNUMCTR
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CatalogueAbosID
, DebutAboDate
, FinAboDate
, RANK() over (partition by ProfilID,CTRCODTIT order by CTRNUMCTR) as NOrder
from #T_Abonnements_Brut
order by ProfilID,CTRCODTIT,CTRNUMCTR  --ранг по номеру контракта, с сортировкой

UPDATE a
SET CTROPTOFF = lastCTRoptOFF
FROM #T_Abo_Fusion_Coupure a
	INNER JOIN (SELECT *, row_number() over (PARTITION BY MasterAboID
	,ProfilID
	,CTRCODSOC
	,CTRCODTIT
	,CTRCODOFF
	, CTRCODPRV order by norder desc) i, CTRoptOFF lastCTRoptOFF
		FROM #T_Abo_Fusion_Coupure) x ON a.MasterAboID = x.MasterAboID AND a.ProfilID = x.ProfilID AND a.CTRCODTIT = x.CTRCODTIT AND a.CTRCODPRV = x.CTRCODPRV
WHERE
x.i = 1
and a.CTRCODTIT=N'W1'
AND a.CTRCODOFF = N'NP1'
AND a.CTROPTOFF IN (N'2',N'18')

select * from #T_Abo_Fusion_Coupure
/*
update a
set MasterAboID=r1.ContratID from #T_Abo_Fusion_Coupure a inner join (
select min(ContratID) as ContratID,ProfilID,CTRCODTIT from #T_Abo_Fusion_Coupure group by ProfilID,CTRCODTIT
) as r1 on a.ContratID=r1.ContratID
where a.MasterAboID is null 
*/

-- on prend directement les lignes avec NOrder=1, qui correspond au min(CTRNUMCTR) et qui doit correspondre au min(ContratID) - normalement, mais pas toujours
 
--update #T_Abo_Fusion_Coupure set MasterAboID=null
--SELECT * FROM #T_Abo_Fusion_Coupure
update #T_Abo_Fusion_Coupure set MasterAboID=ContratID where NOrder=1 --если контракт 1 его номер проставляется в MasterAboID

declare @r4 int
declare @r5 int
declare @r6 int
set @r4=1
set @r5=1
set @r6=1

while not (@r4=0 and @r5=0 and @r6=0)
begin

update a 	   --устанавливаем MasterAboID из предидущей строки
set MasterAboID=b.MasterAboID
from #T_Abo_Fusion_Coupure a inner join #T_Abo_Fusion_Coupure b 
on a.ProfilID=b.ProfilID
and a.CTRCODTIT=b.CTRCODTIT
and a.CTRCODOFF=b.CTRCODOFF
and a.CTRCODPRV=b.CTRCODPRV
and a.CTROPTOFF=b.CTROPTOFF
and a.NOrder=b.NOrder+1
where a.MasterAboID is null
and b.MasterAboID is not null
and not
( dateadd(month,-6,a.DebutAboDate)>coalesce(b.FinAboDate,N'31-12-2078') ) --перерыв /между контрактами не более года
set @r4=@@rowcount

update a 
set MasterAboID=a.ContratID												   --если перерыв между контрактами > полгода, то мастерИД = контрактИд
from #T_Abo_Fusion_Coupure a inner join #T_Abo_Fusion_Coupure b 
on a.ProfilID=b.ProfilID
and a.CTRCODTIT=b.CTRCODTIT
and a.CTRCODOFF=b.CTRCODOFF
and a.CTRCODPRV=b.CTRCODPRV
and a.CTROPTOFF=b.CTROPTOFF
and a.NOrder=b.NOrder+1
where a.MasterAboID is null
and b.MasterAboID is not null
and ( dateadd(month,-6,a.DebutAboDate)>coalesce(b.FinAboDate,N'31-12-2078') )
set @r5=@@rowcount

update a 																  ----мастерИД = контрактИд при смене CTRCODOFF
set MasterAboID=a.ContratID
from #T_Abo_Fusion_Coupure a inner join #T_Abo_Fusion_Coupure b 
on ( a.ProfilID=b.ProfilID
and a.CTRCODTIT=b.CTRCODTIT  )
and not (a.CTRCODOFF=b.CTRCODOFF
and a.CTRCODPRV=b.CTRCODPRV
and a.CTROPTOFF=b.CTROPTOFF )
and a.NOrder=b.NOrder+1
where a.MasterAboID is null
and b.MasterAboID is not null
set @r6=@@rowcount

end	--цикл пока не обработаем все контракты

-- #T_Contrat_MinMax - table temporaire des agrégations
-- Elle servira de jointure avec la première et la dernière lignes de contrat de chaque abonnement
-- et fournira les sommes des montants et de remises

-- Puisque j'ai déjà MasterAboID dans #T_Abo_Fusion_Coupure, je pourrais regrouper directement par MasterAboID

update a
set MasterAboID=b.MasterAboID,  CTROPTOFF = b.CTROPTOFF
from #T_Abonnements_Brut a inner join #T_Abo_Fusion_Coupure b on a.ContratID=b.ContratID

update a
set MasterAboID=b.MasterAboID
from brut.Contrats_Abos a inner join #T_Abonnements_Brut b on a.ContratID=b.ContratID

if OBJECT_ID('tempdb..#T_Abo_Fusion_Coupure') is not null
	drop table #T_Abo_Fusion_Coupure

if OBJECT_ID('tempdb..#T_Contrat_MinMax') is not null
	drop table #T_Contrat_MinMax

create table #T_Contrat_MinMax 
(
ProfilID int null
--, CatalogueAbosID int null
, CTRCODSOC nvarchar(8) null
, CTRCODTIT nvarchar(8) null
, CTRCODOFF nvarchar(8) null
, CTRCODPRV nvarchar(32) null
, CTROPTOFF nvarchar(8) null
, CTRNUMCTR_MIN int null
, CTRNUMCTR_MAX int null
, MasterAboID int null
, RemiseAbo_Sum decimal(10,2) null
, MontantAbo_Sum decimal(10,2) null
)
 
insert #T_Contrat_MinMax 
(
ProfilID
--, CatalogueAbosID
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CTRNUMCTR_MIN
, CTRNUMCTR_MAX
, MasterAboID
, RemiseAbo_Sum
, MontantAbo_Sum
)
select 
ProfilID
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, MIN(ab.CTRNUMCTR) as CTRNUMCTR_MIN
, MAX(ab.CTRNUMCTR) as CTRNUMCTR_MAX
, MasterAboID
, SUM(coalesce(ab.RemiseAbo,0.00)) as RemiseAbo_Sum
, SUM(coalesce(ab.MontantAbo,0.00)) as MontantAbo_Sum
from #T_Abonnements_Brut ab
group by ProfilID
-- , CatalogueAbosID
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, MasterAboID

SELECT * FROM #T_Contrat_MinMax



create index ind_01_T_Contrat_MinMax on #T_Contrat_MinMax (ProfilID, CTRCODSOC, CTRCODTIT, CTRCODOFF, CTRCODPRV, CTROPTOFF)

-- Table temporaire agrégée où il n'y aura qu'une ligne par abonnement
-- Après divers enrichissements, elle alimentera la table dbo.Abonnements

if OBJECT_ID('tempdb..#T_Abonnements_Agreg') is not null
	drop table #T_Abonnements_Agreg
	
create table #T_Abonnements_Agreg
(
ContratID int null
, MasterID int null -- sera récupéré le cas échéant de dbo.Abonnement 
, MasterAboID int null
, ProfilID int null -- Champ de regroupement
, CTRCODSOC nvarchar(8) null -- Champ de regroupement
, CTRCODTIT nvarchar(8) null -- Champ de regroupement
, CTRCODOFF nvarchar(8) null -- Champ de regroupement
, CTRCODPRV nvarchar(32) null -- Champ de regroupement
, CTROPTOFF nvarchar(8) null -- Champ de regroupement
, CTRNUMCTR int null -- cast as int, c'est important
, Marque int null
, CatalogueAbosID int null
, SouscriptionAboDate datetime null
, DebutAboDate datetime null
, FinAboDate datetime null
, ExAboSouscrNb int null
, RemiseAbo decimal(10,2) null
, MontantAbo decimal(10,2) null
, Devise nvarchar(8) null
, PremierNumeroServi int null
, DernierNumeroServi int null
, DatePremierNumeroServi datetime null
, DateDernierNumeroServi datetime null
, Fidelite nvarchar(8) null
, ModeExpedition int null
, SuspensionAbo bit null
, MotifFinAbo int null
, MotifProlongation int null
, AnnulationDate datetime null
, ReaboDate datetime null
, OrigineAbo int null -- dernière 
, ModeSouscription int null
, ModePaiement int null
, ValiditeCB datetime null
, ModifieTop bit null
, SupprimeTop bit null
, CTRNUMGCP nvarchar(18) null	-- Champ technique pour le calcul de StatutAbo
, CTRNUMFIN nvarchar(18) null	-- Champ technique pour le calcul de StatutAbo
, DateFinParutions datetime null	-- Champ technique pour le calcul de StatutAbo
, NumAbonne int null
, NomAbo nvarchar(255) null
)

insert #T_Abonnements_Agreg
(
ContratID
, MasterAboID
, ProfilID
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CTRNUMCTR
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, ExAboSouscrNb
, RemiseAbo
, MontantAbo
, Devise
, PremierNumeroServi
, DernierNumeroServi
, DatePremierNumeroServi
, DateDernierNumeroServi
, Fidelite
, ModeExpedition
, SuspensionAbo
, MotifFinAbo
, MotifProlongation
, AnnulationDate
, ReaboDate
, OrigineAbo
, ModeSouscription
, ModePaiement
, ValiditeCB
, ModifieTop
, SupprimeTop
, CTRNUMGCP
, CTRNUMFIN
, DateFinParutions
, NumAbonne
, NomAbo
)
select
 a.ContratID
, b.MasterAboID
, a.ProfilID
, a.CTRCODSOC
, a.CTRCODTIT
, a.CTRCODOFF
, a.CTRCODPRV
, a.CTROPTOFF
, a.CTRNUMCTR
, a.CatalogueAbosID
, a.SouscriptionAboDate
, a.DebutAboDate
, a.FinAboDate
, a.ExAboSouscrNb
, b.RemiseAbo_Sum as RemiseAbo
, b.MontantAbo_Sum as RemiseAbo
, a.Devise
, a.PremierNumeroServi
, a.DernierNumeroServi
, a.DatePremierNumeroServi
, a.DateDernierNumeroServi
, a.Fidelite
, a.ModeExpedition
, a.SuspensionAbo
, a.MotifFinAbo
, a.MotifProlongation
, a.AnnulationDate
, a.ReaboDate
, a.OrigineAbo
, a.ModeSouscription
, a.ModePaiement
, a.ValiditeCB
, a.ModifieTop
, a.SupprimeTop
, a.CTRNUMGCP
, a.CTRNUMFIN
, a.DateFinParutions
, a.NumAbonne
, a.NomAbo
from #T_Abonnements_Brut a 
inner join #T_Contrat_MinMax b 
on a.ProfilID=b.ProfilID
and a.CTRCODSOC=b.CTRCODSOC
and a.CTRCODTIT=b.CTRCODTIT
and a.CTRCODOFF=b.CTRCODOFF
and a.CTRCODPRV=b.CTRCODPRV
and a.CTROPTOFF=b.CTROPTOFF
and a.CTRNUMCTR=b.CTRNUMCTR_MAX -- On prend la ligne la plus récente car il y a plus à récupérer
and a.MasterAboID=b.MasterAboID  -- выбираем по b.CTRNUMCTR_MAX  
SELECT * from #T_Abonnements_Agreg
-- CatalogueAbosID est pris sur la dernière ligne, plus récente
-- Même avec le regroupement par 6 champs, cette règle reste applicable

-- Ici, éliminer les doublons au niveau de MasterAboID 

create index ind_01_T_Abonnements_Agreg on #T_Abonnements_Agreg (ProfilID,CTRCODSOC,CTRCODTIT)
-- create index ind_02_T_Abonnements_Agreg on #T_Abonnements_Agreg (CatalogueAbosID)

-- Maintenant, récupérer ce qui nous est nécessaire de la 1ère ligne, par jointure avec #T_Contrat_MinMax : 
-- SouscriptionAboDate,DebutAboDate,PremierNumeroServi,DatePremierNumeroServi

update a								--select  DebutAboDate with  b.CTRNUMCTR_MIN
set DebutAboDate=c.DebutAboDate
	, PremierNumeroServi=c.PremierNumeroServi
	, DatePremierNumeroServi=c.DatePremierNumeroServi
from #T_Abonnements_Agreg a 
inner join #T_Contrat_MinMax b 
on a.ProfilID=b.ProfilID
and a.CTRCODSOC=b.CTRCODSOC
and a.CTRCODTIT=b.CTRCODTIT
and a.CTRCODOFF=b.CTRCODOFF
and a.CTRCODPRV=b.CTRCODPRV
and a.CTROPTOFF=b.CTROPTOFF
and a.MasterAboID=b.MasterAboID
inner join #T_Abonnements_Brut c 
on b.ProfilID=c.ProfilID
and b.CTRCODSOC=c.CTRCODSOC
and b.CTRCODTIT=c.CTRCODTIT
and b.CTRCODOFF=c.CTRCODOFF
and b.CTRCODPRV=c.CTRCODPRV
and b.CTROPTOFF=c.CTROPTOFF
and b.CTRNUMCTR_MIN=c.CTRNUMCTR
and b.MasterAboID=b.MasterAboID


-- Prendre la SouscriptionAboDate la plus ancienne renséignée
update a																			--update SouscriptionAboDate with rank 1
set SouscriptionAboDate=r1.SouscriptionAboDate
from #T_Abonnements_Agreg a inner join (
select rank() over (partition by b.MasterAboID order by b.SouscriptionAboDate asc, newid()) as N1 
, b.MasterAboID
, b.SouscriptionAboDate
, b.ProfilID
, b.CTRCODSOC
, b.CTRCODTIT
, b.CTRCODOFF
, b.CTRCODPRV
, b.CTROPTOFF
, b.CTRNUMABO
from brut.Contrats_Abos b where b.SourceID=@SourceID and b.SouscriptionAboDate is not null
) as r1 on a.NumAbonne=r1.CTRNUMABO
and a.CTRCODSOC=r1.CTRCODSOC
and a.CTRCODTIT=r1.CTRCODTIT
and a.CTRCODOFF=r1.CTRCODOFF
and a.CTRCODPRV=r1.CTRCODPRV
and a.CTROPTOFF=r1.CTROPTOFF
and a.MasterAboID=r1.MasterAboID
where r1.N1=1

-- Prendre la ReaboDate la plus récente renseignée
update a
set ReaboDate=r1.ReaboDate
from #T_Abonnements_Agreg a inner join (
select rank() over (partition by b.MasterAboID order by b.ReaboDate desc, newid()) as N1 
, b.MasterAboID
, b.ProfilID
, b.CTRCODSOC
, b.CTRCODTIT
, b.CTRCODOFF
, b.CTRCODPRV
, b.CTROPTOFF
, b.ReaboDate
, b.CTRNUMABO
from brut.Contrats_Abos b where b.SourceID =@SourceID and b.ReaboDate is not null) as r1 on a.NumAbonne=r1.CTRNUMABO
and a.CTRCODSOC=r1.CTRCODSOC
and a.CTRCODTIT=r1.CTRCODTIT
and a.CTRCODOFF=r1.CTRCODOFF
and a.CTRCODPRV=r1.CTRCODPRV
and a.CTROPTOFF=r1.CTROPTOFF
and a.MasterAboID=r1.MasterAboID
where r1.N1=1

-- Prendre le ModeExpedition le plus récent renseigné
update a
set ModeExpedition=r1.ModeExpedition
from #T_Abonnements_Agreg a inner join (
select rank() over (partition by b.MasterAboID order by cast(b.CTRNUMCTR as int) desc, newid()) as N1 
, b.MasterAboID
, b.ProfilID
, b.CTRCODSOC
, b.CTRCODTIT
, b.CTRCODOFF
, b.CTRCODPRV
, b.CTROPTOFF
, b.CTRNUMABO
, b.ModeExpedition
from brut.Contrats_Abos b where b.SourceID =@SourceID and b.ModeExpedition is not null) as r1 on a.NumAbonne=r1.CTRNUMABO
and a.CTRCODSOC=r1.CTRCODSOC
and a.CTRCODTIT=r1.CTRCODTIT
and a.CTRCODOFF=r1.CTRCODOFF
and a.CTRCODPRV=r1.CTRCODPRV
and a.CTROPTOFF=r1.CTROPTOFF
and a.MasterAboID=r1.MasterAboID
where r1.N1=1


-- Renseigner la marque

update a
set Marque=b.Marque
from #T_Abonnements_Agreg a inner join ref.CatalogueAbonnements b
on a.CatalogueAbosID=b.CatalogueAbosID

create index ind_03_T_Abonnements_Agreg on #T_Abonnements_Agreg (MasterAboID)

-- A présent, on peut alimenter la table etl.Abos_Agreg_SDVP

update a
set MasterID=a.MasterID -- afin de ne par perdre MasterID de la ligne dbo.Abonnements existante
from #T_Abonnements_Agreg a inner join dbo.Abonnements b on a.MasterAboID=b.AbonnementID

update #T_Abonnements_Agreg
set MasterID=ProfilID
where MasterID is  null

-- Sauvegarder la table #T_Abonnements_Agreg dans etl.Abos_Agreg_SDVP
-- Son contenu sera déversé dans dbo.Abonnements 
-- par la procédure etl.InsertAbonnements_Agreg dans le cadre du process commun

-- Supprimer les doublons dans #T_Abonnements_Agreg

delete a
from #T_Abonnements_Agreg a inner join 
(select rank() over (partition by a.MasterAboID order by a.ContratID) as N1
, a.MasterAboID, a.ContratID
from #T_Abonnements_Agreg a
inner join
(
select COUNT(*) as N, a.MasterAboID from #T_Abonnements_Agreg a group by a.MasterAboID having COUNT(*)>1
) as r1 on a.MasterAboID=r1.MasterAboID
) as r2 on a.ContratID=r2.ContratID
where r2.N1>1		--where r2.N1>1

delete a -- on supprime les lignes que l'on va remplacer
from etl.Abos_Agreg_SDVP a inner join #T_Abonnements_Agreg b on a.MasterAboID=b.MasterAboID

insert etl.Abos_Agreg_SDVP
(
ContratID
, MasterID
, MasterAboID
, ProfilID
, CTRCODSOC
, CTRCODTIT
, CTRCODOFF
, CTRCODPRV
, CTROPTOFF
, CTRNUMCTR
, Marque
, CatalogueAbosID
, SouscriptionAboDate
, DebutAboDate
, FinAboDate
, ExAboSouscrNb
, RemiseAbo
, MontantAbo
, Devise
, PremierNumeroServi
, DernierNumeroServi
, DatePremierNumeroServi
, DateDernierNumeroServi
, Fidelite
, ModeExpedition
, SuspensionAbo
, MotifFinAbo
, MotifProlongation
, AnnulationDate
, ReaboDate
, OrigineAbo
, ModeSouscription
, ModePaiement
, ValiditeCB
, ModifieTop
, SupprimeTop
, CTRNUMGCP
, CTRNUMFIN
, DateFinParutions
, NumAbonne
, NomAbo
)
select 
a.ContratID
, a.MasterID
, a.MasterAboID
, a.ProfilID
, a.CTRCODSOC
, a.CTRCODTIT
, a.CTRCODOFF
, a.CTRCODPRV
, a.CTROPTOFF
, a.CTRNUMCTR
, a.Marque
, a.CatalogueAbosID
, a.SouscriptionAboDate
, a.DebutAboDate
, a.FinAboDate
, a.ExAboSouscrNb
, a.RemiseAbo
, a.MontantAbo
, a.Devise
, a.PremierNumeroServi
, a.DernierNumeroServi
, a.DatePremierNumeroServi
, a.DateDernierNumeroServi
, a.Fidelite
, a.ModeExpedition
, a.SuspensionAbo
, a.MotifFinAbo
, a.MotifProlongation
, a.AnnulationDate
, a.ReaboDate
, a.OrigineAbo
, a.ModeSouscription
, a.ModePaiement
, a.ValiditeCB
, a.ModifieTop
, a.SupprimeTop
, a.CTRNUMGCP
, a.CTRNUMFIN
, a.DateFinParutions
, a.NumAbonne
, a.NomAbo
from #T_Abonnements_Agreg a


if OBJECT_ID('tempdb..#T_ConsentementsAbos') is not null
	drop table #T_ConsentementsAbos

if OBJECT_ID('tempdb..#T_Abonnements_Agreg') is not null
	drop table #T_Abonnements_Agreg

if OBJECT_ID('tempdb..#T_Contrat_MinMax') is not null
	drop table #T_Contrat_MinMax

-- Contrats BOX (Mode d'expédition : ABONNEMENT DIFFUSEUR)
-- Mise en quarantaine des contacts

/* update a
set QuarantaineTop=1
from brut.Contacts a 
inner join dbo.Abonnements b on a.ProfilID=b.ProfilID
inner join ref.CodeExpedition c
on b.ModeExpedition=c.CodeExpID
where c.CodeExp=N'09'*/
/*
update a
set QuarantaineTop=1
from brut.Contacts a 
inner join dbo.Abonnements b on a.ProfilID=b.ProfilID
inner join ref.CodeExpCompress c
on b.ModeExpedition=c.CodeExpID
where c.Libelle=N'ABONNEMENT DIFFUSEUR'
*/

update import.SDVP_Contrats
set LigneStatut=99
where FichierTS=@FichierTS
and LigneStatut=0


update brut.Contrats_Abos
set ModifieTop=0
where ModifieTop=1 -- Alimentations successives sans build ; normalement, cela doit être fait par la procédure FinTraitement
