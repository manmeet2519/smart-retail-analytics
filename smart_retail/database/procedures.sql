-- ============================================================
-- Smart Retail Demand & Fraud Analytics System
-- Stored Procedures, Triggers, and Views
-- ============================================================
USE smart_retail_db;

DELIMITER $$

-- ============================================================
-- STORED PROCEDURE: sp_get_sales_summary
-- ============================================================
DROP PROCEDURE IF EXISTS sp_get_sales_summary$$
CREATE PROCEDURE sp_get_sales_summary(
    IN p_start_date DATE,
    IN p_end_date   DATE
)
BEGIN
    SELECT
        COUNT(*)                    AS total_transactions,
        SUM(total_amount)           AS total_revenue,
        AVG(total_amount)           AS avg_transaction_value,
        SUM(quantity)               AS total_units_sold,
        COUNT(DISTINCT customer_id) AS unique_customers
    FROM transactions
    WHERE DATE(transaction_date) BETWEEN p_start_date AND p_end_date
      AND status = 'completed';

    SELECT
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(t.quantity)     AS units_sold,
        SUM(t.total_amount) AS revenue
    FROM transactions t
    JOIN products   p ON t.product_id  = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    WHERE DATE(t.transaction_date) BETWEEN p_start_date AND p_end_date
      AND t.status = 'completed'
    GROUP BY p.product_id, p.product_name, c.category_name
    ORDER BY revenue DESC
    LIMIT 5;

    SELECT
        s.store_id,
        s.store_name,
        s.city,
        s.region,
        COUNT(t.transaction_id) AS transaction_count,
        SUM(t.total_amount)     AS revenue
    FROM transactions t
    JOIN stores s ON t.store_id = s.store_id
    WHERE DATE(t.transaction_date) BETWEEN p_start_date AND p_end_date
      AND t.status = 'completed'
    GROUP BY s.store_id, s.store_name, s.city, s.region
    ORDER BY revenue DESC
    LIMIT 5;
END$$

