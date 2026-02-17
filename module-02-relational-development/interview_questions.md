# Module 2: Interview Questions

## SDLC

1. **How do you approach a new database design?**
   - Requirements first, ER model, normalize to 3NF, denormalize only where profiling shows need.

2. **What deliverables do you produce during database design?**
   - ER diagram, schema DDL, index strategy, migration plan.

## Normalization

3. **What is 1NF?**
   - Atomic values, no repeating groups, unique rows with a primary key.

4. **What is the difference between 2NF and 3NF?**
   - 2NF: no partial dependencies. 3NF: no transitive dependencies.

5. **Give an example of an update anomaly.**
   - Customer email stored in every order row; changing email requires updating many rows.

6. **When would you denormalize?**
   - When a specific query is slow and JOINs are the bottleneck; for read-heavy reporting.

## Indexes

7. **When should you index a column?**
   - FK columns (for JOINs), columns in WHERE/JOIN, columns in ORDER BY. When read benefit outweighs write cost.

8. **What is a composite index? When is column order important?**
   - Index on (a, b, c). Left-prefix rule: (a), (a,b), (a,b,c) can use it; (b) or (c) alone cannot. Put most selective column first for equality, range column last.

9. **What is an index-only scan?**
   - Query can be satisfied entirely from the index without touching the table. Use INCLUDE for covering index.

## Execution Plans

10. **How do you debug a slow query?**
    - EXPLAIN (ANALYZE, BUFFERS), look for Seq Scan on large tables, high cost nodes, large row estimates.

11. **What does "Seq Scan" mean? When is it acceptable?**
    - Full table scan. Acceptable for small tables or when most rows are returned.

12. **What is the difference between Hash Join and Nested Loop?**
    - Nested Loop: small inner table, index on join column. Hash Join: larger tables, equality join, builds hash table.
