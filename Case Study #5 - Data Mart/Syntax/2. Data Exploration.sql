-- 1. What day of the week is used for each week_date value?
SELECT DISTINCT(DATENAME(dw, week_date)) AS week_date_value
FROM data_mart.weekly_sales_cleaned;



-- 2. What range of week numbers are missing from the dataset?
WITH missing_weeks AS (
    SELECT 1 AS week_number
    UNION ALL
    SELECT week_number + 1
    FROM missing_weeks
    WHERE week_number < 53
)

SELECT week_number AS missing_week
FROM missing_weeks m
WHERE NOT EXISTS (
    SELECT *
    FROM data_mart.weekly_sales_cleaned s
    WHERE m.week_number = s.week_number
);



-- 3. How many total transactions were there for each year in the dataset?
SELECT calendar_year,
    SUM(transactions) AS total_transactions
FROM data_mart.weekly_sales_cleaned
GROUP BY calendar_year
ORDER BY calendar_year;



-- 4. What is the total sales for each region for each month?
SELECT region, month_number, 
    SUM(sales) AS total_sales
FROM data_mart.weekly_sales_cleaned
GROUP BY region, month_number
ORDER BY region, month_number;



-- 5. What is the total count of transactions for each platform?
SELECT platform,
    SUM(transactions) AS total_transactions
FROM data_mart.weekly_sales_cleaned
GROUP BY platform;



-- 6. What is the percentage of sales for Retail vs Shopify for each month?
WITH platform_sales AS (
    SELECT platform, month_number, calendar_year, 
        SUM(sales) AS monthly_sales
    FROM data_mart.weekly_sales_cleaned
    GROUP BY calendar_year, month_number, platform
)

SELECT calendar_year, month_number, 
    CAST(MAX(CASE WHEN platform = 'Retail' THEN monthly_sales END) * 100.0 /
        SUM(monthly_sales) AS decimal(10, 2)) AS pct_retail,
    CAST(MAX(CASE WHEN platform = 'Shopify' THEN monthly_sales END) * 100.0 /
        SUM(monthly_sales) AS DECIMAL(10, 2)) AS pct_shopify
FROM platform_sales
GROUP BY calendar_year,  month_number
ORDER BY calendar_year, month_number;



-- 7. What is the percentage of sales by demographic for each year in the dataset?
WITH demographic_sales AS (
    SELECT demographic, calendar_year,
        SUM(sales) AS yearly_sales
    FROM data_mart.weekly_sales_cleaned
    GROUP BY calendar_year, demographic
)

SELECT calendar_year,
    CAST(MAX(CASE WHEN demographic = 'Families' THEN yearly_sales END) * 100.0 /
        SUM(yearly_sales) AS DECIMAL(10, 2)) AS pct_families,
    CAST(MAX(CASE WHEN demographic = 'Couples' THEN yearly_sales END) * 100.0 /
        SUM(yearly_sales) AS DECIMAL(10, 2)) AS pct_couples,
    CAST(MAX(CASE WHEN demographic = 'Unknown' THEN yearly_sales END) * 100.0 /
        SUM(yearly_sales) AS DECIMAL(10, 2)) AS pct_unknown
FROM demographic_sales
GROUP BY calendar_year;



-- 8. Which age_band and demographic values contribute the most to Retail sales?
DECLARE @retailSales BIGINT = (
    SELECT SUM(sales)
    FROM data_mart.weekly_sales_cleaned
    WHERE platform = 'Retail'
);

SELECT age_band, demographic,
    SUM(sales) AS sales,
    CAST(SUM(sales) * 100.0 / @retailSales AS DECIMAL(10, 2)) AS contribution
FROM data_mart.weekly_sales_cleaned
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY contribution DESC;



-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

/* Answer: we cannot calculate the average of avg_transaction to find average transaction size. Let's consider the concept of distribution.
Each set of numbers represents a different distribution with its own shape.
When we calculate the average of a set, we are finding the central tendency of that specific distribution.
Taking an average of averages assumes that each distribution has a similar shape, which may not be true.
Thus, combining these averages does not accurately represent the central tendencies of the individual distributions or provide an accurate overall average.
As a result, to calculate the average transaction size correctly, we need to take the average of all the individual transaction values for each year and platform. */

SELECT calendar_year, platform,
    ROUND(AVG(avg_transaction), 2) AS inaccurate_average_transaction,
    ROUND(CAST(SUM(sales) AS FLOAT) / CAST(SUM(transactions) AS FLOAT), 2) AS accurate_average_transaction
FROM data_mart.weekly_sales_cleaned
GROUP BY calendar_year, platform
ORDER BY calendar_year, platform;