-- 1. How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) AS unique_transactions
FROM balanced_tree.sales;



-- 2. What is the average unique products purchased in each transaction?
WITH product_count AS (
    SELECT txn_id,
        COUNT(DISTINCT prod_id) AS product_count
    FROM balanced_tree.sales 
    GROUP BY txn_id
)

SELECT AVG(product_count) AS avg_unique_products
FROM product_count;


-- 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
WITH transaction_revenue AS (
    SELECT txn_id,
        SUM(qty*price) AS revenue
    FROM balanced_tree.sales
    GROUP BY txn_id
)

SELECT DISTINCT PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY revenue) OVER () AS pctile_25,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue) OVER () AS pctile_50,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY revenue) OVER () AS pctile_75
FROM transaction_revenue;



-- 4. What is the average discount value per transaction?
WITH discount AS (
    SELECT txn_id,
        CAST(SUM(qty * price * (discount / 100.0)) AS DECIMAL(10, 2)) AS total_discount
    FROM balanced_tree.sales
    GROUP BY txn_id
)

SELECT CAST(AVG(total_discount) AS DECIMAL(10, 2)) AS avg_discount_per_transaction
FROM discount;



-- 5. What is the percentage split of all transactions for members vs non-members?
SELECT CAST(COUNT(DISTINCT CASE WHEN member = 't' THEN txn_id END) * 100.0 /
	    COUNT(DISTINCT txn_id) AS FLOAT) AS members_pct,
    100 - CAST(COUNT(DISTINCT CASE WHEN member = 't' THEN txn_id END) * 100.0 /
	    COUNT(DISTINCT txn_id) AS FLOAT) AS non_members_pct
FROM balanced_tree.sales;



-- 6. What is the average revenue for member transactions and non-member transactions?
WITH member_revenue AS (
    SELECT member, txn_id,
        SUM(qty*price) AS revenue
    FROM balanced_tree.sales
    GROUP BY member, txn_id
) 

SELECT member,
    CAST(AVG(revenue * 1.0) AS DECIMAL(5,2)) AS avg_revenue
FROM member_revenue
GROUP BY member;