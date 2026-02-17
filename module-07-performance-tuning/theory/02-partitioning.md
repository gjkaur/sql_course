# Partitioning

## When to Partition

- Table too large for maintenance (VACUUM, backup)
- Query patterns filter by partition key (e.g., date)
- Need to drop old data quickly (detach partition)

## Types

- **Range**: By date range, ID range
- **List**: By region, category
- **Hash**: Distribute by hash of key

## Example: Range by Date

```sql
CREATE TABLE orders (
  id BIGSERIAL,
  customer_id BIGINT,
  order_date DATE,
  ...
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2024_01 PARTITION OF orders
  FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

## Query Pruning

Queries with `WHERE order_date >= '2024-01-01' AND order_date < '2024-02-01'` only scan the matching partition(s).

## Trade-offs

- **Pros**: Smaller partitions, faster scans, easier archival
- **Cons**: More objects, global indexes complex, constraint management
