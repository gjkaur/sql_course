"""
Module 5: Database connection with pooling
"""

import os
import psycopg2
from psycopg2 import pool
from contextlib import contextmanager

# Connection pool (initialized on first use)
_connection_pool = None


def get_pool():
    global _connection_pool
    if _connection_pool is None:
        _connection_pool = pool.ThreadedConnectionPool(
            minconn=1,
            maxconn=10,
            host=os.getenv("DB_HOST", "localhost"),
            port=os.getenv("DB_PORT", "5432"),
            dbname=os.getenv("DB_NAME", "sqlcourse"),
            user=os.getenv("DB_USER", "sqlcourse"),
            password=os.getenv("DB_PASSWORD", "sqlcourse"),
        )
    return _connection_pool


@contextmanager
def get_db():
    """Yield a connection from the pool."""
    conn = get_pool().getconn()
    try:
        yield conn
    finally:
        get_pool().putconn(conn)


def init_db():
    """Ensure customers table exists (for demo)."""
    with get_db() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT 1 FROM information_schema.tables
                WHERE table_schema = 'public' AND table_name = 'customers'
            """)
            if not cur.fetchone():
                raise RuntimeError(
                    "customers table not found. Run module-01 schema and seed first."
                )
