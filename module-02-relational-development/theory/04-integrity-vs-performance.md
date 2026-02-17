# Integrity vs Performance Tradeoff

## The Tension

- **Integrity**: Normalized schema, constraints, consistency
- **Performance**: Fewer JOINs, denormalization, caching

## Strategies

### 1. Normalize First

Design in 3NF. Add denormalization only when profiling shows a bottleneck.

### 2. Materialized Views

Pre-compute expensive joins/aggregates. Refresh periodically. Good for reporting.

### 3. Caching

Application-level cache (Redis) for hot data. Invalidate on write.

### 4. Read Replicas

Offload reporting to replicas. Accept eventual consistency for analytics.

### 5. Partitioning

Split large tables by range/list. Improves query pruning and maintenance.

## Decision Framework

| Scenario | Recommendation |
|----------|----------------|
| OLTP, high write rate | Normalize, short transactions |
| OLAP, read-heavy | Denormalize, materialized views |
| Mixed workload | Normalize base, add reporting layer |

## Interview Insight

**Q: When would you denormalize?**

A: When a specific query is slow and profiling shows JOINs as the bottleneck. After normalizing first. For read-heavy reporting tables or materialized views. Document the trade-off and maintain consistency via triggers or ETL.
