-- 1. How many users are there?
SELECT COUNT(DISTINCT user_id) AS users_count
FROM clique_bait.users;



-- 2. How many cookies does each user have on average?
WITH cookie_count AS (
    SELECT user_id,
        CAST(COUNT(cookie_id) AS FLOAT) AS cookie_count
    FROM clique_bait.users
    GROUP BY user_id
)

SELECT CAST(AVG(cookie_count) AS FLOAT) AS avg_cookies_per_user
FROM cookie_count;



-- 3. What is the unique number of visits by all users per month?
SELECT MONTH(event_time) AS month_no,
    COUNT(DISTINCT visit_id) AS unique_visit_count
FROM clique_bait.events
GROUP BY MONTH(event_time)
ORDER BY month_no;



-- 4. What is the number of events for each event type?
SELECT e.event_type, i.event_name,
    COUNT(*) AS event_count
FROM clique_bait.events e
INNER JOIN clique_bait.event_identifier i
    ON e.event_type = i.event_type
GROUP BY e.event_type, i.event_name
ORDER BY e.event_type;



-- 5. What is the percentage of visits which have a purchase event?
DECLARE @visit_count INT = (
    SELECT COUNT(DISTINCT visit_id)
    FROM clique_bait.events
);

SELECT CAST(COUNT(DISTINCT e.visit_id) * 100.0 /
        @visit_count AS DECIMAL(10, 2)) AS visit_purchase_pct
FROM clique_bait.events e
INNER JOIN clique_bait.event_identifier i
    ON e.event_type = i.event_type
WHERE i.event_name = 'Purchase';



-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
DECLARE @visit_checkout_count INT = (
    SELECT COUNT(e.visit_id) AS visit_checkout_count
    FROM clique_bait.events e
    INNER JOIN clique_bait.event_identifier i
        ON e.event_type = i.event_type
    INNER JOIN clique_bait.page_hierarchy p
        ON e.page_id = p.page_id
    WHERE i.event_name = 'Page View'
        AND p.page_name = 'Checkout'
);

SELECT CAST(100 - (COUNT(DISTINCT e.visit_id) * 100.0 /
		@visit_checkout_count) AS DECIMAL(10, 2)) AS view_checkout_not_purchase_pct
FROM clique_bait.events e
INNER JOIN clique_bait.event_identifier i
    ON e.event_type = i.event_type
WHERE i.event_name = 'Purchase';



-- 7. What are the top 3 pages by number of views?
SELECT TOP 3 p.page_name,
    COUNT(*) AS page_view
FROM clique_bait.events e
INNER JOIN clique_bait.event_identifier i
    ON e.event_type = i.event_type 
INNER JOIN clique_bait.page_hierarchy p
    ON e.page_id = p.page_id
WHERE i.event_name = 'Page View'
GROUP BY p.page_name
ORDER BY page_view DESC;



-- 8. What is the number of views and cart adds for each product category?
SELECT p.product_category,
    SUM(CASE WHEN i.event_name = 'Page View' THEN 1
        ELSE 0 END) AS page_view,
    SUM(CASE WHEN i.event_name = 'Add to Cart' THEN 1
        ELSE 0 END) AS cart_add
FROM clique_bait.events e
INNER JOIN clique_bait.event_identifier i
    ON e.event_type = i.event_type
INNER JOIN clique_bait.page_hierarchy p
    ON e.page_id = p.page_id
WHERE p.product_category IS NOT NULL
GROUP BY p.product_category;



-- 9. What are the top 3 products by purchases?
WITH purchase_list AS (
    SELECT e.visit_id
    FROM clique_bait.events e
    INNER JOIN clique_bait.event_identifier i
        ON e.event_type = i.event_type
    WHERE i.event_name = 'Purchase'
)

SELECT TOP 3 p.product_id, p.page_name, p.product_category,
    COUNT(*) AS purchase_count
FROM clique_bait.events e
INNER JOIN clique_bait.event_identifier i
    ON e.event_type = i.event_type
INNER JOIN clique_bait.page_hierarchy p
    ON e.page_id = p.page_id
INNER JOIN purchase_list l
    ON e.visit_id = l.visit_id
WHERE i.event_name = 'Add to cart'
GROUP BY p.product_id, p.page_name, p.product_category
ORDER BY purchase_count DESC;