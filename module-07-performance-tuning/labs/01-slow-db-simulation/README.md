# Slow DB Simulation

## Purpose

Create a scenario with large tables and poor indexing for optimization practice.

## Steps

1. Run `seed_large_data.sql` to create 10K customers and 100K orders
2. Run EXPLAIN (ANALYZE) on the queries at the bottom
3. Note: Seq Scan, execution time
4. Add indexes (see optimization report)
5. Re-run, compare

## Expected Before/After

- Before: Seq Scan, ~100ms+
- After: Index Scan, <10ms
