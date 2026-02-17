"""
Module 5: Performance Logging
Logs query duration and connection pool stats.
"""

import time
import psycopg2
from functools import wraps


def log_query_time(func):
    """Decorator to log query execution time."""
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        elapsed = (time.perf_counter() - start) * 1000
        print(f"[PERF] {func.__name__} took {elapsed:.2f} ms")
        return result
    return wrapper


@log_query_time
def run_query(conn, query: str, params=None):
    """Execute query and return results."""
    with conn.cursor() as cur:
        cur.execute(query, params or ())
        return cur.fetchall()


def main():
    conn = psycopg2.connect(
        host="localhost",
        dbname="sqlcourse",
        user="sqlcourse",
        password="sqlcourse",
    )
    try:
        run_query(conn, "SELECT COUNT(*) FROM customers")
        run_query(conn, "SELECT * FROM customers WHERE id = %s", (1,))
        run_query(
            conn,
            """
            SELECT c.name, COUNT(o.id) FROM customers c
            LEFT JOIN orders o ON c.id = o.customer_id
            GROUP BY c.id, c.name
            """,
        )
    finally:
        conn.close()


if __name__ == "__main__":
    main()
