-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, 
	SUM(price) AS total_pay
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
	ON s.product_id = m.product_id
GROUP BY customer_id;



-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, 
	COUNT(DISTINCT(order_date)) AS visit_per_day
FROM dannys_diner.sales
GROUP BY customer_id;



-- 3. What was the first item from the menu purchased by each customer?
WITH sales_item AS (
	SELECT s.customer_id, s.order_date, m.product_name,
		DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
	FROM dannys_diner.sales AS s
	INNER JOIN dannys_diner.menu AS m
		ON s.product_id = m.product_id
)

SELECT customer_id, product_name
FROM sales_item
WHERE rank = 1
GROUP BY customer_id, product_name;



-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT TOP 1 (COUNT(s.product_id)) AS most_purchased_item,
	m.product_name
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
	ON s.product_id = m.product_id
GROUP BY s.product_id, m.product_name
ORDER BY most_purchased_item DESC;



-- 5. Which item was the most popular for each customer?
WITH fav_item AS (
	SELECT s.customer_id, m.product_name, 
    	COUNT(m.product_id) AS order_count,
		DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) AS rank
	FROM dannys_diner.menu AS m
	INNER JOIN dannys_diner.sales AS s
	ON m.product_id = s.product_id
	GROUP BY s.customer_id, m.product_name
)

SELECT customer_id, product_name, order_count
FROM fav_item 
WHERE rank = 1
ORDER BY customer_id;



-- 6. Which item was purchased first by the customer after they became a member?
WITH member_sales AS (
	SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
    	DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
	 FROM dannys_diner.sales AS s
	INNER JOIN dannys_diner.members AS m
		ON s.customer_id = m.customer_id
	WHERE s.order_date >= m.join_date)

SELECT cte.customer_id, cte.order_date, mn.product_name 
FROM member_sales AS cte
INNER JOIN dannys_diner.menu AS mn
  ON cte.product_id = mn.product_id
WHERE rank = 1;



-- 7. Which item was purchased just before the customer became a member?
WITH prior_member_purchased AS (
	SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
    	DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rank
	FROM dannys_diner.sales AS s
	INNER JOIN dannys_diner.members AS m
		ON s.customer_id = m.customer_id
	WHERE s.order_date < m.join_date
)

SELECT cte.customer_id, cte.order_date, mn.product_name 
FROM prior_member_purchased AS cte
INNER JOIN dannys_diner.menu AS mn
	ON cte.product_id = mn.product_id
WHERE rank = 1;



-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, 
	COUNT(DISTINCT s.product_id) AS unique_menu_item, 
	SUM(mn.price) AS total_sales
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.members AS mb
	ON s.customer_id = mb.customer_id
INNER JOIN dannys_diner.menu AS mn
	ON s.product_id = mn.product_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id;



-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH price_points AS (
	SELECT *, 
		CASE
			WHEN product_name = 'sushi' THEN price * 20
			ELSE price * 10
			END AS points
	FROM dannys_diner.menu
)

SELECT s.customer_id, 
	SUM(cte.points) AS total_points
FROM price_points AS cte
INNER JOIN dannys_diner.sales AS s
	ON cte.product_id = s.product_id
GROUP BY s.customer_id;



-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi -
-- how many points do customer A and B have at the end of January?
WITH dates AS (
	SELECT *, 
    	DATEADD(DAY, 6, join_date) AS valid_date, 
		EOMONTH('2021-01-31') AS last_date
	FROM dannys_diner.members
)

SELECT cte.customer_id, s.order_date, cte.join_date, cte.valid_date, cte.last_date,
	m.product_name, m.price,
	SUM(CASE
		WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
		WHEN s.order_date BETWEEN cte.join_date AND cte.valid_date THEN 2 * 10 * m.price
		ELSE 10 * m.price END) AS points
FROM dates AS cte
INNER JOIN dannys_diner.sales AS s
	ON cte.customer_id = s.customer_id
INNER JOIN dannys_diner.menu AS m
	ON s.product_id = m.product_id
WHERE s.order_date < cte.last_date
GROUP BY cte.customer_id, s.order_date, cte.join_date, cte.valid_date, cte.last_date, m.product_name, m.price;