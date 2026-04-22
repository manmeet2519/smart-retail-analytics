-- ============================================================
-- Smart Retail Demand & Fraud Analytics System
-- Seed Data
-- ============================================================
USE smart_retail_db;

-- ============================================================
-- CATEGORIES
-- ============================================================
INSERT INTO categories (category_name, description) VALUES
  ('Electronics',   'Gadgets, devices, and electronic accessories'),
  ('Clothing',      'Apparel, footwear, and fashion accessories'),
  ('Food',          'Groceries, snacks, beverages, and perishables'),
  ('Home & Garden', 'Furniture, decor, tools, and garden supplies'),
  ('Sports',        'Sporting goods, fitness equipment, and outdoor gear');

-- ============================================================
-- CUSTOMERS
-- ============================================================
INSERT INTO customers (name, email, phone, address, city, country) VALUES
  ('Alice Johnson', 'alice.johnson@email.com', '555-0101', '123 Maple St',   'New York',     'USA'),
  ('Bob Martinez',  'bob.martinez@email.com',  '555-0102', '456 Oak Ave',    'Los Angeles',  'USA'),
  ('Carol White',   'carol.white@email.com',   '555-0103', '789 Pine Rd',    'Chicago',      'USA'),
  ('David Lee',     'david.lee@email.com',     '555-0104', '321 Elm Blvd',   'Houston',      'USA'),
  ('Eva Brown',     'eva.brown@email.com',     '555-0105', '654 Cedar Ln',   'Phoenix',      'USA'),
  ('Frank Davis',   'frank.davis@email.com',   '555-0106', '987 Birch Way',  'Philadelphia', 'USA'),
  ('Grace Wilson',  'grace.wilson@email.com',  '555-0107', '147 Walnut Dr',  'San Antonio',  'USA'),
  ('Henry Taylor',  'henry.taylor@email.com',  '555-0108', '258 Spruce Ct',  'San Diego',    'USA'),
  ('Iris Anderson', 'iris.anderson@email.com', '555-0109', '369 Willow Pl',  'Dallas',       'USA'),
  ('Jack Thomas',   'jack.thomas@email.com',   '555-0110', '741 Poplar Ave', 'San Jose',     'USA');

-- ============================================================
-- STORES
-- ============================================================
INSERT INTO stores (store_name, city, region, manager_name) VALUES
  ('RetailHub Downtown',  'New York',    'Northeast', 'Michael Scott'),
  ('RetailHub Westside',  'Los Angeles', 'West',      'Pam Beesly'),
  ('RetailHub Midtown',   'Chicago',     'Midwest',   'Jim Halpert'),
  ('RetailHub Southpark', 'Houston',     'South',     'Dwight Schrute'),
  ('RetailHub Sunbelt',   'Phoenix',     'Southwest', 'Angela Martin');

-- ============================================================
-- EMPLOYEES
-- ============================================================
INSERT INTO employees (name, store_id, role, hire_date) VALUES
  ('Tom Harris',  1, 'Cashier',    '2021-03-15'),
  ('Sara Connor', 1, 'Sales Rep',  '2020-07-22'),
  ('Mike Chen',   2, 'Cashier',    '2022-01-10'),
  ('Lisa Park',   2, 'Supervisor', '2019-11-05'),
  ('James Brown', 3, 'Cashier',    '2021-09-18'),
  ('Nina Patel',  3, 'Sales Rep',  '2022-04-30'),
  ('Carlos Ruiz', 4, 'Cashier',    '2020-06-14'),
  ('Amy Zhang',   4, 'Supervisor', '2018-12-01'),
  ('Kevin Moore', 5, 'Cashier',    '2023-02-20'),
  ('Diana Ross',  5, 'Sales Rep',  '2021-08-09');

