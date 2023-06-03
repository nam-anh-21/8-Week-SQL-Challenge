-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
SELECT s.customer_id, s.start_date, p.plan_name, p.price
FROM foodie_fi.subscriptions s
INNER JOIN foodie_fi.plans p
    ON s.plan_id = p.plan_id
WHERE customer_id IN (1, 2, 15, 17, 24, 30, 48, 60);



/* Analysis:

1. Customer 1:
- The user signed up for free trial on 2020-08-01. 
- After trial, they upgraded to basic monthly plan on 2020-08-08 and have been maintaining this plan.

2. Customer 2:
- The user signed up for free trial on 2020-09-20. 
- After trial, they upgraded to pro annual plan on 2020-09-27 and have been maintaining this plan.

3. Customer 15:
- The user signed up for free trial on 2020-03-17. 
- After trial, they upgraded to pro monthly plan on 2020-03-24.
- After more than 1 month, they cancelled the service on 2020-04-29.

4. Customer 17:
- The user signed up for free trial on 2020-07-27. 
- After trial, they upgraded to basic monthly plan on 2020-08-03.
- After 3 months, they upgraded to pro annual plan on 2020-12-11 and have been maintaining this plan.

5. Customer 24:
- The user signed up for free trial on 2020-11-10.
- After trial, they upgraded to pro monthly plan on 2020-11-17.
- After 5 months, they upgraded to pro annual plan on 2021-04-17 and have been maintaining this plan.

6. Customer 30:
- The user signed up for free trial on 2020-04-29.
- After trial, they upgraded to basic monthly plan on 2020-05-06 and have been maintaining this plan.

7. Customer 48:
- The user signed up for free trial on 2020-01-11.
- After trial, they upgraded to basic monthly plan on 2020-01-18.
- After 5 months, they cancelled the service on 2020-06-01.

8. Customer 60:
- The user signed up for free trial on 2020-06-17.
- After trial, they upgraded to basic monthly plan on 2020-06-24 and have been maintaining this plan. */