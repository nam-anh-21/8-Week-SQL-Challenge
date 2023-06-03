-- Question: Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
-- Let's find out the key part of each areas having the highest negative impact on that area.
-- Notice: please run all queries at once.
DECLARE @week_no INT = (
    SELECT DISTINCT week_number
    FROM data_mart.weekly_sales_cleaned
    WHERE week_date = '2020-06-15'
    AND calendar_year = 2020
);

DROP TABLE IF EXISTS #region_metric, #platform_metric, #age_band_metric, #demographic_metric, #customer_type_metric;

-- 1. Find region with most negative impact
WITH changes_by_region AS (
    SELECT region,
        SUM(CASE WHEN week_number BETWEEN @week_no - 12 AND @week_no - 1 THEN sales END) AS before_date,
        SUM(CASE WHEN week_number BETWEEN @week_no AND @week_no + 11 THEN sales END) AS after_date
    FROM data_mart.weekly_sales_cleaned
    GROUP BY region
), most_negative_region AS(
    SELECT TOP 1 region,
        CAST((after_date - before_date) * 100.0 /
            before_date AS DECIMAL(10, 2)) AS pct_change
    FROM changes_by_region
    ORDER BY pct_change ASC
)

SELECT 'region' AS area, region AS detail, pct_change
INTO #region_metric
FROM most_negative_region;

-- 2. Find platform with most negative impact
WITH changes_by_platform AS (
    SELECT platform,
        SUM(CASE WHEN week_number BETWEEN @week_no - 12 AND @week_no - 1 THEN sales END) AS before_date,
        SUM(CASE WHEN week_number BETWEEN @week_no AND @week_no + 11 THEN sales END) AS after_date
    FROM data_mart.weekly_sales_cleaned
    GROUP BY platform
), most_negative_platform AS(
    SELECT TOP 1 platform,
        CAST((after_date - before_date) * 100.0 /
            before_date AS DECIMAL(10, 2)) AS pct_change
    FROM changes_by_platform
    ORDER BY pct_change ASC
)

SELECT 'platform' AS area, platform AS detail, pct_change
INTO #platform_metric
FROM most_negative_platform;

-- 3. Find age band with most negative impact (skip unknown age band)
WITH changes_by_age_band AS (
    SELECT age_band,
        SUM(CASE WHEN week_number BETWEEN @week_no - 12 AND @week_no - 1 THEN sales END) AS before_date,
        SUM(CASE WHEN week_number BETWEEN @week_no AND @week_no + 11 THEN sales END) AS after_date
    FROM data_mart.weekly_sales_cleaned
    WHERE age_band != 'Unknown'
    GROUP BY age_band
), most_negative_age_band AS(
    SELECT TOP 1 age_band,
        CAST((after_date - before_date) * 100.0 /
            before_date AS DECIMAL(10, 2)) AS pct_change
    FROM changes_by_age_band
    ORDER BY pct_change ASC
)

SELECT 'age_band' AS area, age_band AS detail, pct_change
INTO #age_band_metric
FROM most_negative_age_band;

-- 4. Find demographic with most negative impact (skip unknown demographic)
WITH changes_by_demographic AS (
    SELECT demographic,
        SUM(CASE WHEN week_number BETWEEN @week_no - 12 AND @week_no - 1 THEN sales END) AS before_date,
        SUM(CASE WHEN week_number BETWEEN @week_no AND @week_no + 11 THEN sales END) AS after_date
    FROM data_mart.weekly_sales_cleaned
    WHERE demographic != 'Unknown'
    GROUP BY demographic
), most_negative_demographic AS(
    SELECT TOP 1 demographic,
        CAST((after_date - before_date) * 100.0 /
           before_date AS DECIMAL(10, 2)) AS pct_change
    FROM changes_by_demographic
    ORDER BY pct_change ASC
)

SELECT 'demographic' AS area, demographic AS detail, pct_change
INTO #demographic_metric
FROM most_negative_demographic;

-- 5. Find customer type with most negative impact
WITH changes_by_customer_type AS (
    SELECT customer_type,
        SUM(CASE WHEN week_number BETWEEN @week_no - 12 AND @week_no - 1 THEN sales END) AS before_date,
        SUM(CASE WHEN week_number BETWEEN @week_no AND @week_no + 11 THEN sales END) AS after_date
    FROM data_mart.weekly_sales_cleaned
    GROUP BY customer_type
), most_negative_customer_type AS(
    SELECT TOP 1 customer_type,
        CAST((after_date - before_date) * 100.0 /
            before_date AS DECIMAL(10, 2)) AS pct_change
    FROM changes_by_customer_type
    ORDER BY pct_change ASC
)

SELECT 'customer_type' AS area, customer_type AS detail, pct_change
INTO #customer_type_metric
FROM most_negative_customer_type;

-- Result
SELECT *
FROM #region_metric
UNION ALL
SELECT *
FROM #platform_metric
UNION ALL
SELECT *
FROM #age_band_metric
UNION ALL
SELECT *
FROM  #demographic_metric
UNION ALL
SELECT *
FROM #customer_type_metric;