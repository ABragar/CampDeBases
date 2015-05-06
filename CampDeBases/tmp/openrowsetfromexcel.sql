SELECT * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
'Excel 12.0;Database=D:\Projects\Camp de bases\Projects\PVL\data\AchatsALActe_Neolane.xlsx', 'SELECT * FROM [Feuil1$]')

SELECT * into #t FROM OPENROWSET('Microsoft.Jet.OLEDB.4.0', 'Excel 12.0;Database=D:\Projects\Camp de bases\Projects\PVL\data\AchatsALActe_Neolane.xlsx','select * from [Feuil1$]')

Select * INTO #g FROM OPENROWSET('Microsoft.Jet.OLEDB.4.0', 
'Excel 12.0;Database=D:\Projects\Camp de bases\SessionsPremium_15000_2.xls ;HDR=YES', 'SELECT * FROM [Feuil1$]');


--ADD LINKED SRERVER
--EXEC master.dbo.sp_addlinkedserver @server = N'excelxx', @srvproduct=N'Excel', @provider=N'Microsoft.ACE.OLEDB.12.0', @datasrc=N'D:\Projects\Camp de bases\Projects\PVL\data\AchatsALActe_Neolane.xlsx', @provstr=N'Excel 15.0'


--sp_configure 'show advanced options', 1;
--GO
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--GO
--RECONFIGURE;
--GO

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1
--GO
--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1
--GO