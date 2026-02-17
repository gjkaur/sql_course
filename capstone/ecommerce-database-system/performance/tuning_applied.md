# Tuning Applied

## Indexes

- All FK columns indexed for JOIN performance
- Composite (status, created_at) for order reports
- GIN on products.attributes for JSONB queries
- Partial index on products(active) WHERE active = true

## Query Optimizations

- Use EXISTS instead of IN for large subqueries
- Avoid SELECT * in production; list columns
- Use covering indexes where beneficial (INCLUDE)

## Configuration (Optional)

- work_mem: 16MB for complex sorts/joins
- shared_buffers: 256MB (adjust for host RAM)
- random_page_cost: 1.1 for SSD
