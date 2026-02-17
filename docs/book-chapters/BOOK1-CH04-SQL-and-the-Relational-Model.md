# BOOK 1 – Chapter 4: SQL and the Relational Model

---

## 1. Core Concept Explanation (Deep Technical Version)

### Relations vs Tables: Set Theory vs Multisets

The relational model is grounded in **set theory**. A mathematical **set** contains unique elements—no duplicates. A **relation** is a set of tuples (rows); therefore, no two tuples may be identical.

**SQL tables** are not strict relations. They are **multisets** (bags): they can contain duplicate rows. `SELECT * FROM t` without DISTINCT or a unique constraint can return the same row multiple times. This divergence has implications:

- **Aggregates**: `COUNT(*)` counts rows; duplicates matter. In a true relation, each tuple would be unique.
- **DISTINCT**: Approximates relational semantics by eliminating duplicates.
- **UNIQUE constraint**: Enforces no duplicates; the table then behaves like a relation for that constraint.

A table is a **relation** (in the strict sense) only if it has a primary key or unique constraint that guarantees no duplicate rows.

### Formal Definition of an SQL Relation

A table qualifies as a relation if and only if:

1. **Atomic values**: Every cell contains a single value (or NULL). No repeating groups, no arrays in a cell.
2. **Homogeneous columns**: All values in a column share the same type/domain.
3. **Unique column names**: No two columns have the same name.
4. **Column order irrelevant**: Reordering columns doesn't change the relation.
5. **Row order irrelevant**: Reordering rows doesn't change the relation.
6. **No duplicate rows**: Every row is unique (enforced by a key).

Violating any of these means the table is not a relation in the formal sense, though it may still be a valid SQL table.

### Functional Dependencies

A **functional dependency** (FD) is a constraint between attributes: if you know the value(s) of one set, you can determine the value of another. Notation: `A ⇒ B` means "A determines B" or "B is functionally dependent on A." A is the **determinant**.

**Examples:**

- `zipcode ⇒ state`: Given zip code, state is determined (in the US).
- `state ⇏ zipcode`: State does not determine zip code; a state has many zip codes.
- `(order_id, product_id) ⇒ quantity`: In order_items, the pair determines quantity.
- `(quantity, unit_price) ⇒ extended_price`: Computed; often not stored, or maintained by trigger.

**Why FDs matter**: They drive **normalization**. If `customer_id ⇒ customer_name` and you store customer_name in the orders table, you have redundancy and update anomalies. Normalization decomposes tables based on FDs.

### Keys

A **key** is a minimal set of attributes that uniquely identifies a row. Types:

- **Candidate key**: Any minimal unique identifier. A table can have multiple candidate keys.
- **Primary key**: The candidate key chosen as the main identifier. One per table.
- **Superkey**: A set that includes a key (e.g., (id, name) when id alone is a key). Not minimal.
- **Foreign key**: An attribute (or set) that references another table's primary key.

**Composite key**: Multiple attributes together form the key. Example: (researcher_id, project_id) when a researcher can work on multiple projects.

**Determining keys**: Ask the users. "Can a researcher work on multiple projects?" If yes, ResearcherID alone is not a key; (ResearcherID, Project) is. Keys encode business rules.

**Every relation has at least one key**: By definition, no duplicate rows means the full set of attributes uniquely identifies each row. The key is some minimal subset of that.

### Views: Virtual Tables

A **view** is a stored query. It has no physical storage; when queried, the DBMS executes the underlying SELECT and returns the result. To the user, a view looks like a table.

**Updatability**: Not all views are updatable. A view is updatable only if updates can be mapped unambiguously to the base tables. Rules (simplified):

- Single-table view, no aggregates, no DISTINCT, no GROUP BY → often updatable.
- Multi-table JOIN view → usually not updatable (which table does UPDATE modify?).
- View with computed columns → those columns cannot be updated.

**Use cases**: Simplify complex queries, restrict columns (security), present denormalized data without storing it.

### Namespace Hierarchy: Catalog → Schema → Table → Column

- **Catalog**: Top-level namespace. In PostgreSQL, a catalog roughly corresponds to a database cluster. Rarely used explicitly.
- **Schema**: Contains tables, views, routines. `public` is the default. Enables multiple tables with the same name in different schemas.
- **Table**: Rows and columns.
- **Column**: Attribute within a table.

