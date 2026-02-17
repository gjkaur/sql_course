# Module 1: Interview Questions

## Relational Model

1. **What is the relational model?**
   - Data organized in tables (relations) of rows and columns. Each row is unique; columns have types. Relationships are enforced via foreign keys.

2. **What is a primary key?**
   - A column (or set) that uniquely identifies each row. Must be unique and NOT NULL. Often used as the target of foreign keys.

3. **What is a foreign key?**
   - A column that references another table's primary key. Enforces referential integrity: you can't orphan a row (e.g., order with non-existent customer).

4. **Why use a surrogate key instead of a natural key?**
   - Natural keys (email, SSN) can change, be composite, or expose PII. Surrogate keys (UUID, serial) are stable, simple for joins, and don't leak business meaning.

5. **What is a functional dependency?**
   - A → B means: for each value of A, there is exactly one value of B. Example: customer_id → customer_name.

## ER Modeling

6. **How do you model a many-to-many relationship?**
   - Create a junction table with FKs to both sides. The junction can have its own attributes (e.g., `order_items` has quantity, unit_price).

7. **What is cardinality?**
   - The number of related entities: 1:1, 1:N, N:M. Determines how many FKs you need and where they go.

8. **When would you split an entity into multiple tables?**
   - When attributes are multi-valued, optional and rarely used, or have different lifecycle/access patterns.

## SQL Overview

9. **What is the difference between SQL and NoSQL?**
   - SQL: relational, schema-first, ACID, best for structured data and complex queries. NoSQL (document, key-value, graph) trades consistency or structure for scale/flexibility.

10. **What does SQL NOT do?**
    - No control flow (if/else, loops) in standard SQL; no I/O; no UI. Use procedural extensions or application code.

## DDL & DML

11. **What is the difference between DELETE and TRUNCATE?**
    - DELETE removes rows one by one, fires triggers, can have WHERE, is transactional. TRUNCATE drops and recreates the table, is faster, resets sequences, doesn't fire row-level triggers.

12. **What is the execution order of SELECT?**
    - FROM → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT
    - Hence you can't use column aliases in WHERE (they're defined in SELECT).

## Data Types & Constraints

13. **When would you use CHECK vs application-level validation?**
    - Use CHECK for data integrity that must hold regardless of application (e.g., price >= 0). Application validation handles UX. Defense in depth: both.

14. **Why use NUMERIC for money instead of FLOAT?**
    - Floating-point has rounding errors. NUMERIC/DECIMAL is exact; critical for financial calculations.

15. **When should you use TIMESTAMPTZ vs TIMESTAMP?**
    - Use TIMESTAMPTZ for user-facing timestamps (stores UTC, displays in user's zone). TIMESTAMP is timezone-naive.

16. **What does NULL mean?**
    - Unknown or not applicable. NULL = NULL is NULL (not true); use IS NULL. Aggregates ignore NULL except COUNT(*).

17. **What constraints are available?**
    - NOT NULL, UNIQUE, PRIMARY KEY, FOREIGN KEY, CHECK, DEFAULT.

18. **What is the difference between VARCHAR and TEXT in PostgreSQL?**
    - No practical difference for performance. TEXT has no length limit.
