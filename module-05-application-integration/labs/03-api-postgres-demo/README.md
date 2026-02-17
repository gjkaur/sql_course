# API + PostgreSQL Demo

This demo is implemented in the parent `mini-backend` folder.

See: `../mini-backend/` for the FastAPI + PostgreSQL integration.

## Key Concepts

- Connection pooling via psycopg2
- Parameterized queries (no SQL injection)
- Transaction management (commit on success)
- Dependency injection for DB connection
