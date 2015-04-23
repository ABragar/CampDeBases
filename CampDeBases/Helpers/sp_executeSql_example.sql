exec sp_executesql
    @statement = N'select * from sys.databases where name = @dbname or database_id = @dbid',
    @parameters = N'@dbname sysname, @dbid int',
    @dbname = N'master',
    @dbid = 1