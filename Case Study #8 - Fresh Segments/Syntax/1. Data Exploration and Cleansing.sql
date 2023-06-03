-- 1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month.
ALTER TABLE fresh_segments.interest_metrics
ALTER COLUMN month_year VARCHAR(10);

UPDATE fresh_segments.interest_metrics
SET month_year =  CONVERT(DATE, '01-' + month_year, 105);

ALTER TABLE fresh_segments.interest_metrics
ALTER COLUMN month_year DATE;




-- 2. What is count of records in the fresh_segments.interest_metrics for each month_year value
-- sorted in chronological order (earliest to latest) with the null values appearing first?
SELECT month_year,
    COUNT(*) AS record_count
FROM fresh_segments.interest_metrics
GROUP BY month_year
ORDER BY month_year;



-- 3. What do you think we should do with these null values in the fresh_segments.interest_metrics?

-- 3.1. Check null values
SELECT '_month' AS column_name, COUNT(*) AS no_of_null
FROM fresh_segments.interest_metrics
WHERE _month IS NULL
UNION ALL
SELECT '_year' AS column_name, COUNT(*) AS no_of_null
FROM fresh_segments.interest_metrics
WHERE _year IS NULL
UNION ALL
SELECT 'month_year' AS column_name, COUNT(*) AS no_of_null
FROM fresh_segments.interest_metrics
WHERE month_year IS NULL
UNION ALL
SELECT 'interest_id' AS column_name, COUNT(*) AS no_of_null
FROM fresh_segments.interest_metrics
WHERE interest_id IS NULL
UNION ALL
SELECT 'composition' AS column_name, COUNT(*) AS no_of_null
FROM fresh_segments.interest_metrics
WHERE composition IS NULL
UNION ALL
SELECT 'index_value' AS column_name, COUNT(*) AS no_of_null
FROM fresh_segments.interest_metrics
WHERE index_value IS NULL
UNION ALL
SELECT 'ranking' AS column_name, COUNT(*) AS no_of_null
FROM fresh_segments.interest_metrics
WHERE ranking IS NULL
UNION ALL
SELECT 'percentile_ranking' AS column_name, COUNT(*) AS no_of_null
FROM fresh_segments.interest_metrics
WHERE percentile_ranking IS NULL;

-- 3.2. Find out more insights about null values
SELECT SUM(CASE WHEN _month IS NULL AND _year IS NULL 
        AND month_year IS NULL AND interest_id IS NULL THEN 1
        ELSE 0 END) AS no_of_null_time_id,
    SUM(CASE WHEN _month IS NULL AND _year IS NULL 
        AND month_year IS NULL AND interest_id IS NOT NULL THEN 1
        ELSE 0 END) AS no_of_null_time_id
FROM fresh_segments.interest_metrics;

-- 3.3. Check interest_id
SELECT *
FROM fresh_segments.interest_metrics
WHERE _month IS NULL AND _year IS NULL
    AND month_year IS NULL AND interest_id IS NOT NULL;

-- 3.4. Conclusion
/* Answer: there are 1193 records with null values in the specific months, and one record with interest_id = 21246 with NULL values in month and year.
To generate better result from this interest_id, it is better to keep this value. However, other value may not be usable for the invalid time and id.
Thus, they will be removed. */
DELETE FROM fresh_segments.interest_metrics
WHERE interest_id IS NULL;



-- 4. How many interest_id values exist in the fresh_segments.interest_metrics table
-- but not in the fresh_segments.interest_map table? What about the other way around?
SELECT COUNT(DISTINCT mp.id) AS map_id_count,
    COUNT(DISTINCT mt.interest_id) AS metrics_id_count,
    SUM(CASE WHEN mp.id IS NULL THEN 1
        ELSE 0 END) AS id_not_in_metrics_table,
    SUM(CASE WHEN mt.interest_id is NULL THEN 1 
        ELSE 0 END) AS id_not_in_map_table
FROM fresh_segments.interest_metrics mt
FULL JOIN fresh_segments.interest_map mp
    ON mt.interest_id = mp.id;



-- 5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table.
SELECT COUNT(*) AS map_id_count
FROM fresh_segments.interest_map;



-- 6. What sort of table join should we perform for our analysis and why? 
-- Answer: interest_metrics should be used for analysis, since the figures are more meaningful and suitable for this purposes.
SELECT mt.*, mp.*
FROM fresh_segments.interest_metrics mt
INNER JOIN fresh_segments.interest_map mp
    ON mt.interest_id = mp.id
WHERE mp.id = 21246;



-- 7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? 
-- Do you think these values are valid and why?

-- 7.1. Check where 'month_year' is before 'created_at'
SELECT COUNT(*) AS value_count
FROM fresh_segments.interest_metrics metrics
INNER JOIN fresh_segments.interest_map map
    ON metrics.interest_id = map.id
WHERE metrics.month_year < CAST(map.created_at AS DATE);

-- 7.2. Check whether 'month_year' and 'created_at' are all in the same month
SELECT COUNT(*) AS value_count
FROM fresh_segments.interest_metrics metrics
INNER JOIN fresh_segments.interest_map map
    ON map.id = metrics.interest_id
WHERE metrics.month_year < CAST(DATEADD(DAY, -DAY(map.created_at)+1, map.created_at) AS DATE);

-- 7.3. Conclusion
/* It seems that there are 188 records month_year value before the created_at value, but they are all valid.
In the previous steps, the first date of the month was added to the 'month_year' column. However, not all records are set in the first day of the month.
Moreover, none of them are created in the previous month of the month in 'created at'. Hence, all records are valid. */