 SELECT COUNT(*) FROM
 dbo.Typologie AS t
 LEFT JOIN
 etl.ChangementTypologieKeySet AS ctks ON t.MasterID = ctks.MasterID AND t.MarqueID = ctks.MarqueID
 WHERE ctks.ChangementId IS NULL
 -- must be 0 