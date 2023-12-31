/* 

Bellabeat Case Study
Google Data Analytics Capstone Project

*/

-- timestamp/date formatting stays the same across tables
-- Setting variables for regular expression based analyses

DECLARE TIMESTAMP_REGEX STRING DEFAULT r'^\d{4}-\d{1,2}-\d{1,2}[T]\d{1,2}:\d{1,2}:\d{1,2}(\.\d{1,6})? *(([+-]\d{1,2}(:\d{1,2})?)|Z|UTC)?$';
DECLARE DATE_REGEX STRING DEFAULT r'^\d{4}-(?:[1-9]|0[1-9]|1[012])-(?:[1-9]|0[1-9]|[12][0-9]|3[01])$';
DECLARE TIME_REGEX STRING DEFAULT r'^\d{1,2}:\d{1,2}:\d{1,2}(\.\d{1,6})?$';


-- Setting variables for time of day/ day of week analyses
DECLARE MORNING_START, MORNING_END, AFTERNOON_END, EVENING_END INT64;

-- Set the times for the times of the day
SET MORNING_START = 6;
SET MORNING_END = 12;
SET AFTERNOON_END = 18;
SET EVENING_END = 21;


-- Finding columns that exist in multiple tables
SELECT 
  table_name, column_name
FROM `tenacious-text-379818.Capstone.INFORMATION_SCHEMA.COLUMNS`
WHERE table_catalog = 'tenacious-text-379818'
  AND table_schema = 'Capstone'
  AND table_name != 'daily_activity'
  AND column_name = 'Id';


-- Checking if 'Id' exists in all tables in dataset
SELECT 
  table_name,
  SUM(
    CASE WHEN column_name = "Id" THEN 1
    ELSE 0
    END
    ) AS has_id_column
FROM `tenacious-text-379818.Capstone.INFORMATION_SCHEMA.COLUMNS`
GROUP BY 1
ORDER BY 1 ASC;


-- Checking that every column has date/time type. The result should be: empty if the columns were detected properly
SELECT table_name,
  SUM (CASE WHEN data_type IN ("TIMESTAMP", "DATETIME", "TIME", "DATE") THEN 1
    ELSE 0
    END
    ) AS has_time_info
FROM `tenacious-text-379818.Capstone.INFORMATION_SCHEMA.COLUMNS`
WHERE data_type IN ("TIMESTAMP","DATETIME","DATE")
GROUP BY 1
HAVING has_time_info = 1;


-- Seeing the name of the time/date datatype column in each table
SELECT
  table_name,
  column_name
FROM `tenacious-text-379818.Capstone.INFORMATION_SCHEMA.COLUMNS`
WHERE data_type IN ("TIMESTAMP","DATETIME","DATE");

-- Finding tables that have day|daily for daily data
SELECT DISTINCT table_name
FROM `tenacious-text-379818.Capstone.INFORMATION_SCHEMA.COLUMNS`
WHERE REGEXP_CONTAINS(LOWER(table_name),"day|daily");


-- Finding the frequency of occurence of the columns in the day|daily tables
SELECT 
  column_name, 
  data_type,
  COUNT(table_name) AS table_count
FROM `tenacious-text-379818.Capstone.INFORMATION_SCHEMA.COLUMNS`
WHERE REGEXP_CONTAINS(LOWER(table_name), r'day|daily')
GROUP BY 1, 2;


-- Filtering columns that contain 'day|daily' that also occur in at least 2 different tables
SELECT
  column_name,
  table_name,
  data_type
FROM `tenacious-text-379818.Capstone.INFORMATION_SCHEMA.COLUMNS`
WHERE REGEXP_CONTAINS(LOWER(table_name), r'day|daily')
  AND table_name NOT IN ('daily_merged_01', 'group1_31days', 'group2_28to30days','group3_less27days')
  AND column_name IN (
    SELECT column_name
    FROM `tenacious-text-379818.Capstone.INFORMATION_SCHEMA.COLUMNS`
    WHERE REGEXP_CONTAINS(LOWER(table_name),r'day|daily')
    GROUP BY 1
    HAVING COUNT(table_name) >= 2
    )
ORDER BY 1;


-- Joined (LEFT JOIN) the filtered tables: daily_activity, daily_calories, daily_intensities, daily_steps, daily_sleep
SELECT
  A.Id,
  A.Calories,
  * EXCEPT(Id,
  Calories,
  ActivityDay,
  SedentaryMinutes,
  LightlyActiveMinutes,
  FairlyActiveMinutes,
  VeryActiveMinutes,
  SedentaryActiveDistance,
  LightActiveDistance,
  ModeratelyActiveDistance,
  VeryActiveDistance
  ),
  I.SedentaryMinutes,
  I.LightlyActiveMinutes,
  I.FairlyActiveMinutes,
  I.VeryActiveMinutes,
  I.SedentaryActiveDistance,
  I.LightActiveDistance,
  I.ModeratelyActiveDistance,
  I.VeryActiveDistance
