"""
app.py - Flask backend for Smart Retail Demand & Fraud Analytics System
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from mysql.connector import Error
from datetime import datetime, date
import decimal
import json

from db import execute_query, call_procedure, execute_many, test_connection

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})


# ── JSON serialisation helper ─────────────────────────────────────────────────
def _serialise(obj):
    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    if isinstance(obj, decimal.Decimal):
        return float(obj)
    raise TypeError(f"Type {type(obj)} not serialisable")


def ok(data, status: int = 200):
    return app.response_class(
        response=json.dumps(data, default=_serialise),
        status=status,
        mimetype="application/json",
    )


def err(message: str, status: int = 500):
    return jsonify({"error": message}), status


# ── Health check ──────────────────────────────────────────────────────────────
@app.route("/api/health", methods=["GET"])
def health():
    alive = test_connection()
    return ok({"status": "ok" if alive else "db_unreachable", "db": alive})


# ── Dashboard summary ─────────────────────────────────────────────────────────
@app.route("/api/dashboard", methods=["GET"])
def dashboard():
    try:
        summary = execute_query("""
            SELECT
                COALESCE(SUM(total_amount), 0)      AS total_revenue,
                COUNT(*)                             AS total_transactions,
                COALESCE(SUM(quantity), 0)           AS total_units_sold,
                COUNT(DISTINCT customer_id)          AS unique_customers
            FROM transactions
            WHERE status = 'completed'
        """)[0]

        fraud_count = execute_query("""
            SELECT COUNT(*) AS fraud_count
            FROM fraud_flags
            WHERE resolved = 0
        """)[0]["fraud_count"]

        low_stock = execute_query("""
            SELECT COUNT(*) AS low_stock_count
            FROM products
            WHERE stock_quantity <= reorder_level
        """)[0]["low_stock_count"]

        monthly = execute_query("""
            SELECT
                DATE_FORMAT(transaction_date, '%Y-%m') AS month,
                SUM(total_amount)                       AS revenue,
                COUNT(*)                                AS transactions
            FROM transactions
            WHERE status = 'completed'
              AND transaction_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
            GROUP BY DATE_FORMAT(transaction_date, '%Y-%m')
            ORDER BY month
        """)

        return ok({
            "summary": {
                **summary,
                "fraud_alerts":    fraud_count,
                "low_stock_items": low_stock,
            },
            "monthly_trend": monthly,
        })
    except Error as e:
        return err(str(e))


# ── Sales ─────────────────────────────────────────────────────────────────────
@app.route("/api/sales", methods=["GET"])
def sales():
    start_date  = request.args.get("start_date", "2024-01-01")
    end_date    = request.args.get("end_date",   date.today().isoformat())
    store_id    = request.args.get("store_id")
    category_id = request.args.get("category_id")

    where  = ["t.status = 'completed'",
              "DATE(t.transaction_date) BETWEEN %s AND %s"]
    params = [start_date, end_date]

    if store_id:
        where.append("t.store_id = %s")
        params.append(int(store_id))
    if category_id:
        where.append("p.category_id = %s")
        params.append(int(category_id))

    where_clause = " AND ".join(where)

    try:
        rows = execute_query(f"""
            SELECT
                t.transaction_id,
                t.transaction_date,
                c.name          AS customer_name,
                p.product_name,
                cat.category_name,
                s.store_name,
                t.quantity,
                t.unit_price,
                t.total_amount,
                t.payment_method
            FROM transactions t
            JOIN customers  c   ON t.customer_id  = c.customer_id
            JOIN products   p   ON t.product_id   = p.product_id
            JOIN categories cat ON p.category_id  = cat.category_id
            JOIN stores     s   ON t.store_id     = s.store_id
            WHERE {where_clause}
            ORDER BY t.transaction_date DESC
            LIMIT 500
        """, tuple(params))

        by_category = execute_query(f"""
            SELECT
                cat.category_name,
                SUM(t.total_amount) AS revenue,
                SUM(t.quantity)     AS units_sold
            FROM transactions t
            JOIN products   p   ON t.product_id  = p.product_id
            JOIN categories cat ON p.category_id = cat.category_id
            WHERE {where_clause}
            GROUP BY cat.category_name
            ORDER BY revenue DESC
        """, tuple(params))

        return ok({"transactions": rows, "by_category": by_category})
    except Error as e:
        return err(str(e))


# ── Products ──────────────────────────────────────────────────────────────────
@app.route("/api/products", methods=["GET"])
def get_products():
    try:
        rows = execute_query("""
            SELECT
                p.product_id,
                p.product_name,
                c.category_name,
                p.price,
                p.stock_quantity,
                p.reorder_level,
                CASE WHEN p.stock_quantity <= p.reorder_level THEN 1 ELSE 0 END AS low_stock,
                p.created_at
            FROM products p
            JOIN categories c ON p.category_id = c.category_id
            ORDER BY p.product_name
        """)
        return ok(rows)
    except Error as e:
        return err(str(e))


@app.route("/api/products", methods=["POST"])
def add_product():
    data = request.get_json(silent=True) or {}
    required = ["product_name", "category_id", "price", "stock_quantity", "reorder_level"]
    missing  = [f for f in required if f not in data]
    if missing:
        return err(f"Missing fields: {missing}", 400)
    try:
        execute_query("""
            INSERT INTO products (product_name, category_id, price, stock_quantity, reorder_level)
            VALUES (%s, %s, %s, %s, %s)
        """, (data["product_name"], data["category_id"],
              data["price"], data["stock_quantity"], data["reorder_level"]),
            fetch=False)
        return ok({"message": "Product created"}, 201)
    except Error as e:
        return err(str(e))


@app.route("/api/products/<int:product_id>", methods=["PUT"])
def update_product(product_id):
    data = request.get_json(silent=True) or {}
    try:
        execute_query("""
            UPDATE products
            SET product_name   = %s,
                price          = %s,
                stock_quantity = %s,
                reorder_level  = %s
            WHERE product_id = %s
        """, (data.get("product_name"), data.get("price"),
              data.get("stock_quantity"), data.get("reorder_level"),
              product_id), fetch=False)
        return ok({"message": "Product updated"})
    except Error as e:
        return err(str(e))


# ── Demand forecast ───────────────────────────────────────────────────────────
@app.route("/api/demand", methods=["GET"])
def demand():
    product_id = request.args.get("product_id")
    try:
        if product_id:
            results = call_procedure("sp_forecast_demand", (int(product_id),))
            rows    = results[0] if results else []
        else:
            rows = execute_query("""
                SELECT
                    df.forecast_id,
                    p.product_name,
                    df.forecast_date,
                    df.predicted_demand,
                    df.actual_demand,
                    df.accuracy_pct,
                    p.stock_quantity,
                    p.reorder_level,
                    CASE WHEN p.stock_quantity <= p.reorder_level
                         THEN 'REORDER NEEDED' ELSE 'OK'
                    END AS stock_status
                FROM demand_forecast df
                JOIN products p ON df.product_id = p.product_id
                ORDER BY df.forecast_date DESC, p.product_name
            """)

        low_stock = execute_query("""
            SELECT
                p.product_id,
                p.product_name,
                c.category_name,
                p.stock_quantity,
                p.reorder_level,
                (p.reorder_level - p.stock_quantity) AS units_needed
            FROM products p
            JOIN categories c ON p.category_id = c.category_id
            WHERE p.stock_quantity <= p.reorder_level
            ORDER BY units_needed DESC
        """)

        return ok({"forecast": rows, "low_stock_alerts": low_stock})
    except Error as e:
        return err(str(e))


# ── Fraud ─────────────────────────────────────────────────────────────────────
@app.route("/api/fraud", methods=["GET"])
def fraud():
    severity = request.args.get("severity")
    resolved = request.args.get("resolved")

    where  = ["1=1"]
    params = []
    if severity:
        where.append("ff.severity = %s")
        params.append(severity)
    if resolved is not None:
        where.append("ff.resolved = %s")
        params.append(int(resolved))

    where_clause = " AND ".join(where)

    try:
        flags = execute_query(f"""
            SELECT
                ff.flag_id,
                ff.transaction_id,
                ff.flag_reason,
                ff.flagged_at,
                ff.severity,
                ff.resolved,
                t.total_amount,
                t.transaction_date,
                t.payment_method,
                t.quantity,
                c.name       AS customer_name,
                p.product_name,
                s.store_name
            FROM fraud_flags ff
            JOIN transactions t ON ff.transaction_id = t.transaction_id
            JOIN customers    c ON t.customer_id     = c.customer_id
            JOIN products     p ON t.product_id      = p.product_id
            JOIN stores       s ON t.store_id        = s.store_id
            WHERE {where_clause}
            ORDER BY ff.flagged_at DESC
        """, tuple(params))

        stats = execute_query("""
            SELECT
                COUNT(*)                                     AS total_flagged,
                SUM(resolved = 1)                            AS resolved_count,
                SUM(resolved = 0)                            AS pending_count,
                SUM(severity = 'critical' AND resolved = 0) AS critical_pending,
                SUM(severity = 'high'     AND resolved = 0) AS high_pending,
                SUM(severity = 'medium'   AND resolved = 0) AS medium_pending,
                SUM(severity = 'low'      AND resolved = 0) AS low_pending
            FROM fraud_flags
        """)[0]

        return ok({"flags": flags, "stats": stats})
    except Error as e:
        return err(str(e))


@app.route("/api/fraud/<int:flag_id>/resolve", methods=["PUT"])
def resolve_fraud(flag_id):
    try:
        execute_query(
            "UPDATE fraud_flags SET resolved = 1 WHERE flag_id = %s",
            (flag_id,), fetch=False
        )
        return ok({"message": "Flag resolved"})
    except Error as e:
        return err(str(e))


@app.route("/api/run-fraud-detection", methods=["GET"])
def run_fraud_detection():
    try:
        results   = call_procedure("sp_detect_fraud")
        new_flags = results[0][0]["new_flags_inserted"] if results and results[0] else 0
        return ok({"message": "Fraud detection complete", "new_flags_inserted": new_flags})
    except Error as e:
        return err(str(e))


# ── Transactions ──────────────────────────────────────────────────────────────
@app.route("/api/transactions", methods=["GET"])
def get_transactions():
    page     = max(1, int(request.args.get("page", 1)))
    per_page = min(100, int(request.args.get("per_page", 20)))
    offset   = (page - 1) * per_page

    try:
        total = execute_query("SELECT COUNT(*) AS cnt FROM transactions")[0]["cnt"]

        rows = execute_query("""
            SELECT
                t.transaction_id,
                t.transaction_date,
                c.name       AS customer_name,
                p.product_name,
                s.store_name,
                t.quantity,
                t.unit_price,
                t.total_amount,
                t.payment_method,
                t.status,
                CASE WHEN ff.flag_id IS NOT NULL THEN 1 ELSE 0 END AS is_flagged
            FROM transactions t
            JOIN customers c ON t.customer_id = c.customer_id
            JOIN products  p ON t.product_id  = p.product_id
            JOIN stores    s ON t.store_id    = s.store_id
            LEFT JOIN fraud_flags ff ON t.transaction_id = ff.transaction_id
            GROUP BY t.transaction_id
            ORDER BY t.transaction_date DESC
            LIMIT %s OFFSET %s
        """, (per_page, offset))

        return ok({
            "transactions": rows,
            "pagination": {
                "page":     page,
                "per_page": per_page,
                "total":    total,
                "pages":    -(-total // per_page),
            },
        })
    except Error as e:
        return err(str(e))


@app.route("/api/transactions", methods=["POST"])
def add_transaction():
    data = request.get_json(silent=True) or {}
    required = ["customer_id", "product_id", "store_id", "employee_id",
                "quantity", "unit_price", "payment_method"]
    missing = [f for f in required if f not in data]
    if missing:
        return err(f"Missing fields: {missing}", 400)

    total = float(data["quantity"]) * float(data["unit_price"])

    try:
        execute_query("""
            INSERT INTO transactions
                (customer_id, product_id, store_id, employee_id,
                 quantity, unit_price, total_amount, payment_method, status)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 'completed')
        """, (data["customer_id"], data["product_id"], data["store_id"],
              data["employee_id"], data["quantity"], data["unit_price"],
              total, data["payment_method"]),
            fetch=False)
        return ok({"message": "Transaction created", "total_amount": total}, 201)
    except Error as e:
        return err(str(e))


# ── Top products ──────────────────────────────────────────────────────────────
@app.route("/api/top-products", methods=["GET"])
def top_products():
    limit = min(20, int(request.args.get("limit", 10)))
    try:
        rows = execute_query("""
            SELECT
                p.product_id,
                p.product_name,
                c.category_name,
                SUM(t.quantity)     AS units_sold,
                SUM(t.total_amount) AS revenue,
                COUNT(*)            AS transaction_count
            FROM transactions t
            JOIN products   p ON t.product_id  = p.product_id
            JOIN categories c ON p.category_id = c.category_id
            WHERE t.status = 'completed'
            GROUP BY p.product_id, p.product_name, c.category_name
            ORDER BY revenue DESC
            LIMIT %s
        """, (limit,))
        return ok(rows)
    except Error as e:
        return err(str(e))


# ── Store performance ─────────────────────────────────────────────────────────
@app.route("/api/store-performance", methods=["GET"])
def store_performance():
    try:
        rows = execute_query("""
            SELECT
                s.store_id,
                s.store_name,
                s.city,
                s.region,
                s.manager_name,
                COUNT(t.transaction_id)          AS total_transactions,
                COALESCE(SUM(t.total_amount), 0) AS total_revenue,
                COALESCE(AVG(t.total_amount), 0) AS avg_transaction,
                COUNT(DISTINCT t.customer_id)    AS unique_customers
            FROM stores s
            LEFT JOIN transactions t
                ON s.store_id = t.store_id AND t.status = 'completed'
            GROUP BY s.store_id, s.store_name, s.city, s.region, s.manager_name
            ORDER BY total_revenue DESC
        """)
        return ok(rows)
    except Error as e:
        return err(str(e))


# ── Sales summary procedure ───────────────────────────────────────────────────
@app.route("/api/sales-summary", methods=["GET"])
def sales_summary():
    start = request.args.get("start_date", "2024-01-01")
    end   = request.args.get("end_date",   date.today().isoformat())
    try:
        results = call_procedure("sp_get_sales_summary", (start, end))
        return ok({
            "summary":      results[0][0] if len(results) > 0 and results[0] else {},
            "top_products": results[1]    if len(results) > 1 else [],
            "top_stores":   results[2]    if len(results) > 2 else [],
        })
    except Error as e:
        return err(str(e))


# ── Customers ─────────────────────────────────────────────────────────────────
@app.route("/api/customers", methods=["GET"])
def get_customers():
    try:
        rows = execute_query("""
            SELECT
                c.customer_id,
                c.name,
                c.email,
                c.phone,
                c.city,
                c.country,
                COUNT(t.transaction_id)          AS total_transactions,
                COALESCE(SUM(t.total_amount), 0) AS total_spent,
                c.created_at
            FROM customers c
            LEFT JOIN transactions t
                ON c.customer_id = t.customer_id AND t.status = 'completed'
            GROUP BY c.customer_id
            ORDER BY total_spent DESC
        """)
        return ok(rows)
    except Error as e:
        return err(str(e))


@app.route("/api/customers", methods=["POST"])
def add_customer():
    data = request.get_json(silent=True) or {}
    required = ["name", "email"]
    missing  = [f for f in required if f not in data]
    if missing:
        return err(f"Missing fields: {missing}", 400)
    try:
        execute_query("""
            INSERT INTO customers (name, email, phone, address, city, country)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (data["name"], data["email"],
              data.get("phone", ""), data.get("address", ""),
              data.get("city", ""), data.get("country", "USA")),
            fetch=False)
        return ok({"message": "Customer created"}, 201)
    except Error as e:
        return err(str(e))


