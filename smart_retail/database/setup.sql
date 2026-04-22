-- ============================================================
-- Smart Retail Analytics — Full Database Setup
-- Run this file once to create and populate the database.
-- Usage: mysql -u root -p < setup.sql
-- ============================================================

SOURCE schema.sql;
SOURCE procedures.sql;
SOURCE seed_data.sql;

SELECT 'Database setup complete!' AS status;
SELECT COUNT(*) AS customers    FROM customers;
SELECT COUNT(*) AS products     FROM products;
SELECT COUNT(*) AS transactions FROM transactions;
SELECT COUNT(*) AS fraud_flags  FROM fraud_flags;
SELECT COUNT(*) AS forecasts    FROM demand_forecast;
