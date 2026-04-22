# Smart Retail Demand & Fraud Analytics System

A full-stack analytics platform built with **MySQL · Python (Flask) · HTML/CSS/JS**.

---

## Project Structure

```
smart_retail/
├── .env                        ← DB credentials (edit this)
├── database/
│   ├── schema.sql              ← All tables with FK, indexes
│   ├── procedures.sql          ← Stored procedures, triggers, views
│   ├── seed_data.sql           ← 100+ transactions, products, customers
│   └── setup.sql               ← Run all 3 SQL files in order
├── backend/
│   ├── app.py                  ← Flask REST API (15+ endpoints)
│   ├── db.py                   ← MySQL connection pool
│   └── requirements.txt
└── frontend/
    ├── index.html              ← Dashboard
    ├── sales.html              ← Sales analytics + add transaction
    ├── demand.html             ← Demand forecast + low stock alerts
    ├── fraud.html              ← Fraud detection + resolve flags
    └── static/
        ├── style.css
        └── script.js
```

---

## Setup Instructions

### 1. Database

```bash
# Option A — run all at once
mysql -u root -p < database/schema.sql
mysql -u root -p < database/procedures.sql
mysql -u root -p < database/seed_data.sql

# Option B — MySQL Workbench
# Open and run each file in order: schema → procedures → seed_data
```

### 2. Configure credentials

Edit `smart_retail/.env`:
```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=smart_retail_db
DB_PORT=3306
```

### 3. Backend

```bash
cd smart_retail/backend
pip install -r requirements.txt
python app.py
# API running at http://localhost:5000
```

### 4. Frontend

Open any HTML file directly in your browser:
```
smart_retail/frontend/index.html
```
Or serve with Python:
```bash
cd smart_retail/frontend
python -m http.server 8080
# Open http://localhost:8080
```

---

## SQL Features Demonstrated

| Feature | Where Used |
|---|---|
| Complex JOINs (4-5 tables) | All API queries |
| Subqueries | Fraud detection, demand forecast |
| Window Functions (RANK, DENSE_RANK, LAG, NTILE, SUM OVER, AVG OVER) | `vw_sales_ranking`, `vw_customer_spending`, `vw_fraud_analysis` |
| Stored Procedures | `sp_get_sales_summary`, `sp_forecast_demand`, `sp_detect_fraud` |
| Triggers | `trg_after_transaction_insert` (fraud), `trg_update_inventory` (stock) |
| Views | 4 analytical views |
| Indexes | All FK columns + frequently queried fields |
| ENUM types | payment_method, status, severity, change_type |

---

## API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | /api/health | DB connection check |
| GET | /api/dashboard | Summary stats + monthly trend |
| GET | /api/sales | Filtered transactions + category breakdown |
| GET | /api/transactions | Paginated transaction list |
| POST | /api/transactions | Add new transaction (triggers fire) |
| GET | /api/products | All products with stock status |
| POST | /api/products | Add new product |
| GET | /api/demand | Forecast data + low stock alerts |
| GET | /api/fraud | Fraud flags with filters |
| PUT | /api/fraud/:id/resolve | Mark flag as resolved |
| GET | /api/run-fraud-detection | Run sp_detect_fraud procedure |
| GET | /api/top-products | Top N products by revenue |
| GET | /api/store-performance | Revenue per store |
| GET | /api/sales-summary | Stored procedure summary |
| GET | /api/customers | Customer list with spend totals |
| POST | /api/customers | Add new customer |
| GET | /api/categories | Category list |
| GET | /api/stores | Store list |
| GET | /api/employees | Employee list |
| GET | /api/inventory | Inventory change log |

---

## Fraud Detection Rules

1. **Critical** — Transaction amount > $5,000
2. **High** — Multiple transactions by same customer within 60 seconds
3. **High** — Late-night transaction (12am–5am) with amount > $1,000
4. **Medium** — Quantity > 30 units in a single transaction

Fraud is detected automatically via **SQL triggers** on every INSERT, and can also be run manually via the stored procedure `sp_detect_fraud`.
