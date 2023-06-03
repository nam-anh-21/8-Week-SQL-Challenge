/* Using a single SQL query - create a new output table which has the following details:
- How many times was each product viewed?
- How many times was each product added to cart?
- How many times was each product added to a cart but not purchased (abandoned)?
- How many times was each product purchased? */
DROP TABLE IF EXISTS #prod_viewed_cart_added, #prod_abandoned, #prod_purchased, clique_bait.product_status;

SELECT p.product_id, p.page_name AS product_name, p.product_category,
    SUM(CASE WHEN i.event_name = 'Page View' THEN 1
        ELSE 0 END) AS viewed,
    SUM(CASE WHEN i.event_name = 'Add To Cart' THEN 1
        ELSE 0 END) AS cart_added
INTO #prod_viewed_cart_added
FROM clique_bait.events e
INNER JOIN clique_bait.event_identifier i
    ON e.event_type = i.event_type
INNER JOIN clique_bait.page_hierarchy p
    ON e.page_id = p.page_id
WHERE p.product_category IS NOT NULL
GROUP BY p.product_id, p.page_name, p.product_category;

SELECT p.product_id, p.page_name AS product_name, p.product_category,
    COUNT(*) AS abandoned
INTO #prod_abandoned
FROM clique_bait.events e
INNER JOIN clique_bait.event_identifier i
    ON e.event_type = i.event_type
INNER JOIN clique_bait.page_hierarchy p
    ON e.page_id = p.page_id
WHERE i.event_name = 'Add to cart'
AND e.visit_id NOT IN (
    SELECT e.visit_id
    FROM clique_bait.events e
    INNER JOIN clique_bait.event_identifier i
        ON e.event_type = i.event_type
    WHERE i.event_name = 'Purchase'
    )
GROUP BY p.product_id, p.page_name, p.product_category;

SELECT p.product_id, p.page_name AS product_name, p.product_category,
    COUNT(*) AS purchased
INTO #prod_purchased
FROM clique_bait.events e
INNER JOIN clique_bait.event_identifier i
    ON e.event_type = i.event_type
INNER JOIN clique_bait.page_hierarchy p
    ON e.page_id = p.page_id
WHERE i.event_name = 'Add to cart'
AND e.visit_id IN (
    SELECT e.visit_id
    FROM clique_bait.events e
    INNER JOIN clique_bait.event_identifier i
        ON e.event_type = i.event_type
    WHERE i.event_name = 'Purchase'
    )
GROUP BY p.product_id, p.page_name, p.product_category

SELECT va.*, ab.abandoned, pc.purchased
INTO clique_bait.product_status
FROM #prod_viewed_cart_added va
INNER JOIN #prod_abandoned ab
    ON va.product_id = ab.product_id
INNER JOIN #prod_purchased pc
    ON va.product_id = pc.product_id;

SELECT *
FROM clique_bait.product_status;



/* Additionally, create another table which further aggregates the data for the above points 
but this time for each product category instead of individual products. */
DROP TABLE IF EXISTS #cate_viewed_cart_added, #cate_abandoned, #cate_purchased, clique_bait.category_status;

SELECT p.product_category,
    SUM(CASE WHEN i.event_name = 'Page View' THEN 1
        ELSE 0 END) AS viewed,
    SUM(CASE WHEN i.event_name = 'Add To Cart' THEN 1
        ELSE 0 END) AS cart_added
INTO #cate_viewed_cart_added
FROM clique_bait.events e
INNER JOIN clique_bait.event_identifier i
    ON e.event_type = i.event_type
INNER JOIN clique_bait.page_hierarchy p
    ON e.page_id = p.page_id
WHERE p.product_category IS NOT NULL
GROUP BY p.product_category;

SELECT p.product_category,
    COUNT(*) AS abandoned
INTO #cate_abandoned
FROM clique_bait.events e
INNER JOIN clique_bait.event_identifier i
    ON e.event_type = i.event_type
INNER JOIN clique_bait.page_hierarchy p
    ON e.page_id = p.page_id
WHERE i.event_name = 'Add to cart'
AND e.visit_id NOT IN (
    SELECT e.visit_id
    FROM clique_bait.events e
    INNER JOIN clique_bait.event_identifier i
        ON e.event_type = i.event_type
    WHERE i.event_name = 'Purchase'
    )
  GROUP BY p.product_category;

SELECT p.product_category,
    COUNT(*) AS purchased
INTO #cate_purchased
FROM clique_bait.events e
INNER JOIN clique_bait.event_identifier i
    ON e.event_type = i.event_type
INNER JOIN clique_bait.page_hierarchy p
     ON e.page_id = p.page_id
WHERE i.event_name = 'Add to cart'
AND e.visit_id IN (
    SELECT e.visit_id
    FROM clique_bait.events e
    INNER JOIN clique_bait.event_identifier i ON e.event_type = i.event_type
    WHERE i.event_name = 'Purchase'
    )
  GROUP BY p.product_category

SELECT va.*, ab.abandoned, pc.purchased
INTO clique_bait.category_status
FROM #cate_viewed_cart_added va
INNER JOIN #cate_abandoned ab
    ON va.product_category = ab.product_category
INNER JOIN #cate_purchased pc
    ON va.product_category = pc.product_category;

SELECT *
FROM clique_bait.category_status;



-- 1. Which product had the most views, cart adds and purchases?
WITH most_views AS (
    SELECT TOP 1 *,  'most views' AS most_status
    FROM clique_bait.product_status
    ORDER BY viewed DESC
), most_cart_adds AS (
    SELECT TOP 1 *,  'most cart adds' AS most_status
    FROM clique_bait.product_status
    ORDER BY cart_added DESC
), most_purchased AS(
    SELECT TOP 1 *,  'most purchases' AS most_status
    FROM clique_bait.product_status
    ORDER BY purchased DESC
)

SELECT *
FROM most_views
UNION ALL
SELECT *
FROM most_cart_adds
UNION ALL
SELECT *
FROM most_purchased;



-- 2. Which product was most likely to be abandoned?
SELECT TOP 1 *
FROM clique_bait.product_status
ORDER BY abandoned DESC;



-- 3. Which product had the highest view to purchase percentage?
SELECT TOP 1 product_name,
    product_id,
    CAST(purchased * 100.0 /
        viewed AS DECIMAL(10, 2)) AS view_to_purchase_pct
FROM clique_bait.product_status
ORDER BY view_to_purchase_pct DESC;



-- 4. What is the average conversion rate from view to cart add?
SELECT CAST(AVG(cart_added * 100.0 /
    viewed) AS DECIMAL(10, 2)) AS avg_view_to_cart
FROM clique_bait.product_status;



-- 5. What is the average conversion rate from cart add to purchase?
SELECT CAST(AVG(purchased * 100.0 /
    cart_added) AS DECIMAL(10, 2)) AS avg_view_to_cart
FROM clique_bait.product_status;