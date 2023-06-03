-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM foodie_fi.subscriptions;



-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value?
SELECT MONTH(s.start_date) AS months,
    COUNT(*) AS distribution_values
FROM foodie_fi.subscriptions s
INNER JOIN foodie_fi.plans p 
    ON s.plan_id = p.plan_id
WHERE p.plan_name = 'trial'
GROUP BY MONTH(s.start_date);



-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name.
SELECT p.plan_name,
    YEAR(s.start_date) AS events,
    COUNT(*) AS value_count
FROM foodie_fi.subscriptions s
INNER JOIN foodie_fi.plans p 
    ON s.plan_id = p.plan_id
WHERE YEAR(s.start_date) > 2020
GROUP BY p.plan_name, YEAR(s.start_date);



-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT SUM(CASE WHEN p.plan_name = 'churn' THEN 1 END) AS churn_count,
    CAST(SUM(CASE WHEN p.plan_name = 'churn' THEN 1 END) AS FLOAT) /
    COUNT(DISTINCT customer_id) * 100 AS churn_pct
FROM foodie_fi.subscriptions s
INNER JOIN foodie_fi.plans p 
    ON s.plan_id = p.plan_id;



-- 5. What is the number and percentage of customer plans after their initial free trial?
DECLARE @no_of_customer INT = (
    SELECT COUNT(DISTINCT customer_id)
    FROM foodie_fi.subscriptions
);

WITH next_plan AS (
    SELECT s.customer_id, s.start_date, p.plan_name,
        LEAD(p.plan_name) OVER(PARTITION BY s.customer_id ORDER BY p.plan_id) AS next_plan
    FROM foodie_fi.subscriptions s
    INNER JOIN foodie_fi.plans p
        ON s.plan_id = p.plan_id
)

SELECT COUNT(*) AS churn_after_trial_count,
    CAST(COUNT(*) AS FLOAT) / @no_of_customer AS churn_after_trial_pct
FROM next_plan
WHERE plan_name = 'trial' AND next_plan = 'churn';



-- 6. What is the number and percentage of customer plans after their initial free trial?
DECLARE @no_of_customer INT = (
    SELECT COUNT(DISTINCT customer_id)
    FROM foodie_fi.subscriptions
);

WITH next_plan AS (
    SELECT s.customer_id, s.start_date, p.plan_name,
        LEAD(p.plan_name) OVER(PARTITION BY s.customer_id ORDER BY p.plan_id) AS next_plan
    FROM foodie_fi.subscriptions s
    INNER JOIN foodie_fi.plans p
        ON s.plan_id = p.plan_id
)

SELECT next_plan, COUNT(*) AS customer_plan,
    ROUND(CAST(COUNT(*) AS FLOAT) / @no_of_customer * 100, 2) AS customer_plan_pct
FROM next_plan
WHERE next_plan IS NOT NULL
    AND plan_name = 'trial'
GROUP BY next_plan;



-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
DECLARE @no_of_customer INT = (
    SELECT COUNT(DISTINCT customer_id)
    FROM foodie_fi.subscriptions
);

WITH plan_date AS (
    SELECT s.customer_id, s.start_date, p.plan_id, p.plan_name,
        LEAD(s.start_date) OVER(PARTITION BY s.customer_id ORDER BY s.start_date) AS next_date
    FROM foodie_fi.subscriptions s
    INNER JOIN foodie_fi.plans p
        ON s.plan_id = p.plan_id
)

SELECT plan_id, plan_name,
    COUNT(*) AS customers,
    ROUND(CAST(COUNT(*) AS FLOAT) * 100 / @no_of_customer * 100, 2) AS conversion_rate
FROM plan_date
WHERE next_date IS NOT NULL
    AND start_date < '2020-12-31'
    AND next_date > '2020-12-31'
        OR (next_date IS NULL AND start_date < '2020-12-31')
GROUP BY plan_id, plan_name
ORDER BY plan_id;



-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT customer_id) AS customer_count
FROM foodie_fi.subscriptions s
INNER JOIN foodie_fi.plans p
    ON s.plan_id = p.plan_id
WHERE p.plan_name = 'pro annual' AND YEAR(s.start_date) = 2020;



-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
DROP TABLE IF EXISTS #trial_plan, #annual_plan;

SELECT s.customer_id, s.start_date AS trial_date
INTO #trial_plan
FROM foodie_fi.subscriptions s
INNER JOIN foodie_fi.plans p
    ON s.plan_id = p.plan_id
WHERE p.plan_name = 'trial';

SELECT s.customer_id, s.start_date AS annual_date
INTO #annual_plan
FROM foodie_fi.subscriptions s
INNER JOIN foodie_fi.plans p 
    ON s.plan_id = p.plan_id
WHERE p.plan_name = 'pro annual';

SELECT AVG(DATEDIFF(d, trial_date, annual_date)) AS avg_days_to_annual
FROM #trial_plan t
INNER JOIN #annual_plan a 
    ON t.customer_id = a.customer_id;



-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)?
DROP TABLE IF EXISTS #trial_plan, #annual_plan, #date_diff;

SELECT s.customer_id, s.start_date AS start_trial
INTO #trial_plan
FROM foodie_fi.subscriptions s
INNER JOIN foodie_fi.plans p
    ON s.plan_id = p.plan_id
WHERE p.plan_name = 'trial';

SELECT s.customer_id, s.start_date AS start_annual
INTO #annual_plan
FROM foodie_fi.subscriptions s
INNER JOIN foodie_fi.plans p
    ON s.plan_id = p.plan_id
WHERE p.plan_name = 'pro annual';

SELECT t.customer_id, DATEDIFF(d, t.start_trial, a.start_annual) AS diff
INTO #date_diff
FROM #trial_plan t
INNER JOIN #annual_plan a
    ON t.customer_id = a.customer_id;

WITH periods AS (
    SELECT 0 AS start_period, 
        30 AS end_period
    UNION ALL
    SELECT end_period + 1 AS start_period,
        end_period + 30 AS end_period
    FROM periods
    WHERE end_period < 360
)

SELECT p.start_period,
    p.end_period,
    COUNT(*) AS customer_count
FROM periods p
LEFT JOIN #date_diff d
    ON (d.diff >= p.start_period AND d.diff <= p.end_period)
GROUP BY p.start_period, p.end_period;



-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH next_plan AS (
    SELECT s.customer_id, s.start_date, p.plan_name,
        LEAD(p.plan_name) OVER(PARTITION BY s.customer_id ORDER BY p.plan_id) AS next_plan
    FROM foodie_fi.subscriptions s
    INNER JOIN foodie_fi.plans p
        ON s.plan_id = p.plan_id
)

SELECT COUNT(*) AS pro_monthly_to_basic_monthly
FROM next_plan
WHERE plan_name = 'pro monthly'
    AND next_plan = 'basic monthly'
    AND YEAR(start_date) = 2020;