Fully qualified name: `catalog.schema.table.column`. In practice, `schema.table` or just `table` (defaults to `search_path`).

### Connections, Sessions, Transactions

- **Connection**: A channel between client and server. Established via CONNECT (or connection string). A connection has authentication context (user, role).
- **Session**: The execution context for one user over one connection. A session persists until disconnect. Session-level settings (e.g., `search_path`, `timezone`) apply to all statements in that session.
- **Transaction**: A sequence of statements that is **atomic** with respect to recovery. Either all commit or all roll back. Begins implicitly (first statement) or explicitly (BEGIN). Ends with COMMIT or ROLLBACK.

**Atomicity**: If the server crashes mid-transaction, recovery undoes uncommitted changes. The database returns to the state before the transaction started.

### Routines

**Routines** are procedures or functions stored in the database. They can be:

- **SQL-invoked**: Called from SQL (CALL for procedures; function in expression).
- **External**: Written in a host language (C, Python) but callable from SQL.
- **SQL routine**: Written in SQL (or PL/pgSQL) and invoked from SQL.

Routines encapsulate logic, reduce round-trips, and enable reuse. They blur the line between "data" and "application"—routines are schema objects.

### Paths (Search Path)

The **search path** is an ordered list of schemas. When you reference an unqualified name (e.g., `customers`), the DBMS searches the path to resolve it. First match wins. Enables:

- Multiple environments (dev, staging, prod) with same table names in different schemas.
- Overloading: `myschema.myfunc` vs `public.myfunc`.

---

## 2. Why This Matters in Production

### Real-World System Example

A multi-tenant SaaS app: each tenant has a schema (`tenant_1`, `tenant_2`). The same table `orders` exists in each. The search path is set per connection to the tenant's schema. One codebase, logical isolation. Without schemas, you'd need separate databases or a `tenant_id` column everywhere.

### Scalability Impact

- **Functional dependencies**: Ignoring FDs leads to denormalization that causes update anomalies. Fixing later requires migration and data backfill.
- **Keys**: Missing or wrong keys cause duplicate rows, ambiguous joins, and replication conflicts.

### Performance Impact

- **Views**: A view is not a cached result (unless materialized). Each query against a view re-runs the underlying SELECT. Complex views can be slow; materialize when needed.
- **Sessions**: Connection pooling reuses connections; each "logical" session may use different physical connections. Session state (temp tables, variables) doesn't persist across pooled connection handoff.

### Data Integrity Implications

- **Keys**: No primary key → duplicates, no referential integrity from other tables.
- **Functional dependencies**: Violating FDs (e.g., storing derived values that can get out of sync) causes inconsistency. Enforce via constraints or avoid redundancy.

### Production Failure Scenario

**Case: View used as table.** A team created a view `active_orders` and wrote `INSERT INTO active_orders (...)`. The view was a multi-table JOIN. PostgreSQL (correctly) rejected the insert—the view was not updatable. They had to refactor to insert into the base `orders` table. Lesson: Understand view updatability before designing around it.

---

## 3. PostgreSQL Implementation

### Relation-Like Table (No Duplicates)

```sql
CREATE TABLE customers (
  id    BIGSERIAL PRIMARY KEY,  -- Guarantees unique rows
  email VARCHAR(255) NOT NULL UNIQUE
);

-- Without PK/UNIQUE, duplicates are allowed
CREATE TABLE logs (
  msg TEXT,
  ts  TIMESTAMPTZ DEFAULT NOW()
);
-- INSERT same row twice → two identical rows
```

### Functional Dependency and Normalization

```sql
-- BAD: customer_name depends on customer_id; redundant
CREATE TABLE orders_bad (
  id           BIGSERIAL PRIMARY KEY,
  customer_id   BIGINT,
  customer_name VARCHAR(100)  -- FD: customer_id => customer_name
);

-- GOOD: customer_name only in customers
CREATE TABLE customers (
  id   BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL
);
CREATE TABLE orders (
  id          BIGSERIAL PRIMARY KEY,
  customer_id BIGINT NOT NULL REFERENCES customers(id)
);
```

### Composite Key

```sql
CREATE TABLE researcher_projects (
  researcher_id INT NOT NULL REFERENCES researchers(id),
  project_id    INT NOT NULL REFERENCES projects(id),
  role          VARCHAR(50),
  PRIMARY KEY (researcher_id, project_id)
);
```

