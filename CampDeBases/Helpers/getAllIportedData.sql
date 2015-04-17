	 
	 DECLARE @fs NVARCHAR(255)
	 SET @fs = N'FF_%'						
	 
	 SELECT * FROM import.[PVL_Abonnements] WHERE FichierTS LIKE @fs
	 union all
	 SELECT * FROM rejet.[PVL_Abonnements] WHERE FichierTS LIKE @fs 
	 
	 SELECT * FROM [import].[PVL_CatalogueOffres] WHERE FichierTS like @fs
	 union all
	 SELECT * FROM rejet.[PVL_CatalogueOffres] WHERE FichierTS like @fs
	 
	 SELECT * FROM [import].PVL_Achats WHERE FichierTS like @fs
	 union all
	 SELECT * FROM rejet.PVL_Achats WHERE FichierTS like @fs
	 
	 SELECT * FROM [import].[PVL_Utilisateur] WHERE FichierTS like @fs
	 union all
	 SELECT * FROM rejet.[PVL_Utilisateur] WHERE FichierTS like @fs  				 