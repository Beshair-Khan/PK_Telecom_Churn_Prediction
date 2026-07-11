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
