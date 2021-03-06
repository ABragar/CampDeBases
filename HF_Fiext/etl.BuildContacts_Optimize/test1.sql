USE AmauryVUC

SET STATISTICS TIME  ON
GO
--(19302 row(s) affected)
--current(52%) 530 ms 483 ms.497 ms.

select distinct masterid from brut.Contacts where MasterID not in (select MasterID from dbo.Contacts where MasterID is not null)									 
GO

--v1(24%) 223 ms.  188 ms. 187 ms.
SELECT DISTINCT c.masterid from brut.Contacts c LEFT JOIN dbo.Contacts dc ON c.MasterID = dc.MasterID WHERE c.MasterID IS NOT NULL AND dc.MasterID IS NULL
GO

--v2(24%) 249 ms  197 ms. 180 ms.
select distinct masterid from brut.Contacts bc where MasterID IS NOT NULL AND not exists (select MasterID from dbo.Contacts where MasterID = bc.MasterID)
Go

