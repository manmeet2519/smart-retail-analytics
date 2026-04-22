# 🛒 Smart Retail Demand & Fraud Analytics System

> A production-style retail analytics platform built with **MySQL · Python (Flask) · HTML/CSS/JavaScript**  
> Designed to help shop owners monitor sales, forecast product demand, and detect fraudulent transactions in real time.

---

## 📌 Project Overview

This system was built to simulate a real-world retail analytics dashboard. A shop owner can:

- Track **live revenue, transactions, and customer activity**
- Identify **which products are selling best** and which need restocking
- Get **demand forecasts** using a 3-month moving average (stored procedure)
- Detect **fraud automatically** via SQL triggers on every new transaction
- **Add, edit, and manage** products, customers, and transactions directly from the UI

---

## 🗂️ Project Structure

```
smart_retail/
├── .env                          ← DB credentials (not committed)
├── README.md
│
├── database/
│   ├── schema.sql                ← All 9 tables with FK, indexes, constraints
│   ├── procedures.sql            ← Stored procedures, triggers, views
│   ├── seed_data.sql             ← 100+ realistic transactions + fraud scenarios
│   ├── run_setup.py              ← Python script to auto-setup the database
│   └── setup.sql                 ← Manual SQL runner
│
├── backend/
│   ├── app.py                    ← Flask REST API — 20+ endpoints
│   ├── db.py                     ← MySQL connection pool (mysql-connector)
│   └── requirements.txt
│
└── frontend/
    ├── index.html                ← Dashboard
    ├── sales.html                ← Sales analytics + add transactions
    ├── demand.html               ← Demand forecast + low stock alerts
    ├── fraud.html                ← Fraud detection + resolve flags
    └── static/
        ├── style.css             ← Dark professional theme
        └── script.js             ← Shared utilities, charts, API calls
```

---

## ⚙️ Tech Stack

| Layer | Technology |
|---|---|
| Database | MySQL 8.0 |
| Backend | Python 3.x, Flask, mysql-connector-python |
| Frontend | HTML5, CSS3, Vanilla JavaScript, Chart.js |
| SQL Features | Joins, Subqueries, Window Functions, Stored Procedures, Triggers, Views |

---

## 🚀 Setup & Run

### 1. Clone the repository
```bash
git clone https://github.com/manmeet2519/smart-retail-analytics.git
cd smart-retail-analytics
```

### 2. Configure database credentials
Create `smart_retail/.env`:
```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=smart_retail_db
DB_PORT=3306
```

### 3. Set up the database
```bash
cd smart_retail/database
python run_setup.py
```
This creates all tables, stored procedures, triggers, views, and seeds 100+ rows of data.

### 4. Install Python dependencies
```bash
cd smart_retail/backend
pip install -r requirements.txt
```

### 5. Start the backend
```bash
python app.py
# API running at http://localhost:5000
```

### 6. Open the frontend
Open `smart_retail/frontend/index.html` in your browser  
*(or serve with `python -m http.server 8080` from the frontend folder)*

---

## 🗄️ Database Schema

```
categories ──< products ──< transactions >── customers
                                │
stores ──────────────────────── │ ──────── employees
                                │
                         fraud_flags
                         demand_forecast
                         inventory_log
```

### Tables (9 total)

| Table | Rows | Description |
|---|---|---|
| `categories` | 5 | Product categories |
| `customers` | 10 | Customer profiles |
| `stores` | 5 | Store locations across 5 US cities |
| `employees` | 10 | Staff assigned to stores |
| `products` | 20 | Products with stock levels and reorder points |
| `transactions` | 102 | Sales records (Jan–Jul 2024) |
| `fraud_flags` | 7 | Auto-detected suspicious transactions |
| `demand_forecast` | 20 | Monthly predicted vs actual demand |
| `inventory_log` | 107 | Stock change history |

---

## 🧠 SQL Features Demonstrated

### Window Functions
```sql
-- Sales ranking with RANK, DENSE_RANK across categories
SELECT
    p.product_name,
    SUM(t.total_amount)                                        AS total_revenue,
    RANK()       OVER (ORDER BY SUM(t.total_amount) DESC)      AS revenue_rank,
    RANK()       OVER (PARTITION BY c.category_id
                       ORDER BY SUM(t.total_amount) DESC)      AS category_rank,
    DENSE_RANK() OVER (ORDER BY SUM(t.quantity) DESC)          AS units_rank
FROM transactions t
JOIN products p ON t.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
WHERE t.status = 'completed'
GROUP BY p.product_id, p.product_name, c.category_name, c.category_id;
```

