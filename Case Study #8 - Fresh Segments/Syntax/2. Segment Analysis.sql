-- 1. Which interests have been present in all month_year dates in our dataset?
DECLARE @month_year_count INT = (
    SELECT COUNT(DISTINCT month_year)
    FROM fresh_segments.interest_metrics
);

SELECT mp.id, mp.interest_name, mp.interest_summary
FROM fresh_segments.interest_metrics mt
INNER JOIN fresh_segments.interest_map mp
    ON mt.interest_id = mp.id
GROUP BY mp.id, mp.interest_name, mp.interest_summary
HAVING COUNT(month_year) = @month_year_count;



-- 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - 
-- which total_months value passes the 90% cumulative percentage value?
-- Answer: the total_month of 6 would surpass the 90% cumulative percentage value.
DROP TABLE IF EXISTS #interest_months;

SELECT interest_id,
    COUNT(DISTINCT month_year) AS total_months
INTO #interest_months
FROM fresh_segments.interest_metrics
GROUP BY interest_id;

WITH interest_count AS (
    SELECT total_months,
        COUNT(interest_id) AS interests
    FROM #interest_months
    GROUP BY total_months
)

SELECT *,
    CAST(SUM(interests) OVER(ORDER BY total_months DESC) * 100.0 /
        SUM(interests) OVER() AS DECIMAL(10, 2)) AS cumulative_pct
FROM interest_count
ORDER BY total_months DESC;



-- 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question -
-- how many total data points would we be removing?
WITH interest_months AS (
    SELECT interest_id,
        COUNT(DISTINCT month_year) AS total_months
    FROM fresh_segments.interest_metrics
    GROUP BY interest_id
    HAVING COUNT(DISTINCT month_year) <= 6
)

SELECT COUNT(interest_id) AS interests_to_remove,
    COUNT(DISTINCT interest_id) AS unique_interests_to_remove
FROM fresh_segments.interest_metrics
WHERE interest_id IN (
    SELECT interest_id 
    FROM interest_months
);

-- Bonus: Find out the information about all unique interests
WITH interest_months AS (
    SELECT interest_id,
        COUNT(DISTINCT month_year) AS total_months
    FROM fresh_segments.interest_metrics
    GROUP BY interest_id
)

SELECT mp.id, mp.interest_name, mp.interest_summary
FROM interest_months cte
INNER JOIN fresh_segments.interest_map mp
    ON cte.interest_id = mp.id
WHERE total_months <= 6;