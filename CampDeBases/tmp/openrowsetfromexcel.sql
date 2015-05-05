SELECT * FROM OPENROWSET('Microsoft.Jet.OLEDB.4.0',
'Excel 12.0;Database=D:\Projects\Camp de bases\SessionsPremium_15000_2.xls', 'SELECT * FROM [Feuil1$]')

SELECT * into #t FROM OPENROWSET('Microsoft.Jet.OLEDB.4.0', 'Excel 12.0;Database=D:\Projects\Camp de bases\SessionsPremium_15000_2.xls','select * from [Feuil1$]')

Select * INTO #g FROM OPENROWSET('Microsoft.Jet.OLEDB.4.0', 
'Excel 12.0;Database=D:\Projects\Camp de bases\SessionsPremium_15000_2.xls ;HDR=YES', 'SELECT * FROM [Feuil1$]');