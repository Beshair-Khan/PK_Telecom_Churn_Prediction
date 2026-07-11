-- Customers
INSERT INTO customers (customer_id, customer_name, customer_cnic, phone_number, email, age, signup_date, operator, plan_type, city, status)
SELECT
    customer_id,
    first_name || ' ' || last_name AS customer_name,
    customer_cnic,
    phone_number,
    CASE
        WHEN random() < 0.3 THEN NULL
        ELSE LOWER(first_name) || n::text || '@gmail.com'
    END AS email,
    age,
    signup_date,
    operator,
    plan_type,
    city,
    status
FROM (
    SELECT
        n,
        'CUST' || LPAD(n::text, 5, '0') AS customer_id,
        (ARRAY['Ahmed','Ali','Hassan','Bilal','Usman','Fatima','Ayesha','Zainab','Sana','Mariam'])
            [FLOOR(random() * 10 + 1)] AS first_name,
        (ARRAY['Khan','Malik','Sheikh','Butt','Chaudhry','Raza','Iqbal','Farooq'])
            [FLOOR(random() * 8 + 1)] AS last_name,
        LPAD(FLOOR(random() * 100000)::text, 5, '0') || '-' ||
        LPAD(FLOOR(random() * 10000000)::text, 7, '0') || '-' ||
        FLOOR(random() * 10)::text AS customer_cnic,
        '03' || LPAD(FLOOR(random() * 1000000000)::text, 9, '0') AS phone_number,
        CASE
            WHEN random() < 0.03 THEN NULL
            WHEN random() < 0.05 THEN FLOOR(random() * 100 + 100)::int
            ELSE FLOOR(random() * 47 + 18)::int
        END AS age,
        (DATE '2021-01-01' + (random() * (DATE '2026-07-11' - DATE '2021-01-01'))::int) AS signup_date,
        CASE
            WHEN random() < 0.35 THEN 'Jazz'
            WHEN random() < 0.60 THEN 'Zong'
            WHEN random() < 0.85 THEN 'Ufone'
            ELSE 'Telenor'
        END AS operator,
        CASE
            WHEN random() < 0.85 THEN 'prepaid'
            ELSE 'postpaid'
        END AS plan_type,
        CASE FLOOR(random() * 6 + 1)::int
            WHEN 1 THEN (CASE WHEN random() < 0.7 THEN 'Karachi' WHEN random() < 0.85 THEN 'karachi' ELSE 'KHI' END)
            WHEN 2 THEN (CASE WHEN random() < 0.7 THEN 'Lahore' WHEN random() < 0.85 THEN 'lahor' ELSE 'LHR' END)
            WHEN 3 THEN (CASE WHEN random() < 0.7 THEN 'Islamabad' WHEN random() < 0.85 THEN 'islamabad' ELSE 'ISL' END)
            WHEN 4 THEN 'Rawalpindi'
            WHEN 5 THEN 'Faisalabad'
            ELSE 'Multan'
        END AS city,
        CASE
            WHEN random() < 0.75 THEN 'active'
            WHEN random() < 0.97 THEN 'churned'
            ELSE 'suspended'
        END AS status
    FROM generate_series(1, 100000) AS n
) AS base
ON CONFLICT (customer_id) DO NOTHING;
INSERT INTO customers (customer_id, customer_name, customer_cnic, phone_number, email, age, signup_date, operator, plan_type, city, status)
SELECT
    'CUST' || LPAD((100000 + ROW_NUMBER() OVER())::text, 6, '0') AS customer_id,
    customer_name,
    customer_cnic,
    phone_number,
    email,
    age,
    signup_date,
    operator,
    plan_type,
    city,
    status
