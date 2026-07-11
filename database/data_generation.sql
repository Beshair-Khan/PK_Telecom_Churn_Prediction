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
