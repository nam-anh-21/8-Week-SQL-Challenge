-- 1. What are the top 3 products by total revenue before discount?
SELECT TOP 3 d.product_name,
    SUM(s.qty * s.price) AS revenue_before_discount
FROM balanced_tree.sales s
INNER JOIN balanced_tree.product_details d 
    ON s.prod_id = d.product_id
GROUP BY d.product_name
ORDER BY SUM(s.qty * s.price) DESC;



-- 2. What is the total quantity, revenue and discount for each segment?
SELECT d.segment_name,
    SUM(s.qty) AS total_quantity,
    SUM(s.qty * s.price) AS total_revenue_before_discount,
    CAST(SUM(s.qty * s.price * (discount / 100.0)) AS DECIMAL(10, 2)) AS total_discount
FROM balanced_tree.sales s
INNER JOIN balanced_tree.product_details d 
    ON s.prod_id = d.product_id
GROUP BY d.segment_name;



-- 3. What is the top selling product for each segment?
WITH segnment_product_sales AS (
SELECT d.segment_name, d.product_name,
    SUM(s.qty) AS total_quantity,
    DENSE_RANK() OVER (PARTITION BY d.segment_name ORDER BY SUM(s.qty) DESC) AS rank
FROM balanced_tree.sales s
INNER JOIN balanced_tree.product_details d 
    ON s.prod_id = d.product_id
GROUP BY d.segment_name, d.product_name
)

SELECT segment_name, product_name AS top_selling_product, total_quantity
FROM segnment_product_sales
WHERE rank = 1;



-- 4. What is the total quantity, revenue and discount for each category?
SELECT d.category_name,
    SUM(s.qty) AS total_quantity,
    SUM(s.qty * s.price) AS total_revenue,
    CAST(SUM(s.qty * s.price * (discount / 100.0)) AS DECIMAL(10, 2)) AS total_discount
FROM balanced_tree.sales s
INNER JOIN balanced_tree.product_details d 
  ON s.prod_id = d.product_id
GROUP BY d.category_name;



-- 5. What is the top selling product for each category?
WITH category_product_sales AS (
    SELECT d.category_name, d.product_name,
        SUM(s.qty) AS quantity,
        DENSE_RANK() OVER (PARTITION BY d.category_name ORDER BY SUM(s.qty) DESC) AS rank
    FROM balanced_tree.sales s
    INNER JOIN balanced_tree.product_details d 
        ON s.prod_id = d.product_id
    GROUP BY d.category_name, d.product_name
)

SELECT category_name, product_name AS top_selling_product, quantity
FROM category_product_sales
WHERE rank = 1;



-- 6. What is the percentage split of revenue by product for each segment?
WITH segment_product_revenue AS (
    SELECT d.segment_name, d.product_name,
        SUM(s.qty * s.price) AS product_revenue
    FROM balanced_tree.sales s
    INNER JOIN balanced_tree.product_details d 
        ON s.prod_id = d.product_id
    GROUP BY d.segment_name, d.product_name
)

SELECT segment_name, product_name,
    CAST(product_revenue * 100.0 /
        SUM(product_revenue) OVER (PARTITION BY segment_name) AS DECIMAL(10, 2)) AS segment_product_pct
FROM segment_product_revenue;



-- 7. What is the percentage split of revenue by segment for each category?
WITH category_segment_revenue AS (
    SELECT d.category_name, d.segment_name,
        SUM(s.qty * s.price) AS segment_revenue
    FROM balanced_tree.sales s
    INNER JOIN balanced_tree.product_details d 
        ON s.prod_id = d.product_id
    GROUP BY d.category_name, d.segment_name
)

SELECT category_name, segment_name,
    CAST(segment_revenue * 100.0 /
        SUM(segment_revenue) OVER (PARTITION BY category_name) AS DECIMAL(10, 2)) AS category_segment_pct
FROM category_segment_revenue;



-- 8. What is the percentage split of total revenue by category?
WITH category_revenue AS (
    SELECT d.category_name,
        SUM(s.qty * s.price) AS revenue
    FROM balanced_tree.sales s
    INNER JOIN balanced_tree.product_details d 
        ON s.prod_id = d.product_id
    GROUP BY d.category_name
)

SELECT category_name,
    CAST(revenue * 100.0 /
        SUM(revenue) OVER () AS DECIMAL(10, 2)) AS category_pct
FROM category_revenue;



-- 9. What is the total transaction “penetration” for each product?
-- (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
DECLARE @total_txn INT = (
    SELECT COUNT(DISTINCT txn_id)
    FROM balanced_tree.sales
);


WITH product_transactions AS (
    SELECT DISTINCT s.prod_id, d.product_name,
        COUNT(DISTINCT s.txn_id) AS product_txn
    FROM balanced_tree.sales s
    INNER JOIN balanced_tree.product_details d 
        ON s.prod_id = d.product_id
    GROUP BY prod_id, d.product_name
)

SELECT *,
    CAST(product_txn * 100.0 /
        @total_txn AS DECIMAL(10, 2)) AS penetration_pct
FROM product_transactions;