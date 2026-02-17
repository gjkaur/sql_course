# Denormalization Tradeoffs

## When to Consider

1. **Reporting queries** that JOIN 5+ tables and run frequently
2. **Read-heavy** workloads where write volume is low
3. **Real-time dashboards** that need sub-second response

## Options

### Materialized View

```sql
CREATE MATERIALIZED VIEW repair_order_summary AS
SELECT ro.id, v.vin, c.company_name, t.name AS technician_name,
       ro.opened_date, ro.status, ro.labor_hours, ro.parts_cost
FROM repair_orders ro
JOIN vehicles v ON ro.vehicle_id = v.id
JOIN customers c ON v.customer_id = c.id
JOIN technicians t ON ro.technician_id = t.id;
```

- **Refresh**: `REFRESH MATERIALIZED VIEW repair_order_summary;` (or CONCURRENTLY)
- **Trade-off**: Stale data until refresh. Use for batch reporting.

### Redundant Columns

Store `customer_id` in `repair_orders` to avoid joining through vehicles for "repairs by customer" queries.

- **Trade-off**: Must keep in sync on update. Use triggers or application logic.

### Summary Tables

Pre-aggregate (e.g., daily repair counts per technician).

- **Trade-off**: ETL complexity. Use for analytics.

## Fleet Repair Example

For "monthly repair report by customer", a materialized view or summary table is appropriate. For OLTP (creating repair orders, adding parts), keep normalized schema.
