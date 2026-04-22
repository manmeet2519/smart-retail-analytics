"""
db.py - MySQL connection module with connection pooling
Smart Retail Demand & Fraud Analytics System
"""

import mysql.connector
from mysql.connector import pooling, Error
import os
from dotenv import load_dotenv

# Load .env from the smart_retail folder (one level up from backend/)
_env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
load_dotenv(dotenv_path=_env_path)

# ── Database configuration ────────────────────────────────────────────────────
DB_CONFIG = {
    "host":        os.getenv("DB_HOST",     "localhost"),
    "user":        os.getenv("DB_USER",     "root"),
    "password":    os.getenv("DB_PASSWORD", "root"),
    "database":    os.getenv("DB_NAME",     "smart_retail_db"),
    "port":        int(os.getenv("DB_PORT", 3306)),
    "charset":     "utf8mb4",
    "use_unicode": True,
    "autocommit":  False,
}

POOL_CONFIG = {
    "pool_name":          "smart_retail_pool",
    "pool_size":          5,
    "pool_reset_session": True,
}

# ── Connection pool (lazy-initialised) ───────────────────────────────────────
_pool = None


def _get_pool():
    """Return the singleton connection pool, creating it on first call."""
    global _pool
    if _pool is None:
        _pool = pooling.MySQLConnectionPool(**POOL_CONFIG, **DB_CONFIG)
    return _pool


def get_connection():
    """Borrow a connection from the pool."""
    return _get_pool().get_connection()


def execute_query(query: str, params: tuple = (), fetch: bool = True):
    """
    Execute a query and return rows as a list of dicts (fetch=True)
    or the row count (fetch=False).
    """
    conn = get_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(query, params)
        if fetch:
            result = cursor.fetchall()
        else:
            conn.commit()
            result = cursor.rowcount
        return result
    except Error as exc:
        conn.rollback()
        raise exc
    finally:
        cursor.close()
        conn.close()


def execute_many(query: str, params_list: list):
    """Execute an INSERT/UPDATE for multiple rows."""
    conn = get_connection()
    try:
        cursor = conn.cursor()
        cursor.executemany(query, params_list)
        conn.commit()
        return cursor.rowcount
    except Error as exc:
        conn.rollback()
        raise exc
    finally:
        cursor.close()
        conn.close()


def call_procedure(proc_name: str, args: tuple = ()):
    """
    Call a stored procedure and return all result sets as list[list[dict]].
    """
    conn = get_connection()
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.callproc(proc_name, args)
        results = []
        for result_set in cursor.stored_results():
            results.append(result_set.fetchall())
        conn.commit()
        return results
    except Error as exc:
        conn.rollback()
        raise exc
    finally:
        cursor.close()
        conn.close()


def test_connection() -> bool:
    """Ping the database; return True if reachable."""
    try:
        conn = get_connection()
        conn.ping(reconnect=True)
        conn.close()
        return True
    except Error:
        return False
