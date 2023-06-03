-- 1. Clean customer_orders
DROP TABLE IF EXISTS pizza_runner.customer_orders_cleaned;

SELECT order_id, customer_id, pizza_id, order_time,
	CASE
		WHEN exclusions = 'null'
			OR exclusions IS NULL
			THEN ''
    	ELSE exclusions
		END AS exclusions,
	CASE WHEN extras = 'null'
			OR extras IS NULL
			THEN ''
		ELSE extras
		END AS extras
INTO pizza_runner.customer_orders_cleaned
FROM pizza_runner.customer_orders;

SELECT *
FROM pizza_runner.customer_orders_cleaned;



-- 2. Clean runner_orders
DROP TABLE IF EXISTS pizza_runner.runner_orders_cleaned;

SELECT order_id, runner_id,  
	CASE
		WHEN pickup_time = 'null' THEN ''
		ELSE pickup_time
		END AS pickup_time,
	CASE
		WHEN distance = 'null' THEN ''
		WHEN distance LIKE '%km' THEN TRIM('km' FROM distance)
		ELSE distance
		END AS distance,
	CASE
		WHEN duration = 'null' THEN ''
		WHEN duration LIKE '%mins' THEN TRIM('mins' FROM duration)
		WHEN duration LIKE '%minute' THEN TRIM('minute' FROM duration)
		WHEN duration LIKE '%minutes' THEN TRIM('minutes' FROM duration)
		ELSE duration
		END AS duration,
	CASE
		WHEN cancellation IS NULL
			OR cancellation = 'null'
			THEN ''
		ELSE cancellation
		END AS cancellation
INTO pizza_runner.runner_orders_cleaned
FROM pizza_runner.runner_orders;

ALTER TABLE pizza_runner.runner_orders_cleaned
ALTER COLUMN pickup_time DATETIME;

ALTER TABLE pizza_runner.runner_orders_cleaned
ALTER COLUMN distance FLOAT;

ALTER TABLE pizza_runner.runner_orders_cleaned
ALTER COLUMN duration INT

SELECT *
FROM pizza_runner.runner_orders_cleaned;