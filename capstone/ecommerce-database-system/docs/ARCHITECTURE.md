# E-Commerce Database Architecture

## Design Decisions

### Schema

- **Normalized to 3NF** for core entities (users, products, orders)
- **JSONB for product attributes** (size, color, specs) — flexible per category
- **Surrogate keys** (BIGSERIAL) for stability and simple joins
- **Soft delete** via `deleted_at` where audit trail matters

### Index Strategy

- B-tree on all FK columns for JOINs
- Composite indexes for common filters (status + date)
- GIN on JSONB attributes for product search
- BRIN on order_date for large time-series (optional)

### Transaction Boundaries

- **Checkout**: Single transaction: create order, create items, update inventory, create payment
- **Short transactions** to minimize lock duration

### Security

- Least privilege: customer (own data), seller (own products/orders), admin (full), analytics (read-only)
- Row-level security (RLS) for multi-tenant isolation (optional)