FROM customers
WHERE random() < 0.02
ON CONFLICT (customer_id) DO NOTHING;
select count(*) from customers;
--Plans
INSERT INTO plans (plan_id, operator, plan_type, monthly_price, data_cap_gb, minutes_included) VALUES
('PLAN001', 'Jazz', 'prepaid', 350.00, 8, 500),
('PLAN002', 'Jazz', 'prepaid', 850.00, 24, 1500),
('PLAN003', 'Jazz', 'postpaid', 1500.00, 50, 3000),
('PLAN004', 'Jazz', 'postpaid', 3000.00, 9999, 9999),
('PLAN005', 'Zong', 'prepaid', 300.00, 8, 500),
('PLAN006', 'Zong', 'prepaid', 800.00, 24, 1500),
('PLAN007', 'Zong', 'postpaid', 1400.00, 50, 3000),
('PLAN008', 'Zong', 'postpaid', 2800.00, 9999, 9999),
('PLAN009', 'Ufone', 'prepaid', 320.00, 6, 400),
('PLAN010', 'Ufone', 'prepaid', 780.00, 20, 1200),
('PLAN011', 'Ufone', 'postpaid', 1300.00, 40, 2500),
('PLAN012', 'Ufone', 'postpaid', 2500.00, 9999, 9999),
('PLAN013', 'Telenor', 'prepaid', 280.00, 6, 400),
('PLAN014', 'Telenor', 'prepaid', 750.00, 20, 1200),
('PLAN015', 'Telenor', 'postpaid', 1200.00, 40, 2500),
('PLAN016', 'Telenor', 'postpaid', 2400.00, 9999, 9999);
select count(*) from plans;
UPDATE customers c
SET plan_id = (
    SELECT p.plan_id
    FROM plans p
    WHERE p.operator = c.operator
      AND p.plan_type = c.plan_type
    ORDER BY random()
    LIMIT 1
);
--Recharge
INSERT INTO recharges (recharge_id, customer_id, amount_pkr, recharge_date, channel)
SELECT
    'RCH' || LPAD(ROW_NUMBER() OVER ()::text, 8, '0') AS recharge_id,
    sub.customer_id,
    CASE 
        WHEN random() < 0.02 THEN -1 * (ARRAY[50,100,150,200,300,500,1000])[FLOOR(random()*7+1)::int]
        ELSE (ARRAY[50,100,150,200,300,500,1000])[FLOOR(random()*7+1)::int]
    END::decimal(10,2) AS amount_pkr,
    (sub.signup_date + (random() * (sub.end_date - sub.signup_date))::int) AS recharge_date,
    (ARRAY['Easypaisa','JazzCash','Retailer','Bank Transfer','easypaisa','EP'])[FLOOR(random()*6+1)::int] AS channel
FROM (
    SELECT 
        c.customer_id,
        c.signup_date,
        CASE 
            WHEN c.status = 'churned' 
            THEN c.signup_date + ((CURRENT_DATE - c.signup_date) * (0.3 + random()*0.4))::int
            ELSE CURRENT_DATE
        END AS end_date,
        CASE 
            WHEN c.status = 'churned' THEN FLOOR(random()*5+1)::int
            ELSE FLOOR(random()*39+2)::int
        END AS num_recharges
    FROM customers c
    WHERE c.plan_type = 'prepaid'
) sub
CROSS JOIN LATERAL generate_series(1, sub.num_recharges) AS g
ON CONFLICT (recharge_id) DO NOTHING;
--Invoices
INSERT INTO invoices (invoice_id, customer_id, billing_month, amount_due, amount_paid, payment_date, late_flag)
SELECT
    'INV' || LPAD(ROW_NUMBER() OVER ()::text, 8, '0') AS invoice_id,
    sub.customer_id,
    (sub.signup_date + (g * INTERVAL '1 month'))::date AS billing_month,
    sub.amount_due,
    CASE 
        WHEN sub.status = 'churned' AND g > sub.paid_until THEN 0
        WHEN random() < 0.1 THEN ROUND((sub.amount_due * (0.3 + random()*0.5))::numeric, 2)
        ELSE sub.amount_due
    END AS amount_paid,
    CASE 
        WHEN sub.status = 'churned' AND g > sub.paid_until THEN NULL
        ELSE (sub.signup_date + (g * INTERVAL '1 month') + (FLOOR(random()*20)::int || ' days')::interval)::date
    END AS payment_date,
    CASE 
        WHEN sub.status = 'churned' AND g > sub.paid_until THEN TRUE
        WHEN random() < 0.15 THEN TRUE
        ELSE FALSE
    END AS late_flag
