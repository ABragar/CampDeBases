/************************************************************
 * Code formatted by SoftTree SQL Assistant © v7.2.338
 * Time: 12.10.2015 21:45:32
 ************************************************************/

 USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [import].[PublierLPPROSP_Prospects]    Script Date: 16.07.2015 14:27:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [import].[PublierLPPROSP_Prospects]
	@FichierTS NVARCHAR(255)
AS
	-- =============================================
	-- Author:		Anatoli VELITCHKO
	-- Creation date: 02/10/2013
	-- Description:	Publication des Contacts, Emails, Telephones, Domiciliations, ConsentmentsEmail
	-- a partir des fichiers LPPROSP_Prospects du Parisien
	-- Modification date: 12/12/2013
	-- Modifications :	source_detail_jc as Origine
	--					source_recrutement as TypeOrigine
	-- Modification date: 31/10/2014
	-- Modifications :	la date de creation est la plus ancienne
	--					des dates de join, modif ou souscr
	-- Modification date: 20/11/2014
	-- Modifications :	1) si seulement optin est modifie, on ne met pas ModifieTop=1 dans les Contacts
	--					2) les opt-out
	-- Modified by :	Andrei BRAGAR
	-- Modification date: 20/07/2015
	-- Modifications : add optin_news_them_psg
	-- =============================================

