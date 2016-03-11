 USE [AmauryVUC]
GO

/****** Object:  StoredProcedure [import].[CumulLPPROSP_Prospects]    Script Date: 13.10.2015 20:19:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER PROC [import].[CumulLPPROSP_Prospects] (@FichierTS NVARCHAR(255))
AS

BEGIN
	SET NOCOUNT ON
	
	-- Vйrification du fichier s'il n'est pas vide ni trop court
	
	DECLARE @m XML
	DECLARE @n INT
	
	SELECT @n = COUNT(*)
	FROM   import.LPPROSP_Prospects
	WHERE  FichierTS = @FichierTS
	
	IF @n < 500000 -- la taille moyenne est d'environ 1000000 lignes
	BEGIN
	    SET @m = 
	        N'<StepResult>
				<ExitCode>1</ExitCode>
				<Messages>
					<Message>
						<Id>004AE05E-95A6-4C0D-B34A-B03E690370FB</Id>
						<Destinataires>
							<Destinataire ModeEnvoi="3">924AFE01-3F9E-4C40-B54E-87293CB8CF6E</Destinataire>
						</Destinataires>
						<Parametres>
							<Parametre>' + @FichierTS + 
	        N'</Parametre>
						</Parametres>
					</Message>
				</Messages>
			</StepResult>'
	    
	    SELECT @m
	    RETURN
	END 
	
	-- Dйtection de lignes а mettre а jour, avant l'insertion des nouvelles lignes
	
	-- Ce sont les lignes qui ont le email_courant dйjа existant dans Prospects_Cumul mais les valeurs des champs ont changй
	
	-- Pour s'assurer qu'il n'y a pas de lignes avec ModifieTop=1 restйes d'un tratement prйcйdent,
	-- on les remet toutes а 0
	
	UPDATE import.Prospects_Cumul
	SET    ModifieTop = 0
	WHERE  ModifieTop = 1
	
	UPDATE import.Prospects_Cumul
	SET    ModifOptin = 0
	WHERE  ModifOptin = 1
	
	UPDATE import.Prospects_Cumul
	SET    ModifProfil = 0
	WHERE  ModifProfil = 1
	
	-- On dйtecte les lignes а modifier
	
	-- Traiter sйparйment la modification du profil et modification d'opt-in
	
	UPDATE a
	SET    ModifProfil = 1
	FROM   import.Prospects_Cumul a
	       INNER JOIN import.LPPROSP_Prospects b
	            ON  a.email_courant = b.email_courant
	WHERE  (
	           COALESCE(a.datejoin ,N'') <> COALESCE(b.datejoin ,N'')
	           OR COALESCE(a.email_origine ,N'') <> COALESCE(b.email_origine ,N'')
	           OR COALESCE(a.username ,N'') <> COALESCE(b.username ,N'')
	           OR COALESCE(a.civilite ,N'') <> COALESCE(b.civilite ,N'')
	           OR COALESCE(a.nom ,N'') <> COALESCE(b.nom ,N'')
	           OR COALESCE(a.prenom ,N'') <> COALESCE(b.prenom ,N'')
	           OR COALESCE(a.date_de_naissance ,N'') <> COALESCE(b.date_de_naissance ,N'')
	           OR COALESCE(a.adresse ,N'') <> COALESCE(b.adresse ,N'')
	           OR COALESCE(a.code_postal ,N'') <> COALESCE(b.code_postal ,N'')
	           OR COALESCE(a.ville ,N'') <> COALESCE(b.ville ,N'')
	           OR COALESCE(a.pays ,N'') <> COALESCE(b.pays ,N'')
	           OR COALESCE(a.telephone_particulier ,N'') <> COALESCE(b.telephone_particulier ,N'')
	       )
	       AND b.FichierTS = @FichierTS
	       AND b.LigneStatut = 0
	
	UPDATE a
	SET    ModifOptin = 1
	FROM   import.Prospects_Cumul a
	       INNER JOIN import.LPPROSP_Prospects b
	            ON  a.email_courant = b.email_courant
	WHERE  (
	           COALESCE(a.optin_leparisien ,N'') <> COALESCE(b.optin_leparisien ,N'')
	           OR COALESCE(a.optin_partenaire ,N'') <> COALESCE(b.optin_partenaire ,N'')
	           OR COALESCE(a.optin_newsletter ,N'') <> COALESCE(b.optin_newsletter ,N'')
	           OR COALESCE(a.optin_alerte ,N'') <> COALESCE(b.optin_alerte ,N'')
	           OR COALESCE(a.optin_aujourdhui_etudiant ,N'') <> COALESCE(b.optin_aujourdhui_etudiant ,N'')
	           OR COALESCE(a.date_souscrip_optin_leparisien ,N'') <> COALESCE(b.date_souscrip_optin_leparisien ,N'')
	           OR COALESCE(a.date_resil_optin_leparisien ,N'') <> COALESCE(b.date_resil_optin_leparisien ,N'')
	           OR COALESCE(a.date_souscrip_optin_partenaire ,N'') <> COALESCE(b.date_souscrip_optin_partenaire ,N'')
	           OR COALESCE(a.date_resil_optin_partenaire ,N'') <> COALESCE(b.date_resil_optin_partenaire ,N'')
	           OR COALESCE(a.date_souscrip_optin_newsletter ,N'') <> COALESCE(b.date_souscrip_optin_newsletter ,N'')
	           OR COALESCE(a.date_resil_optin_newsletter ,N'') <> COALESCE(b.date_resil_optin_newsletter ,N'')
	           OR COALESCE(a.date_souscrip_optin_alerte ,N'') <> COALESCE(b.date_souscrip_optin_alerte ,N'')
	           OR COALESCE(a.date_resil_optin_alerte ,N'') <> COALESCE(b.date_resil_optin_alerte ,N'')
	           OR COALESCE(a.date_souscr_optin_auj_etudiant ,N'') <> COALESCE(b.date_souscr_optin_auj_etudiant ,N'')
	           OR COALESCE(a.date_resil_optin_auj_etudiant ,N'') <> COALESCE(b.date_resil_optin_auj_etudiant ,N'')
	           OR COALESCE(a.date_modif_profil ,N'') <> COALESCE(b.date_modif_profil ,N'')
	           OR COALESCE(a.source_recrutement ,N'') <> COALESCE(b.source_recrutement ,N'')
	           OR COALESCE(a.source_detail_jc ,N'') <> COALESCE(b.source_detail_jc ,N'')
	           OR COALESCE(a.marque_mobile ,N'') <> COALESCE(b.marque_mobile ,N'')
	           OR COALESCE(a.modele_mobile ,N'') <> COALESCE(b.modele_mobile ,N'')
	           OR COALESCE(a.optin_news_them_laparisienne ,N'') <> COALESCE(b.optin_news_them_laparisienne ,N'')
	           OR COALESCE(a.optin_news_them_politique ,N'') <> COALESCE(b.optin_news_them_politique ,N'')
	           OR COALESCE(a.optin_news_them_loisirs ,N'') <> COALESCE(b.optin_news_them_loisirs ,N'')
	           OR COALESCE(a.date_souscr_nl_thematique ,N'') <> COALESCE(b.date_souscr_nl_thematique ,N'')
	           OR COALESCE(a.date_resiliation_nl_thematique ,N'') <> COALESCE(b.date_resiliation_nl_thematique ,N'')
	           OR COALESCE(a.optin_news_them_psg ,N'') <> COALESCE(b.optin_news_them_psg ,N'')
	           OR COALESCE(a.optin_newsletter_thematique_ile_de_france ,N'') <> 
	              COALESCE(b.optin_newsletter_thematique_ile_de_france ,N'')
	           OR COALESCE(a.optin_newsletter_thematique_paris ,N'') <> COALESCE(b.optin_newsletter_thematique_paris ,N'')
	           OR COALESCE(a.optin_newsletter_thematique_seine_et_marne ,N'') <> 
	              COALESCE(b.optin_newsletter_thematique_seine_et_marne ,N'')
	           OR COALESCE(a.optin_newsletter_thematique_yvelines ,N'') <> 
	              COALESCE(b.optin_newsletter_thematique_yvelines ,N'')
	           OR COALESCE(a.optin_newsletter_thematique_essonne ,N'') <> 
	              COALESCE(b.optin_newsletter_thematique_essonne ,N'')
	           OR COALESCE(a.optin_newsletter_thematique_hauts_de_seine ,N'') <> 
	              COALESCE(b.optin_newsletter_thematique_hauts_de_seine ,N'')
	           OR COALESCE(a.optin_newsletter_thematique_seine_st_denis ,N'') <> 
	              COALESCE(b.optin_newsletter_thematique_seine_st_denis ,N'')
	           OR COALESCE(a.optin_newsletter_thematique_val_de_marne ,N'') <> 
	              COALESCE(b.optin_newsletter_thematique_val_de_marne ,N'')
	           OR COALESCE(a.optin_newsletter_thematique_val_oise ,N'') <> 
	              COALESCE(b.optin_newsletter_thematique_val_oise ,N'')
	           OR COALESCE(a.optin_newsletter_thematique_oise ,N'') <> COALESCE(b.optin_newsletter_thematique_oise ,N'')
	           OR COALESCE(a.optin_newsletter_thematique_medias_people ,N'') <> COALESCE(b.optin_newsletter_thematique_medias_people ,N'')
	           OR COALESCE(a.optin_newsletter_thematique_tv ,N'') <> COALESCE(b.optin_newsletter_thematique_tv ,N'')
	           OR COALESCE(a.optin_newsletter_thematique_environnement ,N'') <> COALESCE(b.optin_newsletter_thematique_environnement ,N'')
	       )
	       AND b.FichierTS = @FichierTS
	       AND b.LigneStatut = 0
	
	UPDATE import.Prospects_Cumul
	SET    ModifieTop = 1
	WHERE  (ModifOptin = 1 OR ModifProfil = 1)
	
	IF OBJECT_ID(N'tempdb..#T_MarquerModif') IS NOT NULL
	    DROP TABLE #T_MarquerModif
	
	CREATE TABLE #T_MarquerModif
	(
		email_courant     NVARCHAR(255) NULL
	   ,ModifOptin        BIT NOT NULL DEFAULT(0)
	   ,ModifProfil       BIT NOT NULL DEFAULT(0)
	)
	
	INSERT #T_MarquerModif
	  (
	    email_courant
	  )
	SELECT email_courant
	FROM   import.Prospects_Cumul
	WHERE  ModifieTop = 1
	
	CREATE INDEX idx01_T_MarquerModif ON #T_MarquerModif(email_courant)
	
	UPDATE c
	SET    ModifOptin = a.ModifOptin
	FROM   #T_MarquerModif c
	       INNER JOIN import.Prospects_Cumul a
	            ON  c.email_courant = a.email_courant
	
	UPDATE c
	SET    ModifProfil = a.ModifProfil
	FROM   #T_MarquerModif c
	       INNER JOIN import.Prospects_Cumul a
	            ON  c.email_courant = a.email_courant
	
	
	IF OBJECT_ID('tempdb..#T_MAJ_Prospects') IS NOT NULL
	    DROP TABLE #T_MAJ_Prospects
	
	CREATE TABLE #T_MAJ_Prospects
	(
		email_courant     NVARCHAR(255) NULL
	   ,ImportID          INT NULL
	)
	
	INSERT #T_MAJ_Prospects
	  (
	    email_courant
	   ,ImportID
	  )
	SELECT email_courant
	      ,ImportID
	FROM   import.Prospects_Cumul
	WHERE  ModifieTop = 1
	
	-- Supprimer les anciennes lignes marquйes "A modifier" et les remplacer par les nouvelles
	DELETE a
	FROM   import.Prospects_Cumul a
	       INNER JOIN #T_MAJ_Prospects t
	            ON  a.ImportID = t.ImportID
	                AND a.email_courant = t.email_courant
	
	INSERT import.Prospects_Cumul
	  (
	    RejetCode
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
	   ,telephone_particulier
	   ,optin_leparisien
	   ,optin_partenaire
	   ,optin_newsletter
	   ,optin_alerte
	   ,optin_aujourdhui_etudiant
	   ,date_souscrip_optin_leparisien
	   ,date_resil_optin_leparisien
	   ,date_souscrip_optin_partenaire
	   ,date_resil_optin_partenaire
	   ,date_souscrip_optin_newsletter
	   ,date_resil_optin_newsletter
	   ,date_souscrip_optin_alerte
	   ,date_resil_optin_alerte
	   ,date_souscr_optin_auj_etudiant
	   ,date_resil_optin_auj_etudiant
	   ,date_modif_profil
	   ,source_recrutement
	   ,source_detail_jc
	   ,marque_mobile
	   ,modele_mobile
	   ,optin_news_them_laparisienne
	   ,optin_news_them_politique
	   ,optin_news_them_loisirs
	   ,date_souscr_nl_thematique
	   ,date_resiliation_nl_thematique
	   ,ModifieTop
	   ,LigneStatut
	   ,FichierTS
	   ,optin_news_them_psg
	   ,optin_newsletter_thematique_ile_de_france
	   ,optin_newsletter_thematique_paris
	   ,optin_newsletter_thematique_seine_et_marne
	   ,optin_newsletter_thematique_yvelines
	   ,optin_newsletter_thematique_essonne
	   ,optin_newsletter_thematique_hauts_de_seine
	   ,optin_newsletter_thematique_seine_st_denis
	   ,optin_newsletter_thematique_val_de_marne
	   ,optin_newsletter_thematique_val_oise
	   ,optin_newsletter_thematique_oise
	   ,optin_newsletter_thematique_medias_people
	   ,optin_newsletter_thematique_tv
	   ,optin_newsletter_thematique_environnement
	   	  )
	SELECT a.RejetCode
	      ,a.datejoin
	      ,a.email_origine
	      ,a.email_courant
	      ,a.username
	      ,a.civilite
	      ,a.nom
	      ,a.prenom
	      ,a.date_de_naissance
	      ,a.adresse
	      ,a.code_postal
	      ,a.ville
	      ,a.pays
	      ,a.telephone_particulier
	      ,a.optin_leparisien
	      ,a.optin_partenaire
	      ,a.optin_newsletter
	      ,a.optin_alerte
	      ,a.optin_aujourdhui_etudiant
	      ,a.date_souscrip_optin_leparisien
	      ,a.date_resil_optin_leparisien
	      ,a.date_souscrip_optin_partenaire
	      ,a.date_resil_optin_partenaire
	      ,a.date_souscrip_optin_newsletter
	      ,a.date_resil_optin_newsletter
	      ,a.date_souscrip_optin_alerte
	      ,a.date_resil_optin_alerte
	      ,a.date_souscr_optin_auj_etudiant
	      ,a.date_resil_optin_auj_etudiant
	      ,a.date_modif_profil
	      ,a.source_recrutement
	      ,a.source_detail_jc
	      ,a.marque_mobile
	      ,a.modele_mobile
	      ,a.optin_news_them_laparisienne
	      ,a.optin_news_them_politique
	      ,a.optin_news_them_loisirs
	      ,a.date_souscr_nl_thematique
	      ,a.date_resiliation_nl_thematique
	      ,1 AS ModifieTop
	      ,a.LigneStatut
	      ,a.FichierTS
	      ,a.optin_news_them_psg
	      ,a.optin_newsletter_thematique_ile_de_france
	      ,a.optin_newsletter_thematique_paris
	      ,a.optin_newsletter_thematique_seine_et_marne
	      ,a.optin_newsletter_thematique_yvelines
	      ,a.optin_newsletter_thematique_essonne
	      ,a.optin_newsletter_thematique_hauts_de_seine
	      ,a.optin_newsletter_thematique_seine_st_denis
	      ,a.optin_newsletter_thematique_val_de_marne
	      ,a.optin_newsletter_thematique_val_oise
	      ,a.optin_newsletter_thematique_oise
      	  ,a.optin_newsletter_thematique_medias_people
	      ,a.optin_newsletter_thematique_tv
	      ,a.optin_newsletter_thematique_environnement

	FROM   import.LPPROSP_Prospects a
	       INNER JOIN #T_MAJ_Prospects t
	            ON  a.email_courant = t.email_courant
	WHERE  a.FichierTS = @FichierTS
	       AND a.LigneStatut = 0
	
	UPDATE a
	SET    ModifOptin = b.ModifOptin
	      ,ModifProfil = b.ModifProfil
	FROM   import.Prospects_Cumul a
	       INNER JOIN #T_MarquerModif b
	            ON  a.email_courant = b.email_courant
	                AND a.ModifieTop = 1
	
	-- Insertion des nouvelles lignes
	
	-- Chaque nouvelle ligne est censйe donner lieu а un nouveau contacts et ses opt-ins
	-- on l'on met d'office ModifOptin=1, ModifProfil=1
	
	INSERT import.Prospects_Cumul
	  (
	    RejetCode
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
	   ,telephone_particulier
	   ,optin_leparisien
	   ,optin_partenaire
	   ,optin_newsletter
	   ,optin_alerte
	   ,optin_aujourdhui_etudiant
	   ,date_souscrip_optin_leparisien
	   ,date_resil_optin_leparisien
	   ,date_souscrip_optin_partenaire
	   ,date_resil_optin_partenaire
	   ,date_souscrip_optin_newsletter
	   ,date_resil_optin_newsletter
	   ,date_souscrip_optin_alerte
	   ,date_resil_optin_alerte
	   ,date_souscr_optin_auj_etudiant
	   ,date_resil_optin_auj_etudiant
	   ,date_modif_profil
	   ,source_recrutement
	   ,source_detail_jc
	   ,marque_mobile
	   ,modele_mobile
	   ,optin_news_them_laparisienne
	   ,optin_news_them_politique
	   ,optin_news_them_loisirs
	   ,date_souscr_nl_thematique
	   ,date_resiliation_nl_thematique
	   ,LigneStatut
	   ,FichierTS
	   ,ModifOptin
	   ,ModifProfil
	   ,optin_news_them_psg
	   ,optin_newsletter_thematique_ile_de_france
	   ,optin_newsletter_thematique_paris
	   ,optin_newsletter_thematique_seine_et_marne
	   ,optin_newsletter_thematique_yvelines
	   ,optin_newsletter_thematique_essonne
	   ,optin_newsletter_thematique_hauts_de_seine
	   ,optin_newsletter_thematique_seine_st_denis
	   ,optin_newsletter_thematique_val_de_marne
	   ,optin_newsletter_thematique_val_oise
	   ,optin_newsletter_thematique_oise
	   ,optin_newsletter_thematique_medias_people
	   ,optin_newsletter_thematique_tv
	   ,optin_newsletter_thematique_environnement
	  )
	SELECT a.RejetCode
	      ,a.datejoin
	      ,a.email_origine
	      ,a.email_courant
	      ,a.username
	      ,a.civilite
	      ,a.nom
	      ,a.prenom
	      ,a.date_de_naissance
	      ,a.adresse
	      ,a.code_postal
	      ,a.ville
	      ,a.pays
	      ,a.telephone_particulier
	      ,a.optin_leparisien
	      ,a.optin_partenaire
	      ,a.optin_newsletter
	      ,a.optin_alerte
	      ,a.optin_aujourdhui_etudiant
	      ,a.date_souscrip_optin_leparisien
	      ,a.date_resil_optin_leparisien
	      ,a.date_souscrip_optin_partenaire
	      ,a.date_resil_optin_partenaire
	      ,a.date_souscrip_optin_newsletter
	      ,a.date_resil_optin_newsletter
	      ,a.date_souscrip_optin_alerte
	      ,a.date_resil_optin_alerte
	      ,a.date_souscr_optin_auj_etudiant
	      ,a.date_resil_optin_auj_etudiant
	      ,a.date_modif_profil
	      ,a.source_recrutement
	      ,a.source_detail_jc
	      ,a.marque_mobile
	      ,a.modele_mobile
	      ,a.optin_news_them_laparisienne
	      ,a.optin_news_them_politique
	      ,a.optin_news_them_loisirs
	      ,a.date_souscr_nl_thematique
	      ,a.date_resiliation_nl_thematique
	      ,a.LigneStatut
	      ,a.FichierTS
	      ,1                  AS ModifOptin
	      ,1                  AS ModifProfil
	      ,a.optin_news_them_psg
	      ,a.optin_newsletter_thematique_ile_de_france
	      ,a.optin_newsletter_thematique_paris
	      ,a.optin_newsletter_thematique_seine_et_marne
	      ,a.optin_newsletter_thematique_yvelines
	      ,a.optin_newsletter_thematique_essonne
	      ,a.optin_newsletter_thematique_hauts_de_seine
	      ,a.optin_newsletter_thematique_seine_st_denis
	      ,a.optin_newsletter_thematique_val_de_marne
	      ,a.optin_newsletter_thematique_val_oise
	      ,a.optin_newsletter_thematique_oise
		,a.optin_newsletter_thematique_medias_people
	   ,a.optin_newsletter_thematique_tv
	   ,a.optin_newsletter_thematique_environnement
	FROM   import.LPPROSP_Prospects a
	       LEFT OUTER JOIN import.Prospects_Cumul b
	            ON  a.email_courant = b.email_courant
	WHERE  a.FichierTS = @FichierTS
	       AND a.LigneStatut = 0
	       AND b.ImportID IS     NULL
	
	
	IF OBJECT_ID('tempdb..#T_MAJ_Prospects') IS NOT NULL
	    DROP TABLE #T_MAJ_Prospects
	
	IF OBJECT_ID(N'tempdb..#T_MarquerModif') IS NOT NULL
	    DROP TABLE #T_MarquerModif
	
	-- Suppression dans import.Prospects_Cumul et SupprimeTop=1 dans brut.Contacts des lignes qui ne sont plus dans le fichier Prospects d'origine
	
	IF OBJECT_ID(N'tempdb..#T_Prospects_Cumul_Suppr') IS NOT NULL
	    DROP TABLE #T_Prospects_Cumul_Suppr
	
	CREATE TABLE #T_Prospects_Cumul_Suppr
	(
		email_courant     NVARCHAR(255)
	   ,email_origine     NVARCHAR(255)
	)
	
	INSERT #T_Prospects_Cumul_Suppr
	  (
	    email_courant
	   ,email_origine
	  )
	SELECT a.email_courant
	      ,a.email_origine
	FROM   import.Prospects_Cumul a
	       LEFT OUTER JOIN import.LPPROSP_Prospects b
	            ON  a.email_courant = b.email_courant
	WHERE  a.email_courant IS NOT NULL
	       AND b.email_courant IS NULL
	
	CREATE INDEX idx01_T_SSO_Cumul_Suppr ON #T_Prospects_Cumul_Suppr(email_courant)
	CREATE INDEX idx02_T_SSO_Cumul_Suppr ON #T_Prospects_Cumul_Suppr(email_origine)
	
	DELETE a
	FROM   import.Prospects_Cumul a
	       INNER JOIN #T_Prospects_Cumul_Suppr b
	            ON  a.email_courant = b.email_courant
	
	UPDATE a
	SET    SupprimeTop = 1
	FROM   brut.Contacts a
	       INNER JOIN #T_Prospects_Cumul_Suppr b
	            ON  a.OriginalID = b.email_courant
	WHERE  a.SourceID = 4 -- Prospects
	
	IF OBJECT_ID(N'tempdb..#T_Prospects_Cumul_Suppr') IS NOT NULL
	    DROP TABLE #T_Prospects_Cumul_Suppr
END


GO


