# Performance Report

## Baseline (Before Optimization)

- Orders by user: Seq Scan, ~50ms (10K orders)
- Products by category: Seq Scan, ~20ms
- Monthly sales report: Hash Join + Sort, ~100ms

## Optimizations Applied

1. **Index on orders(user_id)** — Index Scan, ~2ms
2. **Index on products(category_id)** — Index Scan, ~1ms
3. **Composite index on orders(status, created_at)** — Report query uses index, ~15ms
4. **GIN index on products.attributes** — JSONB containment queries, ~5ms

## Before/After Metrics

| Query | Before | After |
|-------|--------|-------|
| Orders by user | 50ms | 2ms |
| Products by category | 20ms | 1ms |
| Monthly sales | 100ms | 15ms |

## Recommendations

- Enable pg_stat_statements for production monitoring
- Consider partitioning orders by created_at when > 10M rows
- Materialized view for daily sales summary if report is run frequently