FROM `tenacious-text-379818.Capstone.daily_activity` A
LEFT JOIN `tenacious-text-379818.Capstone.daily_calories` C
  ON
    A.Id = C.Id
    AND A.ActivityDate=C.ActivityDay
    AND A.Calories = C.Calories
LEFT JOIN `tenacious-text-379818.Capstone.daily_intensities` I
  ON
    A.Id = I.Id
    AND A.ActivityDate=I.ActivityDay
    AND A.FairlyActiveMinutes = I.FairlyActiveMinutes
    AND A.LightActiveDistance = I.LightActiveDistance
    AND A.LightlyActiveMinutes = I.LightlyActiveMinutes
    AND A.ModeratelyActiveDistance = I.ModeratelyActiveDistance
    AND A.SedentaryActiveDistance = I.SedentaryActiveDistance
    AND A.SedentaryMinutes = I.SedentaryMinutes
    AND A.VeryActiveDistance = I.VeryActiveDistance
    AND A.VeryActiveMinutes = I.VeryActiveMinutes
LEFT JOIN `tenacious-text-379818.Capstone.daily_steps` S
  ON
    A.Id = S.Id
    AND DATE(A.ActivityDate) = DATE(S.ActivityDay)
LEFT JOIN `tenacious-text-379818.Capstone.daily_sleep` S1
  ON
    A.Id = S1.Id
    AND DATE(A.ActivityDate) = DATE(S1.SleepDay);


-- Finding start (2016.04.12) and end date (2016.05.12), to find the duration over which the data was tracked
SELECT
  MIN(ActivityDate) AS earliest_date,
  MAX(ActivityDate) AS latest_date,
  DATE_DIFF(
  CAST(MAX(ActivityDate) AS DATETIME),
  CAST(MIN(ActivityDate) AS DATETIME),
  DAY) +1 AS number_of_days
FROM `tenacious-text-379818.Capstone.daily_merged_01`


-- Finding the count of occurence for each distinct 'Total_Id' (num of days) value in the daily_merged_01 table
WITH user_counts AS (
  SELECT
  Id,
  COUNT(DISTINCT DATE(ActivityDate)) AS CountDays
  FROM `tenacious-text-379818.Capstone.daily_merged_01`
  GROUP BY Id
  )
SELECT
  CountDays,
  COUNT(DISTINCT Id) AS UserCount,
  ROUND((COUNT(DISTINCT Id) / (SELECT COUNT(DISTINCT Id) FROM user_counts)) * 100, 2) AS UserPercentage,
  ROUND((CountDays / 31.0) * 100, 2) AS DaysPercentage
FROM user_counts
GROUP BY CountDays
ORDER BY CountDays DESC;


-- Grouped the users by the number of days that they had a data entry
SELECT
  CASE WHEN CountDays = 31 
    THEN 'Group 1: 100% (31/31 days)'
    WHEN CountDays <= 28 
      THEN 'Group 2: >90% (at least 28/31 days)'
    ELSE 'Group 3: <90% (26 days or less)>'
  END AS Category,
  COUNT(*) AS UserCount
FROM 
  (
  SELECT Id, COUNT(DISTINCT DATE(ActivityDate)) AS CountDays
  FROM `tenacious-text-379818.Capstone.daily_merged_01`
  GROUP BY Id
  )
GROUP BY Category
ORDER BY Category


-- How many of those that have entries for the entire 31 days also have entries for sleep (missing 5)

WITH user_counts AS (
  SELECT
  Id,
  COUNT(DISTINCT DATE(ActivityDate)) AS CountDays
  FROM `tenacious-text-379818.Capstone.daily_merged_01`
  GROUP BY Id
  ),
  users_with_countdays AS (
    SELECT
    uc.Id,
    dm.TotalSteps
    FROM user_counts uc
    JOIN `tenacious-text-379818.Capstone.daily_merged_01` dm
    ON uc.Id = dm.Id
    WHERE uc.CountDays = 31
    AND dm.TotalSteps IS NOT NULL
    ),
  users_without_entry AS (
    SELECT
    uc.Id
    FROM users_with_countdays uc
    LEFT JOIN `tenacious-text-379818.Capstone.daily_sleep` ds
    ON uc.Id = ds.Id
    WHERE ds.Id IS NULL
    )
SELECT
  COUNT(*) AS Count,
  uw.Id
FROM users_without_entry uw
GROUP BY uw.Id;


-- Grouped the users in 3 groups based upon they have 100%, at least 90%, and less than 90% of the days of daily data
CREATE TABLE Capstone.group3_less27days AS
SELECT *
FROM `tenacious-text-379818.Capstone.daily_merged_01`
WHERE Id IN (
  SELECT Id
  FROM (
    SELECT Id, COUNT(DISTINCT DATE(ActivityDate)) AS CountDays
    FROM `tenacious-text-379818.Capstone.daily_merged_01`
    GROUP BY Id
    HAVING CountDays <= 27
    ) AS Group2
   )

