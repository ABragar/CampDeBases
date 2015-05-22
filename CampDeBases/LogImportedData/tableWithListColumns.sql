
SELECT Table_Name
      ,(
           SELECT Column_name + ','
           FROM   information_schema.columns t2
           WHERE  TABLE_SCHEMA = N'import'
                  AND COLUMN_NAME IN ('RejetCode' ,'FichierTS' ,'ActionID' ,'TIMESTAMP')
                  AND t1.Table_Name = t2.Table_Name FOR XML PATH('')
      ) AS Fields
FROM   information_schema.columns t1
WHERE  TABLE_SCHEMA = N'import'
       AND COLUMN_NAME IN ('RejetCode' ,'FichierTS' ,'ActionID' ,'TIMESTAMP')
GROUP BY
       Table_Name
ORDER BY Fields
