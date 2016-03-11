ALTER PROCEDURE etl.ChangeInTypologiesMixed
	@onDate DATETIME
AS
BEGIN
	SET NOCOUNT ON
	--DECLARE @onDate DATETIME = '20151121'
	
	IF OBJECT_ID('tempdb..#T_ChangedContacts') IS NOT NULL
	    DROP TABLE #T_ChangedContacts
	
	--          Only those typologies are in the scope :
	--          o   Subscribers  (*S***)
	--          o   Buyers (*A***)
	--          o   Visitors (V***)
	--          o   Optins (O***)
	--          And only for those brands :
	--          o   Aujourd'hui en France (2)
	--			o   Le Parisien (6)
	
	--select contacts with typologies changes.
	SELECT MasterID
	      ,ctsl.CurrTypologieID
	      ,ctsl.PrevTypologieID
	       INTO #T_ChangedContacts
	FROM   etl.ChangementTypologieKeySet ks
	       JOIN etl.ChangementTypologieSliceLast AS ctsl
	            ON  ks.ChangementId = ctsl.ChangementId
	WHERE  MarqueID IN (2 ,6)
	       AND (
	               TypoGR1 LIKE '_S%'
	               OR TypoGR1 LIKE '_A%'
	               OR TypoGR1 LIKE 'V%'
	               OR TypoGR1 LIKE 'O%'
	           )
	       AND ctsl.ChangeDate >= @onDate--	       AND masterId IN (4640989,4050908,8985642,4052339 )
	       GROUP BY
	       ks.MasterID
	      ,ctsl.CurrTypologieID
	      ,ctsl.PrevTypologieID
	
	IF OBJECT_ID('tempdb..#T_TypologieKeySet') IS NOT NULL
	    DROP TABLE #T_TypologieKeySet
	
	SELECT distinct ks.ChangementId
	      ,ks.MasterID
	      ,ks.MarqueID
	      ,t1.Code  AS typologieCode
	      ,t2.Code  AS PrevtypologieCode
	      ,prefix = CASE 
	                     WHEN MarqueID = 2 THEN 'AF'
	                     WHEN MarqueID = 6 THEN 'LP'
	                END
	      ,profil = t1.Profil + ISNULL(t1.SousProfil ,'') 
	       --for fight between typologies
	      ,LifeCycle = t1.Cycle
	      ,t1.Payant
	       ,TypoGR1                     
	       INTO #T_TypologieKeySet
	FROM   etl.ChangementTypologieKeySet ks
	       JOIN #T_ChangedContacts
	            ON  ks.MasterID = #T_ChangedContacts.MasterID
	       JOIN etl.ChangementTypologieSliceLast AS sl
	            ON  ks.ChangementId = sl.ChangementId
	       LEFT JOIN ref.Typologie AS t1
	            ON  t1.TypoID = sl.CurrTypologieID
	       LEFT JOIN ref.Typologie AS t2
	            ON  t2.TypoID = sl.PrevTypologieID
	WHERE sl.CurrTypologieID IS NOT NULL 
	and MarqueID IN (2 ,6)
	       AND (
	               TypoGR1 LIKE '_S%'
	               OR TypoGR1 LIKE '_A%'
	               OR TypoGR1 LIKE 'V%'
	               OR TypoGR1 LIKE 'O%'
	           )
	IF OBJECT_ID('tempdb..#T_Mixed') IS NOT NULL
	    DROP TABLE #T_Mixed
	--  We need to mix physical (**P**) /digital ( **N**) typologies into three values : P (physical), N (digital), M (both).
	--  So someone who is CSPPA and CSNPA becomes CSMPA.
	SELECT MasterId
	      ,MarqueID
	      ,typologieCode
	      ,MixTypologieCode
	      ,N
	       INTO #T_Mixed
	FROM   (
	           SELECT *
	                 ,ISNULL(STUFF(typologieCode ,3 ,1 ,'M') ,typologieCode) 
	                  MixTypologieCode
	                 ,COUNT(MasterID) OVER(
	                      PARTITION BY masterId
	                     ,MArqueID
	                     ,Left(ISNULL(STUFF(TypoGR1 ,3 ,1 ,'M') ,TypoGR1),3)
	                  ) n
	           FROM   #T_TypologieKeySet
	       ) xxx
	WHERE  xxx.n >= 2
	UPDATE ks
	SET    ks.typologieCode = m.MixTypologieCode
	FROM   #T_TypologieKeySet ks
	       JOIN #T_Mixed m
	            ON  ks.MasterID = m.MasterID
	                AND ks.MarqueID = m.MarqueID
	                AND ks.typologieCode = m.typologieCode
		--FIGHT
	--E>*(F)
	DELETE x2
	FROM   #T_TypologieKeySet X1
	       JOIN #T_TypologieKeySet X2
	            ON  x1.masterID = x2.masterID
	                AND x1.MarqueID = x2.MarqueID
	WHERE  x1.profil LIKE '_S%'
	       AND x2.profil LIKE '_S%'
	       AND x1.LifeCycle = N'E'
	       AND x2.LifeCycle IN (N'A' ,N'N' ,N'T' ,N'R' ,N'I')
	       AND x1.Payant>=x2.Payant 

	--A>*(E)
	DELETE x2
	FROM   #T_TypologieKeySet X1
	       JOIN #T_TypologieKeySet X2
	            ON  x1.masterID = x2.masterID
	                AND x1.MarqueID = x2.MarqueID
	WHERE  x1.profil LIKE '_S%'
	       AND x2.profil LIKE '_S%'
	       AND x1.LifeCycle = N'A'
	       AND x2.LifeCycle IN (N'N' ,N'T' ,N'R' ,N'I' ,N'F')
	       AND x1.Payant>=x2.Payant 

	--N>*(A,E)       
	DELETE x2
	FROM   #T_TypologieKeySet X1
	       JOIN #T_TypologieKeySet X2
	            ON  x1.masterID = x2.masterID
	                AND x1.MarqueID = x2.MarqueID
	WHERE  x1.profil LIKE '_S%'
	       AND x2.profil LIKE '_S%'
	       AND x1.LifeCycle = N'N'
	       AND x2.LifeCycle IN (N'T' ,N'R' ,N'I' ,N'F') 
	       AND x1.Payant>=x2.Payant 
	
	--F>*(A,N)       
	DELETE x2
	FROM   #T_TypologieKeySet X1
	       JOIN #T_TypologieKeySet X2
	            ON  x1.masterID = x2.masterID
	                AND x1.MarqueID = x2.MarqueID
	WHERE  x1.profil LIKE '_S%'
	       AND x2.profil LIKE '_S%'
	       AND x1.LifeCycle = N'F'
	       AND x2.LifeCycle IN (N'E' ,N'T' ,N'R' ,N'I') 
	       AND x1.Payant>=x2.Payant 
	
	--T>R,I       
	DELETE x2
	FROM   #T_TypologieKeySet X1
	       JOIN #T_TypologieKeySet X2
	            ON  x1.masterID = x2.masterID
	                AND x1.MarqueID = x2.MarqueID
	WHERE  x1.profil LIKE '_S%'
	       AND x2.profil LIKE '_S%'
	       AND x1.LifeCycle = N'T'
	       AND x2.LifeCycle IN (N'R' ,N'I') 
	       AND x1.Payant>=x2.Payant 
	
	--R>I       
	DELETE x2
	FROM   #T_TypologieKeySet X1
	       JOIN #T_TypologieKeySet X2
	            ON  x1.masterID = x2.masterID
	                AND x1.MarqueID = x2.MarqueID
	WHERE  x1.profil LIKE '_S%'
	       AND x2.profil LIKE '_S%'
	       AND x1.LifeCycle = N'R'
	       AND x2.LifeCycle IN (N'I')
	       AND x1.Payant>=x2.Payant 
	
	
	--OTHER
	--
	--N>A,I       
	DELETE x2
	FROM   #T_TypologieKeySet X1
	       JOIN #T_TypologieKeySet X2
	            ON  x1.masterID = x2.masterID
	                AND x1.MarqueID = x2.MarqueID
	WHERE  x1.profil NOT LIKE '_S%'
	       AND x2.profil NOT LIKE '_S%'
	       AND x1.LifeCycle = N'N'
	       AND x2.LifeCycle IN (N'A' ,N'I') 
	       AND x1.Payant>=x2.Payant 
	
	--A>I           
	DELETE x2
	FROM   #T_TypologieKeySet X1
	       JOIN #T_TypologieKeySet X2
	            ON  x1.masterID = x2.masterID
	                AND x1.MarqueID = x2.MarqueID
	WHERE  x1.profil NOT LIKE '_S%'
	       AND x2.profil NOT LIKE '_S%'
	       AND x1.LifeCycle = N'A'
	       AND x2.LifeCycle IN (N'I')   
	       AND x1.Payant>=x2.Payant 
	
	--Fight	payant
	IF OBJECT_ID('tempdb..#T_TypologieKeySetFight') IS NOT NULL
	    DROP TABLE #T_TypologieKeySetFight

	SELECT *
	      ,ROW_NUMBER() OVER(
	           PARTITION BY MasterId
	          ,marqueId
	          ,Profil ORDER BY payant DESC
	       ) N --<-it's fight, winner in with rownumber = 1
	       INTO #T_TypologieKeySetFight
	FROM   #T_TypologieKeySet
	ORDER BY
	       masterId
	      ,marqueID
	--      

	IF OBJECT_ID('tempdb..#tmp') IS NOT NULL
	    DROP TABLE #tmp 
	-- select  
	SELECT ks.MasterID
	      ,c.OriginalID        AS email
	      ,dc.CiviliteID
	      ,dc.Prenom
	      ,dc.Nom
	      ,prefix
	      ,valueType = CASE 
	                        WHEN COALESCE(typologieCode ,PrevtypologieCode) LIKE 
	                             '_S%' THEN 'Souscripteur '
	                        WHEN COALESCE(typologieCode ,PrevtypologieCode) LIKE 
	                             '_A%' THEN 'Acheteur '
	                        WHEN COALESCE(typologieCode ,PrevtypologieCode) LIKE 
	                             'V%' THEN 'Visiteur '
	                        WHEN COALESCE(typologieCode ,PrevtypologieCode) LIKE 
	                             'O%' THEN 'Optin '
	                   END + prefix
	      ,DateType = CASE 
	                       WHEN COALESCE(typologieCode ,PrevtypologieCode) LIKE 
	                            '_S%' THEN 'Date souscripteur '
	                       WHEN COALESCE(typologieCode ,PrevtypologieCode) LIKE 
	                            '_A%' THEN 'Date acheteur '
	                       WHEN COALESCE(typologieCode ,PrevtypologieCode) LIKE 
	                            'V%' THEN 'Date visiteur '
	                       WHEN COALESCE(typologieCode ,PrevtypologieCode) LIKE 
	                            'O%' THEN 'Date optin '
	                  END + prefix
	      ,ks.typologieCode
	      ,ls.ChangeDate
	       INTO                   #tmp
		   FROM   #T_TypologieKeySetFight ks
	       JOIN brut.Contacts  AS c
	            ON  c.SourceID = 4
	                AND ks.MasterID = c.MasterID
	       JOIN dbo.Contacts   AS dc
	            ON  ks.MasterID = dc.MasterID
	       JOIN etl.ChangementTypologieSliceLast AS ls
	            ON  ls.ChangementId = ks.ChangementId
	WHERE  ks.N = 1            
	
	
	SELECT MasterID
	      ,email
	      ,CiviliteID
	      ,Prenom
	      ,Nom
	      ,[Souscripteur LP] = MAX([Souscripteur LP])
	      ,[Date souscripteur LP] = MAX([Date souscripteur LP])
	      ,[Acheteur LP] = MAX([Acheteur LP])
	      ,[Date acheteur LP] = MAX([Date acheteur LP])
	      ,[Optin LP] = MAX([Optin LP])
	      ,[Date optin LP] = MAX([Date optin LP])
	      ,[Visiteur LP] = MAX([Visiteur LP])
	      ,[Date visiteur LP] = MAX([Date visiteur LP])
	      ,[Souscripteur AF] = MAX([Souscripteur AF])
	      ,[Date souscripteur AF] = MAX([Date souscripteur AF])
	      ,[Acheteur AF] = MAX([Acheteur AF])
	      ,[Date acheteur AF] = MAX([Date acheteur AF])
	      ,[Optin AF] = MAX([Optin AF])
	      ,[Date optin AF] = MAX([Date optin AF])
	      ,[Visiteur AF] = MAX([Visiteur AF])
	      ,[Date visiteur AF] = MAX([Date visiteur AF])
	FROM   #tmp 
	       PIVOT(
	           MAX(typologieCode)
	           FOR valueType IN ([Souscripteur LP]
	                            ,[Acheteur LP]
	                            ,[Optin LP]
	                            ,[Visiteur LP]
	                            ,[Souscripteur AF]
	                            ,[Acheteur AF]
	                            ,[Optin AF]
	                            ,[Visiteur AF])
	       ) AS Pivot1
	       PIVOT(
	           MAX(ChangeDate)
	           FOR DateType IN ([Date souscripteur LP]
	                           ,[Date acheteur LP]
	                           ,[Date optin LP]
	                           ,[Date visiteur LP]
	                           ,[Date souscripteur AF]
	                           ,[Date acheteur AF]
	                           ,[Date optin AF]
	                           ,[Date visiteur AF])
	       ) AS Pivot2
	GROUP BY
	       MasterID
	      ,email
	      ,CiviliteID
	      ,Prenom
	      ,Nom
	ORDER BY
	       MasterID
	      ,Email 
	
	
	
	DROP TABLE #T_TypologieKeySet
	DROP TABLE #T_Mixed
	DROP TABLE #tmp
END

