# BOOK 8 – Appendix A: SQL Glossary

---

Engineer-level definitions for interview prep and quick reference.

---

## A–C

| Term | Definition |
|------|------------|
| **ACID** | Atomicity, Consistency, Isolation, Durability. Properties of reliable transactions. |
| **Advisory lock** | Application-controlled lock (e.g., `pg_advisory_lock`). Coordinate across sessions without locking rows. |
| **Aggregate** | Function over a set of rows: COUNT, SUM, AVG, MIN, MAX. |
| **Anomaly** | Insert, update, or delete anomaly. Unintended side effect from redundancy. |
| **Assertion** | Multi-table constraint. Not implemented in PostgreSQL. Use triggers. |
| **Atomicity** | All or nothing. Transaction either commits fully or rolls back fully. |
| **B-tree** | Default index type. Supports equality, range, ORDER BY. |
| **BCNF** | Boyce-Codd Normal Form. Every determinant is a candidate key. |
| **Bloat** | Dead tuples or index entries. Space not reclaimed. VACUUM, REINDEX. |
| **BRIN** | Block Range Index. For large sorted tables (e.g., time-series). Small index. |
| **Cardinality** | Number of distinct values in a column. Affects index usefulness. |
| **Checkpoint** | Flush dirty buffers to disk. WAL position for recovery. |
| **CLI** | Call-Level Interface. Library (ODBC, JDBC, psycopg2) that sends SQL as strings. |
| **Closure** | Set of all attributes functionally dependent on a given set. |
| **Composite key** | Primary key of multiple columns. |
| **Consistency** | Constraints hold before and after transaction. (ACID) |
| **Constraint** | NOT NULL, UNIQUE, CHECK, PRIMARY KEY, FOREIGN KEY. |
| **Correlated subquery** | Subquery that references outer query. Executed per outer row. |
| **Covering index** | Index that contains all columns needed for query. Index-only scan. |
| **Cursor** | Server-side handle for row-by-row fetch. |
| **CVE** | Common Vulnerabilities and Exposures. (SQL injection is a class.) |

---

## D–F

| Term | Definition |
|------|------------|
| **Deadlock** | Two transactions waiting for each other's locks. DB aborts victim. |
| **Denormalization** | Introducing redundancy for read performance. Trade-off: consistency. |
| **Derived table** | Subquery in FROM. Must have alias. |
| **Determinant** | Left side of functional dependency. X in X → Y. |
| **Dirty read** | Reading uncommitted data. PostgreSQL prevents at all isolation levels. |
| **DML** | Data Manipulation Language. SELECT, INSERT, UPDATE, DELETE. |
| **DDL** | Data Definition Language. CREATE, ALTER, DROP. |
| **DCL** | Data Control Language. GRANT, REVOKE. |
| **Durability** | Committed data survives crash. WAL, fsync. (ACID) |
| **EAV** | Entity-Attribute-Value. Rows for each attribute. Alternative to JSONB. |
| **Entity** | Thing to track. Maps to table. |
| **ER model** | Entity-Relationship model. Conceptual design before relational schema. |
| **EXPLAIN** | Show query execution plan. ANALYZE = execute and show actuals. |
| **Expression index** | Index on expression (e.g., `(col->>'key')`) not just column. |
| **FD** | Functional dependency. X → Y: X determines Y. |
| **FK** | Foreign key. References another table's PK. |
| **Full table scan** | Seq Scan. Read all rows. |
| **Functional dependency** | X → Y: same X implies same Y. |

---

## G–L

| Term | Definition |
|------|------------|
| **GIN** | Generalized Inverted Index. For JSONB, arrays, full-text. |
| **GiST** | Generalized Search Tree. Geometric, full-text, range. |
| **Hash join** | Build hash table from inner; probe with outer. Equality join. |
| **Impedance mismatch** | SQL (set-based) vs host language (row-based). NULL, types. |
| **Index-only scan** | Query satisfied from index. No heap access. Best. |
| **Isolation** | Concurrent transactions don't interfere. (ACID) |
| **Isolation level** | Read Uncommitted, Read Committed, Repeatable Read, Serializable. |
| **JDBC** | Java Database Connectivity. Java CLI for SQL. |
| **Join** | Combine rows from two tables based on condition. |
| **JSONB** | Binary JSON. Pre-parsed, indexed. Preferred over json. |
| **Keyset pagination** | `WHERE id > last_id ORDER BY id LIMIT n`. O(1) per page. |
| **Left-prefix** | Composite index (a,b,c) supports (a), (a,b), (a,b,c). Not (b) alone. |
| **Lock** | Coordination for concurrent access. Row, table, advisory. |
| **Lost update** | Two transactions overwrite each other. Use SELECT FOR UPDATE. |

