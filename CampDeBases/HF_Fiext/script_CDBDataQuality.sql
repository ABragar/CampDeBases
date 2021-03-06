USE [CDBDataQuality]
GO
/****** Object:  UserDefinedFunction [etl].[FormatPrenom]    Script Date: 04/01/2015 16:59:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [etl].[FormatPrenom]
(
	-- Add the parameters for the function here
	@Prenom nvarchar (255)
)
RETURNS nvarchar(255)
AS
BEGIN
declare @prenomF nvarchar(80)

set @prenomF = '';


declare @nbcar int;
declare @i int;
declare @upper int;

set @nbcar = LEN(@prenom);
set @i = 1;
set @upper = 1;

while @i < @nbcar
begin
	if SUBSTRING(@prenom, @i, 1) = ' ' or SUBSTRING(@prenom, @i, 1) = '-'
	begin
		set @prenomF += UPPER(SUBSTRING(@prenom, @upper, 1));
		set @prenomF += LOWER(SUBSTRING(@prenom, @upper+1, @i-@upper))
		set @upper = @i+1;
	end 
	set @i += 1;
end
set @prenomF += UPPER(SUBSTRING(@prenom, @upper, 1));
set @prenomF += LOWER(SUBSTRING(@prenom, @upper+1, @i-@upper))

return @prenomF

	
END
GO
/****** Object:  Table [ref].[FAI]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ref].[FAI](
	[PREFIXE] [nvarchar](10) NULL,
	[OPERATEUR] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [ref].[FaceBookDirectory]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ref].[FaceBookDirectory](
	[Email] [nvarchar](80) NULL,
	[ID] [bigint] NULL,
	[NomComplet] [nvarchar](128) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [etl].[Encodage]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [etl].[Encodage](
	[Caractere] [nchar](1) NULL,
	[CodeISO] [nvarchar](12) NULL,
	[CodeHTML] [nvarchar](8) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [etl].[EMAILSTRINGREMPLACEMENTS]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [etl].[EMAILSTRINGREMPLACEMENTS](
	[ID] [int] NOT NULL,
	[AREMPLACER] [varchar](64) NULL,
	[REMPLACEMENT] [varchar](64) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [etl].[EMAILDOMAINEREMPLACEMENTS]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [etl].[EMAILDOMAINEREMPLACEMENTS](
	[ID] [int] NOT NULL,
	[AREMPLACER] [varchar](128) NOT NULL,
	[REMPLACEMENT] [varchar](128) NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [etl].[ConstruireDedupTag]    Script Date: 04/01/2015 16:59:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [etl].[ConstruireDedupTag]
(
	-- Add the parameters for the function here
	@Adresse nvarchar(320)
)
RETURNS nvarchar(320)
AS
BEGIN
	
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'ALLEES','AL')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'ALLEE','AL')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'APPARTEMENT','APT')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'APPART','APT')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'APPT','APT')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'APP','APT')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'AVENUE','AV')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'AVE','AV')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'BATIMENT','BT')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'BAT','BT')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'BOULEVARD','BD')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'BLD','BD')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'BOITE POSTALE','BP')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'COMMANDANT','CDT')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'CHEMIN','CH')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'CHE','CH')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'DOCTEUR','DR')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'ESCALIER','ESC')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'FAUBOURG','FBG')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'GENERAL','GAL')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'IMMEUBLE','IMM')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'IMPASSE','IMP')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'COLONEL','COL')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'LIEUTENANT','LT')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'LOTISSEMENT','LOT')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'LOTI','LOT')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'MADAME','MME')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'MARECHAL','MAL')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'MONSIEUR','M')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'MR','M')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'PRESIDENT','PDT')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'PLACE','PL')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'RESIDENCE','RES')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'ROUTE','RTE')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'RUE','R')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'SQUARE','SQ')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'ZONE INDUSTRIELLE','ZI')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'ZONE ARTISANALE','ZA')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'ZONE COMMERCIALE','ZC')
	set @Adresse = REPLACE(@Adresse collate sql_latin1_General_Cp1_CI_AI,'ZONE D''ACTIVITE','ZAC')


	RETURN @Adresse
END
GO
/****** Object:  Table [ref].[CodesTel]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [ref].[CodesTel](
	[CDPAYS] [varchar](50) NULL,
	[CDTEL] [numeric](18, 0) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [ref].[CIVILITE]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ref].[CIVILITE](
	[ID] [int] NOT NULL,
	[SHORTLIB] [nvarchar](20) NOT NULL,
	[LONGLIB] [nvarchar](128) NOT NULL,
	[SEXE] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [etl].[CHARSWAP]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [etl].[CHARSWAP](
	[NOK] [nvarchar](32) NULL,
	[OK] [nvarchar](32) NULL,
	[FIELD] [nvarchar](32) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UTFFull]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UTFFull](
	[Char] [nvarchar](255) NULL,
	[Hex] [nvarchar](255) NULL,
	[NCR] [nvarchar](255) NULL,
	[Description ] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Unicode3]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Unicode3](
	[Column 0] [nvarchar](5) NULL,
	[Column 1] [nvarchar](8) NULL,
	[Column 2] [nvarchar](10) NULL,
	[Column 3] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Unicode1]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Unicode1](
	[Column 0] [nvarchar](1) NULL,
	[Column 1] [nvarchar](13) NULL,
	[Column 2] [nvarchar](7) NULL,
	[Column 3] [nvarchar](255) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Unicode]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Unicode](
	[Caractere] [varchar](1) NULL,
	[Column 1] [varchar](12) NULL,
	[CodeISO] [varchar](12) NULL,
	[Column 3] [varchar](50) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [etl].[UCToNChar]    Script Date: 04/01/2015 16:59:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [etl].[UCToNChar]
(
	@LaChaine nvarchar (max)
)
RETURNS nvarchar(max)
AS
BEGIN
	declare @WkChaine nvarchar(max)
	declare @debcode bigint;
	declare @fincode bigint;
	declare @cunic nvarchar(max);

	set @WkChaine = @LaChaine;

	set @debcode = CHARINDEX('&#', @WkChaine)

	WHILE @debcode <> 0
	BEGIN
		set @fincode = CHARINDEX(';', @WkChaine, @debcode)
		if @fincode = 0 
		begin
			set @WkChaine = LEFT(@WkChaine, @debcode-1) + RIGHT(@WkChaine, case when LEN(@WkChaine)-2-@debcode >= 0 then LEN(@WkChaine)-2-@debcode else 0 end);
			return @WkChaine
		end
		else
		begin
			set @cunic = SUBSTRING(@WkChaine, @debcode+2, @fincode-@debcode-2)
			if ISNUMERIC(@cunic) = 1 
				set @WkChaine = LEFT(@WkChaine, @debcode-1) + NCHAR(CAST(@cunic as int)) + RIGHT(@WkChaine, LEN(@WkChaine)-@fincode)
			else
				set @WkChaine = LEFT(@WkChaine, @debcode-1) + RIGHT(@WkChaine, LEN(@WkChaine)-1-@debcode);
		end
		set @debcode = CHARINDEX('&#', @WkChaine)
	END

	return @WkChaine;
	
END
GO
/****** Object:  StoredProcedure [etl].[TrimColonnes]    Script Date: 04/01/2015 16:59:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [etl].[TrimColonnes] (
	@database NVARCHAR(50),
	@schema NVARCHAR(20), 
	@tablename NVARCHAR(32),
	@whereClause NVARCHAR(250) = null
) 
	-- Add the parameters for the stored procedure here
AS
BEGIN

DECLARE @ColName NVARCHAR(32);
DECLARE @cmd NVARCHAR(255);

IF @whereClause IS NOT NULL AND CHARINDEX(@whereClause, 'AND') = 0
BEGIN
	SET @whereClause = 'AND ' + @whereClause
END
ELSE
	SET @whereClause = ''


DECLARE colcursor CURSOR FOR 
SELECT C.name FROM sys.columns C 
INNER JOIN sys.tables T on C.object_id = T.object_id
INNER JOIN sys.schemas S on T.schema_id = S.schema_id
WHERE T.name = @tablename AND S.name = @schema AND C.system_type_id IN (167, 231)

OPEN colcursor 

	FETCH NEXT FROM colcursor INTO 	
		@ColName

	WHILE (@@fetch_status <> -1) BEGIN
		IF (@@fetch_status <> -2) BEGIN
			SET @cmd = 'UPDATE ['+ @database +'].[' + @schema + '].[' + @tablename + '] set [' + @ColName + '] = RTRIM([' + @ColName + ']) WHERE FichierTS IS NULL ' + @whereClause
			EXECUTE sp_executesql  @cmd
		END
	FETCH NEXT FROM colcursor INTO 	
		@ColName
	END

	CLOSE colcursor
	DEALLOCATE colcursor


END
GO
/****** Object:  Table [ref].[TelStatus]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ref].[TelStatus](
	[CodeVal] [int] NOT NULL,
	[Valeur] [nvarchar](80) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[StatsRNVP]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StatsRNVP](
	[Client] [nvarchar](50) NOT NULL,
	[RNVPDate] [datetime] NULL,
	[Quantite] [int] NULL,
	[Iris] [int] NULL,
	[Presta] [nvarchar](50) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [ref].[SEXE]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ref].[SEXE](
	[IDSEXE] [int] NULL,
	[LIBELLE] [nvarchar](32) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [ref].[PRENOMSMIXTES]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [ref].[PRENOMSMIXTES](
	[prenom] [varchar](80) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [ref].[PRENOMS_SEXE]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [ref].[PRENOMS_SEXE](
	[PRENOM] [varchar](80) NULL,
	[SEXE] [numeric](18, 0) NULL,
	[EFFECTIF] [numeric](18, 0) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [ref].[PRENOMS]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [ref].[PRENOMS](
	[prenom] [varchar](80) NULL,
	[sexe] [numeric](18, 0) NULL,
	[Effectif] [numeric](18, 0) NULL,
	[AGE1829] [numeric](18, 0) NULL,
	[AGE3044] [numeric](18, 0) NULL,
	[AGE4559] [numeric](18, 0) NULL,
	[AGESUP60] [numeric](18, 0) NULL,
	[AGE0324] [numeric](18, 0) NULL,
	[AGE0315] [numeric](18, 0) NULL,
	[TAGE] [nchar](8) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [ref].[PostalStatus]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [ref].[PostalStatus](
	[Code] [nchar](2) NULL,
	[Libelle] [varchar](50) NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [ref].[Pays]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [ref].[Pays](
	[ISO-3166A2] [varchar](80) NULL,
	[ISO-3166A3] [varchar](3) NULL,
	[ISO-3166NUM] [smallint] NULL,
	[fips] [varchar](2) NULL,
	[Country] [varchar](80) NULL,
	[Capital] [varchar](80) NULL,
	[Area-km] [varchar](50) NULL,
	[Population] [varchar](13) NULL,
	[Continent] [varchar](2) NULL,
	[Pays] [varchar](80) NULL,
	[extension] [nvarchar](10) NULL,
	[indicatif] [int] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [ref].[OperateursMobiles]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ref].[OperateursMobiles](
	[PREFIXE] [nvarchar](10) NULL,
	[OPERATEUR] [nvarchar](255) NULL,
	[RESEAU] [nvarchar](255) NULL,
	[MVNO] [int] NULL,
	[CDPAYS] [nvarchar](3) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [ref].[MISC]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ref].[MISC](
	[VALEUR] [int] NOT NULL,
	[TYPE] [int] NOT NULL,
	[LIBELLE] [nvarchar](50) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [ref].[LANGUES]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ref].[LANGUES](
	[Id] [nchar](3) NOT NULL,
	[Part2B] [nchar](3) NULL,
	[Part2T] [nchar](3) NULL,
	[Part1] [nchar](2) NULL,
	[Scope] [nchar](1) NOT NULL,
	[Type] [nchar](1) NOT NULL,
	[Ref_Name] [nvarchar](150) NOT NULL,
	[Comment] [nvarchar](150) NULL
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [etl].[IsThatKindOfInt]    Script Date: 04/01/2015 16:59:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [etl].[IsThatKindOfInt]
(
	-- Add the parameters for the function here
	@Value nvarchar(320), @Type nvarchar(8)
)
RETURNS bit
AS
BEGIN
	declare @biValue bigint


	if ISNUMERIC(@value) = 0 
	begin
		return 0
	end
	
	if CHARINDEX('.', @value) > 0
	begin
		return 0
	end
	
	if CHARINDEX(',', @value) > 0
	begin
		return 0
	end

	if (LEN(@Value) > 0 and LEFT(@Value, 1) = '-')
	begin
		if LEN(@value) > 20 or (LEN(@Value) = 20 and @Value >  '-9223372036854775808')
		begin 
			return 0
		end
	end
	else -- Positifs
	begin
		if LEN(@value) > 19 or (LEN(@Value) = 19 and @Value >  '9223372036854775807')
		begin 
			return 0
		end
	end

	set @biValue = CAST (@Value as bigint)

	if @Type = 'bigint' and @biValue < cast (9223372036854775807 as bigint) and @biValue >= CAST (-9223372036854775808 as bigint)
	begin
		return 1
	end
	
	if @Type = 'int' and @biValue <= 2147483647 and @biValue >= -2147483648
	begin
		return 1
	end
	
	if @Type = 'smallint' and @biValue <= 32767 and @biValue >= -32768
	begin
		return 1
	end
	
	if @Type = 'tinyint' and @biValue <= 255 and @biValue >= 0
	begin
		return 1
	end
	
	return 0
END
GO
/****** Object:  UserDefinedFunction [etl].[IsMoney]    Script Date: 04/01/2015 16:59:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [etl].[IsMoney] 
(
   @chkCol varchar(512)
)
RETURNS bit
AS
BEGIN
 -- Declare the return variable here
 DECLARE @retVal bit


SET @chkCol = REPLACE(@chkCol, '.', ',');

SET @chkCol = REPLACE(@chkCol, '€', '');
SET @chkCol = REPLACE(@chkCol, '$', '');
SET @chkCol = REPLACE(@chkCol, ',', '');

SET @retVal = ISNUMERIC (@chkCol)

RETURN @retVal

END
GO
/****** Object:  UserDefinedFunction [etl].[IsGuid]    Script Date: 04/01/2015 16:59:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Delphine Bouloy>
-- Create date: <11/04/2013>
-- Description:	<Permet de savoir si une chaine de caractère peut être castée en guid>
-- =============================================
CREATE FUNCTION [etl].[IsGuid] 
(
@Value nvarchar(320)
)
RETURNS bit
AS
BEGIN
	
	if  @Value like REPLACE('00000000-0000-0000-0000-000000000000', '0', '[0-9a-fA-F]')
	begin
		return 1
	end

	else
	begin
		return 0
	end

	return 0
END
GO
/****** Object:  StoredProcedure [dbo].[InsertOrUpdate_STEP]    Script Date: 04/01/2015 16:59:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InsertOrUpdate_STEP]
	@processcode nvarchar(50)
	,@STEPID int
	,@STEPNAME nvarchar(80)
	,@STEPTYPE int
	,@STEPCOMMAND nvarchar(255)
	,@STEPTIMEOUT int
	,@STEPUSAGE int
    ,@STEPASSEMBLY nvarchar(200)
    ,@STEPTYPENAME nvarchar(200)
    ,@STEPENABLED bit
    ,@STEPCONTEXT XML
    ,@STEPBOUCLEID int
    ,@SOURCEEXPORT int
	,@STEPIDTEMOIN INT = -1
AS
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @ProcessStep int

	DECLARE @delta int = 1
	if @STEPIDTEMOIN > -1
	SET @delta = CASE WHEN @STEPID = @STEPIDTEMOIN THEN 0 ELSE 1 END
	print 'DELTA='+ cast(@delta as NVARCHAR(10))
				
	-- if stepidtemoin = -1 we are adding new row
	-- we need to break condition for found process step
	select @ProcessStep = stepid from process_steps 
	where processcode = @processcode and stepid =  case when @delta < 0 then  @STEPIDTEMOIN when  @STEPIDTEMOIN = -1 then -1 else @stepid end

	print 'PROCESSSTEP=' + cast(@processstep as NVARCHAR(255))

	-- shifting stepids excluding stepidtemoin
	UPDATE [dbo].[PROCESS_STEPS] SET STEPID = STEPID + @delta 
	WHERE STEPID >= @STEPID AND STEPID != @STEPIDTEMOIN 
	AND PROCESSCODE = @processcode

	-- update record
	IF @ProcessStep > 0
	BEGIN
		-- updating record ID
		UPDATE process_steps SET
					[STEPID] = @stepId
		WHERE processCode = @processCode 
		AND stepid= case when @delta = 0 then @stepid else @STEPIDTEMOIN end
		AND [STEPNAME] = @STEPNAME

		print 'UPDATED STEPID=' + CAST(case when @delta = 0 then @stepid else @STEPIDTEMOIN end AS NVARCHAR(255)) +' WITH STEPID='+ CAST(@stepid AS NVARCHAR(255))

		-- updating record info
		UPDATE process_steps SET
					[STEPID] = @stepId
					,[STEPNAME] = @STEPNAME
					,[STEPTYPE] = @STEPTYPE
					,[STEPCOMMAND] = @STEPCOMMAND
					,[STEPTIMEOUT] = @STEPTIMEOUT
					,[STEPUSAGE] = @STEPUSAGE
					,[STEPASSEMBLY] = @STEPASSEMBLY
					,[STEPTYPENAME] = @STEPTYPENAME
					,[STEPENABLED] = @STEPENABLED
					,[STEPCONTEXT] = @STEPCONTEXT
					,[STEPBOUCLEID] = @STEPBOUCLEID
					,[SOURCEEXPORT] = @SOURCEEXPORT 
		WHERE processCode = @processCode AND stepid= @stepid 
		print 'UPDATED FIELDS WHERE STEPID =' + CAST(@stepid AS NVARCHAR(255))
	END
	ELSE
	BEGIN
		INSERT INTO dbo.process_steps ([PROCESSCODE]
						,[STEPID] 
						,[STEPNAME] 
						,[STEPTYPE]
						,[STEPCOMMAND] 
						,[STEPTIMEOUT]
						,[STEPUSAGE] 
						,[STEPASSEMBLY]
						,[STEPTYPENAME]
						,[STEPENABLED] 
						,[STEPCONTEXT] 
						,[STEPBOUCLEID]
						,[SOURCEEXPORT]) 
		VALUES(  @processcode
				,@stepId
				, @STEPNAME
				,@STEPTYPE
				,@STEPCOMMAND
				,@STEPTIMEOUT
				,@STEPUSAGE
				,@STEPASSEMBLY
				,@STEPTYPENAME
				,@STEPENABLED
				,@STEPCONTEXT
				,@STEPBOUCLEID
				,@SOURCEEXPORT )
	END
END
GO
/****** Object:  Table [dbo].[InseePop]    Script Date: 04/01/2015 16:59:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[InseePop](
	[IdRegion] [char](2) NOT NULL,
	[NomRegion] [nvarchar](50) NULL,
	[Dep] [char](3) NOT NULL,
	[Arrondissement] [char](2) NOT NULL,
	[Canton] [char](2) NOT NULL,
	[Commune] [char](3) NOT NULL,
	[Nom] [nvarchar](50) NULL,
	[PopMunicipal] [varchar](7) NULL,
	[PopAddons] [varchar](7) NULL,
	[PopTotale] [varchar](7) NULL,
	[rien] [nchar](10) NULL,
	[Insee] [varchar](6) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  StoredProcedure [etl].[getEmailStringRemplacementList]    Script Date: 04/01/2015 16:59:40 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  PROCEDURE [etl].[getEmailStringRemplacementList]                                                                                                                                                                                                         

AS
/***************************************************************************                                                                                                                                                                      
* Auteur : Philippe TOULEMONT                                                                                                                                                                                                                       
* Creation : 01/02/2005                                                                                                                                                                                                                           
* Modif :                                                                                                                                                                                                                               
*                                                                                                                                                                                                                                                 
*                                                                                                                                                                                                                                                 
* Description : Liste les substitution de chaînes dans l'email
*                                                                                                                                                                                                                                                 
***************************************************************************/                                                                                                                                                                      
SET NOCOUNT ON

SELECT ID, AREMPLACER, REMPLACEMENT FROM EMAILSTRINGREMPLACEMENTS
GO
/****** Object:  StoredProcedure [etl].[getEmailDomaineRemplacementList]    Script Date: 04/01/2015 16:59:40 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  PROCEDURE [etl].[getEmailDomaineRemplacementList]                                                                                                                                                                                                         

AS
/***************************************************************************                                                                                                                                                                      
* Auteur : Philippe TOULEMONT                                                                                                                                                                                                                       
* Creation : 01/02/2005                                                                                                                                                                                                                           
* Modif :                                                                                                                                                                                                                               
*                                                                                                                                                                                                                                                 
*                                                                                                                                                                                                                                                 
* Description : Liste les substitution de domaine dans l'email
*                                                                                                                                                                                                                                                 
***************************************************************************/                                                                                                                                                                      
SET NOCOUNT ON

SELECT ID, AREMPLACER, REMPLACEMENT FROM EMAILDOMAINEREMPLACEMENTS
GO
