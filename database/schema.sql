CREATE TABLE customers (
    customer_id     VARCHAR(20)   PRIMARY KEY,
    customer_name   VARCHAR(50),
    customer_cnic   VARCHAR(15),
    phone_number    VARCHAR(15),
    email           VARCHAR(50),
    age             INT,
    signup_date     DATE,
    operator        VARCHAR(20),
    plan_type       VARCHAR(10),
    city            VARCHAR(50),
    status          VARCHAR(10)
);
SELECT * FROM customers;
CREATE TABLE plans (
    plan_id           VARCHAR(20)    PRIMARY KEY,
    operator          VARCHAR(20),
    plan_type         VARCHAR(10),
    monthly_price     DECIMAL(10,2),
    data_cap_gb       INT,
    minutes_included  INT
);
CREATE TABLE recharges (
    recharge_id     VARCHAR(20)    PRIMARY KEY,
    customer_id     VARCHAR(20)    REFERENCES customers(customer_id),
    amount_pkr      DECIMAL(10,2),
    recharge_date   DATE,
    channel         VARCHAR(50)
);
CREATE TABLE invoices (
    invoice_id      VARCHAR(20)    PRIMARY KEY,
    customer_id     VARCHAR(20)    REFERENCES customers(customer_id),
    billing_month   DATE,
    amount_due      DECIMAL(10,2),
    amount_paid     DECIMAL(10,2),
    payment_date    DATE,
    late_flag       BOOLEAN
);
CREATE TABLE call_logs (
    call_id         VARCHAR(20)    PRIMARY KEY,
    customer_id     VARCHAR(20)    REFERENCES customers(customer_id),
    call_date       TIMESTAMP,
    duration_sec    INT,
    dropped_flag    BOOLEAN,
    tower_id        VARCHAR(20),
    call_type       VARCHAR(30)
);
CREATE TABLE data_usage (
    usage_id        VARCHAR(20)    PRIMARY KEY,
    customer_id     VARCHAR(20)    REFERENCES customers(customer_id),
    usage_date      TIMESTAMP,
    mb_used         DECIMAL(10,2),
    network_type    VARCHAR(10)
);
ALTER TABLE customers
ADD COLUMN plan_id VARCHAR(20) REFERENCES plans(plan_id);
SELECT table_name, column_name, data_type, character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;