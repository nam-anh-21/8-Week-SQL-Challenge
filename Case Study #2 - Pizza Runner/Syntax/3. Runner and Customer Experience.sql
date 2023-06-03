-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT runner_id,
	CASE
		WHEN registration_date BETWEEN '2021-01-01' AND '2021-01-07' THEN 'Week 1'
		WHEN registration_date BETWEEN '2021-01-08' AND '2021-01-14'THEN 'Week 2'
		ELSE 'Week 3'
		END AS runner_signups
FROM pizza_runner.runners
GROUP BY registration_date, runner_id;



-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
WITH time_taken AS (
	SELECT r.runner_id, c.order_id,	c.order_time,	r.pickup_time,
		DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS mins_taken_to_arrive_HQ
	FROM pizza_runner.customer_orders_cleaned AS c
	INNER JOIN pizza_runner.runner_orders_cleaned AS r
		ON c.order_id = r.order_id
	WHERE r.distance != 0
	GROUP BY r.runner_id, c.order_id, c.order_time, r.pickup_time
)

SELECT runner_id,
	AVG(mins_taken_to_arrive_HQ) AS avg_mins_taken_to_arrive_HQ
FROM time_taken
WHERE mins_taken_to_arrive_HQ > 1
GROUP BY runner_id;



-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
/* Answer:
- The more pizza ordered, the more time it takes to prepare.
- Based on the result, t = (n - 1) * 6
	t: the time to prepare the next pizza (min)
	n: the ordinal number of the next pizza (n > 1) */
WITH prepare_time AS (
	SELECT c.order_id, c.order_time, r.pickup_time,
		COUNT(c.order_id) AS no_pizza_ordered,
		DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS time_taken_to_prepare
	FROM pizza_runner.customer_orders_cleaned AS c
	INNER JOIN pizza_runner.runner_orders_cleaned AS r
		ON c.order_id = r.order_id
	WHERE r.distance != 0
	GROUP BY c.order_id, c.order_time, r.pickup_time
)

SELECT no_pizza_ordered,
	AVG(time_taken_to_prepare) AS avg_time_to_prepare
FROM prepare_time
WHERE time_taken_to_prepare > 1
GROUP BY no_pizza_ordered;



-- 4. What was the average distance travelled for each customer?
SELECT c.customer_id,
	ROUND(AVG(r.distance), 2) AS avg_distance
FROM pizza_runner.customer_orders_cleaned AS c
INNER JOIN pizza_runner.runner_orders_cleaned AS r
	ON c.order_id = r.order_id
WHERE duration != 0
GROUP BY c.customer_id;



-- 5. What was the difference between the longest and shortest delivery times for all orders?
WITH delivery_time AS (
	SELECT r.runner_id,	c.order_id,	c.order_time, r.pickup_time,
		DATEDIFF(MINUTE, c.order_time, r.pickup_time) AS delivery_time
	FROM pizza_runner.customer_orders_cleaned AS c
	INNER JOIN pizza_runner.runner_orders_cleaned AS r
		ON c.order_id = r.order_id
	WHERE r.distance != 0
	GROUP BY r.runner_id, c.order_id, c.order_time, r.pickup_time
)	

SELECT (MAX(delivery_time) - MIN(delivery_time)) AS longest_shortest_delivery_time_diff
FROM delivery_time
WHERE delivery_time > 1;



-- 6. What was the average speed for each runner for each delivery?
SELECT r.runner_id, c.order_id,	duration,
	COUNT(c.order_id) AS pizza_count,
	distance * 1000 AS distance_meter,
	ROUND((distance * 1000 / duration), 2) AS avg_speed
FROM pizza_runner.runner_orders_cleaned AS r
INNER JOIN pizza_runner.customer_orders_cleaned AS c
	ON r.order_id = c.order_id
WHERE distance != 0
GROUP BY runner_id, c.order_id, distance, duration
ORDER BY runner_id, pizza_count, avg_speed;



-- 7. What is the successful delivery percentage for each runner?
WITH delivery_check AS (
SELECT runner_id,
	COUNT(order_id) AS total_delivery,
	SUM(CASE WHEN distance != 0 THEN 1
		ELSE distance END) AS successful_delivery,
	SUM(CASE WHEN cancellation LIKE '%Cancel%' THEN 1 
		ELSE cancellation END) AS failed_delivery
FROM pizza_runner.runner_orders_cleaned
GROUP BY runner_id, order_id
)

SELECT runner_id,
	(SUM(successful_delivery) / SUM(total_delivery)) * 100 AS successful_delivery_pct
FROM delivery_check
GROUP BY runner_id;