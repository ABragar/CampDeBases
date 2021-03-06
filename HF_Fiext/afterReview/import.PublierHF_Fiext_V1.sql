USE AmauryVUC

DECLARE @fs NVARCHAR(255)
DECLARE @FichierTS NVARCHAR(255)
SET @FichierTS = 'D:\Projects\Camp de bases\FIEXT-18112014.csv' 
DECLARE @SourceID INT
SET @SourceID = 11

IF (NOT OBJECT_ID('tempdb..#HFFiextContacts') IS NULL)
    DROP TABLE #HFFiextContacts

CREATE TABLE #HFFiextContacts
(
	ProfilID             INT NULL,
	OriginalID           NVARCHAR(255) NULL,
	Origine              NVARCHAR(255) NULL,
	SourceID             INT NULL,
	RaisonSociale        NVARCHAR(255),
	Civilite             NVARCHAR(255),
	Prenom               NVARCHAR(255),
	Nom                  NVARCHAR(255),
	Genre                TINYINT,
	NaissanceDate        DATE,
	CatSocioProf         NVARCHAR(255),
	CreationDate         DATETIME,
	ModificationDate     DATETIME,
	FichierSource        NVARCHAR(255)
)
-- CreationDate и ModificationDate у нас всегда имеют тип DATETIME
-- если они не заданы в файле, присваиваем им значение GETDATE()

INSERT #HFFiextContacts
  (
    ProfilID,
    OriginalID,
    Origine,
    SourceID,
    RaisonSociale,
    Civilite,
    Prenom,
    Nom,
    Genre,
    NaissanceDate,
    CatSocioProf,
    CreationDate,
    ModificationDate,
    FichierSource
  )
SELECT NULL                          AS ProfilID,
       ImportID                      AS OriginalID,
       SOURCE_ID                     AS Origine,
       @SourceID                     AS SourceID,
       etl.trim(RAISON_SOCIALE)      AS RAISON_SOCIALE,
       etl.trim(CIVILITE)            AS CIVILITE,
       etl.trim(PRENOM)              AS PRENOM,
       etl.trim(NOM)                 AS NOM,
       GENRE,
       DATE_NAISSANCE                AS NaissanceDate,
       etl.trim(CATEGORIE_SOCIOPRO)  AS CatSocioProf,
       DATE_ANCIENNETE               AS CreationDate,
       DATE_MODIFICATION             AS ModificationDate,
       @FichierTS                    AS FichierSource
FROM   import.HF_Fiext                  h
WHERE  h.LigneStatut = 0
       AND h.RejetCode = 0 -- это излишний критерий: если LigneStatut = 0, то заведомо RejetCode = 0
       AND h.FichierTS = @FichierTS
       
CREATE INDEX idx01_ImportID ON #HFFiextContacts(OriginalID)       

IF OBJECT_ID('tempdb..#ExistingContacts') IS NOT NULL
    DROP TABLE #ExistingContacts
	
CREATE TABLE #ExistingContacts
(
	ProfilID       INT NULL,
	OriginalID     NVARCHAR(255) NULL
)

-- fill existing profileId by sourceId
INSERT #ExistingContacts
  (
    ProfilID,
    OriginalID
  )
SELECT b.ProfilID,
       b.OriginalID
FROM   brut.Contacts b
-- нас интересуют не все существующие контакты, а только те, которые мы собираемся изменить 
-- поэтому добавляем INNER JOIN :
INNER JOIN #ExistingContacts a on a.OriginalID=b.OriginalID
WHERE  b.SourceID = @SourceID


CREATE INDEX idx01_OriginalID ON #ExistingContacts(OriginalID)

UPDATE a
SET    ProfilID = b.ProfilID
FROM   #HFFiextContacts a
       INNER JOIN #ExistingContacts b
            ON  a.OriginalID = b.OriginalID

-- insert new contacts
INSERT INTO brut.Contacts
  (
    OriginalID,
    Origine,
    SourceID,
    RaisonSociale,
    Civilite,
    Prenom,
    Nom,
    Genre,
    NaissanceDate,
    CatSocioProf,
    CreationDate,
    ModificationDate,
    FichierSource
  )
SELECT OriginalID,
       Origine,
       SourceID,
       RaisonSociale,
       Civilite,
       Prenom,
       Nom,
       Genre,
       NaissanceDate,
       CatSocioProf,
       CreationDate,
       ModificationDate,
       FichierSource
FROM   #HFFiextContacts
WHERE  ProfilID IS NULL

--update existing contacts

UPDATE a
SET    Origine = b.Origine,
       Civilite = b.Civilite,
       Prenom = b.Prenom,
       Nom = b.Nom,
       Genre = b.Genre,
       NaissanceDate = b.NaissanceDate,
       CatSocioProf = b.CatSocioProf,
       CreationDate = b.CreationDate,
       ModificationDate = b.ModificationDate,
       RaisonSociale = b.RaisonSociale
       -- установить флаг модификации:
       , ModifieTop=1
FROM   brut.Contacts a
       INNER JOIN #HFFiextContacts b
            ON  a.ProfilID = b.ProfilID
WHERE  b.ProfilID IS NOT NULL -- излишнее условие: INNER JOIN всё равно не работает по значению NULL

UPDATE a
SET    a.LigneStatut = 99
FROM   import.HF_fiext a
       INNER JOIN #HFFiextContacts b
            ON  a.ImportID = b.OriginalID

--DROP TABLE #ExistingContacts
--DROP TABLE #HF_FIEXT_Contacts

SELECT *
FROM   brut.Contacts
WHERE  SourceID = 11

SELECT *
FROM   import.HF_fiext AS hf


