-- ============================================================
-- Smart Retail Demand & Fraud Analytics System
-- Database Schema
-- ============================================================

CREATE DATABASE IF NOT EXISTS smart_retail_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE smart_retail_db;

-- ============================================================
-- TABLE: categories
-- ============================================================
CREATE TABLE IF NOT EXISTS categories (
    category_id   INT           NOT NULL AUTO_INCREMENT,
    category_name VARCHAR(100)  NOT NULL UNIQUE,
    description   TEXT,
    PRIMARY KEY (category_id)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: customers
-- ============================================================
CREATE TABLE IF NOT EXISTS customers (
    customer_id   INT           NOT NULL AUTO_INCREMENT,
    name          VARCHAR(100)  NOT NULL,
    email         VARCHAR(150)  NOT NULL UNIQUE,
    phone         VARCHAR(20),
    address       VARCHAR(255),
    city          VARCHAR(100),
    country       VARCHAR(100)  DEFAULT 'USA',
    created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id),
    INDEX idx_customers_email (email),
    INDEX idx_customers_city  (city)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: stores
-- ============================================================
CREATE TABLE IF NOT EXISTS stores (
    store_id      INT          NOT NULL AUTO_INCREMENT,
    store_name    VARCHAR(150) NOT NULL,
    city          VARCHAR(100) NOT NULL,
    region        VARCHAR(100),
    manager_name  VARCHAR(100),
    PRIMARY KEY (store_id),
    INDEX idx_stores_city   (city),
    INDEX idx_stores_region (region)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: employees
-- ============================================================
CREATE TABLE IF NOT EXISTS employees (
    employee_id  INT          NOT NULL AUTO_INCREMENT,
    name         VARCHAR(100) NOT NULL,
    store_id     INT          NOT NULL,
    role         VARCHAR(80),
    hire_date    DATE,
    PRIMARY KEY (employee_id),
    CONSTRAINT fk_employees_store
        FOREIGN KEY (store_id) REFERENCES stores (store_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_employees_store (store_id)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: products
-- ============================================================
CREATE TABLE IF NOT EXISTS products (
    product_id      INT             NOT NULL AUTO_INCREMENT,
    product_name    VARCHAR(150)    NOT NULL,
    category_id     INT             NOT NULL,
    price           DECIMAL(10, 2)  NOT NULL,
    stock_quantity  INT             NOT NULL DEFAULT 0,
    reorder_level   INT             NOT NULL DEFAULT 10,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (product_id),
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id) REFERENCES categories (category_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_products_category (category_id),
    INDEX idx_products_stock    (stock_quantity)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: transactions
-- ============================================================
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id    INT             NOT NULL AUTO_INCREMENT,
    customer_id       INT             NOT NULL,
    product_id        INT             NOT NULL,
    store_id          INT             NOT NULL,
    employee_id       INT             NOT NULL,
    quantity          INT             NOT NULL,
    unit_price        DECIMAL(10, 2)  NOT NULL,
    total_amount      DECIMAL(12, 2)  NOT NULL,
    transaction_date  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_method    ENUM('cash', 'credit_card', 'debit_card', 'online', 'gift_card')
                      NOT NULL DEFAULT 'cash',
    status            ENUM('completed', 'pending', 'refunded', 'cancelled')
                      NOT NULL DEFAULT 'completed',
    PRIMARY KEY (transaction_id),
    CONSTRAINT fk_transactions_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_transactions_product
        FOREIGN KEY (product_id) REFERENCES products (product_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_transactions_store
        FOREIGN KEY (store_id) REFERENCES stores (store_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_transactions_employee
        FOREIGN KEY (employee_id) REFERENCES employees (employee_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_transactions_customer (customer_id),
    INDEX idx_transactions_product  (product_id),
    INDEX idx_transactions_store    (store_id),
    INDEX idx_transactions_date     (transaction_date),
    INDEX idx_transactions_status   (status)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: fraud_flags
-- ============================================================
CREATE TABLE IF NOT EXISTS fraud_flags (
    flag_id         INT          NOT NULL AUTO_INCREMENT,
    transaction_id  INT          NOT NULL,
    flag_reason     VARCHAR(255) NOT NULL,
    flagged_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    severity        ENUM('low', 'medium', 'high', 'critical') NOT NULL DEFAULT 'medium',
    resolved        TINYINT(1)   NOT NULL DEFAULT 0,
    PRIMARY KEY (flag_id),
    CONSTRAINT fk_fraud_transaction
        FOREIGN KEY (transaction_id) REFERENCES transactions (transaction_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_fraud_transaction (transaction_id),
    INDEX idx_fraud_severity    (severity),
    INDEX idx_fraud_resolved    (resolved)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: demand_forecast
-- ============================================================
CREATE TABLE IF NOT EXISTS demand_forecast (
    forecast_id       INT            NOT NULL AUTO_INCREMENT,
    product_id        INT            NOT NULL,
    forecast_date     DATE           NOT NULL,
    predicted_demand  DECIMAL(10, 2) NOT NULL DEFAULT 0,
    actual_demand     DECIMAL(10, 2),
    accuracy_pct      DECIMAL(5, 2),
    PRIMARY KEY (forecast_id),
    CONSTRAINT fk_forecast_product
        FOREIGN KEY (product_id) REFERENCES products (product_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY uq_forecast_product_date (product_id, forecast_date),
    INDEX idx_forecast_product (product_id),
    INDEX idx_forecast_date    (forecast_date)
) ENGINE=InnoDB;

-- ============================================================
-- TABLE: inventory_log
-- ============================================================
CREATE TABLE IF NOT EXISTS inventory_log (
    log_id          INT          NOT NULL AUTO_INCREMENT,
    product_id      INT          NOT NULL,
    store_id        INT          NOT NULL,
    change_type     ENUM('sale', 'restock', 'adjustment', 'return', 'damage')
                    NOT NULL DEFAULT 'sale',
    quantity_change INT          NOT NULL,
    log_date        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes           VARCHAR(255),
    PRIMARY KEY (log_id),
    CONSTRAINT fk_invlog_product
        FOREIGN KEY (product_id) REFERENCES products (product_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_invlog_store
        FOREIGN KEY (store_id) REFERENCES stores (store_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_invlog_product (product_id),
    INDEX idx_invlog_store   (store_id),
    INDEX idx_invlog_date    (log_date)
) ENGINE=InnoDB;
