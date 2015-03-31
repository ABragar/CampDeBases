USE AmauryVUC
GO

ALTER PROCEDURE import.publierHF_Fiext
	@FichierTS NVARCHAR(255)
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @SourceID INT
	SET @SourceID = 11
	
	IF (NOT OBJECT_ID('tempdb..#HFFiextContacts') IS NULL)
	    DROP TABLE #HFFiextContacts
	
	CREATE TABLE #HFFiextContacts
	(
		ProfilID             INT NULL
	   ,OriginalID           NVARCHAR(255) NULL
	   ,Origine              NVARCHAR(255) NULL
	   ,SourceID             INT NULL
	   ,RaisonSociale        NVARCHAR(255)
	   ,Civilite             NVARCHAR(255)
	   ,Prenom               NVARCHAR(255)
	   ,Nom                  NVARCHAR(255)
	   ,Genre                TINYINT
	   ,NaissanceDate        DATETIME
	   ,CatSocioProf         NVARCHAR(255)
	   ,CreationDate         DATETIME
	   ,ModificationDate     DATETIME
	   ,FichierSource        NVARCHAR(255)
	)
	
	-- установить формат даты как в процедуре валидации: 
	SET DATEFORMAT DMY
	
	INSERT #HFFiextContacts
	  (
	    ProfilID
	   ,OriginalID
	   ,Origine
	   ,SourceID
	   ,RaisonSociale
	   ,Civilite
	   ,Prenom
	   ,Nom
	   ,Genre
	   ,NaissanceDate
	   ,CatSocioProf
	   ,CreationDate
	   ,ModificationDate
	   ,FichierSource
	  )
	SELECT NULL                          AS ProfilID
	      ,ImportID                      AS OriginalID
	      ,SOURCE_ID                     AS Origine
	      ,@SourceID                     AS SourceID
	      ,etl.trim(RAISON_SOCIALE)      AS RAISON_SOCIALE
	      ,etl.trim(CIVILITE)            AS CIVILITE
	      ,etl.trim(PRENOM)              AS PRENOM
	      ,etl.trim(NOM)                 AS NOM
	      ,CAST(GENRE AS TINYINT)        AS Genre
	      ,CAST(DATE_NAISSANCE AS DATETIME) AS NaissanceDate
	      ,etl.trim(CATEGORIE_SOCIOPRO)  AS CatSocioProf
	      ,ISNULL(CAST(DATE_ANCIENNETE AS DATETIME) ,GETDATE()) AS CreationDate
	      ,ISNULL(CAST(DATE_MODIFICATION AS DATETIME) ,GETDATE()) AS 
	       ModificationDate
	      ,@FichierTS                    AS FichierSource
	FROM   import.HF_Fiext                  h
	WHERE  h.LigneStatut = 0
	       AND h.FichierTS = @FichierTS
	
	CREATE INDEX idx01_ImportID ON #HFFiextContacts(OriginalID)       
	
	IF OBJECT_ID('tempdb..#ExistingContacts') IS NOT NULL
	    DROP TABLE #ExistingContacts
	
	CREATE TABLE #ExistingContacts
	(
		ProfilID       INT NULL
	   ,OriginalID     NVARCHAR(255) NULL
	)
	
	-- fill existing profileId by sourceId
	INSERT #ExistingContacts
	  (
	    ProfilID
	   ,OriginalID
	  )
	SELECT b.ProfilID
	      ,b.OriginalID
	FROM   brut.Contacts b
	       INNER JOIN #HFFiextContacts a
	            ON  a.OriginalID = b.OriginalID
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
	    OriginalID
	   ,Origine
	   ,SourceID
	   ,RaisonSociale
	   ,Civilite
	   ,Prenom
	   ,Nom
	   ,Genre
	   ,NaissanceDate
	   ,CatSocioProf
	   ,CreationDate
	   ,ModificationDate
	   ,FichierSource
	  )
	SELECT OriginalID
	      ,Origine
	      ,SourceID
	      ,RaisonSociale
	      ,Civilite
	      ,Prenom
	      ,Nom
	      ,Genre
	      ,NaissanceDate
	      ,CatSocioProf
	      ,CreationDate
	      ,ModificationDate
	      ,FichierSource
	FROM   #HFFiextContacts
	WHERE  ProfilID IS NULL
	
	--update existing contacts
	UPDATE a
	SET    Origine = b.Origine
	      ,Civilite = b.Civilite
	      ,Prenom = b.Prenom
	      ,Nom = b.Nom
	      ,Genre = b.Genre
	      ,NaissanceDate = b.NaissanceDate
	      ,CatSocioProf = b.CatSocioProf
	      ,CreationDate = b.CreationDate
	      ,ModificationDate = b.ModificationDate
	      ,RaisonSociale = b.RaisonSociale
	      ,ModifieTop = 1
	FROM   brut.Contacts a
	       INNER JOIN #HFFiextContacts b
	            ON  a.ProfilID = b.ProfilID
	
	-- update new profileId
	UPDATE hc
	SET    ProfilID = c.ProfilID
	FROM   brut.Contacts AS c
	       INNER JOIN #HFFiextContacts hc
	            ON  c.OriginalID = hc.OriginalID
	WHERE  c.SourceID = @SourceID
	       AND hc.ProfilID IS NULL
	
	-- здесь можно создать индекс по #HFFiextContacts(ProfilID)
	CREATE INDEX idx01_ProfilID ON #HFFiextContacts(ProfilID)
	
	/* update Domiciliations*/
	ALTER TABLE #HFFiextContacts ADD 
	
	Type_habitation NVARCHAR(255),
	Adresse1 NVARCHAR(255),
	Adresse2 NVARCHAR(255),
	Adresse3 NVARCHAR(255),
	Adresse4 NVARCHAR(255),
	CodePostal NVARCHAR(32), -- CodePostal NVARCHAR(32): могут присутствовать буквы, например, в английских или канадских почтовых кодах
	                         --					кроме того, нужно сохранить слева ноль, если почтовый код, например, 06103 
	Commune NVARCHAR(255),
	Pays NVARCHAR(32),
	Stop_adresse_postal BIT NOT NULL DEFAULT(0), -- поскольку в базе это поле всегда 0 или 1, лучше сделать его NOT NULL DEFAULT(0)
	Date_stop_adresse_postal DATETIME
	
	
	UPDATE hc
	SET    hc.Type_habitation = LEFT(hf.TYPE_HABITATION ,8)
	      ,hc.Adresse1 = LEFT(hf.ADRESSE1 ,80)
	      ,hc.Adresse2 = LEFT(hf.ADRESSE2 ,80)
	      ,hc.Adresse3 = LEFT(hf.ADRESSE3 ,80)
	      ,hc.Adresse4 = LEFT(hf.ADRESSE4 ,80)
	      ,hc.CodePostal = LEFT(hf.CODE_POSTAL ,32)
	      ,hc.Commune = LEFT(hf.COMMUNE ,80)
	      ,hc.Pays = LEFT(hf.PAYS ,32)	-- 32, поскольку Pays NVARCHAR(32)
	      ,hc.Stop_adresse_postal = CASE 
	                                     WHEN ISNUMERIC(hf.STOP_ADRESSE_POSTAL) 
	                                          = 1 THEN CAST(hf.STOP_ADRESSE_POSTAL AS BIT)
	                                     ELSE 0
	                                END
	      ,hc.Date_stop_adresse_postal = CAST(hf.DATE_STOP_ADRESSEPOSTAL AS DATETIME)
	FROM   #HFFiextContacts hc
	       INNER JOIN import.HF_fiext AS hf
	            ON  hf.ImportID = hc.OriginalID
	
	INSERT brut.Domiciliations
	  (
	    ProfilID
	   ,TypeAdr
	   ,Adr1
	   ,Adr2
	   ,Adr3
	   ,Adr4
	   ,CodePostal
	   ,Region
	   ,Pays
	   ,StopCourrier
	   ,StopCourrierDate
	   ,CreationDate
	   ,ModificationDate
	   ,ValeurOrigine
	  )
	SELECT t.ProfilID
	      ,t.Type_habitation
	      ,t.Adresse1
	      ,t.Adresse2
	      ,t.Adresse3
	      ,t.Adresse4
	      ,t.CodePostal
	      ,t.Commune
	      ,t.Pays
	      ,t.Stop_adresse_postal
	      ,t.Date_stop_adresse_postal
	      ,t.CreationDate
	      ,t.ModificationDate
	      ,CAST(COALESCE(t.Adresse1 ,N'') AS NVARCHAR(255)) 
	       + CAST(COALESCE(t.Adresse2 ,N'') AS NVARCHAR(255)) 
	       + CAST(COALESCE(t.Adresse3 ,N'')AS NVARCHAR(255)) 
	       + CAST(COALESCE(t.Adresse4 ,N'')AS NVARCHAR(255)) 
	       + CAST(COALESCE(t.CodePostal ,N'')AS NVARCHAR(255)) 
	       + CAST(COALESCE(t.Commune ,N'') AS NVARCHAR(255))
	       + CAST(COALESCE(t.Pays ,N'') AS NVARCHAR(255)) AS ValeurOrigine
	FROM   #HFFiextContacts t
	       LEFT JOIN brut.Domiciliations AS d
	            ON  t.ProfilID = d.ProfilID
	                AND d.ValeurOrigine = CAST(COALESCE(t.Adresse1 ,N'') AS NVARCHAR(255)) 
	                    + CAST(COALESCE(t.Adresse2 ,N'') AS NVARCHAR(255)) 
	                    + CAST(COALESCE(t.Adresse3 ,N'')AS NVARCHAR(255)) 
	                    + CAST(COALESCE(t.Adresse4 ,N'')AS NVARCHAR(255)) 
	                    + CAST(COALESCE(t.CodePostal ,N'')AS NVARCHAR(255)) 
	                    + CAST(COALESCE(t.Commune ,N'') AS NVARCHAR(255))
	                    + CAST(COALESCE(t.Pays ,N'') AS NVARCHAR(255))
	WHERE  NOT (
	           t.Adresse1 IS NULL
	           AND t.Adresse2 IS NULL
	           AND t.Adresse3 IS NULL
	           AND t.Adresse4 IS NULL
	           AND t.CodePostal IS NULL
	           AND t.CodePostal IS NULL
	           AND t.Commune IS NULL
	           AND t.Pays IS NULL
	           AND t.Stop_adresse_postal IS NULL
	           AND t.Date_stop_adresse_postal IS NULL
	       )
	       AND t.ProfilID IS NOT NULL
	       AND d.ProfilID IS NULL
	
	UPDATE d
	SET    TypeAdr = c.Type_habitation
	      ,StopCourrier = c.Stop_adresse_postal
	      ,StopCourrierDate = c.Date_stop_adresse_postal
	FROM   brut.Domiciliations d
	       INNER JOIN #HFFiextContacts c
	            ON  c.ProfilID = d.ProfilID
	                AND d.ValeurOrigine = CAST(COALESCE(c.Adresse1 ,N'') AS NVARCHAR(255)) 
	                    + CAST(COALESCE(c.Adresse2 ,N'') AS NVARCHAR(255)) 
	                    + CAST(COALESCE(c.Adresse3 ,N'')AS NVARCHAR(255)) 
	                    + CAST(COALESCE(c.Adresse4 ,N'')AS NVARCHAR(255)) 
	                    + CAST(COALESCE(c.CodePostal ,N'')AS NVARCHAR(255)) 
	                    + CAST(COALESCE(c.Commune ,N'') AS NVARCHAR(255))
	                    + CAST(COALESCE(c.Pays ,N'') AS NVARCHAR(255))
	WHERE  NOT (
	           c.Adresse1 IS NULL
	           AND c.Adresse2 IS NULL
	           AND c.Adresse3 IS NULL
	           AND c.Adresse4 IS NULL
	           AND c.CodePostal IS NULL
	           AND c.CodePostal IS NULL
	           AND c.Commune IS NULL
	           AND c.Pays IS NULL
	           AND c.Stop_adresse_postal IS NULL
	           AND c.Date_stop_adresse_postal IS NULL
	       )
	       AND c.ProfilID IS NOT NULL
	       AND d.ProfilID IS NOT NULL
	       AND (
	               c.Type_habitation <> d.TypeAdr
	               OR c.Stop_adresse_postal <> d.StopCourrier
	               OR c.Date_stop_adresse_postal <> d.StopCourrierDate
	           ) 
	/* end update Domiciliations*/
	
	/* update emails*/
	
	ALTER TABLE #HFFiextContacts ADD 
	email NVARCHAR(255)
	
	UPDATE hc
	SET    hc.email = hf.email
	FROM   #HFFiextContacts hc
	       INNER JOIN import.HF_fiext AS hf
	            ON  hf.ImportID = hc.OriginalID
	
	INSERT brut.Emails
	  (
	    Email
	   ,ProfilID
	   ,ValeurOrigine
	   ,CreationDate
	   ,ModificationDate
	  )
	SELECT t.Email
	      ,t.ProfilID
	      ,t.Email
	      ,t.CreationDate
	      ,t.ModificationDate
	FROM   #HFFiextContacts t
	       LEFT OUTER JOIN [brut].[Emails] em
	            ON  t.ProfilID = em.ProfilID
	                AND t.Email = em.Email
	WHERE  em.ProfilID IS NULL
	       AND COALESCE(t.[Email] ,N'') <> N'' 
	/* end update emails*/
	
	/* update telephones*/
	ALTER TABLE #HFFiextContacts ADD 
	
	TelFixe NVARCHAR(20),
	stopTelfixe NVARCHAR(1),
	TelMobile NVARCHAR(20),
	stopTelMobile NVARCHAR(1)
	
	
	UPDATE hc
	SET    hc.TelFixe = etl.trim(LEFT(hf.TEL_FIXE ,20))
	      ,hc.TelMobile = etl.trim(LEFT(hf.TEL_FIXE ,20))
	      ,hc.stopTelfixe = etl.trim(hf.STOP_TEL_FIXE)
	      ,hc.stopTelMobile = etl.trim(hf.STOP_TEL_MOBILE)
	FROM   #HFFiextContacts hc
	       INNER JOIN import.HF_fiext AS hf
	            ON  hf.ImportID = hc.OriginalID
	
	IF OBJECT_ID('tempdb..#telephones') IS NOT NULL
	    DROP TABLE #telephones
	
	SELECT DISTINCT * INTO     #telephones
	FROM   (
	           SELECT c.ProfilID
	                 ,c.CreationDate
	                 ,c.ModificationDate
	                 ,c.TelFixe         AS PhoneNumber
	                 ,c.stopTelfixe     AS StopFlag
	                 ,etl.getPhoneType(c.TelFixe) AS PhoneType
	           FROM   #HFFiextContacts     c
	           WHERE  TelFixe IS NOT NULL
	           UNION
	           SELECT c.ProfilID
	                 ,c.CreationDate
	                 ,c.ModificationDate
	                 ,c.TelMobile
	                 ,c.stopTelMobile
	                 ,etl.getPhoneType(c.TelMobile)
	           FROM   #HFFiextContacts c
	           WHERE  TelMobile IS NOT NULL
	       )                   x
	
	INSERT brut.Telephones
	  (
	    ProfilID
	   ,LigneType
	   ,NumeroTelephone
	   ,CreationDate
	   ,ModificationDate
	   ,StopTel
	  )
	SELECT t.ProfilID
	      ,t.PhoneType
	      ,t.PhoneNumber
	      ,t.CreationDate
	      ,t.ModificationDate
	      ,t.StopFlag
	FROM   #telephones t
	       LEFT JOIN [brut].[Telephones] bt
	            ON  bt.ProfilID = t.ProfilID
	                AND RIGHT(REPLACE(bt.NumeroTelephone ,N' ' ,N'') ,9) = RIGHT(REPLACE(t.PhoneNumber ,N' ' ,N'') ,9)
	WHERE  bt.ProfilID IS NULL
	       AND COALESCE(t.PhoneNumber ,N'') <> N'' 
	/* end update telephones*/
	
	/* update optins*/
	ALTER TABLE #HFFiextContacts ADD 
	MARQUE_ID INT
	, [OPTIN_M] INT
	, [OPTIN_P] INT
	
	UPDATE hc
	SET    hc.MARQUE_ID = hf.MARQUE_ID
	      ,hc.[OPTIN_M] = hf.[OPTIN_M]
	      ,hc.[OPTIN_P] = hf.[OPTIN_P]
	FROM   #HFFiextContacts hc
	       INNER JOIN import.HF_fiext AS hf
	            ON  hf.ImportID = hc.OriginalID
	
	IF OBJECT_ID('tempdb..#optins') IS NOT NULL
	    DROP TABLE #optins
	
	SELECT * INTO     #optins
	FROM   (
	           SELECT profilId
	                 ,hf.email
	                 ,hf.MARQUE_ID
	                 ,c.ContenuID
	                 ,CASE 
	                       WHEN OPTIN_M = 1 THEN 1
	                       ELSE -1
	                  END               AS Valeur
	                 ,hf.CreationDate   AS ConsentementDate
	           FROM   #HFFiextContacts  AS hf
	                  INNER JOIN ref.Contenus AS c
	                       ON  hf.MARQUE_ID = c.MarqueID
	                           AND c.TypeContenu = 2
	           WHERE  hf.email IS NOT NULL
	           UNION ALL
	           SELECT profilId
	                 ,hf.email
	                 ,hf.MARQUE_ID
	                 ,c.ContenuID
	                 ,CASE 
	                       WHEN OPTIN_P = 1 THEN 1
	                       ELSE -1
	                  END               AS Valeur
	                 ,hf.CreationDate   AS ConsentementDate
	           FROM   #HFFiextContacts  AS hf
	                  INNER JOIN ref.Contenus AS c
	                       ON  hf.MARQUE_ID = c.MarqueID
	                           AND c.TypeContenu = 3
	           WHERE  hf.email IS NOT NULL
	       )          x
	
	CREATE INDEX idx01_ProfilID ON #optins(ProfilID)
	
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT x.ProfilID
	      ,x.Email
	      ,x.ContenuID
	      ,x.Valeur
	      ,x.ConsentementDate
	FROM   #optins x
	       LEFT JOIN brut.ConsentementsEmail AS ce
	            ON  ce.profilId = x.profilId
	                AND ce.email = x.email
	                AND ce.ContenuID = x.ContenuID
	                AND ce.Valeur = x.Valeur
	WHERE  ce.ProfilID IS NULL
	/*end update optins*/
	
	-- логика совершенно правильная, но поскольку brut.ConsentementsEmail - очень объемная таблица (на сегодняшний день почти 16 млн. строк)
	-- то лучше создать сначала временную таблицу для результата вложенного запроса х , проиндексировать ее по (ProfilID) и по (Email,ContenuID)
	-- и тогда уже делать LEFT JOIN c brut.ConsentementsEmail
	
	DROP TABLE #HFFiextContacts
	DROP TABLE #telephones
END