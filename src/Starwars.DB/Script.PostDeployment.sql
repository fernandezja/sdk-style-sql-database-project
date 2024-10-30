-- This file contains SQL statements that will be executed after the build script.

--Populate table
INSERT INTO dbo.Jedi
([Name], [DateBirth])
SELECT TOP 5000 
	[name] = CONCAT('Jedi ', TEMP.[name]),
	[DateB] = DATEADD(YEAR, TEMP.column_id * -1, GETDATE())
FROM 
	(SELECT 
		c1.[name],
		c1.column_id
	FROM sys.all_columns c1
	WHERE 
		LEN(c1.[name]) > 4) AS TEMP
