"""
run_setup.py - Sets up the smart_retail_db database from SQL files.
Run from: smart_retail/database/
"""

import mysql.connector
import os
import re

DB_HOST     = "localhost"
DB_USER     = "root"
DB_PASSWORD = "manmeet"
DB_PORT     = 3306

SQL_FILES = ["schema.sql", "procedures.sql", "seed_data.sql"]


def split_statements(sql: str):
    """
    Split SQL text into individual statements, handling:
    - DELIMITER $$ blocks (stored procedures / triggers)
    - Regular ; terminated statements
    - Comments
    """
    statements = []
    delimiter  = ";"
    current    = []
    lines      = sql.splitlines()

    for line in lines:
        stripped = line.strip()

        # Skip pure comment lines
        if stripped.startswith("--") or stripped.startswith("#"):
            continue

        # Handle DELIMITER change
        if stripped.upper().startswith("DELIMITER"):
            parts = stripped.split()
            if len(parts) >= 2:
                delimiter = parts[1]
            continue

        current.append(line)

        # Check if line ends with current delimiter
        if stripped.endswith(delimiter):
            stmt = "\n".join(current).strip()
            # Remove trailing delimiter
            if stmt.endswith(delimiter):
                stmt = stmt[: -len(delimiter)].strip()
            if stmt:
                statements.append(stmt)
            current = []

    # Catch any remaining
    leftover = "\n".join(current).strip()
    if leftover:
        statements.append(leftover)

    return statements


def run_file(cursor, conn, filepath):
    print(f"\n{'='*55}")
    print(f"  Running: {os.path.basename(filepath)}")
    print(f"{'='*55}")

    with open(filepath, "r", encoding="utf-8") as f:
        sql = f.read()

    statements = split_statements(sql)
    ok = 0
    skipped = 0

    for stmt in statements:
        stmt = stmt.strip()
        if not stmt:
            continue
        try:
            # Multi-statement aware execution
            for result in cursor.execute(stmt, multi=True):
                try:
                    rows = result.fetchall()
                    if rows:
                        for row in rows:
                            print("  ", row)
                except Exception:
                    pass
            conn.commit()
            ok += 1
        except mysql.connector.Error as e:
            # Skip duplicate entry / already exists errors during re-run
            if e.errno in (1050, 1060, 1061, 1062, 1304, 1360, 1630):
                skipped += 1
            else:
                print(f"  [WARN] {e.errno}: {e.msg}")
                print(f"         Statement: {stmt[:80]}...")

    print(f"  Done — {ok} executed, {skipped} skipped (already exist)")


def main():
    print("\n" + "="*55)
    print("  Smart Retail DB Setup")
    print("="*55)

    # Connect without selecting a database first
    conn = mysql.connector.connect(
        host=DB_HOST, user=DB_USER, password=DB_PASSWORD,
        port=DB_PORT, charset="utf8mb4", autocommit=False
    )
    cursor = conn.cursor()
    print(f"  Connected to MySQL at {DB_HOST}:{DB_PORT}")

    base = os.path.dirname(os.path.abspath(__file__))

    for sql_file in SQL_FILES:
        path = os.path.join(base, sql_file)
        if not os.path.exists(path):
            print(f"  [SKIP] {sql_file} not found")
            continue
        run_file(cursor, conn, path)

    # Final counts
    cursor.execute("USE smart_retail_db;")
    tables = ["categories", "customers", "stores", "employees",
              "products", "transactions", "fraud_flags",
              "demand_forecast", "inventory_log"]
    print("\n" + "="*55)
    print("  Database Summary")
    print("="*55)
    for t in tables:
        try:
            cursor.execute(f"SELECT COUNT(*) FROM {t}")
            count = cursor.fetchone()[0]
            print(f"  {t:<20} {count:>5} rows")
        except Exception as e:
            print(f"  {t:<20} ERROR: {e}")

    cursor.close()
    conn.close()
    print("\n  Setup complete! ✓")
    print("="*55)


if __name__ == "__main__":
    main()