```sql
-- Customer spending tiers using NTILE + PERCENT_RANK
SELECT
    c.name,
    SUM(t.total_amount)                                        AS total_spent,
    NTILE(4)  OVER (ORDER BY SUM(t.total_amount) DESC)         AS spending_quartile,
    PERCENT_RANK() OVER (ORDER BY SUM(t.total_amount))         AS spending_percentile,
    CASE NTILE(4) OVER (ORDER BY SUM(t.total_amount) DESC)
        WHEN 1 THEN 'Platinum' WHEN 2 THEN 'Gold'
        WHEN 3 THEN 'Silver'   ELSE 'Bronze'
    END AS customer_tier
FROM transactions t JOIN customers c ON t.customer_id = c.customer_id
WHERE t.status = 'completed'
GROUP BY c.customer_id, c.name, c.city;
```

```sql
-- Fraud detection using LAG + rolling window
SELECT
    t.transaction_id,
    t.total_amount,
    LAG(t.transaction_date) OVER (
        PARTITION BY t.customer_id ORDER BY t.transaction_date
    ) AS prev_transaction_date,
    TIMESTAMPDIFF(SECOND,
        LAG(t.transaction_date) OVER (
            PARTITION BY t.customer_id ORDER BY t.transaction_date),
        t.transaction_date
    ) AS seconds_since_last,
    COUNT(*) OVER (
        PARTITION BY t.customer_id
        ORDER BY t.transaction_date
        RANGE BETWEEN INTERVAL 1 HOUR PRECEDING AND CURRENT ROW
    ) AS tx_count_last_hour
FROM transactions t;
```

### Stored Procedures (3)

**`sp_get_sales_summary(start_date, end_date)`** — Returns 3 result sets: overall KPIs, top 5 products, top 5 stores for any date range.

**`sp_forecast_demand(product_id)`** — Calculates 3-month moving average demand, upserts into `demand_forecast`, returns 12-month history with stock status.

**`sp_detect_fraud()`** — Scans all transactions for 4 fraud patterns and inserts new flags into `fraud_flags`. Returns count of new flags inserted.

### Triggers (2)

**`trg_after_transaction_insert`** — Fires on every INSERT into `transactions`. Automatically checks for:
- Amount > $5,000 → `critical` flag
- Multiple purchases within 60 seconds → `high` flag  
- Late-night (12am–5am) + amount > $1,000 → `high` flag
- Quantity > 30 units → `medium` flag

**`trg_update_inventory`** — Fires on every completed transaction INSERT. Automatically deducts `stock_quantity` from `products` and logs the change to `inventory_log`.

### Views (4)

| View | Purpose |
|---|---|
| `vw_sales_ranking` | Product revenue/units ranking with window functions |
| `vw_running_total` | Daily revenue + running total + 7-day rolling avg per store |
| `vw_customer_spending` | Customer tiers (Platinum/Gold/Silver/Bronze) using NTILE |
| `vw_fraud_analysis` | Full fraud context with LAG, rolling counts, fraud indicators |

---

## 📊 Live Results

> Data from the running system — Jan 2024 to Jul 2024

### Overall KPIs

| Metric | Value |
|---|---|
| 💵 Total Revenue | **$36,231.14** |
| 🧾 Total Transactions | **98** (completed) |
| 📦 Units Sold | **286** |
| 👥 Unique Customers | **10** |
| 🚨 Fraud Alerts (unresolved) | **7** |
| ⚠️ Low Stock Items | **2** |

---

### 🏆 Top 5 Products by Revenue

| Rank | Product | Category | Units Sold | Revenue |
|---|---|---|---|---|
| 1 | Laptop UltraBook | Electronics | 20 | **$19,999.80** |
| 2 | Smartphone X12 | Electronics | 6 | **$4,199.94** |
| 3 | 4K Smart TV 55in | Electronics | 5 | **$2,749.95** |
| 4 | Cotton T-Shirt Pack | Clothing | 71 | **$1,774.29** |
| 5 | Winter Jacket | Clothing | 9 | **$1,169.91** |

---

### 💰 Revenue by Category

| Category | Revenue | Units Sold | Revenue Share |
|---|---|---|---|
| Electronics | $27,939.58 | 42 | 77.1% |
| Clothing | $4,433.95 | 105 | 12.2% |
| Sports | $1,704.55 | 45 | 4.7% |
| Home & Garden | $1,184.73 | 27 | 3.3% |
| Food | $968.33 | 67 | 2.7% |

---

### 🏪 Store Performance

