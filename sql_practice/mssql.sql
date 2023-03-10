-- Homework-3
--Vamsee Narahari

-- Bonus Query-1

-- Create the table
CREATE TABLE #TableValues(ID INT, Data INT);

-- Populate the table
INSERT INTO #TableValues(ID, Data)
VALUES(1,100),(2,100),(3,NULL),
(4,NULL),(5,600),(6,NULL),
(7,500),(8,1000),(9,1300),
(10,1200),(11,NULL);

SELECT 
    DISTINCT
    A.ID
    ,CASE 
        WHEN A.DATA IS NULL 
        THEN LAST_VALUE(B.DATA) OVER(PARTITION BY A.ID ORDER BY B.ID ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
        ELSE A.DATA
    END AS NEW_DATA
FROM 
    #TABLEVALUES A
LEFT JOIN   
    #TABLEVALUES B 
ON
    A.ID > B.ID
AND     
    A.DATA IS NULL
AND B.DATA IS NOT NULL;

-- BONUS QUERY-2
-- Create the temp table
CREATE TABLE #Registrations(ID INT NOT NULL IDENTITY PRIMARY KEY,
	DateJoined DATE NOT NULL, DateLeft DATE NULL);

-- Variables
DECLARE @Rows INT = 10000, 
		@Years INT = 5, 
		@StartDate DATE = '2011-01-01'

-- Insert 10,000 rows with five years of possible dates
INSERT INTO #Registrations (DateJoined)
	SELECT TOP(@Rows) DATEADD(DAY,CAST(RAND(CHECKSUM(NEWID())) * @Years *
			365 as INT) ,@StartDate)
	FROM sys.objects a
		CROSS JOIN sys.objects b
		CROSS JOIN sys.objects c;

-- Give cancellation dates to 75% of the subscribers
UPDATE TOP(75) PERCENT #Registrations
	SET DateLeft = DATEADD(DAY,CAST(RAND(CHECKSUM(NEWID())) * @Years * 365
		as INT),DateJoined);


    
WITH CTE_SUB AS 
(
SELECT  
    EOMONTH(DATEJOINED) AS END_OF_MONTH
    ,COUNT(ID) AS SUB
FROM    
    #Registrations
GROUP BY
    EOMONTH(DATEJOINED)
)
,CTE_UNSUB AS 
(
SELECT  
    EOMONTH(DATELEFT) AS END_OF_MONTH
    ,COUNT(ID) AS UNSUB
FROM    
    #Registrations
GROUP BY
    EOMONTH(DATELEFT)   
)
,CTE_UNION_DATES AS 
(
SELECT
    END_OF_MONTH
FROM 
    CTE_SUB
UNION 
SELECT 
    END_OF_MONTH 
FROM 
    CTE_UNSUB
)

SELECT  
    CTE_UNION_DATES.END_OF_MONTH
    ,COALESCE(SUB,0) AS NUMBER_SUBSCRIBED
    ,COALESCE(UNSUB,0) AS NUMBER_UNSUBSCRIBED
    ,COALESCE(SUM(COALESCE(SUB,0)) OVER(ORDER BY CTE_UNION_DATES.END_OF_MONTH) - SUM(COALESCE(UNSUB,0)) OVER(ORDER BY CTE_UNION_DATES.END_OF_MONTH),SUB) AS ACTIVE_SUB
FROM 
    CTE_UNION_DATES
LEFT JOIN 
    CTE_SUB
ON
    CTE_SUB.END_OF_MONTH = CTE_UNION_DATES.END_OF_MONTH
LEFT JOIN 
    CTE_UNSUB
ON
    CTE_UNSUB.END_OF_MONTH = CTE_UNION_DATES.END_OF_MONTH
ORDER BY 
    CTE_UNION_DATES.END_OF_MONTH;




-- BONUS QUERY-3
DROP TABLE IF EXISTS #TimeCards;

CREATE TABLE #TimeCards(
	TimeStampID INT NOT NULL IDENTITY PRIMARY KEY,
	EmployeeID INT NOT NULL,
	ClockDateTime DATETIME2(0) NOT NULL,
	EventType VARCHAR(5) NOT NULL);

-- Populate the table
INSERT INTO #TimeCards(EmployeeID,
	ClockDateTime, EventType)
VALUES
	(1,'2021-01-02 08:00','ENTER'),
	(2,'2021-01-02 08:03','ENTER'),
	(2,'2021-01-02 12:00','EXIT'),
	(2,'2021-01-02 12:34','ENTER'),
	(3,'2021-01-02 16:30','ENTER'),
	(2,'2021-01-02 16:00','EXIT'),
	(1,'2021-01-02 16:07','EXIT'),
	(3,'2021-01-03 01:00','EXIT'),
	(2,'2021-01-03 08:10','ENTER'),
	(1,'2021-01-03 08:15','ENTER'),
	(2,'2021-01-03 12:17','EXIT'),
	(3,'2021-01-03 16:00','ENTER'),
	(1,'2021-01-03 15:59','EXIT'),
	(3,'2021-01-04 01:00','EXIT');