### View (Virtual Table)

```sql
CREATE VIEW active_orders AS
SELECT id, customer_id, status, total, created_at
FROM orders
WHERE status IN ('pending', 'shipped');

-- Query it like a table
SELECT * FROM active_orders;

-- Updatable? Single table, no computed columns → yes (for supported operations)
UPDATE active_orders SET status = 'shipped' WHERE id = 1;
```

### Non-Updatable View (JOIN)

```sql
CREATE VIEW order_summary AS
SELECT o.id, c.name AS customer_name, o.total
FROM orders o
JOIN customers c ON o.customer_id = c.id;

-- UPDATE order_summary SET total = 100 WHERE id = 1;
-- ERROR: cannot update view (multiple base tables)
```

### Schema and Search Path

```sql
CREATE SCHEMA tenant_1;
CREATE TABLE tenant_1.orders (...);

SET search_path TO tenant_1;
SELECT * FROM orders;  -- Resolves to tenant_1.orders

SHOW search_path;
```

### Connection, Session, Transaction

```sql
-- Connection: established by client (psql, app)
-- Session: one connection, one user

BEGIN;  -- Start transaction
INSERT INTO orders (customer_id, status) VALUES (1, 'pending');
UPDATE inventory SET quantity = quantity - 1 WHERE product_id = 5;
COMMIT;  -- Atomic: both succeed or both roll back

-- Or ROLLBACK; to undo
```

### Routine (Function)

```sql
CREATE OR REPLACE FUNCTION order_total(p_order_id BIGINT)
RETURNS NUMERIC
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(SUM(quantity * unit_price), 0)
  FROM order_items
  WHERE order_id = p_order_id;
$$;

SELECT order_total(1);
```

---

## 4. Common Developer Mistakes

### Mistake 1: Tables Without Primary Keys

Allowing duplicate rows, making joins ambiguous, breaking replication. Always define a PK (surrogate or natural).

### Mistake 2: Ignoring Functional Dependencies

Storing `customer_name` in orders "for convenience." When the customer changes their name, you must update all orders. Normalize: store only `customer_id`.

### Mistake 3: Assuming Views Are Updatable

Writing `INSERT INTO my_view` or `UPDATE my_view` without checking. Multi-table views and views with expressions are usually not updatable.

### Mistake 4: Confusing Schema and Database

In PostgreSQL, a **database** is a separate cluster (separate data directory). A **schema** is a namespace within a database. `CREATE DATABASE` creates a new DB; `CREATE SCHEMA` creates a namespace.

### Mistake 5: Forgetting Transaction Boundaries

Leaving autocommit on and assuming multi-statement "transactions" are atomic. They're not—each statement commits separately. Use explicit BEGIN/COMMIT for atomicity.

### Mistake 6: Relying on Row Order

`SELECT * FROM t` returns rows in unspecified order. Without ORDER BY, order can change between executions. Always use ORDER BY when order matters.

---

## 5. Interview Deep-Dive Section

### Conceptual Questions

**Q: What is the difference between a relation and a table?**  
A: A relation is a set of unique tuples (no duplicates). A SQL table can have duplicate rows (multiset). A table with a primary key enforces uniqueness and approximates a relation.

**Q: What is a functional dependency?**  
A: A constraint: if you know the value(s) of attribute set A, you can determine the value of attribute B. Notation: A ⇒ B. Drives normalization.

**Q: Can a relation have no key?**  
A: No. By definition, no two rows are identical, so the full set of attributes uniquely identifies each row. The key is some minimal subset of that.

**Q: When is a view updatable?**  
A: When updates can be mapped unambiguously to base tables. Typically: single base table, no aggregates, no DISTINCT, no GROUP BY. Multi-table JOINs and computed columns usually make a view non-updatable.

### Scenario-Based Questions

**Q: You have (researcher_id, project, location). Researchers can work on multiple projects. What is the key?**  
A: (researcher_id, project). Researcher_id alone doesn't uniquely identify a row if one researcher has multiple projects. Location may be determined by project (FD: project ⇒ location)—if so, consider normalizing to avoid redundancy.

**Q: How would you implement multi-tenancy with schema isolation?**  
A: One schema per tenant. Set `search_path` per connection to the tenant's schema. Same table names across schemas. Application assigns connection to tenant at login.

### Optimization Questions