FROM (
    SELECT 
        c.customer_id,
        c.signup_date,
        c.status,
        p.monthly_price AS amount_due,
        LEAST(
            GREATEST(1, FLOOR((CURRENT_DATE - c.signup_date) / 30.0)::int),
            36
        ) AS total_months,
        FLOOR(random() * GREATEST(1, FLOOR((CURRENT_DATE - c.signup_date)/30.0)::int) * 0.6)::int AS paid_until
    FROM customers c
    JOIN plans p ON c.plan_id = p.plan_id
    WHERE c.plan_type = 'postpaid'
) sub
CROSS JOIN LATERAL generate_series(0, sub.total_months - 1) AS g
WHERE sub.status != 'churned' OR g <= sub.paid_until + 2
ON CONFLICT (invoice_id) DO NOTHING;
--Call Logs
INSERT INTO call_logs (call_id, customer_id, call_date, duration_sec, dropped_flag, tower_id, call_type)
SELECT
    'CALL' || LPAD(ROW_NUMBER() OVER ()::text, 9, '0') AS call_id,
    sub.customer_id,
    (sub.signup_date + (random() * (sub.end_date - sub.signup_date))::int 
        + (FLOOR(random()*24)::int || ' hours')::interval
        + (FLOOR(random()*60)::int || ' minutes')::interval) AS call_date,
    CASE 
        WHEN random() < 0.01 THEN FLOOR(random()*500000 + 100000)::int
        ELSE FLOOR(random()*1200 + 5)::int
    END AS duration_sec,
    CASE WHEN random() < 0.08 THEN TRUE ELSE FALSE END AS dropped_flag,
    CASE 
        WHEN random() < 0.1 THEN NULL
        ELSE 'TWR' || LPAD(FLOOR(random()*500+1)::text, 4, '0')
    END AS tower_id,
    (ARRAY['incoming','outgoing','SMS'])[FLOOR(random()*3+1)::int] AS call_type
FROM (
    SELECT 
        c.customer_id,
        c.signup_date,
        CASE 
            WHEN c.status = 'churned' 
            THEN c.signup_date + ((CURRENT_DATE - c.signup_date) * (0.3 + random()*0.4))::int
            ELSE CURRENT_DATE
        END AS end_date,
        CASE 
            WHEN c.status = 'churned' THEN FLOOR(random()*15+3)::int
            ELSE FLOOR(random()*80+10)::int
        END AS num_calls
    FROM customers c
) sub
CROSS JOIN LATERAL generate_series(1, sub.num_calls) AS g
ON CONFLICT (call_id) DO NOTHING;
--Data Usage
INSERT INTO data_usage (usage_id, customer_id, usage_date, mb_used, network_type)
SELECT
    'USG' || LPAD(ROW_NUMBER() OVER ()::text, 9, '0') AS usage_id,
    sub.customer_id,
    (sub.signup_date + (random() * (sub.end_date - sub.signup_date))::int 
        + (FLOOR(random()*24)::int || ' hours')::interval) AS usage_date,
    CASE 
        WHEN random() < 0.01 THEN ROUND((random()*50000 + 20000)::numeric, 2)
        ELSE ROUND((random()*900 + 5)::numeric, 2)
    END AS mb_used,
    (ARRAY['2G','3G','4G','4G','4G','5G'])[FLOOR(random()*6+1)::int] AS network_type
FROM (
    SELECT 
        c.customer_id,
        c.signup_date,
        CASE 
            WHEN c.status = 'churned' 
            THEN c.signup_date + ((CURRENT_DATE - c.signup_date) * (0.3 + random()*0.4))::int
            ELSE CURRENT_DATE
        END AS end_date,
        CASE 
            WHEN c.status = 'churned' THEN FLOOR(random()*20+3)::int
            ELSE FLOOR(random()*100+15)::int
        END AS num_records
    FROM customers c
) sub
CROSS JOIN LATERAL generate_series(1, sub.num_records) AS g
ON CONFLICT (usage_id) DO NOTHING;