# ── Categories & stores (for filter dropdowns) ────────────────────────────────
@app.route("/api/categories", methods=["GET"])
def categories():
    try:
        return ok(execute_query("SELECT * FROM categories ORDER BY category_name"))
    except Error as e:
        return err(str(e))


@app.route("/api/stores", methods=["GET"])
def stores():
    try:
        return ok(execute_query("SELECT * FROM stores ORDER BY store_name"))
    except Error as e:
        return err(str(e))


@app.route("/api/employees", methods=["GET"])
def employees():
    try:
        rows = execute_query("""
            SELECT e.employee_id, e.name, e.role, s.store_name
            FROM employees e
            JOIN stores s ON e.store_id = s.store_id
            ORDER BY e.name
        """)
        return ok(rows)
    except Error as e:
        return err(str(e))


# ── Inventory log ─────────────────────────────────────────────────────────────
@app.route("/api/inventory", methods=["GET"])
def inventory():
    try:
        rows = execute_query("""
            SELECT
                il.log_id,
                p.product_name,
                s.store_name,
                il.change_type,
                il.quantity_change,
                il.log_date,
                il.notes
            FROM inventory_log il
            JOIN products p ON il.product_id = p.product_id
            JOIN stores   s ON il.store_id   = s.store_id
            ORDER BY il.log_date DESC
            LIMIT 200
        """)
        return ok(rows)
    except Error as e:
        return err(str(e))


# ── Entry point ───────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 55)
    print("  Smart Retail Analytics — Flask API")
    print("  http://localhost:5000")
    print("=" * 55)
    app.run(debug=True, host="0.0.0.0", port=5000)
