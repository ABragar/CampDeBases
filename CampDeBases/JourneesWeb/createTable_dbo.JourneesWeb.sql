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
 ,MoyenneDuree DECIMAL NOT NULL DEFAULT 0 
 ,CodeOSPrincipal INT NULL
 ,NumericAbo BIT NOT NULL DEFAULT 0 
 ,OptinEditorial BIT NOT NULL DEFAULT 0
 ,PremierVisite DATETIME NOT NULL DEFAULT 0
 ,DernierVisite DATETIME NOT NULL DEFAULT 0
 --,CONSTRAINT pk_MasterSiteDate PRIMARY KEY (MasterID,SiteID,DateVisite) 
 )