---

## M–R

| Term | Definition |
|------|------------|
| **Materialized view** | Pre-computed query result. Refreshed periodically. |
| **Merge join** | Both sides sorted; merge. O(n+m). |
| **MVCC** | Multi-Version Concurrency Control. Snapshots; readers don't block writers. |
| **Natural key** | Business identifier (email, SSN). |
| **Nested loop** | For each outer row, scan inner. Good for small inner. |
| **Non-repeatable read** | Same query returns different result; another transaction committed. |
| **Normalization** | Decompose tables to reduce redundancy. 1NF, 2NF, 3NF, BCNF. |
| **NULL** | Absence of value. Not zero, not empty. Three-valued logic. |
| **ODBC** | Open Database Connectivity. C/C++ CLI. |
| **ORM** | Object-Relational Mapping. Generates SQL from object operations. |
| **Parameterized query** | Placeholders for values. Prevents SQL injection. |
| **Partition** | Physical subdivision of table. Range, list, hash. |
| **Partition pruning** | Planner skips partitions that can't contain matching rows. |
| **Phantom read** | New rows appear in same query. Repeatable Read prevents in PostgreSQL. |
| **PK** | Primary key. Uniquely identifies row. UNIQUE + NOT NULL. |
| **Planner** | Chooses execution plan. Uses statistics, indexes, cost model. |
| **Prepared statement** | Parsed/planned once; executed many times with different parameters. |
| **Procedure** | Stored block. CALL. Can COMMIT. No return. |
| **RPO** | Recovery Point Objective. Max acceptable data loss (time). |
| **RTO** | Recovery Time Objective. Max acceptable downtime. |

---

## S–Z

| Term | Definition |
|------|------------|
| **Scalar subquery** | Subquery returning one row, one column. |
| **Schema** | Namespace for tables, views. `public` default. |
| **Seq Scan** | Full table scan. Sequential read. |
| **Serializable** | Strictest isolation. Transactions as if serial. May abort. |
| **Snapshot** | Point-in-time view of data. MVCC. |
| **SQL injection** | Attacker injects SQL via user input. Prevent with parameterization. |
| **SQLSTATE** | 5-char error code. 23505 = unique violation. 40P01 = deadlock. |
| **Subquery** | SELECT nested in another statement. |
| **Surrogate key** | Artificial key (SERIAL, UUID). No business meaning. |
| **Three-valued logic** | TRUE, FALSE, UNKNOWN. NULL comparisons yield UNKNOWN. |
| **Transaction** | Unit of work. BEGIN, COMMIT, ROLLBACK. |
| **Trigger** | Code that runs on INSERT/UPDATE/DELETE. BEFORE or AFTER. |
| **Tuple** | Row. Set of attribute values. |
| **VACUUM** | Reclaim dead tuple space. Update visibility. |
| **View** | Virtual table. Stored query. |
| **WAL** | Write-Ahead Log. Changes logged before data files. Crash recovery. |
| **Window function** | Compute over partition. ROW_NUMBER, SUM OVER. |
| **Work mem** | Memory for sort/hash per operation. |

---

## Quick Reference: Common SQLSTATE Codes

| Code | Meaning |
|------|---------|
| 23502 | Not null violation |
| 23503 | Foreign key violation |
| 23505 | Unique violation |
| 23514 | Check violation |
| 40P01 | Deadlock detected |
| 42P01 | Undefined table |

---

## Quick Reference: Normal Forms

| Form | Rule |
|------|------|
| 1NF | Atomic values, no repeating groups, unique rows |
| 2NF | 1NF + no partial dependencies |
| 3NF | 2NF + no transitive dependencies |
| BCNF | Every determinant is a candidate key |