-- Looking at the relationship between the incomplete daily_sleep table and from which of the 3 groups the Ids are coming from
SELECT 
  ds.Id,
  CASE
    WHEN g1.Id IS NOT NULL THEN 'Group 1: 100%'
    WHEN g2.Id IS NOT NULL THEN 'Group 2: >90% (28-30 days)'
    WHEN g3.Id IS NOT NULL THEN 'Group 3: <90% (26 days or less)'
    ELSE 'Not in any group'
    END AS GroupCategory
FROM (SELECT DISTINCT Id FROM Capstone.daily_sleep) ds
LEFT JOIN tenacious-text-379818.Capstone.group1_31days g1 ON ds.Id = g1.Id
LEFT JOIN tenacious-text-379818.Capstone.group2_28to30days g2 ON ds.Id = g2.Id
LEFT JOIN tenacious-text-379818.Capstone.group3_less27days g3 ON ds.Id = g3.Id
GROUP BY ds.Id, GroupCategory
ORDER BY GroupCategory;


-- Aggregating the distinct Ids in the 3 groups  and counting how Ids have daily_sleep entry and how many don't
SELECT
  Group 1: 100%' AS group_name,
  COUNT(DISTINCT CASE WHEN ds.id IS NOT NULL THEN gs1.id END) AS count_with_entry,
  COUNT(DISTINCT CASE WHEN ds.id IS NULL THEN gs1.id END) AS count_without_entry
FROM Capstone.group1_31days gs1
LEFT JOIN Capstone.daily_sleep ds 
  ON gs1.id = ds.id
UNION ALL
SELECT
  Group 2: >90%' AS group_name,
  COUNT(DISTINCT CASE WHEN ds.id IS NOT NULL THEN gs2.id END) AS count_with_entry,
  COUNT(DISTINCT CASE WHEN ds.id IS NULL THEN gs2.id END) AS count_without_entry
FROM Capstone.group2_28to30days gs2
LEFT JOIN Capstone.daily_sleep ds 
  ON gs2.id = ds.id
UNION ALL
SELECT
  Group 3: <90%' AS group_name,
  COUNT(DISTINCT CASE WHEN ds.id IS NOT NULL THEN gs3.id END) AS count_with_entry,
  COUNT(DISTINCT CASE WHEN ds.id IS NULL THEN gs3.id END) AS count_without_entry
FROM Capstone.group3_less27days gs3
LEFT JOIN Capstone.daily_sleep ds 
  ON gs3.id = ds.id;


-- Average calories and steps for the 3 groups
-- Calculate the average of Calories and TotalSteps for group1_31days
SELECT 
  AVG(Calories) AS Average_Calories, 
  AVG(TotalSteps) AS Average_TotalSteps
FROM Capstone.group1_31days
UNION ALL
-- Calculate the average of Calories and TotalSteps for group2_28to30days
SELECT 
  AVG(Calories) AS Average_Calories, 
  AVG(TotalSteps) AS Average_TotalSteps
FROM Capstone.group2_28to30days
UNION ALL
-- Calculate the average of Calories and TotalSteps for group3_less27days
SELECT 
  AVG(Calories) AS Average_Calories, 
  AVG(TotalSteps) AS Average_TotalSteps
FROM Capstone.group3_less27days;


-- Average step count for group1 throughout the week by day
SELECT
  FORMAT_TIMESTAMP('%A', ActivityDate) AS DayOfWeek,
  AVG(TotalSteps) AS AverageSteps
FROM `tenacious-text-379818.Capstone.group1_31days`
GROUP BY DayOfWeek
ORDER BY DayOfWeek;


-- Looking at calories and total steps
SELECT
  Id,
  AVG(TotalSteps) AS average_steps,
  AVG(Calories) AS average_calories
FROM `tenacious-text-379818.Capstone.group1_31days`
GROUP BY Id


-- Hourly average step count by day for group 1
WITH hourly_avg AS (
  SELECT
    FORMAT_TIMESTAMP('%A', hs.ActivityHour) AS DayOfWeek,
    EXTRACT(HOUR FROM hs.ActivityHour) AS HourOfDay,
    AVG(hs.StepTotal) AS AverageHourlySteps
  FROM `Capstone.hourly_steps` hs
  LEFT JOIN `Capstone.group1_31days` g 
    ON hs.Id = g.Id
  GROUP BY 
    DayOfWeek,
    HourOfDay
  )
SELECT
  HourOfDay,
  AVG(IF(DayOfWeek = 'Monday', AverageHourlySteps, NULL)) AS Monday,
  AVG(IF(DayOfWeek = 'Tuesday', AverageHourlySteps, NULL)) AS Tuesday,
  AVG(IF(DayOfWeek = 'Wednesday', AverageHourlySteps, NULL)) AS Wednesday,
  AVG(IF(DayOfWeek = 'Thursday', AverageHourlySteps, NULL)) AS Thursday,
  AVG(IF(DayOfWeek = 'Friday', AverageHourlySteps, NULL)) AS Friday,
  AVG(IF(DayOfWeek = 'Saturday', AverageHourlySteps, NULL)) AS Saturday,
  AVG(IF(DayOfWeek = 'Sunday', AverageHourlySteps, NULL)) AS Sunday
FROM hourly_avg
GROUP BY HourOfDay
ORDER BY HourOfDay
