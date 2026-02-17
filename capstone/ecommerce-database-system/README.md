# Capstone: Enterprise E-Commerce Database System

A production-grade database design for an e-commerce platform. Portfolio-ready project demonstrating schema design, indexing, security, transactions, JSON, and performance tuning.

## Features

- Full schema: users, products, categories, orders, payments, inventory, reviews
- Index strategy with rationale
- Role-based security (customer, seller, admin, analytics)
- Transaction boundaries for checkout
- JSONB for product attributes
- Reporting queries with EXPLAIN analysis
- Python API integration demo

## Quick Start

```bash
# Run schema
psql -h localhost -U sqlcourse -d sqlcourse -f schema/01_schema.sql
psql -h localhost -U sqlcourse -d sqlcourse -f schema/02_constraints.sql
psql -h localhost -U sqlcourse -d sqlcourse -f schema/03_indexes.sql
psql -h localhost -U sqlcourse -d sqlcourse -f schema/04_roles.sql
psql -h localhost -U sqlcourse -d sqlcourse -f seeds/seed_data.sql
```

## Structure

```
capstone/ecommerce-database-system/
├── docs/           # Architecture, ER diagram, performance report
├── schema/         # DDL scripts
├── seeds/          # Sample data
├── queries/        # Reporting and analytics
├── application/    # FastAPI demo
└── performance/    # Tuning and EXPLAIN analysis
```
