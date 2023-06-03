-- 1. How many pizzas were ordered?
SELECT COUNT(order_id) AS no_of_pizza_ordered
FROM pizza_runner.customer_orders_cleaned;



-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT(order_id)) AS no_of_order
FROM pizza_runner.customer_orders_cleaned;



-- 3. How many successful orders were delivered by each runner?
SELECT runner_id,
	COUNT(order_id) AS successful_orders
FROM pizza_runner.runner_orders_cleaned
WHERE cancellation = ''
GROUP BY runner_id;



-- 4. How many of each type of pizza was delivered?
SELECT pizza_id,
	COUNT(pizza_id) AS no_of_delivered_pizza
FROM pizza_runner.customer_orders_cleaned AS c
INNER JOIN pizza_runner.runner_orders_cleaned AS r
	ON c.order_id = r.order_id
WHERE distance != 0
GROUP BY pizza_id;



-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT c.customer_id, p.pizza_name,
	COUNT(p.pizza_name) AS no_of_orders
FROM pizza_runner.customer_orders_cleaned AS c
INNER JOIN pizza_runner.pizza_names AS p
	ON c.pizza_id= p.pizza_id
GROUP BY c.customer_id, p.pizza_name
ORDER BY c.customer_id;



-- 6. What was the maximum number of pizzas delivered in a single order?
WITH no_of_pizzas AS (
SELECT c.order_id,
	COUNT(c.pizza_id) AS no_of_pizzas_per_order
FROM pizza_runner.customer_orders_cleaned AS c
INNER JOIN pizza_runner.runner_orders_cleaned AS r
	ON c.order_id = r.order_id
WHERE r.distance != 0
GROUP BY c.order_id
)

SELECT MAX(no_of_pizzas_per_order) AS max_no_of_pizzas_in_single_order
FROM no_of_pizzas;



-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT c.customer_id,
	SUM(CASE WHEN c.exclusions != '' OR c.extras != '' THEN 1
		ELSE 0 END) AS pizza_with_change,
	SUM(CASE WHEN c.exclusions = '' OR c.extras = '' THEN 1 
		ELSE 0 END) AS _pizza_without_change
FROM pizza_runner.customer_orders_cleaned AS c
INNER JOIN pizza_runner.runner_orders_cleaned AS r
	ON c.order_id = r.order_id
WHERE r.distance != 0
GROUP BY c.customer_id
ORDER BY c.customer_id;



-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT c.order_id, 
	SUM(CASE WHEN exclusions != '' AND extras != '' THEN 1
		ELSE 0 END) AS no_of_pizza_with_exclusions_extras
FROM pizza_runner.customer_orders_cleaned AS c
INNER JOIN pizza_runner.runner_orders_cleaned AS r
	ON c.order_id = r.order_id
WHERE r.distance >= 1 
	AND exclusions != '' 
	AND extras != '' 
GROUP BY c.order_id, c.pizza_id;



-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT DATEPART(HOUR, order_time) AS hour_of_day,
	COUNT(order_id) AS total_pizzas
FROM pizza_runner.customer_orders_cleaned
GROUP BY DATEPART(HOUR, order_time);



-- 10. What was the volume of orders for each day of the week?
SELECT DATEPART(DAY, order_time) AS day_of_week,
	COUNT(order_id) AS total_pizzas_ordered
FROM pizza_runner.customer_orders_cleaned
GROUP BY DATEPART(DAY, order_time);