-- ============================================================
-- STORED PROCEDURE: sp_forecast_demand
-- ============================================================
DROP PROCEDURE IF EXISTS sp_forecast_demand$$
CREATE PROCEDURE sp_forecast_demand(
    IN p_product_id INT
)
BEGIN
    DECLARE v_avg_demand DECIMAL(10,2);
    DECLARE v_next_month DATE;
    DECLARE v_exists     INT DEFAULT 0;

    IF NOT EXISTS (SELECT 1 FROM products WHERE product_id = p_product_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Product not found';
    END IF;

    SELECT AVG(monthly_qty) INTO v_avg_demand
    FROM (
        SELECT
            DATE_FORMAT(transaction_date, '%Y-%m-01') AS month_start,
            SUM(quantity)                              AS monthly_qty
        FROM transactions
        WHERE product_id = p_product_id
          AND status     = 'completed'
          AND transaction_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
        GROUP BY DATE_FORMAT(transaction_date, '%Y-%m-01')
    ) monthly_data;

    SET v_avg_demand = COALESCE(v_avg_demand, 0);
    SET v_next_month = DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01');

    SELECT COUNT(*) INTO v_exists
    FROM demand_forecast
    WHERE product_id    = p_product_id
      AND forecast_date = v_next_month;

    IF v_exists > 0 THEN
        UPDATE demand_forecast
        SET predicted_demand = v_avg_demand
        WHERE product_id    = p_product_id
          AND forecast_date = v_next_month;
    ELSE
        INSERT INTO demand_forecast (product_id, forecast_date, predicted_demand)
        VALUES (p_product_id, v_next_month, v_avg_demand);
    END IF;

    SELECT
        df.forecast_date,
        df.predicted_demand,
        df.actual_demand,
        df.accuracy_pct,
        p.product_name,
        p.stock_quantity,
        p.reorder_level,
        CASE WHEN p.stock_quantity <= p.reorder_level
             THEN 'REORDER NEEDED' ELSE 'OK'
        END AS stock_status
    FROM demand_forecast df
    JOIN products p ON df.product_id = p.product_id
    WHERE df.product_id = p_product_id
    ORDER BY df.forecast_date DESC
    LIMIT 12;
END$$

-- ============================================================
-- STORED PROCEDURE: sp_detect_fraud
-- ============================================================
DROP PROCEDURE IF EXISTS sp_detect_fraud$$
CREATE PROCEDURE sp_detect_fraud()
BEGIN
    DECLARE v_flagged INT DEFAULT 0;

    -- 1. High-amount transactions (> $5000)
    INSERT INTO fraud_flags (transaction_id, flag_reason, severity, resolved)
    SELECT
        t.transaction_id,
        CONCAT('High transaction amount: $', FORMAT(t.total_amount, 2), ' exceeds $5000 threshold'),
        'critical',
        0
    FROM transactions t
    WHERE t.total_amount > 5000
      AND t.status = 'completed'
      AND NOT EXISTS (
          SELECT 1 FROM fraud_flags ff
          WHERE ff.transaction_id = t.transaction_id
            AND ff.flag_reason LIKE 'High transaction amount%'
      );
    SET v_flagged = v_flagged + ROW_COUNT();

    -- 2. Multiple transactions by same customer within 60 seconds
    INSERT INTO fraud_flags (transaction_id, flag_reason, severity, resolved)
    SELECT DISTINCT
        t2.transaction_id,
        CONCAT('Rapid successive transaction: customer #', t2.customer_id,
               ' made multiple purchases within 60 seconds'),
        'high',
        0
    FROM transactions t1
    JOIN transactions t2
      ON  t1.customer_id     = t2.customer_id
      AND t1.transaction_id <> t2.transaction_id
      AND ABS(TIMESTAMPDIFF(SECOND, t1.transaction_date, t2.transaction_date)) <= 60
    WHERE t1.status = 'completed'
      AND t2.status = 'completed'
      AND NOT EXISTS (
          SELECT 1 FROM fraud_flags ff
          WHERE ff.transaction_id = t2.transaction_id
            AND ff.flag_reason LIKE 'Rapid successive transaction%'
      );
    SET v_flagged = v_flagged + ROW_COUNT();

    -- 3. Unusual quantity (> 30 units)
    INSERT INTO fraud_flags (transaction_id, flag_reason, severity, resolved)
    SELECT
        t.transaction_id,
        CONCAT('Unusual quantity: ', t.quantity, ' units of "', p.product_name, '" in single transaction'),
        'medium',
        0
    FROM transactions t
    JOIN products p ON t.product_id = p.product_id
    WHERE t.quantity > 30
      AND t.status = 'completed'
      AND NOT EXISTS (
          SELECT 1 FROM fraud_flags ff
          WHERE ff.transaction_id = t.transaction_id
            AND ff.flag_reason LIKE 'Unusual quantity%'
      );
    SET v_flagged = v_flagged + ROW_COUNT();

    -- 4. Late-night high-value (midnight-5am, > $1000)
    INSERT INTO fraud_flags (transaction_id, flag_reason, severity, resolved)
    SELECT
        t.transaction_id,
        CONCAT('Late-night high-value transaction: $', FORMAT(t.total_amount, 2),
               ' at ', TIME(t.transaction_date)),
        'high',
        0
    FROM transactions t
    WHERE HOUR(t.transaction_date) BETWEEN 0 AND 4
      AND t.total_amount > 1000
      AND t.status = 'completed'
      AND NOT EXISTS (
          SELECT 1 FROM fraud_flags ff
          WHERE ff.transaction_id = t.transaction_id
            AND ff.flag_reason LIKE 'Late-night high-value%'
      );
    SET v_flagged = v_flagged + ROW_COUNT();

    SELECT v_flagged AS new_flags_inserted;
END$$

-- ============================================================
-- TRIGGER: trg_after_transaction_insert (fraud auto-check)
-- ============================================================
DROP TRIGGER IF EXISTS trg_after_transaction_insert$$
CREATE TRIGGER trg_after_transaction_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.total_amount > 5000 THEN
        INSERT INTO fraud_flags (transaction_id, flag_reason, severity, resolved)
        VALUES (NEW.transaction_id,
                CONCAT('High transaction amount: $', FORMAT(NEW.total_amount, 2),
                       ' exceeds $5000 threshold'),
                'critical', 0);
    END IF;

    IF NEW.quantity > 30 THEN
        INSERT INTO fraud_flags (transaction_id, flag_reason, severity, resolved)
        VALUES (NEW.transaction_id,
                CONCAT('Unusual quantity: ', NEW.quantity, ' units in a single transaction'),
                'medium', 0);
    END IF;

    IF HOUR(NEW.transaction_date) BETWEEN 0 AND 4 AND NEW.total_amount > 1000 THEN
        INSERT INTO fraud_flags (transaction_id, flag_reason, severity, resolved)
        VALUES (NEW.transaction_id,
                CONCAT('Late-night high-value transaction: $', FORMAT(NEW.total_amount, 2),
                       ' at ', TIME(NEW.transaction_date)),
                'high', 0);
    END IF;

    IF EXISTS (
        SELECT 1 FROM transactions
        WHERE customer_id     = NEW.customer_id
          AND transaction_id <> NEW.transaction_id
          AND ABS(TIMESTAMPDIFF(SECOND, transaction_date, NEW.transaction_date)) <= 60
          AND status          = 'completed'
    ) THEN
        INSERT INTO fraud_flags (transaction_id, flag_reason, severity, resolved)
        VALUES (NEW.transaction_id,
                CONCAT('Rapid successive transaction: customer #', NEW.customer_id,
                       ' made multiple purchases within 60 seconds'),
                'high', 0);
    END IF;
END$$

-- ============================================================
-- TRIGGER: trg_update_inventory (stock deduction)
-- ============================================================
DROP TRIGGER IF EXISTS trg_update_inventory$$
CREATE TRIGGER trg_update_inventory
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' THEN
        UPDATE products
        SET stock_quantity = stock_quantity - NEW.quantity
        WHERE product_id = NEW.product_id;

        INSERT INTO inventory_log
            (product_id, store_id, change_type, quantity_change, log_date, notes)
        VALUES (
            NEW.product_id, NEW.store_id, 'sale', -NEW.quantity,
            NEW.transaction_date,
            CONCAT('Auto-logged from transaction #', NEW.transaction_id)
        );
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- VIEW: vw_sales_ranking
-- ============================================================
CREATE OR REPLACE VIEW vw_sales_ranking AS
SELECT
    p.product_id,
    p.product_name,
    c.category_name,
    SUM(t.quantity)                                                AS total_units_sold,
    SUM(t.total_amount)                                            AS total_revenue,
    RANK()       OVER (ORDER BY SUM(t.total_amount) DESC)          AS revenue_rank,
    RANK()       OVER (PARTITION BY c.category_id
                       ORDER BY SUM(t.total_amount) DESC)          AS category_rank,
    DENSE_RANK() OVER (ORDER BY SUM(t.quantity) DESC)              AS units_rank
FROM transactions t
JOIN products   p ON t.product_id  = p.product_id
JOIN categories c ON p.category_id = c.category_id
WHERE t.status = 'completed'
GROUP BY p.product_id, p.product_name, c.category_name, c.category_id;

-- ============================================================
-- VIEW: vw_running_total
-- ============================================================
CREATE OR REPLACE VIEW vw_running_total AS
SELECT
    s.store_id,
    s.store_name,
    s.city,
    DATE(t.transaction_date)                                       AS sale_date,
    SUM(t.total_amount)                                            AS daily_revenue,
    SUM(SUM(t.total_amount)) OVER (
        PARTITION BY s.store_id
        ORDER BY DATE(t.transaction_date)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                              AS running_total,
    AVG(SUM(t.total_amount)) OVER (
        PARTITION BY s.store_id
        ORDER BY DATE(t.transaction_date)
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    )                                                              AS rolling_7day_avg
FROM transactions t
JOIN stores s ON t.store_id = s.store_id
WHERE t.status = 'completed'
GROUP BY s.store_id, s.store_name, s.city, DATE(t.transaction_date);

-- ============================================================
-- VIEW: vw_customer_spending
-- ============================================================
CREATE OR REPLACE VIEW vw_customer_spending AS
SELECT
    c.customer_id,
    c.name                                                         AS customer_name,
    c.city,
    COUNT(t.transaction_id)                                        AS total_transactions,
    SUM(t.total_amount)                                            AS total_spent,
    AVG(t.total_amount)                                            AS avg_transaction,
    MAX(t.total_amount)                                            AS max_transaction,
    NTILE(4)  OVER (ORDER BY SUM(t.total_amount) DESC)             AS spending_quartile,
    NTILE(10) OVER (ORDER BY SUM(t.total_amount) DESC)             AS spending_decile,
    PERCENT_RANK() OVER (ORDER BY SUM(t.total_amount))             AS spending_percentile,
    CASE NTILE(4) OVER (ORDER BY SUM(t.total_amount) DESC)
        WHEN 1 THEN 'Platinum'
        WHEN 2 THEN 'Gold'
        WHEN 3 THEN 'Silver'
        ELSE        'Bronze'
    END                                                            AS customer_tier
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
WHERE t.status = 'completed'
GROUP BY c.customer_id, c.name, c.city;

-- ============================================================
-- VIEW: vw_fraud_analysis
-- ============================================================
CREATE OR REPLACE VIEW vw_fraud_analysis AS
SELECT
    t.transaction_id,
    t.customer_id,
    c.name                                                         AS customer_name,
    t.product_id,
    p.product_name,
    t.store_id,
    s.store_name,
    t.total_amount,
    t.transaction_date,
    t.payment_method,
    LAG(t.transaction_date) OVER (
        PARTITION BY t.customer_id ORDER BY t.transaction_date
    )                                                              AS prev_transaction_date,
    TIMESTAMPDIFF(SECOND,
        LAG(t.transaction_date) OVER (
            PARTITION BY t.customer_id ORDER BY t.transaction_date),
        t.transaction_date
    )                                                              AS seconds_since_last,
    LAG(t.total_amount) OVER (
        PARTITION BY t.customer_id ORDER BY t.transaction_date
    )                                                              AS prev_amount,
    SUM(t.total_amount) OVER (
        PARTITION BY t.customer_id
        ORDER BY t.transaction_date
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    )                                                              AS rolling_5tx_total,
    COUNT(*) OVER (
        PARTITION BY t.customer_id
        ORDER BY t.transaction_date
        RANGE BETWEEN INTERVAL 1 HOUR PRECEDING AND CURRENT ROW
    )                                                              AS tx_count_last_hour,
    CASE
        WHEN t.total_amount > 5000 THEN 'HIGH_AMOUNT'
        WHEN TIMESTAMPDIFF(SECOND,
             LAG(t.transaction_date) OVER (
                 PARTITION BY t.customer_id ORDER BY t.transaction_date),
             t.transaction_date) <= 60 THEN 'RAPID_SUCCESSION'
        WHEN t.quantity > 30 THEN 'UNUSUAL_QUANTITY'
        WHEN HOUR(t.transaction_date) BETWEEN 0 AND 4
             AND t.total_amount > 1000 THEN 'LATE_NIGHT_HIGH_VALUE'
        ELSE 'NORMAL'
    END                                                            AS fraud_indicator,
    ff.flag_id,
    ff.flag_reason,
    ff.severity,
    ff.resolved
FROM transactions t
JOIN customers  c  ON t.customer_id    = c.customer_id
JOIN products   p  ON t.product_id     = p.product_id
JOIN stores     s  ON t.store_id       = s.store_id
LEFT JOIN fraud_flags ff ON t.transaction_id = ff.transaction_id;