| Store | City | Region | Transactions | Revenue | Avg Transaction |
|---|---|---|---|---|---|
| RetailHub Downtown | New York | Northeast | 21 | **$15,386.48** | $732.69 |
| RetailHub Southpark | Houston | South | 19 | **$8,604.44** | $452.87 |
| RetailHub Midtown | Chicago | Midwest | 19 | **$5,639.10** | $296.79 |
| RetailHub Westside | Los Angeles | West | 21 | **$4,239.57** | $201.88 |
| RetailHub Sunbelt | Phoenix | Southwest | 18 | **$2,361.55** | $131.20 |

---

### 🚨 Fraud Flags Detected

| Severity | Count | Description |
|---|---|---|
| 🔴 Critical | 1 | Amount > $5,000 |
| 🟠 High | 5 | Rapid succession / Late-night high-value |
| 🟡 Medium | 1 | Unusual quantity (50 units) |
| ✅ Resolved | 0 | — |
| **Total** | **7** | Auto-detected by SQL triggers |

**Sample fraud cases caught by triggers:**

| Flag | Customer | Product | Amount | Reason |
|---|---|---|---|---|
| #1 🔴 | Alice Johnson | Laptop UltraBook | $9,999.90 | High amount + Late-night (2:30am) |
| #3 🟠 | Carol White | Wireless Earbuds Pro | $179.98 | 3 purchases within 45 seconds |
| #4 🟠 | Carol White | 4K Smart TV 55in | $549.99 | Rapid succession (3:15am) |
| #5 🟡 | Eva Brown | Cotton T-Shirt Pack | $1,249.50 | 50 units in one transaction |
| #6 🟠 | Grace Wilson | Laptop UltraBook | $4,999.95 | Late-night high-value (11:55pm) |

---

### ⚠️ Low Stock Alerts

| Product | Category | In Stock | Reorder At | Units Needed |
|---|---|---|---|---|
| Laptop UltraBook | Electronics | **2** | 8 | 6 |
| Dumbbell Pair 20lb | Sports | **4** | 10 | 6 |

> Stock was automatically reduced by the `trg_update_inventory` trigger on every completed sale.

---

## 🌐 API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/health` | DB connection status |
| GET | `/api/dashboard` | KPIs + monthly revenue trend |
| GET | `/api/sales` | Filtered transactions + category breakdown |
| GET | `/api/transactions` | Paginated transaction list |
| POST | `/api/transactions` | Add transaction (triggers fire automatically) |
| GET | `/api/products` | All products with stock status |
| POST | `/api/products` | Add new product |
| PUT | `/api/products/:id` | Update product details |
| GET | `/api/demand` | Forecast data + low stock alerts |
| GET | `/api/fraud` | Fraud flags with severity/status filters |
| PUT | `/api/fraud/:id/resolve` | Mark a fraud flag as resolved |
| GET | `/api/run-fraud-detection` | Run `sp_detect_fraud` stored procedure |
| GET | `/api/top-products` | Top N products by revenue |
| GET | `/api/store-performance` | Revenue breakdown per store |
| GET | `/api/sales-summary` | Stored procedure: KPIs + top products + top stores |
| GET | `/api/customers` | Customer list with total spend |
| POST | `/api/customers` | Add new customer |
| GET | `/api/categories` | Category list |
| GET | `/api/stores` | Store list |
| GET | `/api/employees` | Employee list |
| GET | `/api/inventory` | Inventory change log |

---

## 🖥️ Frontend Pages

### 📊 Dashboard (`index.html`)
- 6 KPI stat cards (revenue, transactions, fraud alerts, low stock, customers, units)
- Monthly revenue trend line chart
- Store performance bar chart
- Top 8 products table
- Recent 8 transactions table

### 💰 Sales (`sales.html`)
- Filter by date range, store, and category
- Revenue by category doughnut chart
- Top products horizontal bar chart
- Full transactions table with sortable columns
- **Add new transaction form** — customer, product, store, employee, quantity, price, payment method

### 📈 Demand Forecast (`demand.html`)
- Low stock alerts table with reorder status
- Run forecast for any individual product (calls `sp_forecast_demand`)
- Predicted vs Actual demand line chart
- Full forecast table with accuracy percentages

### 🚨 Fraud Detection (`fraud.html`)
- 6 severity/status stat cards
- Fraud flags by severity doughnut chart
- Resolved vs Pending bar chart
- Filter flags by severity and status
- **Resolve button** on each pending flag
- **Run Detection button** — executes `sp_detect_fraud` stored procedure

---

## 📋 Requirements

```
flask==2.3.3
flask-cors==4.0.0
mysql-connector-python==8.1.0
python-dotenv==1.0.0
Werkzeug==2.3.7
```

---

## 👤 Author

**Manmeet** — [github.com/manmeet2519](https://github.com/manmeet2519)

---

*Built as a portfolio project demonstrating advanced SQL, backend API design, and interactive frontend development.*
