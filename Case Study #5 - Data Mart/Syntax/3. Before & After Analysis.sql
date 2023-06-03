-- 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
DECLARE @week_no INT = (
    SELECT DISTINCT week_number
    FROM data_mart.weekly_sales_cleaned
    WHERE week_date = '2020-06-15'
);

WITH sales_changes AS (
    SELECT SUM(CASE WHEN week_number BETWEEN (@week_no - 4) AND (@week_no - 1) THEN sales END) AS before_date,
        SUM(CASE WHEN week_number BETWEEN @week_no AND (@week_no + 3) THEN sales END) AS after_date
    FROM data_mart.weekly_sales_cleaned
    WHERE calendar_year = 2020
)

SELECT before_date AS sales_4weeks_before,
    after_date AS sales_4weeks_after,
    after_date - before_date AS sales_difference_4weeks,
    CAST((after_date - before_date) * 100.0 /
        before_date AS DECIMAL(10, 2)) AS pct_change_4weeks
FROM sales_changes;



-- 2. What about the entire 12 weeks before and after?
DECLARE @week_no INT = (
    SELECT DISTINCT week_number
    FROM data_mart.weekly_sales_cleaned
    WHERE week_date = '2020-06-15'
);

WITH sales_changes AS (
    SELECT SUM(CASE WHEN week_number BETWEEN (@week_no - 12) AND (@week_no - 1) THEN sales END) AS before_date,
        SUM(CASE WHEN week_number BETWEEN @week_no AND (@week_no + 11) THEN sales END) AS after_date
    FROM data_mart.weekly_sales_cleaned
    WHERE calendar_year = 2020
)

SELECT before_date AS sales_12weeks_before,
    after_date AS sales_12weeks_after,
    after_date - before_date AS sales_12weeks_difference,
    CAST((after_date - before_date) * 100.0 /
        before_date AS DECIMAL(10, 2)) AS pct_change_12weeks
FROM sales_changes;


-- 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
DECLARE @week_no INT = (
    SELECT DISTINCT week_number
    FROM data_mart.weekly_sales_cleaned
    WHERE week_date = '2020-06-15'
);

DROP TABLE IF EXISTS #sales_changes_4week, #sales_changes_12week;

SELECT calendar_year,
    SUM(CASE WHEN week_number BETWEEN (@week_no - 4) AND (@week_no - 1) THEN sales END) AS before_date_4week,
    SUM(CASE WHEN week_number BETWEEN @week_no AND (@week_no + 3) THEN sales END) AS after_date_4week
INTO #sales_changes_4week
FROM data_mart.weekly_sales_cleaned
GROUP BY calendar_year;

SELECT calendar_year,
    SUM(CASE WHEN week_number BETWEEN (@week_no - 12) AND (@week_no - 1) THEN sales END) AS before_date_12week,
    SUM(CASE WHEN week_number BETWEEN @week_no AND (@week_no + 11) THEN sales END) AS after_date_12week
INTO #sales_changes_12week
FROM data_mart.weekly_sales_cleaned
GROUP BY calendar_year;

WITH pct_metrics AS (
    SELECT a.calendar_year,
        CAST((after_date_4week - before_date_4week) * 100.0 /
        before_date_4week AS DECIMAL(10, 2)) AS pct_change_4weeks,
        CAST((after_date_12week - before_date_12week) * 100.0 /
        before_date_12week AS DECIMAL(10, 2)) AS pct_change_12weeks
    FROM #sales_changes_4week a
    JOIN #sales_changes_12week b
    ON a.calendar_year = b.calendar_year

)
SELECT *,
    pct_change_4weeks - LAG(pct_change_4weeks, 2) OVER (ORDER BY calendar_year) AS comparison_4weeks_2019,
    pct_change_12weeks - LAG(pct_change_12weeks, 2) OVER (ORDER BY calendar_year) AS comparison_12weeks_2019,
    pct_change_4weeks - LAG(pct_change_4weeks) OVER (ORDER BY calendar_year) AS comparison_4weeks_2018,
    pct_change_12weeks - LAG(pct_change_12weeks) OVER (ORDER BY calendar_year) AS comparison_12weeks_2018
FROM pct_metrics
ORDER BY calendar_year