-- 1. What is the unique count and total amount for each transaction type?
SELECT txn_type,
    COUNT(*) AS unique_count,
    SUM(txn_amount) AS total_amount
FROM data_bank.customer_transactions
GROUP BY txn_type;



-- 2. What is the average total historical deposit counts and amounts for all customers?
WITH customer_deposit AS (
    SELECT customer_id, txn_type,
        COUNT(*) AS deposit_count,
        SUM(txn_amount) AS deposit_amount
    FROM data_bank.customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id, txn_type
)

SELECT AVG(deposit_count) AS avg_deposit_count,
    AVG(deposit_amount) AS avg_deposit_amount
FROM customer_deposit;



-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH transactions AS (
    SELECT customer_id,
        MONTH(txn_date) AS months,
        SUM(CASE WHEN txn_type = 'deposit' THEN 1
        ELSE 0 END) AS deposit_count,
        SUM(CASE WHEN txn_type = 'purchase' THEN 1
        ELSE 0 END) AS purchase_count,
        SUM(CASE WHEN txn_type = 'withdrawal' THEN 1
        ELSE 0 END) AS withdrawal_count
    FROM data_bank.customer_transactions
    GROUP BY customer_id, MONTH(txn_date)
)

SELECT months,
    COUNT(customer_id) AS customer_count
FROM transactions
WHERE deposit_count > 1
    AND (purchase_count = 1 OR withdrawal_count = 1)
GROUP BY months;


-- 4. What is the closing balance for each customer at the end of the month?
WITH monthy_balance AS (
    SELECT customer_id,
        MONTH(txn_date) as txn_month,
        SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount
        ELSE -txn_amount END) AS net_amount
    FROM data_bank.customer_transactions
    GROUP BY customer_id, month(txn_date)
)

SELECT customer_id, txn_month, 
    SUM(net_amount) OVER (PARTITION BY customer_id ORDER BY txn_month) AS closing_balance
FROM monthy_balance;