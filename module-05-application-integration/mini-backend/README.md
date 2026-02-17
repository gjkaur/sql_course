# Mini Backend: FastAPI + PostgreSQL

## Setup

```bash
# Install dependencies
pip install -r requirements.txt

# Ensure PostgreSQL is running (docker-compose up -d)
# Run Module 1 schema and seed first
psql -h localhost -U sqlcourse -d sqlcourse -f ../../module-01-sql-concepts/project/schema.sql
psql -h localhost -U sqlcourse -d sqlcourse -f ../../module-01-sql-concepts/project/seed_data.sql

# Optional: set env vars
export DB_HOST=localhost DB_USER=sqlcourse DB_PASSWORD=sqlcourse DB_NAME=sqlcourse

# Run server
uvicorn app.main:app --reload
```

## Endpoints

- `GET /health` - Health check
- `GET /customers` - List all customers
- `GET /customers/{id}` - Get customer by ID
- `POST /customers` - Create customer

## Test

```bash
curl http://localhost:8000/customers
curl -X POST http://localhost:8000/customers -H "Content-Type: application/json" -d '{"name":"Test","email":"test@example.com"}'
```
