# Lab 2: Index Design Lab

## Scenario

You have a table `events` (id, user_id, event_type, created_at) with 1M rows. Common queries:

1. All events for user_id = 123
2. All events of type 'click' in the last 7 days
3. Count events per user in January 2024
4. Latest 10 events for user 123

## Tasks

1. **Design indexes** for each query. Consider:
   - Single column vs composite
   - Order of columns in composite index
   - Covering index (INCLUDE) for index-only scan

2. **Write the CREATE INDEX statements**

3. **Run EXPLAIN** on each query with and without your indexes. Compare:
   - Seq Scan vs Index Scan
   - Execution time
   - Buffers (hit vs read)

4. **Trade-off**: How many indexes? Each index costs INSERT/UPDATE/DELETE. Would you create all four?
