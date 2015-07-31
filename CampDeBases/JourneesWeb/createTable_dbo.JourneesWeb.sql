 IF OBJECT_ID('dbo.JourneesWeb', 'U') IS NOT NULL 
	DROP TABLE dbo.JourneesWeb
 GO	
 
 CREATE TABLE  dbo.JourneesWeb
 (
  MasterID INT NOT NULL
 ,SiteID INT NOT NULL
 ,DateVisite DATE NOT NULL
 ,NbVisites INT NOT NULL DEFAULT 0
 ,NbPagesVues INT NOT NULL DEFAULT 0 
 ,NbPremiumPagesVues INT NOT NULL DEFAULT 0 
 ,MoyenneDuree FLOAT NOT NULL DEFAULT 0 
 ,CodeOSPrincipal INT NULL
 ,NumericAbo BIT NOT NULL DEFAULT 0 
 ,OptinEditorial BIT NOT NULL DEFAULT 0
 ,PremierVisite DATETIME NOT NULL DEFAULT 0
 ,DernierVisite DATETIME NOT NULL DEFAULT 0
 --,CONSTRAINT pk_MasterSiteDate PRIMARY KEY (MasterID,SiteID,DateVisite) 
 )

 IF OBJECT_ID('brut.V_NewsletterContenu', 'V') IS NOT NULL 
	DROP VIEW brut.V_NewsletterContenu
 GO	

CREATE VIEW brut.V_NewsletterContenu 
with SCHEMABINDING
AS

SELECT ce.ConsentementID
	  ,masterId
      ,MarqueID
      ,ce.ContenuID
      ,ce.ConsentementDate
      ,ce.valeur
FROM   brut.ConsentementsEmail AS ce
       INNER JOIN ref.Contenus cn
            ON  cn.TypeContenu = 1
                AND ce.ContenuID = cn.ContenuID
GO

CREATE unique CLUSTERED INDEX IX_ConsentementID ON brut.V_NewsletterContenu(ConsentementID)
CREATE INDEX IX_masterId ON brut.V_NewsletterContenu(masterId)
