USE TALENTDB
GO
IF EXISTS (SELECT 1 FROM SYS.PROCEDURES WHERE NAME = 'UNION_3_UNPIVOT_TABLES') DROP PROC UNION_3_UNPIVOT_TABLES
CREATE PROC UNION_3_UNPIVOT_TABLES (@TABLE_NAME1 NVARCHAR(MAX), @TABLE_NAME2 NVARCHAR(MAX), @TABLE_NAME3 NVARCHAR(MAX))
AS 
BEGIN

	IF EXISTS (SELECT 1 FROM SYS.TABLES WHERE NAME = 'SALES') DROP TABLE SALES
	CREATE TABLE SALES (
	[PRODUCT NAME] NVARCHAR(MAX), [LATITUDE] FLOAT, [LONGITUDE] FLOAT, 
	[CUSTOMER ID] NVARCHAR(MAX), [POST CODE] NVARCHAR(MAX), 
	SALES_DATE DATE, SALES_AMOUNT FLOAT)
	IF EXISTS (SELECT 1 FROM SYS.TABLES WHERE NAME = 'ERRORS_LOG') DROP TABLE ERRORS_LOG
	CREATE TABLE ERRORS_LOG (
	[PRODUCT NAME] NVARCHAR(MAX), [LATITUDE] FLOAT, [LONGITUDE] FLOAT, 
	[CUSTOMER ID] NVARCHAR(MAX), [POST CODE] NVARCHAR(MAX), 
	SALES_DATE DATE, SALES_AMOUNT FLOAT)
	DECLARE @BANG TABLE (NAME NVARCHAR(MAX))
	INSERT INTO @BANG VALUES (@TABLE_NAME1)
	INSERT INTO @BANG VALUES (@TABLE_NAME2)
	INSERT INTO @BANG VALUES (@TABLE_NAME3) 
	DECLARE CUR CURSOR FOR
				 SELECT * FROM @BANG
	OPEN CUR
	DECLARE @TABLE_NAME NVARCHAR(MAX)
	FETCH NEXT FROM CUR INTO @TABLE_NAME
	WHILE @@FETCH_STATUS = 0
	BEGIN
		DECLARE @YEAR NVARCHAR(MAX) = RIGHT(@TABLE_NAME, 4)
		DECLARE @COLUMNS AS NVARCHAR(MAX);
		DECLARE @SQL AS NVARCHAR(MAX);
		SET @COLUMNS = (SELECT STRING_AGG(QUOTENAME(COLUMN_NAME), ',') 
						FROM INFORMATION_SCHEMA.COLUMNS
						WHERE TABLE_NAME = @TABLE_NAME
							AND COLUMN_NAME <> 'PRODUCT NAME' 
							AND COLUMN_NAME <> 'LATITUDE'
							AND COLUMN_NAME <> 'LONGITUDE'
							AND COLUMN_NAME <> 'CUSTOMER ID'
							AND COLUMN_NAME <> 'POST CODE')
		SET @SQL = '
					INSERT INTO SALES
					SELECT [PRODUCT NAME]
						, LATITUDE
						, LONGITUDE
						, [CUSTOMER ID]
						, [POST CODE]
						, ''1-'' + LEFT(UNP.DATE, 3) + ''-'' + CONVERT(NVARCHAR(MAX),'+@YEAR+') AS [DATE]
						, [REVENUE]
					FROM '+@TABLE_NAME+'
					UNPIVOT
					(
						REVENUE
						FOR DATE IN(' + @COLUMNS + ')
					) AS UNP
			
					INSERT INTO ERRORS_LOG
					SELECT * FROM SALES WHERE [POST CODE] = ''0''
					DELETE FROM SALES WHERE [POST CODE] = ''0''
					

				  '
				 -- PRINT @SQL
		EXECUTE(@SQL)
		FETCH NEXT FROM CUR INTO @TABLE_NAME
	END
	CLOSE CUR
	DEALLOCATE CUR
END
EXEC UNION_3_UNPIVOT_TABLES 'IMP_SALES_2013', 'IMP_SALES_2014', 'IMP_SALES_2015'
SELECT COUNT(*) FROM SALES
SELECT COUNT(*) FROM IMP_SALES_2013
SELECT COUNT(*) FROM IMP_SALES_2014 
SELECT COUNT(*) FROM IMP_SALES_2015 
SELECT * FROM SALES WHERE [POST CODE] = '0'
SELECT * FROM ERRORS_LOG
SELECT (SELECT COUNT(*) FROM SALES) + (SELECT COUNT(*) FROM ERRORS_LOG)


-------------
IF EXISTS (SELECT 1 FROM SYS.PROCEDURES WHERE NAME = 'PR_REPORT_MASTER') DROP PROC PR_REPORT_MASTER
CREATE PROC PR_REPORT_MASTER (@START_DATE DATE, @END_DATE DATE)
AS
BEGIN
-- 1
	
	SELECT  FORMAT(SUM(SALES_AMOUNT), '#,###.##') AS TOTAL_SALES
	FROM SALES
	WHERE SALES_DATE >= @START_DATE AND SALES_DATE <= @END_DATE
-- 2

	SELECT TOP 3
			A.[PRODUCT NAME] AS [BEST-SALE PRODUCT NAME]
			, FORMAT(SUM(A.SALES_AMOUNT), '#,###.##') AS TOTAL_SALES
	FROM (
		SELECT *
		FROM SALES
		WHERE SALES_DATE >= @START_DATE AND SALES_DATE <= @END_DATE) AS A
	GROUP BY [PRODUCT NAME]
	ORDER BY SUM(A.SALES_AMOUNT) DESC

-- 3

	SELECT TOP 5
			[CUSTOMER ID] AS [BEST_BUY CUSTOMER]
			, FORMAT(SUM(A.SALES_AMOUNT), '#,###.##') AS TOTAL_PURCHASING
	FROM (
			SELECT *
			FROM SALES
			WHERE SALES_DATE >= @START_DATE AND SALES_DATE <= @END_DATE) AS A
	GROUP BY [CUSTOMER ID]
	ORDER BY SUM(SALES_AMOUNT) DESC

END

EXEC PR_REPORT_MASTER '2013-01-01', '2014-01-01'