BEGIN
	SET NOCOUNT ON
	
	-- Publication des donnees de la table Prospects_Cumul
	
	DECLARE @SourceID INT
	
	SELECT @SourceID = 4 -- Prospects LP
	
	-- Creation de table temporaire
	
	IF OBJECT_ID('tempdb..#T_Contacts_Prospects') IS NOT NULL
	    DROP TABLE #T_Contacts_Prospects
	
	CREATE TABLE #T_Contacts_Prospects
	(
		ProfilID                           INT NULL
	   ,SourceID                           INT NULL
	   ,OriginalID                         NVARCHAR(255) NULL
	   ,datejoin                           DATETIME NULL
	   ,email_origine                      NVARCHAR(255) NULL
	   ,email_courant                      NVARCHAR(255) NULL
	   ,username                           NVARCHAR(255) NULL
	   ,civilite                           NVARCHAR(255) NULL
	   ,nom                                NVARCHAR(255) NULL
	   ,prenom                             NVARCHAR(255) NULL
	   ,date_de_naissance                  DATETIME NULL
	   ,adresse                            NVARCHAR(255) NULL
	   ,code_postal                        NVARCHAR(255) NULL
	   ,ville                              NVARCHAR(255) NULL
	   ,pays                               NVARCHAR(255) NULL
	   ,telephone                          NVARCHAR(255) NULL
	   ,date_modif_profil                  DATETIME NULL
	   ,date_resil_optin_alerte            DATETIME NULL
	   ,date_resil_optin_auj_etudiant      DATETIME NULL
	   ,date_resil_optin_leparisien        DATETIME NULL
	   ,date_resil_optin_newsletter        DATETIME NULL
	   ,date_resil_optin_partenaire        DATETIME NULL
	   ,date_souscr_optin_auj_etudiant     DATETIME NULL
	   ,date_souscrip_optin_alerte         DATETIME NULL
	   ,date_souscrip_optin_leparisien     DATETIME NULL
	   ,date_souscrip_optin_newsletter     DATETIME NULL
	   ,date_souscrip_optin_partenaire     DATETIME NULL
	   ,date_resiliation_nl_thematique     DATETIME NULL
	   ,date_souscr_nl_thematique          DATETIME NULL
	   ,optin_alerte                       TINYINT NULL
	   ,optin_aujourdhui_etudiant          TINYINT NULL
	   ,optin_leparisien                   TINYINT NULL
	   ,optin_news_them_laparisienne       TINYINT NULL
	   ,optin_news_them_loisirs            TINYINT NULL
	   ,optin_news_them_politique          TINYINT NULL
	   ,optin_newsletter                   TINYINT NULL
	   ,optin_partenaire                   TINYINT NULL
	   ,source_detail_jc                   NVARCHAR(255) NULL
	   ,source_recrutement                 NVARCHAR(255) NULL
	   ,CreationDate                       DATETIME NULL
	   ,ModifOptin                         BIT NULL
	   ,ModifProfil                        BIT NULL
	   ,optin_news_them_psg                TINYINT NULL
	)
	
	SET DATEFORMAT ymd
	
	INSERT #T_Contacts_Prospects
	  (
	    ProfilID
	   ,SourceID
	   ,OriginalID
	   ,datejoin
	   ,email_origine
	   ,email_courant
	   ,username
	   ,civilite
	   ,nom
	   ,prenom
	   ,date_de_naissance
	   ,adresse
	   ,code_postal
	   ,ville
	   ,pays
	   ,telephone
	   ,date_modif_profil
	   ,date_resil_optin_alerte
	   ,date_resil_optin_auj_etudiant
	   ,date_resil_optin_leparisien
	   ,date_resil_optin_newsletter
	   ,date_resil_optin_partenaire
	   ,date_souscr_optin_auj_etudiant
	   ,date_souscrip_optin_alerte
	   ,date_souscrip_optin_leparisien
	   ,date_souscrip_optin_newsletter
	   ,date_souscrip_optin_partenaire
	   ,date_resiliation_nl_thematique
	   ,date_souscr_nl_thematique
	   ,optin_alerte
	   ,optin_aujourdhui_etudiant
	   ,optin_leparisien
	   ,optin_news_them_laparisienne
	   ,optin_news_them_loisirs
	   ,optin_news_them_politique
	   ,optin_newsletter
	   ,optin_partenaire
	   ,source_detail_jc
	   ,source_recrutement
	   ,ModifOptin
	   ,ModifProfil
	   ,optin_news_them_psg
	  )
	SELECT NULL                           AS ProfilID
	      ,@SourceID
	      ,email_courant                  AS OriginalID
	      ,CAST(datejoin AS DATETIME)
	      ,email_origine
	      ,email_courant
	      ,username
	      ,civilite
	      ,nom
	      ,prenom
	      ,CAST(date_de_naissance AS DATETIME)
	      ,adresse
	      ,code_postal
	      ,ville
	      ,pays
	      ,telephone_particulier
	      ,CAST(date_modif_profil AS DATETIME) AS date_modif_profil
	      ,CAST(date_resil_optin_alerte AS DATETIME) AS date_resil_optin_alerte
	      ,CAST(date_resil_optin_auj_etudiant AS DATETIME) AS 
	       date_resil_optin_auj_etudiant
	      ,CAST(date_resil_optin_leparisien AS DATETIME) AS 
	       date_resil_optin_leparisien
	      ,CAST(date_resil_optin_newsletter AS DATETIME) AS 
	       date_resil_optin_newsletter
	      ,CAST(date_resil_optin_partenaire AS DATETIME) AS 
	       date_resil_optin_partenaire
	      ,CAST(date_souscr_optin_auj_etudiant AS DATETIME) AS 
	       date_souscr_optin_auj_etudiant
	      ,CAST(date_souscrip_optin_alerte AS DATETIME) AS 
	       date_souscrip_optin_alerte
	      ,CAST(date_souscrip_optin_leparisien AS DATETIME) AS 
	       date_souscrip_optin_leparisien
	      ,CAST(date_souscrip_optin_newsletter AS DATETIME) AS 
	       date_souscrip_optin_newsletter
	      ,CAST(date_souscrip_optin_partenaire AS DATETIME) AS 
	       date_souscrip_optin_partenaire
	      ,CAST(date_resiliation_nl_thematique AS DATETIME) AS 
	       date_resiliation_nl_thematique
	      ,CAST(date_souscr_nl_thematique AS DATETIME) AS 
	       date_souscr_nl_thematique
	      ,CAST(optin_alerte AS TINYINT)  AS optin_alerte
	      ,CAST(optin_aujourdhui_etudiant AS TINYINT) AS 
	       optin_aujourdhui_etudiant
	      ,CAST(optin_leparisien AS TINYINT) AS optin_leparisien
	      ,CAST(optin_news_them_laparisienne AS TINYINT) AS 
	       optin_news_them_laparisienne
	      ,CAST(optin_news_them_loisirs AS TINYINT) AS optin_news_them_loisirs
	      ,CAST(optin_news_them_politique AS TINYINT) AS 
	       optin_news_them_politique
	      ,CAST(optin_newsletter AS TINYINT) AS optin_newsletter
	      ,CAST(optin_partenaire AS TINYINT) AS optin_partenaire
	      ,source_detail_jc
	      ,source_recrutement
	      ,ModifOptin
	      ,ModifProfil
	      ,CAST(optin_news_them_psg AS TINYINT) AS optin_news_them_psg
	FROM   import.Prospects_Cumul
	WHERE  FichierTS = @FichierTS
	       AND LigneStatut = 0
	
	UPDATE #T_Contacts_Prospects
	SET    email_origine = REPLACE(email_origine ,CHAR(9) ,N'')
	WHERE  PATINDEX(N'%' + CHAR(9) + N'%' ,email_origine) > 0
	
	UPDATE #T_Contacts_Prospects
	SET    email_courant = REPLACE(email_courant ,CHAR(9) ,N'')
	WHERE  PATINDEX(N'%' + CHAR(9) + N'%' ,email_courant) > 0
	
	UPDATE #T_Contacts_Prospects
	SET    username = REPLACE(username ,CHAR(9) ,N'')
	WHERE  PATINDEX(N'%' + CHAR(9) + N'%' ,username) > 0
	
	UPDATE #T_Contacts_Prospects
	SET    email_origine = REPLACE(email_origine ,CHAR(13) ,N'')
	WHERE  PATINDEX(N'%' + CHAR(13) + N'%' ,email_origine) > 0
	
	UPDATE #T_Contacts_Prospects
	SET    email_courant = REPLACE(email_courant ,CHAR(13) ,N'')
	WHERE  PATINDEX(N'%' + CHAR(13) + N'%' ,email_courant) > 0
	
	UPDATE #T_Contacts_Prospects
	SET    username = REPLACE(username ,CHAR(13) ,N'')
	WHERE  PATINDEX(N'%' + CHAR(13) + N'%' ,username) > 0
	
	CREATE INDEX idx01_OriginalID ON #T_Contacts_Prospects(OriginalID)
	
	IF OBJECT_ID(N'tempdb..#T_Dates') IS NOT NULL
	    DROP TABLE #T_Dates
	
	CREATE TABLE #T_Dates
	(
		OriginalID       NVARCHAR(255) NULL
	   ,CreationDate     DATETIME NULL
	   ,TpDt             NVARCHAR(255) NULL
	)
	
	INSERT #T_Dates
	  (
	    OriginalID
	   ,CreationDate
	   ,TpDt
	  )
	SELECT r1.OriginalID
	      ,r1.CreationDate
	      ,r1.TpDt
	FROM   (
	           SELECT b.OriginalID
	                 ,datejoin      AS CreationDate
	                 ,N'datejoin'   AS TpDt
	           FROM   #T_Contacts_Prospects b 
	           UNION SELECT b.OriginalID
	                       ,date_souscrip_optin_leparisien AS CreationDate
	                       ,N'optin_leparisien' AS TpDt
	                 FROM   #T_Contacts_Prospects b 
	           UNION SELECT b.OriginalID
	                       ,date_souscrip_optin_partenaire AS CreationDate
	                       ,N'optin_partenaire' AS TpDt
	                 FROM   #T_Contacts_Prospects b 
	           UNION SELECT b.OriginalID
	                       ,date_souscrip_optin_newsletter AS CreationDate
	                       ,N'optin_newsletter' AS TpDt
	                 FROM   #T_Contacts_Prospects b 
	           UNION SELECT b.OriginalID
	                       ,date_souscrip_optin_alerte AS CreationDate
	                       ,N'optin_alerte' AS TpDt
	                 FROM   #T_Contacts_Prospects b 
	           UNION SELECT b.OriginalID
	                       ,date_souscr_optin_auj_etudiant AS CreationDate
	                       ,N'optin_auj_etudiant' AS TpDt
	                 FROM   #T_Contacts_Prospects b 
	           UNION SELECT b.OriginalID
	                       ,date_modif_profil AS CreationDate
	                       ,N'modif_profil' AS TpDt
	                 FROM   #T_Contacts_Prospects b 
	           UNION SELECT b.OriginalID
	                       ,date_souscr_nl_thematique AS CreationDate
	                       ,N'nl_thematique' AS TpDt
	                 FROM   #T_Contacts_Prospects b
	       ) AS r1
	
	CREATE INDEX idx01_OriginalID ON #T_Dates(OriginalID)
	
	UPDATE a
	SET    CreationDate = b.date_resil_optin_leparisien
	FROM   #T_Dates a
	       INNER JOIN #T_Contacts_Prospects b
	            ON  a.OriginalID = b.OriginalID
	                AND COALESCE(a.CreationDate ,N'2079-01-01') > b.date_resil_optin_leparisien
	WHERE  a.TpDt = N'optin_leparisien'
	
	UPDATE a
	SET    CreationDate = b.date_resil_optin_partenaire
	FROM   #T_Dates a
	       INNER JOIN #T_Contacts_Prospects b
	            ON  a.OriginalID = b.OriginalID
	                AND COALESCE(a.CreationDate ,N'2079-01-01') > b.date_resil_optin_partenaire
	WHERE  a.TpDt = N'optin_partenaire'
	
	UPDATE a
	SET    CreationDate = b.date_resil_optin_newsletter
	FROM   #T_Dates a
	       INNER JOIN #T_Contacts_Prospects b
	            ON  a.OriginalID = b.OriginalID
	                AND COALESCE(a.CreationDate ,N'2079-01-01') > b.date_resil_optin_newsletter
	WHERE  a.TpDt = N'optin_newsletter'
	
	UPDATE a
	SET    CreationDate = b.date_resil_optin_alerte
	FROM   #T_Dates a
	       INNER JOIN #T_Contacts_Prospects b
	            ON  a.OriginalID = b.OriginalID
	                AND COALESCE(a.CreationDate ,N'2079-01-01') > b.date_resil_optin_alerte
	WHERE  a.TpDt = N'optin_alerte'
	
	UPDATE a
	SET    CreationDate = b.date_resil_optin_auj_etudiant
	FROM   #T_Dates a
	       INNER JOIN #T_Contacts_Prospects b
	            ON  a.OriginalID = b.OriginalID
	                AND COALESCE(a.CreationDate ,N'2079-01-01') > b.date_resil_optin_auj_etudiant
	WHERE  a.TpDt = N'optin_auj_etudiant'
	
	UPDATE a
	SET    CreationDate = b.date_resiliation_nl_thematique
	FROM   #T_Dates a
	       INNER JOIN #T_Contacts_Prospects b
	            ON  a.OriginalID = b.OriginalID
	                AND COALESCE(a.CreationDate ,N'2079-01-01') > b.date_resiliation_nl_thematique
	WHERE  a.TpDt = N'nl_thematique'
	
	IF OBJECT_ID(N'tempdb..#T_Dates_Min') IS NOT NULL
	    DROP TABLE #T_Dates_Min
	
	CREATE TABLE #T_Dates_Min
	(
		OriginalID       NVARCHAR(255) NULL
	   ,CreationDate     DATETIME NULL
	)
	
	INSERT #T_Dates_Min
	  (
	    OriginalID
	   ,CreationDate
	  )
	SELECT a.OriginalID
	      ,MIN(a.CreationDate)  AS CreationDate
	FROM   #T_Dates                a
	WHERE  a.OriginalID IS NOT NULL
	       AND a.CreationDate IS NOT NULL
	GROUP BY
	       a.OriginalID
	
	IF OBJECT_ID(N'tempdb..#T_Dates') IS NOT NULL
	    DROP TABLE #T_Dates
	
	CREATE INDEX idx01_OriginalID ON #T_Dates_Min(OriginalID)
	
	UPDATE a
	SET    CreationDate = b.CreationDate
	FROM   #T_Contacts_Prospects a
	       INNER JOIN #T_Dates_Min b
	            ON  a.OriginalID = b.OriginalID
	
	IF OBJECT_ID(N'tempdb..#T_Dates_Min') IS NOT NULL
	    DROP TABLE #T_Dates_Min
	
	UPDATE b
	SET    Origine = a.source_detail_jc
	      ,TypeOrigine = a.source_recrutement
	      ,Civilite = a.civilite
	      ,Prenom = a.prenom
	      ,Nom = a.nom
	      ,NaissanceDate = a.date_de_naissance
	      ,Age = DATEDIFF(YEAR ,a.date_de_naissance ,GETDATE())
	      ,CreationDate = COALESCE(a.CreationDate ,GETDATE())
	      ,ModificationDate = COALESCE(a.date_modif_profil ,a.CreationDate ,GETDATE())
	      ,MasterID = b.ProfilID
	      ,ModifieTop = 1
	FROM   #T_Contacts_Prospects a
	       INNER JOIN brut.Contacts b
	            ON  a.OriginalID = b.OriginalID
	                AND b.SourceID = @SourceID
	WHERE  a.ModifProfil = 1
	
	UPDATE b
	SET    CreationDate = COALESCE(a.CreationDate ,GETDATE())
	      ,ModificationDate = COALESCE(a.date_modif_profil ,a.CreationDate ,GETDATE())
	FROM   #T_Contacts_Prospects a
	       INNER JOIN brut.Contacts b
	            ON  a.OriginalID = b.OriginalID
	                AND b.SourceID = @SourceID
	WHERE  (
	           b.CreationDate <> COALESCE(a.CreationDate ,GETDATE())
	           OR b.ModificationDate <> COALESCE(a.date_modif_profil ,a.CreationDate ,GETDATE())
	       )
	
	
	INSERT brut.Contacts
	  (
	    SourceID
	   ,OriginalID
	   ,Origine
	   ,TypeOrigine
	   ,Civilite
	   ,Prenom
	   ,Nom
	   ,Genre
	   ,NaissanceDate
	   ,Age
	   ,CreationDate
	   ,ModificationDate
	   ,ModifieTop
	   ,SupprimeTop
	   ,FichierSource
	   ,Appartenance
	  )
	SELECT a.SourceID
	      ,a.OriginalID
	      ,a.source_detail_jc    AS Origine
	      ,a.source_recrutement  AS TypeOrigine
	      ,a.civilite
	      ,a.prenom
	      ,a.nom
	      ,NULL                  AS Genre
	      ,a.date_de_naissance
	      ,DATEDIFF(YEAR ,a.date_de_naissance ,GETDATE())
	      ,COALESCE(a.CreationDate ,GETDATE()) AS CreationDate
	      ,COALESCE(a.date_modif_profil ,a.CreationDate ,GETDATE()) AS 
	       ModificationDate
	      ,1                     AS ModifieTop
	      ,0                     AS SupprimeTop
	      ,@FichierTS            AS FichierSource
	      ,2
	FROM   #T_Contacts_Prospects a
	       LEFT OUTER JOIN brut.Contacts b
	            ON  a.OriginalID = b.OriginalID
	                AND b.SourceID = @SourceID
	WHERE  a.OriginalID IS NOT NULL
	       AND b.OriginalID IS NULL
	       AND a.ModifProfil = 1
	
	UPDATE a
	SET    ProfilID = b.ProfilID
	FROM   #T_Contacts_Prospects a
	       INNER JOIN brut.Contacts b
	            ON  a.OriginalID = b.OriginalID
	                AND a.SourceID = b.SourceID
	
	UPDATE b
	SET    MasterID = b.ProfilID
	FROM   #T_Contacts_Prospects a
	       INNER JOIN brut.Contacts b
	            ON  a.OriginalID = b.OriginalID
	                AND a.SourceID = b.SourceID
	                AND b.MasterID IS NULL
	
	CREATE INDEX idx02_ProfilID ON #T_Contacts_Prospects(ProfilID)
	
	DELETE #T_Contacts_Prospects
	WHERE  ProfilID IS NULL
	
	INSERT brut.Domiciliations
	  (
	    ProfilID
	   ,Adr1
	   ,Adr2
	   ,Adr3
	   ,Adr4
	   ,CodePostal
	   ,Ville
	   ,Pays
	   ,CreationDate
	   ,ModificationDate
	   ,ValeurOrigine
	  )
	SELECT a.ProfilID
	      ,LEFT(a.adresse ,80)      AS Adr1
	      ,NULL                     AS Adr2
	      ,NULL                     AS Adr3
	      ,NULL                     AS Adr4
	      ,LEFT(a.code_postal ,32)  AS CodePostal
	      ,LEFT(a.ville ,80)        AS Ville
	      ,LEFT(a.pays ,80)         AS Pays
	      ,COALESCE(a.CreationDate ,GETDATE()) AS CreationDate
	      ,COALESCE(a.date_modif_profil ,a.CreationDate ,GETDATE()) AS 
	       ModificationDate
	      ,COALESCE(LEFT(a.adresse ,80) ,N'') + COALESCE(LEFT(a.code_postal ,32) ,N'')
	       + COALESCE(LEFT(a.ville ,80) ,N'') AS ValeurOrigine
	FROM   #T_Contacts_Prospects a
	       LEFT OUTER JOIN brut.Domiciliations b
	            ON  a.ProfilID = b.ProfilID
	                AND COALESCE(LEFT(a.adresse ,80) ,N'') = COALESCE(b.Adr1 ,N'')
	                AND COALESCE(LEFT(a.code_postal ,32) ,N'') = COALESCE(b.CodePostal ,N'')
	                AND COALESCE(LEFT(a.ville ,80) ,N'') = COALESCE(b.Ville ,N'')
	                AND COALESCE(LEFT(a.pays ,80) ,N'') = COALESCE(b.Pays ,N'')
	WHERE  NOT (
	           a.adresse IS NULL
	           AND a.code_postal IS NULL
	           AND a.ville IS NULL
	           AND a.pays IS NULL
	       )
	       AND a.ProfilID IS NOT NULL
	       AND b.ProfilID IS NULL
	       AND a.ModifProfil = 1
	
	-- brut.Emails
	
	INSERT brut.Emails
	  (
	    Email
	   ,ProfilID
	   ,ValeurOrigine
	   ,CreationDate
	   ,ModificationDate
	  )
	SELECT LEFT(t.email_courant ,128)
	      ,t.ProfilID
	      ,LEFT(t.email_courant ,128)
	      ,COALESCE(t.CreationDate ,GETDATE()) AS CreationDate
	      ,COALESCE(t.date_modif_profil ,t.CreationDate ,GETDATE()) AS 
	       ModificationDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN [brut].[Contacts] bc
	            ON  t.[ProfilID] = bc.[ProfilID]
	       LEFT OUTER JOIN [brut].[Emails] em
	            ON  bc.ProfilID = em.ProfilID
	                AND t.email_courant = em.Email
	WHERE  em.ProfilID IS NULL
	       AND COALESCE(t.[email_courant] ,N'') <> N''
	       AND t.ModifProfil = 1
	
	INSERT brut.Telephones
	  (
	    ProfilID
	   ,LigneType
	   ,NumeroTelephone
	   ,CreationDate
	   ,ModificationDate
	  )
	SELECT t.ProfilID
	      ,CASE 
	            WHEN (
	                     LEN(t.telephone) = 9
	                     AND LEFT(t.telephone ,1) IN (N'6' ,N'7')
	                 ) 
	                 OR (
	                     LEN(t.telephone) = 10
	                     AND LEFT(t.telephone ,2) IN (N'06' ,N'07')
	                 ) THEN 4
	            ELSE 3
	       END
	      ,LEFT(telephone ,20) AS NumeroTelephone
	      ,COALESCE(t.CreationDate ,GETDATE()) AS CreationDate
	      ,COALESCE(t.date_modif_profil ,t.CreationDate ,GETDATE()) AS 
	       ModificationDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN [brut].[Contacts] bc
	            ON  t.[ProfilID] = bc.[ProfilID]
	       LEFT OUTER JOIN [brut].[Telephones] bt
	            ON  bc.ProfilID = bt.ProfilID
	                AND t.telephone = bt.NumeroTelephone
	WHERE  bt.ProfilID IS NULL
	       AND COALESCE(t.telephone ,N'') <> N''
	       AND t.ModifProfil = 1
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT t.ProfilID
	      ,t.ProfilID
	      ,LEFT(t.email_courant ,128)
	      ,c.ContenuID
	      ,1  AS Valeur
	      ,COALESCE(
	           t.date_souscrip_optin_alerte
	          ,t.date_modif_profil
	          ,t.CreationDate
	          ,GETDATE()
	       )  AS ConsentementDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'optin_alerte'
	       LEFT OUTER JOIN brut.ConsentementsEmail d
	            ON  t.ProfilID = d.ProfilID
	                AND c.ContenuID = d.ContenuID
	                AND d.Valeur IN (1 ,-4)
	WHERE  t.optin_alerte = 1
	       AND (
	               t.date_resil_optin_alerte IS NULL
	               OR t.date_resil_optin_alerte < t.date_souscrip_optin_alerte
	           )
	       AND t.ProfilID IS NOT NULL
	       AND d.ProfilID IS NULL
	       AND t.ModifOptin = 1
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT t.ProfilID
	      ,t.ProfilID
	      ,LEFT(t.email_courant ,128)
	      ,c.ContenuID
	      ,-1  AS Valeur
	      ,COALESCE(
	           t.date_resil_optin_alerte
	          ,t.date_modif_profil
	          ,t.CreationDate
	          ,GETDATE()
	       )   AS ConsentementDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'optin_alerte'
	       LEFT OUTER JOIN brut.ConsentementsEmail d
	            ON  t.ProfilID = d.ProfilID
	                AND c.ContenuID = d.ContenuID
	                AND d.Valeur IN (-1 ,-4)
	WHERE  t.date_resil_optin_alerte IS NOT NULL
	       AND t.date_resil_optin_alerte > COALESCE(t.date_souscrip_optin_alerte ,N'1900-01-01')
	       AND t.ProfilID IS NOT NULL
	       AND d.ProfilID IS NULL
	       AND t.ModifOptin = 1
	
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT t.ProfilID
	      ,t.ProfilID
	      ,LEFT(t.email_courant ,128)
	      ,c.ContenuID
	      ,1  AS Valeur
	      ,COALESCE(
	           t.date_souscr_optin_auj_etudiant
	          ,t.date_modif_profil
	          ,t.CreationDate
	          ,GETDATE()
	       )  AS ConsentementDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'optin_aujourdhui_etudiant'
	       LEFT OUTER JOIN brut.ConsentementsEmail d
	            ON  t.ProfilID = d.ProfilID
	                AND c.ContenuID = d.ContenuID
	                AND d.Valeur IN (1 ,-4)
	WHERE  t.optin_aujourdhui_etudiant = 1
	       AND (
	               t.date_resil_optin_auj_etudiant IS NULL
	               OR t.date_resil_optin_auj_etudiant < t.date_souscr_optin_auj_etudiant
	           )
	       AND t.ProfilID IS NOT NULL
	       AND d.ProfilID IS NULL
	       AND t.ModifOptin = 1
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT t.ProfilID
	      ,t.ProfilID
	      ,LEFT(t.email_courant ,128)
	      ,c.ContenuID
	      ,-1  AS Valeur
	      ,COALESCE(
	           t.date_resil_optin_auj_etudiant
	          ,t.date_modif_profil
	          ,t.CreationDate
	          ,GETDATE()
	       )   AS ConsentementDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'optin_aujourdhui_etudiant'
	       LEFT OUTER JOIN brut.ConsentementsEmail d
	            ON  t.ProfilID = d.ProfilID
	                AND c.ContenuID = d.ContenuID
	                AND d.Valeur IN (-1 ,-4)
	WHERE  t.date_resil_optin_auj_etudiant IS NOT NULL
	       AND t.date_resil_optin_auj_etudiant > COALESCE(t.date_souscr_optin_auj_etudiant ,N'1900-01-01')
	       AND t.ProfilID IS NOT NULL
	       AND d.ProfilID IS NULL
	       AND t.ModifOptin = 1
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT t.ProfilID
	      ,t.ProfilID
	      ,LEFT(t.email_courant ,128)
	      ,c.ContenuID
	      ,1  AS Valeur
	      ,COALESCE(
	           t.date_souscrip_optin_leparisien
	          ,t.date_modif_profil
	          ,t.CreationDate
	          ,GETDATE()
	       )  AS ConsentementDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'Optin Editeur LP' -- 51 remplace 43 optin_leparisien
	                
	       LEFT OUTER JOIN brut.ConsentementsEmail d
	            ON  t.ProfilID = d.ProfilID
	                AND c.ContenuID = d.ContenuID
	                AND d.Valeur IN (1 ,-4)
	WHERE  t.optin_leparisien = 1
	       AND (
	               t.date_resil_optin_leparisien IS NULL
	               OR t.date_resil_optin_leparisien < t.date_souscrip_optin_leparisien
	           )
	       AND t.ProfilID IS NOT NULL
	       AND d.ProfilID IS NULL
	       AND t.ModifOptin = 1
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT t.ProfilID
	      ,t.ProfilID
	      ,LEFT(t.email_courant ,128)
	      ,c.ContenuID
	      ,-1  AS Valeur
	      ,COALESCE(
	           t.date_resil_optin_leparisien
	          ,t.date_modif_profil
	          ,t.CreationDate
	          ,GETDATE()
	       )   AS ConsentementDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'Optin Editeur LP' -- 51 remplace 43 optin_leparisien
	                
	       LEFT OUTER JOIN brut.ConsentementsEmail d
	            ON  t.ProfilID = d.ProfilID
	                AND c.ContenuID = d.ContenuID
	                AND d.Valeur IN (-1 ,-4)
	WHERE  t.date_resil_optin_leparisien IS NOT NULL
	       AND t.date_resil_optin_leparisien > COALESCE(t.date_souscrip_optin_leparisien ,N'1900-01-01')
	       AND t.ProfilID IS NOT NULL
	       AND d.ProfilID IS NULL
	       AND t.ModifOptin = 1
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT t.ProfilID
	      ,t.ProfilID
	      ,LEFT(t.email_courant ,128)
	      ,c.ContenuID
	      ,1  AS Valeur
	      ,COALESCE(
	           t.date_souscr_nl_thematique
	          ,t.date_modif_profil
	          ,t.CreationDate
	          ,GETDATE()
	       )  AS ConsentementDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'optin_news_them_laparisienne'
	       LEFT OUTER JOIN brut.ConsentementsEmail d
	            ON  t.ProfilID = d.ProfilID
	                AND c.ContenuID = d.ContenuID
	                AND d.Valeur IN (1 ,-4)
	WHERE  t.optin_news_them_laparisienne = 1
	       AND (
	               t.date_resiliation_nl_thematique IS NULL
	               OR t.date_resiliation_nl_thematique < t.date_souscr_nl_thematique
	           )
	       AND t.ProfilID IS NOT NULL
	       AND d.ProfilID IS NULL
	       AND t.ModifOptin = 1
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT t.ProfilID
	      ,t.ProfilID
	      ,LEFT(t.email_courant ,128)
	      ,c.ContenuID
	      ,-1  AS Valeur
	      ,COALESCE(
	           t.date_resiliation_nl_thematique
	          ,t.date_modif_profil
	          ,t.CreationDate
	          ,GETDATE()
	       )   AS ConsentementDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'optin_news_them_laparisienne'
	       LEFT OUTER JOIN brut.ConsentementsEmail d
	            ON  t.ProfilID = d.ProfilID
	                AND c.ContenuID = d.ContenuID
	                AND d.Valeur IN (-1 ,-4)
	WHERE  t.date_resiliation_nl_thematique IS NOT NULL
	       AND t.date_resiliation_nl_thematique > COALESCE(t.date_souscr_nl_thematique ,N'1900-01-01')
	       AND t.ProfilID IS NOT NULL
	       AND d.ProfilID IS NULL
	       AND t.ModifOptin = 1
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT t.ProfilID
	      ,t.ProfilID
	      ,LEFT(t.email_courant ,128)
	      ,c.ContenuID
	      ,1  AS Valeur
	      ,COALESCE(
	           t.date_souscr_nl_thematique
	          ,t.date_modif_profil
	          ,t.CreationDate
	          ,GETDATE()
	       )  AS ConsentementDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'optin_news_them_loisirs'
	       LEFT OUTER JOIN brut.ConsentementsEmail d
	            ON  t.ProfilID = d.ProfilID
	                AND c.ContenuID = d.ContenuID
	                AND d.Valeur IN (1 ,-4)
	WHERE  t.optin_news_them_loisirs = 1
	       AND (
	               t.date_resiliation_nl_thematique IS NULL
	               OR t.date_resiliation_nl_thematique < t.date_souscr_nl_thematique
	           )
	       AND t.ProfilID IS NOT NULL
	       AND d.ProfilID IS NULL
	       AND t.ModifOptin = 1
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT t.ProfilID
	      ,t.ProfilID
	      ,LEFT(t.email_courant ,128)
	      ,c.ContenuID
	      ,-1  AS Valeur
	      ,COALESCE(
	           t.date_resiliation_nl_thematique
	          ,t.date_modif_profil
	          ,t.CreationDate
	          ,GETDATE()
	       )   AS ConsentementDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'optin_news_them_loisirs'
	       LEFT OUTER JOIN brut.ConsentementsEmail d
	            ON  t.ProfilID = d.ProfilID
	                AND c.ContenuID = d.ContenuID
	                AND d.Valeur IN (-1 ,-4)
	WHERE  t.date_resiliation_nl_thematique IS NOT NULL
	       AND t.date_resiliation_nl_thematique > COALESCE(t.date_souscr_nl_thematique ,N'1900-01-01')
	       AND t.ProfilID IS NOT NULL
	       AND d.ProfilID IS NULL
	       AND t.ModifOptin = 1
	
	--optin_news_them_psg
	
	DECLARE @optin_news_them_psg_date DATETIME = CAST(
	            SUBSTRING(@FichierTS ,LEN(@FichierTS) -7 ,4) + SUBSTRING(@FichierTS ,LEN(@FichierTS) -9 ,2) 
	            +
	            SUBSTRING(@FichierTS ,LEN(@FichierTS) -11 ,2) AS DATETIME
	        ) 
	
	UPDATE ce
	SET    ce.Valeur = -1
	      ,ConsentementDate = @optin_news_them_psg_date
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'optin_news_them_psg'
	       INNER JOIN brut.ConsentementsEmail ce
	            ON  t.ProfilID = ce.ProfilID
	                AND c.ContenuID = ce.ContenuID
	WHERE  t.ProfilID IS NOT NULL
	       AND t.optin_news_them_psg = 2
	
	UPDATE ce
	SET    ce.Valeur = 1
	      ,ConsentementDate = @optin_news_them_psg_date
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'optin_news_them_psg'
	       INNER JOIN brut.ConsentementsEmail ce
	            ON  t.ProfilID = ce.ProfilID
	                AND c.ContenuID = ce.ContenuID
	WHERE  t.ProfilID IS NOT NULL
	       AND t.optin_news_them_psg = 1
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT t.ProfilID
	      ,t.ProfilID
	      ,LEFT(t.email_courant ,128)
	      ,c.ContenuID --,58
	      ,1                          AS Valeur
	      ,@optin_news_them_psg_date  AS ConsentementDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'optin_news_them_psg'
	       LEFT JOIN brut.ConsentementsEmail ce
	            ON  t.ProfilID = ce.ProfilID
	                AND c.ContenuID = ce.ContenuID
	WHERE  t.ProfilID IS NOT NULL
	       AND t.optin_news_them_psg = 1
	       AND ce.ProfilID IS            NULL
	
	--end of optin_news_them_psg
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT t.ProfilID
	      ,t.ProfilID
	      ,LEFT(t.email_courant ,128)
	      ,c.ContenuID
	      ,1  AS Valeur
	      ,COALESCE(
	           t.date_souscr_nl_thematique
	          ,t.date_modif_profil
	          ,t.CreationDate
	          ,GETDATE()
	       )  AS ConsentementDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'optin_news_them_politique'
	       LEFT OUTER JOIN brut.ConsentementsEmail d
	            ON  t.ProfilID = d.ProfilID
	                AND c.ContenuID = d.ContenuID
	                AND d.Valeur IN (1 ,-4)
	WHERE  t.optin_news_them_politique = 1
	       AND (
	               t.date_resiliation_nl_thematique IS NULL
	               OR t.date_resiliation_nl_thematique < t.date_souscr_nl_thematique
	           )
	       AND t.ProfilID IS NOT NULL
	       AND d.ProfilID IS NULL
	       AND t.ModifOptin = 1
	
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT t.ProfilID
	      ,t.ProfilID
	      ,LEFT(t.email_courant ,128)
	      ,c.ContenuID
	      ,-1  AS Valeur
	      ,COALESCE(
	           t.date_resiliation_nl_thematique
	          ,t.date_modif_profil
	          ,t.CreationDate
	          ,GETDATE()
	       )   AS ConsentementDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'optin_news_them_politique'
	       LEFT OUTER JOIN brut.ConsentementsEmail d
	            ON  t.ProfilID = d.ProfilID
	                AND c.ContenuID = d.ContenuID
	                AND d.Valeur IN (-1 ,-4)
	WHERE  t.date_resiliation_nl_thematique IS NOT NULL
	       AND t.date_resiliation_nl_thematique > COALESCE(t.date_souscr_nl_thematique ,N'1900-01-01')
	       AND t.ProfilID IS NOT NULL
	       AND d.ProfilID IS NULL
	       AND t.ModifOptin = 1
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT t.ProfilID
	      ,t.ProfilID
	      ,LEFT(t.email_courant ,128)
	      ,c.ContenuID
	      ,1  AS Valeur
	      ,COALESCE(
	           t.date_souscrip_optin_newsletter
	          ,t.date_modif_profil
	          ,t.CreationDate
	          ,GETDATE()
	       )  AS ConsentementDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'Newsletter Le Parisien.fr'
	       LEFT OUTER JOIN brut.ConsentementsEmail d
	            ON  t.ProfilID = d.ProfilID
	                AND c.ContenuID = d.ContenuID
	                AND d.Valeur IN (1 ,-4)
	WHERE  t.optin_newsletter = 1
	       AND (
	               t.date_resil_optin_newsletter IS NULL
	               OR t.date_resil_optin_newsletter < t.date_souscrip_optin_newsletter
	           )
	       AND t.ProfilID IS NOT NULL
	       AND d.ProfilID IS NULL
	       AND t.ModifOptin = 1
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT t.ProfilID
	      ,t.ProfilID
	      ,LEFT(t.email_courant ,128)
	      ,c.ContenuID
	      ,-1  AS Valeur
	      ,COALESCE(
	           t.date_resil_optin_newsletter
	          ,t.date_modif_profil
	          ,t.CreationDate
	          ,GETDATE()
	       )   AS ConsentementDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'Newsletter Le Parisien.fr'
	       LEFT OUTER JOIN brut.ConsentementsEmail d
	            ON  t.ProfilID = d.ProfilID
	                AND c.ContenuID = d.ContenuID
	                AND d.Valeur IN (-1 ,-4)
	WHERE  t.date_resil_optin_newsletter IS NOT NULL
	       AND t.date_resil_optin_newsletter > COALESCE(t.date_souscrip_optin_newsletter ,N'1900-01-01')
	       AND t.ProfilID IS NOT NULL
	       AND d.ProfilID IS NULL
	       AND t.ModifOptin = 1
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT t.ProfilID
	      ,t.ProfilID
	      ,LEFT(t.email_courant ,128)
	      ,c.ContenuID
	      ,1  AS Valeur
	      ,COALESCE(
	           t.date_souscrip_optin_partenaire
	          ,t.date_modif_profil
	          ,t.CreationDate
	          ,GETDATE()
	       )  AS ConsentementDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'Optin Partenaires LP'
	       LEFT OUTER JOIN brut.ConsentementsEmail d
	            ON  t.ProfilID = d.ProfilID
	                AND c.ContenuID = d.ContenuID
	                AND d.Valeur IN (1 ,-4)
	WHERE  t.optin_partenaire = 1
	       AND (
	               t.date_resil_optin_partenaire IS NULL
	               OR t.date_resil_optin_partenaire < t.date_souscrip_optin_partenaire
	           )
	       AND t.ProfilID IS NOT NULL
	       AND d.ProfilID IS NULL
	       AND t.ModifOptin = 1
	
	INSERT brut.ConsentementsEmail
	  (
	    ProfilID
	   ,MasterID
	   ,Email
	   ,ContenuID
	   ,Valeur
	   ,ConsentementDate
	  )
	SELECT t.ProfilID
	      ,t.ProfilID
	      ,LEFT(t.email_courant ,128)
	      ,c.ContenuID
	      ,-1  AS Valeur
	      ,COALESCE(
	           t.date_resil_optin_partenaire
	          ,t.date_modif_profil
	          ,t.CreationDate
	          ,GETDATE()
	       )   AS ConsentementDate
	FROM   #T_Contacts_Prospects t
	       INNER JOIN ref.Contenus c
	            ON  c.NomContenu = N'Optin Partenaires LP'
	       LEFT OUTER JOIN brut.ConsentementsEmail d
	            ON  t.ProfilID = d.ProfilID
	                AND c.ContenuID = d.ContenuID
	                AND d.Valeur IN (-1 ,-4)
	WHERE  t.date_resil_optin_partenaire IS NOT NULL
	       AND t.date_resil_optin_partenaire > COALESCE(t.date_souscrip_optin_partenaire ,N'1900-01-01')
	       AND t.ProfilID IS NOT NULL
	       AND d.ProfilID IS NULL
	       AND t.ModifOptin = 1
	
	UPDATE a
	SET    LigneStatut = 99
	FROM   import.Prospects_Cumul a
	       INNER JOIN #T_Contacts_Prospects b
	            ON  a.email_courant = b.OriginalID
	WHERE  a.FichierTS = @FichierTS
	       AND a.LigneStatut = 0
	
	UPDATE a
	SET    LigneStatut = 99
	FROM   import.LPPROSP_Prospects a
	       INNER JOIN #T_Contacts_Prospects b
	            ON  a.email_courant = b.OriginalID
	WHERE  a.FichierTS = @FichierTS
	       AND a.LigneStatut = 0
	
	IF OBJECT_ID('tempdb..#T_Contacts_Prospects') IS NOT NULL
	    DROP TABLE #T_Contacts_Prospects
	
	/********** AUTOCALCULATE REJECTSTATS **********/
	DELETE 
	FROM   QTSDQF.rejet.REJETS_TAUX
	WHERE  TableName = '[AmauryVUC].[import].[LPPROSP_Prospects]'
	
	IF (
	       EXISTS(
	           SELECT NULL
	           FROM   sys.tables t
	                  INNER JOIN sys.[schemas] s
	                       ON  s.SCHEMA_ID = t.SCHEMA_ID
	           WHERE  s.name = 'import'
	                  AND t.Name = 'LPPROSP_Prospects'
	       )
	   )
	    EXECUTE [QTSDQF].[dbo].[RejetsStats] 
	            '95940C81-C7A7-4BD9-A523-445A343A9605'
	           ,'LPPROSP_Prospects'
	           ,@FichierTS
END
