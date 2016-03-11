USE [AmauryVUC]
GO
/****** Object:  StoredProcedure [import].[TrimColonnes]    Script Date: 17.10.2015 13:07:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [import].[TrimColonnes] (@schema nvarchar(20), @tablename nvarchar(32)) 
	-- Add the parameters for the stored procedure here
AS
BEGIN

set nocount on


declare @ColName nvarchar(64);
declare @cmd nvarchar(255);

declare colcursor cursor for 
select C.name from sys.columns C 
inner join sys.tables T on C.object_id = T.object_id
inner join sys.schemas S on T.schema_id = S.schema_id
where T.name = @tablename and S.name = @schema and C.system_type_id in (167, 231)

open colcursor 

	fetch next from colcursor into 	
		@ColName

	while (@@fetch_status <> -1) begin
		if (@@fetch_status <> -2) begin
			set @cmd = 'UPDATE [' + @schema + '].[' + @tablename + '] set [' + @ColName + '] = RTRIM([' + @ColName + '])'
			execute sp_executesql  @cmd
		end
	fetch next from colcursor into 	
		@ColName
	end

	close colcursor
	deallocate colcursor


END
