DECLARE @fs NVARCHAR(255)
SET @fs = N'FF_%-31032015.csv'

delete FROM import.[PVL_Abonnements] WHERE FichierTS LIKE @fs
delete FROM rejet.[PVL_Abonnements] WHERE FichierTS LIKE @fs

delete FROM import.PVL_Achats WHERE FichierTS LIKE @fs
delete FROM rejet.PVL_Achats WHERE FichierTS LIKE @fs
delete FROM import.PVL_Achats2 WHERE FichierTS LIKE @fs

delete FROM import.PVL_CatalogueOffres WHERE FichierTS LIKE @fs
delete FROM rejet.PVL_CatalogueOffres WHERE FichierTS LIKE @fs

delete FROM import.PVL_Utilisateur WHERE FichierTS LIKE @fs
delete FROM rejet.PVL_Utilisateur WHERE FichierTS LIKE @fs