-- ============================================================
-- PRODUCTS (20)
-- ============================================================
INSERT INTO products (product_name, category_id, price, stock_quantity, reorder_level) VALUES
  ('Smartphone X12',       1, 699.99,  45, 10),
  ('Wireless Earbuds Pro', 1,  89.99, 120, 20),
  ('4K Smart TV 55in',     1, 549.99,  18,  5),
  ('Laptop UltraBook',     1, 999.99,  22,  8),
  ('Classic Denim Jeans',  2,  49.99, 200, 30),
  ('Cotton T-Shirt Pack',  2,  24.99, 350, 50),
  ('Running Sneakers',     2,  79.99,  90, 20),
  ('Winter Jacket',        2, 129.99,  60, 15),
  ('Organic Coffee Beans', 3,  14.99, 300, 50),
  ('Protein Bar Box',      3,  29.99, 180, 40),
  ('Green Tea Pack',       3,   9.99, 250, 60),
  ('Almond Butter Jar',    3,   7.99, 220, 50),
  ('Cordless Drill Set',   4,  89.99,  55, 10),
  ('Ceramic Plant Pot',    4,  19.99, 140, 25),
  ('LED Desk Lamp',        4,  34.99,  75, 15),
  ('Memory Foam Pillow',   4,  44.99,  95, 20),
  ('Yoga Mat Premium',     5,  39.99, 110, 20),
  ('Resistance Band Set',  5,  24.99, 160, 30),
  ('Cycling Helmet',       5,  59.99,  40, 10),
  ('Dumbbell Pair 20lb',   5,  54.99,   8, 10);

-- ============================================================
-- TRANSACTIONS (disable triggers for seed, re-enable after)
-- ============================================================
SET @OLD_SQL_MODE = @@SQL_MODE;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';

-- Temporarily disable triggers for clean seed
SET @disable_triggers = 1;

INSERT INTO transactions
  (customer_id, product_id, store_id, employee_id, quantity,
   unit_price, total_amount, transaction_date, payment_method, status)
