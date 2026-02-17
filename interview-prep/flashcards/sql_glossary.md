# SQL Glossary

| Term | Definition |
|------|------------|
| ACID | Atomicity, Consistency, Isolation, Durability |
| B-tree | Default index type; supports equality, range, ORDER BY |
| Cardinality | Number of distinct values in a column |
| Correlated subquery | Subquery that references outer query |
| Deadlock | Two transactions waiting for each other's locks |
| Denormalization | Introducing redundancy for read performance |
| FK | Foreign key; references another table's PK |
| GIN | Generalized Inverted Index; for JSONB, arrays |
| Isolation level | Degree to which transactions are isolated |
| JSONB | Binary JSON; indexed, queryable |
| Keyset pagination | WHERE id > last_id LIMIT n |
| Materialized view | Pre-computed query result; refreshed periodically |
| Normalization | Decomposing tables to reduce redundancy |
| PK | Primary key; uniquely identifies a row |
| Seq Scan | Full table scan |
| SQLSTATE | 5-char error code (e.g., 23505 = unique violation) |
| Surrogate key | Artificial key (e.g., auto-increment) |
| Transaction | Unit of work; all or nothing |
| WAL | Write-Ahead Log; for crash recovery |