**Q: Is querying a view slower than querying the base table?**  
A: The view is expanded inline; the planner optimizes the combined query. No inherent slowdown for simple views. Complex views (many JOINs, subqueries) can be slow—consider materialized views for repeated heavy queries.

---

## 6. Advanced Engineering Notes

### Internal Behavior

- **View expansion**: The view definition is merged into the query. The planner sees the full query, not "view + filter." It can push predicates down, use indexes on base tables.
- **Materialized view**: Stores the result. Must be refreshed. Use for expensive queries run frequently.

### Tradeoffs

| Concept | Pros | Cons |
|---------|------|------|
| Multiset (SQL default) | Flexible; UNION ALL keeps duplicates | Must use DISTINCT when set semantics needed |
| View | Encapsulation, security | Not always updatable; no physical storage |
| Schema | Namespace isolation | More objects to manage |
| Stored routine | Less round-trips, reuse | Logic in DB; harder to test, version |

### Design Alternatives

- **Materialized view vs view**: Materialized for read-heavy, expensive queries; refresh strategy (manual, scheduled, on commit).
- **Schema vs tenant_id column**: Schema for strict isolation; tenant_id for simpler ops, shared indexes, cross-tenant queries.

---

## 7. Mini Practical Exercise

### Hands-On SQL Task

1. Create a table that violates the "no duplicate rows" rule (no PK). Insert two identical rows. Demonstrate that `SELECT *` returns both.
2. Add a PRIMARY KEY. Attempt to insert a duplicate—observe the error.
3. Create a view over that table. Query the view. Attempt an UPDATE—verify updatability.

```sql
CREATE TABLE demo (a INT, b INT);
INSERT INTO demo VALUES (1, 2), (1, 2);  -- Duplicates allowed
SELECT * FROM demo;

ALTER TABLE demo ADD PRIMARY KEY (a, b);
-- INSERT INTO demo VALUES (1, 2);  -- Fails

CREATE VIEW demo_view AS SELECT * FROM demo WHERE a = 1;
UPDATE demo_view SET b = 3 WHERE a = 1;  -- Works (single table, no computed cols)
```

### Schema Modification Task

Create two schemas, `dev` and `prod`. Create `orders` in both. Set `search_path` to `dev` and run a query. Switch to `prod`. Demonstrate that the same query name resolves to different tables.

```sql
CREATE SCHEMA dev;
CREATE SCHEMA prod;
CREATE TABLE dev.orders (id INT PRIMARY KEY, total NUMERIC);
CREATE TABLE prod.orders (id INT PRIMARY KEY, total NUMERIC);
INSERT INTO dev.orders VALUES (1, 100);
INSERT INTO prod.orders VALUES (1, 200);

SET search_path TO dev;
SELECT * FROM orders;  -- 100

SET search_path TO prod;
SELECT * FROM orders;  -- 200
```

### Query Challenge

Given a table with (order_id, product_id, quantity, unit_price), write a query that uses the functional dependency (quantity, unit_price) ⇒ extended_price to compute line totals. Then create a view that exposes order_id, product_id, quantity, unit_price, and extended_price. Ensure the view is useful for reporting.

```sql
CREATE VIEW order_line_items AS
SELECT order_id, product_id, quantity, unit_price,
       quantity * unit_price AS extended_price
FROM order_items;
```

---

## 8. Summary in 10 Bullet Points

1. **Relation vs table**: Relations are sets (no duplicates); SQL tables are multisets. Use PK/UNIQUE for relation-like behavior.
2. **Formal relation**: Atomic values, homogeneous columns, unique names, order-independent, no duplicate rows.
3. **Functional dependency** A ⇒ B: Knowing A determines B. Drives normalization.
4. **Keys**: Minimal unique identifier. Composite key when multiple attributes required. Ask users to validate.
5. **Views**: Stored queries; no physical storage. Not always updatable—depends on structure.
6. **Namespace**: Catalog → Schema → Table → Column. Schemas enable same table name in different namespaces.
7. **Connection/Session/Transaction**: Connection = channel; Session = execution context; Transaction = atomic unit of work.
8. **Routines**: Procedures and functions in the DB; callable from SQL or host language.
9. **Search path**: Order of schemas for resolving unqualified names.
10. **Production**: Always use PKs; respect FDs; understand view updatability; use transactions for multi-statement atomicity.
