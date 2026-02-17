# Optimization Report Template

## Scenario

Large orders table (100K+ rows), slow queries for:
- Orders by customer_id
- Orders by status
- Orders by date range

## Step 1: Baseline

Run EXPLAIN (ANALYZE, BUFFERS) on each query. Record:
- Execution time
- Plan (Seq Scan vs Index Scan)
- Rows estimated vs actual

## Step 2: Index Recommendations

| Query Pattern | Index | Rationale |
|---------------|-------|-----------|
| WHERE customer_id = ? | CREATE INDEX idx_lo_customer ON large_orders(customer_id) | FK, equality |
| WHERE status = ? | CREATE INDEX idx_lo_status ON large_orders(status) | Filter |
| WHERE order_date > ? | CREATE INDEX idx_lo_date ON large_orders(order_date) | Range |
| Composite: status + date | CREATE INDEX idx_lo_status_date ON large_orders(status, order_date) | Common report |

## Step 3: Apply Indexes

```sql
CREATE INDEX idx_lo_customer ON large_orders(customer_id);
CREATE INDEX idx_lo_status ON large_orders(status);
CREATE INDEX idx_lo_date ON large_orders(order_date);
ANALYZE large_orders;
```

## Step 4: Verify

Re-run EXPLAIN (ANALYZE). Compare execution time and plan.

## Step 5: Partitioning Decision

If table grows to millions and queries are date-range heavy, consider:

```sql
-- Partition by month
CREATE TABLE large_orders_partitioned (
  LIKE large_orders
) PARTITION BY RANGE (order_date);
```

## Conclusion

Document before/after metrics. Indexes reduced query time from Xms to Yms.
