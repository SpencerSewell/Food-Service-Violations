/* Table Creation */
CREATE TABLE food_service_inspection_violations (
    Inspection_ID INT,
    Item VARCHAR(255),
    Type VARCHAR(255),
    Facility VARCHAR(255),
    Address VARCHAR(255),
    City VARCHAR(255),
    State CHAR(2),
    Zipcode INT,
    Date DATE,
    Permit_Number VARCHAR(255),
    Score INT,
	Grade CHAR(1),
	Purpose VARCHAR(255),
	Risk_Type INT,
	Last_Score INT,
	Last_Grade CHAR(1),
	Last_Date DATE,
	Prior_Score INT,
	Prior_Grade CHAR(1),
	Prior_Date DATE,
    Follow_Up_Needed BOOLEAN,
    Follow_Up_Date DATE,
    Foodborne_Illness_Risk BOOLEAN,
    Date_Time_In TIMESTAMP,
    Date_Time_Out TIMESTAMP
);

/*Data Cleaning*/

/*Check for nulls*/
SELECT *
FROM fsiv
WHERE inspection_id IS NULL

/* Checking for Duplicate Entries. Gives each duplicate a unique number with ROW_NUMBER(). To get duplicates, we simply take all ROW_NUMBER()>1 */
SELECT *
FROM (
    SELECT a.*, 
           ROW_NUMBER() OVER (PARTITION BY a.inspection_id, a.item, a.date ORDER BY a.inspection_id, a.item, a.date) AS row_num
    FROM fsiv a
    JOIN (
        SELECT inspection_id, item, date
        FROM fsiv
        GROUP BY inspection_id, item, date
        HAVING COUNT(*) > 1
    ) b ON a.inspection_id = b.inspection_id 
         AND a.item = b.item 
         AND a.date = b.date
) AS subquery
WHERE subquery.row_num > 1
ORDER BY subquery.inspection_id, subquery.item, subquery.date;

/* Data cleaned. Questions to ask:
	Which City Has the Highest number of infractions?
	Which Restaurant has the highest number of infractions?
	Which Restaurant has the highest number of level 3 infractions?
	Can we count level 3, 2, and 1 infractions?
	What kinds of trends can we see year by year, do the infractions get better or worse? 
	Did COVID (2019-2020) have any affect on infractions/type of infractions*/

/* Number of Violations by City */
SELECT COUNT(city), city
FROM fsiv
GROUP BY city
ORDER BY COUNT(city) DESC
LIMIT(10)

/* Number of violations by year*/
SELECT EXTRACT(YEAR FROM date), COUNT(1) 
FROM fsiv
GROUP BY EXTRACT(YEAR FROM date)
ORDER BY EXTRACT(YEAR FROM date) asc

/* Number of infractions by facility*/
SELECT facility, COUNT(facility)
FROM fsiv
GROUP BY facility 
ORDER BY COUNT(facility) desc
LIMIT(20)

/* Number of type of infraction*/
SELECT item as Infraction, COUNT(*) as Total 
FROM fsiv
GROUP BY item
ORDER BY COUNT(*) DESC
LIMIT (10)

/* Total violations by foodborne illness risk type: 1 - Low, 2 - Moderate, 3 - High */
SELECT risk_type, COUNT(*) 
FROM fsiv
GROUP BY risk_type
ORDER BY risk_type ASC

/*What is the average score of a facility including a particular item/risk-type combination? Help us judge the weight of violations*/
WITH DistinctInspectionScores AS (
    SELECT
        item,
        risk_type,
        facility,
        date,
        AVG(score) as AvgScore
    FROM fsiv
    GROUP BY item, risk_type, facility, date
)
SELECT 
    item,
    risk_type,
    ROUND(AVG(AvgScore), 2) as AverageScore,
    COUNT(*) as NumberOfInspectionsWithViolation
FROM DistinctInspectionScores
GROUP BY item, risk_type
HAVING COUNT(*) > 1
ORDER BY AverageScore ASC, item
LIMIT (20)

/*Facilities with most level 3 risk type and avg score*/
SELECT facility, ROUND(AVG(score),2) as average_score, COUNT(risk_type) as total_level_3s
FROM fsiv
WHERE risk_type = 3
GROUP BY facility
ORDER BY COUNT(risk_type) desc
LIMIT (20)

/*Facility score change from last 3 inspections (Most improved) (Least Improved)*/
WITH InspectionsScores AS (
    SELECT
        facility,
        date,
        ROUND(AVG(score),0) as AvgScore
    FROM fsiv
    GROUP BY facility, date
),
InspectionsRanked AS (
    SELECT
        facility,
        AvgScore,
        ROW_NUMBER() OVER (PARTITION BY facility ORDER BY date DESC) as InspectionRank
    FROM InspectionsScores
)
SELECT 
    facility,
    MAX(CASE WHEN InspectionRank = 1 THEN AvgScore ELSE NULL END) - MAX(CASE WHEN InspectionRank = 3 THEN AvgScore ELSE NULL END) as ScoreImprovement
FROM InspectionsRanked
GROUP BY facility
HAVING COUNT(*) >= 3
ORDER BY ScoreImprovement DESC;
















































































































