VALUES
-- January 2024
(1,  1,1,1, 1, 699.99,  699.99,'2024-01-03 09:15:00','credit_card','completed'),
(2,  5,2,3, 2,  49.99,   99.98,'2024-01-03 10:30:00','debit_card', 'completed'),
(3,  9,3,5, 3,  14.99,   44.97,'2024-01-04 11:00:00','cash',       'completed'),
(4, 13,4,7, 1,  89.99,   89.99,'2024-01-04 14:20:00','credit_card','completed'),
(5, 17,5,9, 2,  39.99,   79.98,'2024-01-05 09:45:00','online',     'completed'),
(6,  2,1,2, 3,  89.99,  269.97,'2024-01-05 13:10:00','credit_card','completed'),
(7,  6,2,4, 5,  24.99,  124.95,'2024-01-06 10:00:00','cash',       'completed'),
(8, 10,3,6, 2,  29.99,   59.98,'2024-01-06 15:30:00','debit_card', 'completed'),
(9, 14,4,8, 3,  19.99,   59.97,'2024-01-07 11:20:00','cash',       'completed'),
(10,18,5,10,4,  24.99,   99.96,'2024-01-07 16:00:00','credit_card','completed'),
(1,  3,1,1, 1, 549.99,  549.99,'2024-01-08 09:00:00','credit_card','completed'),
(2,  7,2,3, 1,  79.99,   79.99,'2024-01-08 12:45:00','debit_card', 'completed'),
(3, 11,3,5, 4,   9.99,   39.96,'2024-01-09 10:15:00','cash',       'completed'),
(4, 15,4,7, 2,  34.99,   69.98,'2024-01-09 14:00:00','online',     'completed'),
(5, 19,5,9, 1,  59.99,   59.99,'2024-01-10 09:30:00','credit_card','completed'),
-- February 2024
(6,  4,1,2, 1, 999.99,  999.99,'2024-02-01 10:00:00','credit_card','completed'),
(7,  8,2,4, 2, 129.99,  259.98,'2024-02-02 11:30:00','debit_card', 'completed'),
(8, 12,3,6, 5,   7.99,   39.95,'2024-02-03 13:00:00','cash',       'completed'),
(9, 16,4,8, 1,  44.99,   44.99,'2024-02-04 09:15:00','online',     'completed'),
(10,20,5,10,1,  54.99,   54.99,'2024-02-05 14:45:00','credit_card','completed'),
(1,  5,1,1, 3,  49.99,  149.97,'2024-02-06 10:30:00','debit_card', 'completed'),
(2,  9,2,3, 2,  14.99,   29.98,'2024-02-07 11:00:00','cash',       'completed'),
(3, 13,3,5, 1,  89.99,   89.99,'2024-02-08 15:20:00','credit_card','completed'),
(4, 17,4,7, 3,  39.99,  119.97,'2024-02-09 09:00:00','online',     'completed'),
(5,  1,5,9, 1, 699.99,  699.99,'2024-02-10 12:00:00','credit_card','completed'),
(6,  6,1,2, 4,  24.99,   99.96,'2024-02-11 10:15:00','cash',       'completed'),
(7, 10,2,4, 3,  29.99,   89.97,'2024-02-12 14:30:00','debit_card', 'completed'),
(8, 14,3,6, 2,  19.99,   39.98,'2024-02-13 11:45:00','cash',       'completed'),
(9, 18,4,8, 5,  24.99,  124.95,'2024-02-14 09:30:00','online',     'completed'),
(10, 2,5,10,2,  89.99,  179.98,'2024-02-15 13:00:00','credit_card','completed'),
-- March 2024
(1, 11,1,1, 6,   9.99,   59.94,'2024-03-01 10:00:00','cash',       'completed'),
(2, 15,2,3, 1,  34.99,   34.99,'2024-03-02 11:30:00','debit_card', 'completed'),
(3, 19,3,5, 2,  59.99,  119.98,'2024-03-03 09:45:00','credit_card','completed'),
(4,  3,4,7, 1, 549.99,  549.99,'2024-03-04 14:00:00','credit_card','completed'),
(5,  7,5,9, 3,  79.99,  239.97,'2024-03-05 10:30:00','online',     'completed'),
(6, 12,1,2, 4,   7.99,   31.96,'2024-03-06 12:00:00','cash',       'completed'),
(7, 16,2,4, 2,  44.99,   89.98,'2024-03-07 15:15:00','debit_card', 'completed'),
(8, 20,3,6, 1,  54.99,   54.99,'2024-03-08 09:00:00','credit_card','completed'),
(9,  4,4,8, 1, 999.99,  999.99,'2024-03-09 11:00:00','credit_card','completed'),
(10, 8,5,10,2, 129.99,  259.98,'2024-03-10 14:30:00','online',     'completed'),
(1, 13,1,1, 2,  89.99,  179.98,'2024-03-11 10:00:00','debit_card', 'completed'),
(2, 17,2,3, 4,  39.99,  159.96,'2024-03-12 11:45:00','cash',       'completed'),
(3,  1,3,5, 1, 699.99,  699.99,'2024-03-13 09:30:00','credit_card','completed'),
(4,  5,4,7, 5,  49.99,  249.95,'2024-03-14 13:00:00','debit_card', 'completed'),
(5,  9,5,9, 3,  14.99,   44.97,'2024-03-15 10:15:00','cash',       'completed'),
-- April 2024
(6, 14,1,2, 2,  19.99,   39.98,'2024-04-01 09:00:00','online',     'completed'),
(7, 18,2,4, 3,  24.99,   74.97,'2024-04-02 12:30:00','credit_card','completed'),
(8,  2,3,6, 1,  89.99,   89.99,'2024-04-03 14:00:00','debit_card', 'completed'),
(9,  6,4,8, 6,  24.99,  149.94,'2024-04-04 10:45:00','cash',       'completed'),
(10,10,5,10,2,  29.99,   59.98,'2024-04-05 11:30:00','online',     'completed'),
(1, 15,1,1, 1,  34.99,   34.99,'2024-04-06 09:15:00','credit_card','completed'),
(2, 19,2,3, 2,  59.99,  119.98,'2024-04-07 13:45:00','debit_card', 'completed'),
(3,  3,3,5, 1, 549.99,  549.99,'2024-04-08 10:00:00','credit_card','completed'),
(4,  7,4,7, 2,  79.99,  159.98,'2024-04-09 14:15:00','online',     'completed'),
(5, 11,5,9, 5,   9.99,   49.95,'2024-04-10 09:30:00','cash',       'completed'),
-- May 2024
(6, 16,1,2, 1,  44.99,   44.99,'2024-05-01 10:00:00','debit_card', 'completed'),
(7, 20,2,4, 1,  54.99,   54.99,'2024-05-02 11:00:00','credit_card','completed'),
(8,  4,3,6, 1, 999.99,  999.99,'2024-05-03 09:45:00','credit_card','completed'),
(9,  8,4,8, 3, 129.99,  389.97,'2024-05-04 14:00:00','online',     'completed'),
(10,12,5,10,6,   7.99,   47.94,'2024-05-05 10:30:00','cash',       'completed'),
(1, 17,1,1, 2,  39.99,   79.98,'2024-05-06 12:00:00','debit_card', 'completed'),
(2,  1,2,3, 1, 699.99,  699.99,'2024-05-07 09:00:00','credit_card','completed'),
(3,  5,3,5, 4,  49.99,  199.96,'2024-05-08 13:30:00','cash',       'completed'),
(4,  9,4,7, 3,  14.99,   44.97,'2024-05-09 10:15:00','online',     'completed'),
(5, 13,5,9, 1,  89.99,   89.99,'2024-05-10 11:45:00','credit_card','completed'),
-- June 2024
(6,  2,1,2, 2,  89.99,  179.98,'2024-06-01 09:30:00','debit_card', 'completed'),
(7,  6,2,4, 3,  24.99,   74.97,'2024-06-02 14:00:00','cash',       'completed'),
(8, 10,3,6, 4,  29.99,  119.96,'2024-06-03 10:45:00','online',     'completed'),
(9, 14,4,8, 2,  19.99,   39.98,'2024-06-04 12:30:00','credit_card','completed'),
(10,18,5,10,5,  24.99,  124.95,'2024-06-05 09:00:00','debit_card', 'completed'),
(1, 19,1,1, 1,  59.99,   59.99,'2024-06-06 11:00:00','cash',       'completed'),
(2,  3,2,3, 1, 549.99,  549.99,'2024-06-07 14:30:00','credit_card','completed'),
(3,  7,3,5, 2,  79.99,  159.98,'2024-06-08 10:00:00','online',     'completed'),
(4, 11,4,7, 6,   9.99,   59.94,'2024-06-09 13:15:00','cash',       'completed'),
(5, 15,5,9, 1,  34.99,   34.99,'2024-06-10 09:45:00','debit_card', 'completed'),
-- SUSPICIOUS TRANSACTIONS (will trigger fraud flags via trigger)
(1,  4,1,1,10, 999.99, 9999.90,'2024-06-15 02:30:00','credit_card','completed'),
(3,  1,2,3, 1, 699.99,  699.99,'2024-06-16 03:15:00','credit_card','completed'),
(3,  2,2,3, 2,  89.99,  179.98,'2024-06-16 03:15:30','credit_card','completed'),
(3,  3,2,3, 1, 549.99,  549.99,'2024-06-16 03:15:45','credit_card','completed'),
(5,  6,3,5,50,  24.99, 1249.50,'2024-06-17 01:00:00','cash',       'completed'),
(7,  4,4,7, 5, 999.99, 4999.95,'2024-06-18 23:55:00','online',     'completed'),
(9,  1,1,1, 1, 699.99,  699.99,'2024-06-19 04:10:00','credit_card','completed'),
(9,  4,1,1, 1, 999.99,  999.99,'2024-06-19 04:10:20','credit_card','completed'),
-- July 2024
(1,  6,1,2, 3,  24.99,   74.97,'2024-07-01 10:00:00','cash',       'completed'),
(2, 10,2,4, 2,  29.99,   59.98,'2024-07-02 11:30:00','debit_card', 'completed'),
(3, 14,3,6, 1,  19.99,   19.99,'2024-07-03 09:15:00','online',     'completed'),
(4, 18,4,8, 4,  24.99,   99.96,'2024-07-04 14:00:00','credit_card','completed'),
(5,  2,5,10,1,  89.99,   89.99,'2024-07-05 10:30:00','cash',       'completed'),
(6, 16,1,2, 2,  44.99,   89.98,'2024-07-06 12:45:00','debit_card', 'completed'),
(7, 20,2,4, 1,  54.99,   54.99,'2024-07-07 09:00:00','credit_card','completed'),
(8,  4,3,6, 1, 999.99,  999.99,'2024-07-08 13:30:00','credit_card','completed'),
(9,  8,4,8, 2, 129.99,  259.98,'2024-07-09 10:15:00','online',     'completed'),
(10,12,5,10,3,   7.99,   23.97,'2024-07-10 11:00:00','cash',       'completed'),
(1, 17,1,1, 1,  39.99,   39.99,'2024-07-11 09:30:00','debit_card', 'completed'),
(2,  5,2,3, 3,  49.99,  149.97,'2024-07-12 14:15:00','cash',       'completed'),
(3,  9,3,5, 4,  14.99,   59.96,'2024-07-13 10:00:00','online',     'completed'),
(4, 13,4,7, 1,  89.99,   89.99,'2024-07-14 12:30:00','credit_card','completed'),
(5, 19,5,9, 2,  59.99,  119.98,'2024-07-15 09:45:00','debit_card', 'completed'),
(6,  1,1,2, 1, 699.99,  699.99,'2024-07-16 10:00:00','credit_card','refunded'),
(7,  3,2,4, 1, 549.99,  549.99,'2024-07-17 11:30:00','debit_card', 'refunded'),
(8,  4,3,6, 1, 999.99,  999.99,'2024-07-18 14:00:00','online',     'pending'),
(9,  2,4,8, 2,  89.99,  179.98,'2024-07-19 09:15:00','credit_card','pending');

