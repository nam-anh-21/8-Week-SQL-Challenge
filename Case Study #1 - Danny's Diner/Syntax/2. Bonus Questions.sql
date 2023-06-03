-- 1. Join all the things
SELECT s.customer_id, s.order_date, mn.product_name, mn.price,
	CASE
		WHEN mb.join_date > s.order_date THEN 'N'
		WHEN mb.join_date <= s.order_date THEN 'Y'
		ELSE 'N'
		END AS member
FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.menu AS mn
	ON s.product_id = mn.product_id
LEFT JOIN dannys_diner.members AS mb
	ON s.customer_id = mb.customer_id
ORDER BY s.customer_id, s.order_date;



-- 2. Rank all the things
WITH summary AS (
	SELECT s.customer_id, s.order_date, mn.product_name, mn.price,
		CASE
			WHEN mb.join_date > s.order_date THEN 'N'
	    	WHEN mb.join_date <= s.order_date THEN 'Y'
	    	ELSE 'N'
			END AS member
FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.menu AS mn
	ON s.product_id = mn.product_id
LEFT JOIN dannys_diner.members AS mb
	ON s.customer_id = mb.customer_id
)

SELECT *,
	CASE
		WHEN member = 'N' then NULL
    	ELSE RANK () OVER(PARTITION BY customer_id, member ORDER BY order_date)
		END AS ranking
FROM summary;