WITH CTE AS 
(
SELECT  
    *
    ,DATEDIFF(SECOND,CLOCKDATETIME,LEAD(CLOCKDATETIME) OVER(PARTITION BY EMPLOYEEID ORDER BY CLOCKDATETIME)) AS DIFF_SEC
FROM    
    #TIMECARDS
)
,CTE_2 AS
(
SELECT
    EMPLOYEEID
    ,CONVERT(DATE,CLOCKDATETIME) AS WORK_DATE
    ,SUM(DIFF_SEC) AS TOTAL_SEC
FROM 
    CTE
WHERE
    EVENTTYPE='ENTER'
GROUP BY
    EMPLOYEEID
   ,CONVERT(DATE,CLOCKDATETIME)
   
)
,CTE_3 AS 
(
SELECT
    *
    ,TOTAL_SEC % 3600 AS REM_MINS
    ,TOTAL_SEC % (3600*24) AS REM_HOURS
FROM
    CTE_2
)
SELECT
    WORK_DATE
    ,EMPLOYEEID
    ,CONCAT(
            FORMAT(FLOOR(REM_HOURS / 3600),'00'), ':',
            FORMAT(FLOOR(REM_MINS / 60),'00'), ':',
            '00'
            ) AS difference
FROM 
    CTE_3;



-- BONUS QUERY-4
DROP TABLE IF EXISTS #FolderHierarchy;
GO

---------------------
---------------------
CREATE TABLE #FolderHierarchy
(
ID			INTEGER PRIMARY KEY,
Name		VARCHAR(100),
ParentID	INTEGER
);
GO

---------------------
---------------------
INSERT INTO #FolderHierarchy VALUES
(1, 'my_folder', NULL),
(2,	'my_documents', 1),
(3, 'events', 2),
(4, 'meetings', 3),
(5, 'conferences', 3),
(6, 'travel', 3),
(7, 'integration', 3),
(8, 'out_of_town', 4),
(9, 'abroad', 8),
(10, 'in_town', 4);
GO

WITH CTE AS 
(
SELECT 
    ID 
    ,NAME
    ,PARENTID
    ,CAST('/my_folder' as varchar(200)) AS path 
FROM
    #FOLDERHIERARCHY
WHERE
    PARENTID IS NULL
UNION ALL
SELECT 
    FOLDER.ID 
    ,FOLDER.NAME
    ,FOLDER.PARENTID
    ,CAST(CONCAT_WS('/', CTE.PATH, FOLDER.NAME) as Varchar(200)) AS path
FROM
    #FOLDERHIERARCHY FOLDER
INNER JOIN
    CTE 
ON 
    FOLDER.PARENTID = CTE.ID
)
SELECT
    *
FROM 
    CTE;

-- BONUS QUERY-5
DROP TABLE IF EXISTS #Destination;
GO

---------------------
CREATE TABLE #Destination
(
ID			INTEGER PRIMARY KEY,
Name		VARCHAR(100)
);
GO

---------------------
INSERT INTO #Destination VALUES
(1, 'Warsaw'),
(2,	'Berlin'),
(3, 'Bucharest'),
(4, 'Prague');
GO

DROP TABLE IF EXISTS #Ticket;
GO

---------------------
CREATE TABLE #Ticket
(
CityFrom	INTEGER,
CityTo		INTEGER,
Cost		INTEGER
);
GO

---------------------
INSERT INTO #Ticket VALUES
(1, 2, 350),
(1, 3, 80),
(1, 4, 220),
(2, 3, 410),
(2, 4, 230),
(3, 2, 160),
(3, 4, 110),
(4, 2, 140),
(4, 3, 75);
GO

WITH CTE_JOIN AS 
(
SELECT 
    #TICKET.*
    ,CITYFROM.NAME AS FROM_CITY
    ,CITYTO.NAME AS TO_CITY
FROM 
    #TICKET 
INNER JOIN 
    #DESTINATION CITYFROM
ON 
    #TICKET.CITYFROM = CITYFROM.ID
INNER JOIN 
    #DESTINATION CITYTO
ON 
    #TICKET.CITYTO = CITYTO.ID
)
,CTE_RECUR AS 
(
SELECT
    CITYFROM 
    ,CITYTO
    ,CAST(CONCAT_WS('->',FROM_CITY,TO_CITY) AS VARCHAR(200)) AS PATH
    ,COST
    ,2 AS VISITED
FROM 
    CTE_JOIN
WHERE
    CITYFROM = 1
UNION ALL
SELECT
    CTE_JOIN.CITYFROM 
    ,CTE_JOIN.CITYTO
    ,CAST(CONCAT_WS('->',CTE_RECUR.PATH,CTE_JOIN.TO_CITY) AS VARCHAR(200)) AS PATH
    ,CTE_JOIN.COST + CTE_RECUR.COST
    ,CTE_RECUR.VISITED + 1
FROM 
    CTE_JOIN 
INNER JOIN 
    CTE_RECUR
ON 
    CTE_JOIN.CITYFROM = CTE_RECUR.CITYTO
WHERE 
    CTE_RECUR.PATH NOT LIKE '%' + CTE_JOIN.TO_CITY +'%' 
)
SELECT 
    *
FROM 
    CTE_RECUR
WHERE
    VISITED = 4;


