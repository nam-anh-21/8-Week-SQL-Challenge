-- 1. How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM data_bank.customer_nodes;



-- 2. What is the number of nodes per region?
SELECT r.region_id, r.region_name,
    COUNT(n.node_id) AS nodes_count
FROM data_bank.customer_nodes n
INNER JOIN data_bank.regions r
    ON n.region_id = r.region_id
GROUP BY r.region_id, r.region_name
ORDER BY r.region_id;



-- 3. How many customers are allocated to each region?
SELECT r.region_id, r.region_name,
    COUNT(DISTINCT n.customer_id) AS customers_count
FROM data_bank.customer_nodes n
INNER JOIN data_bank.regions r
    ON n.region_id = r.region_id
GROUP BY r.region_id, r.region_name
ORDER BY r.region_id;



-- 4. How many days on average are customers reallocated to a different node?
DROP TABLE IF EXISTS #customer_dates;

SELECT customer_id, region_id, node_id,
    MIN(start_date) AS first_date
INTO #customer_dates
FROM data_bank.customer_nodes
GROUP BY customer_id, region_id, node_id;

WITH reallocation AS (
    SELECT customer_id, node_id, region_id, first_date,
        DATEDIFF(DAY, first_date, 
        LEAD(first_date) OVER(PARTITION BY customer_id ORDER BY first_date)) AS moving_day
  FROM #customer_dates
)

SELECT ROUND(AVG(CAST(moving_day AS FLOAT)), 2) AS avg_moving_day
FROM reallocation;



-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
DROP TABLE IF EXISTS #customer_dates;

SELECT customer_id, region_id, node_id,
    MIN(start_date) AS first_date
INTO #customer_dates
FROM data_bank.customer_nodes
GROUP BY customer_id, region_id, node_id;

WITH reallocation AS (
    SELECT customer_id, node_id, region_id, first_date,
        DATEDIFF(DAY, first_date, 
        LEAD(first_date) OVER(PARTITION BY customer_id ORDER BY first_date)) AS moving_days
  FROM #customer_dates
)

SELECT DISTINCT re.region_id, rg.region_name,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY re.moving_days) OVER(PARTITION BY re.region_id), 2) AS median,
    ROUND(PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY re.moving_days) OVER(PARTITION BY re.region_id), 2) AS pctile_80,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY re.moving_days) OVER(PARTITION BY re.region_id), 2) AS pctile_95
FROM reallocation re
INNER JOIN data_bank.regions rg ON re.region_id = rg.region_id
WHERE moving_days IS NOT NULL;