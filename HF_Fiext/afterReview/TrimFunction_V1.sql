CREATE FUNCTION etl.TRIM(@string NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
BEGIN
RETURN LTRIM(RTRIM(@string))
END
GO
-- мы работаем только с типом NVARCHAR, так как у нас данные в Юникоде