-- ============================================================
-- DEMAND FORECAST
-- ============================================================
INSERT INTO demand_forecast (product_id, forecast_date, predicted_demand, actual_demand, accuracy_pct) VALUES
  (1, '2024-06-01',12.00,11.00, 91.67),
  (1, '2024-07-01',13.00,14.00, 92.86),
  (2, '2024-06-01',25.00,23.00, 92.00),
  (2, '2024-07-01',26.00,28.00, 92.86),
  (3, '2024-06-01', 5.00, 4.00, 80.00),
  (3, '2024-07-01', 6.00, 6.00,100.00),
  (4, '2024-06-01', 8.00, 9.00, 88.89),
  (4, '2024-07-01', 9.00, 8.00, 88.89),
  (5, '2024-06-01',40.00,38.00, 95.00),
  (5, '2024-07-01',42.00,45.00, 93.33),
  (6, '2024-06-01',60.00,65.00, 92.31),
  (6, '2024-07-01',65.00,62.00, 95.16),
  (9, '2024-06-01',50.00,48.00, 96.00),
  (9, '2024-07-01',52.00,55.00, 94.55),
  (13,'2024-06-01',10.00,11.00, 90.91),
  (13,'2024-07-01',11.00,10.00, 90.91),
  (17,'2024-06-01',20.00,19.00, 95.00),
  (17,'2024-07-01',21.00,22.00, 95.45),
  (20,'2024-06-01', 3.00, 2.00, 66.67),
  (20,'2024-07-01', 4.00, 3.00, 75.00);

-- ============================================================
-- INVENTORY LOG (manual entries)
-- ============================================================
INSERT INTO inventory_log (product_id, store_id, change_type, quantity_change, log_date, notes) VALUES
  (1, 1,'restock',   50,'2024-01-15 08:00:00','Monthly restock'),
  (5, 2,'restock',  100,'2024-01-15 08:30:00','Monthly restock'),
  (9, 3,'restock',  150,'2024-01-15 09:00:00','Monthly restock'),
  (4, 1,'restock',   20,'2024-02-20 08:00:00','Restock order'),
  (20,5,'restock',   15,'2024-02-25 09:00:00','Low stock restock'),
  (1, 2,'adjustment',-2,'2024-06-20 10:00:00','Inventory audit adjustment'),
  (13,4,'damage',    -3,'2024-06-22 14:00:00','Damaged in transit'),
  (17,5,'return',     2,'2024-07-01 11:00:00','Customer return'),
  (3, 1,'restock',   10,'2024-07-05 08:00:00','Restock - low inventory');
