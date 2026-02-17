# BOOK 1 – Chapter 5: Knowing the Major Components of SQL

---

## 1. Core Concept Explanation (Deep Technical Version)

### The Three Pillars of SQL

SQL is organized into three sublanguages, each with a distinct responsibility:

| Component | Purpose | Key Statements |
|------------|---------|----------------|
| **DDL** (Data Definition Language) | Define and modify structure (metadata) | CREATE, ALTER, DROP |
| **DML** (Data Manipulation Language) | Operate on data | SELECT, INSERT, UPDATE, DELETE |
| **DCL** (Data Control Language) | Security and access control | GRANT, REVOKE |

This separation reflects the relational model's distinction between schema (structure) and instance (data). DDL changes the schema; DML changes the instance; DCL governs who can do what.

### Containment Hierarchy

Relational databases have a nested structure:

```
Database (cluster)
  └── Catalog (namespace; in PostgreSQL, often one per cluster)
        └── Schema (e.g., public)
              └── Table / View
                    └── Column
```

- **Database**: Top-level container. In PostgreSQL, `CREATE DATABASE` creates a new database in the cluster; each has its own set of schemas.
- **Schema**: Namespace for tables, views, routines. `public` is the default. Enables `schema1.customers` and `schema2.customers` to coexist.
- **Table**: Rows and columns. The primary data container.
- **View**: Virtual table—stored query, no physical storage.

Small systems may use only tables; larger systems add schemas for organization; very large systems may use multiple catalogs.

### DDL: Structure, Not Data

DDL operates on metadata. It does not insert or modify rows (except indirectly, e.g., adding a column with a DEFAULT). DDL statements are typically **auto-committing** in some DBMSs; in PostgreSQL, they participate in transactions and can be rolled back.

**CREATE** brings objects into existence: tables, views, schemas, indexes, functions. **ALTER** modifies existing objects (add/drop columns, constraints). **DROP** removes objects. Dropping a table removes its data permanently (unless using a recycle-bin feature).

### DML: The Four Operations

- **SELECT**: Retrieve. The only read operation. Returns a result set (possibly empty).
- **INSERT**: Add rows. Single-row or multi-row (VALUES, SELECT).
- **UPDATE**: Modify existing rows. SET specifies new values; WHERE specifies which rows. No WHERE → all rows (dangerous).
- **DELETE**: Remove rows. WHERE specifies which. No WHERE → all rows (dangerous).

**CRUD** (Create, Read, Update, Delete) maps to INSERT, SELECT, UPDATE, DELETE. "Create" in CRUD is INSERT, not CREATE TABLE.

### DCL: Privileges and Transactions

**GRANT** assigns privileges (SELECT, INSERT, UPDATE, DELETE, etc.) to users or roles. **REVOKE** removes them. Privileges can be table-level, column-level (in some DBMSs), or schema-level.

**Transactions** are not strictly DCL but are essential for integrity. BEGIN/START TRANSACTION, COMMIT, ROLLBACK. Transactions ensure atomicity: either all statements in the transaction complete or none do.

### Views: Single-Table vs Multitable

- **Single-table view**: Subset of one table (selected columns, filtered rows). Use case: restrict columns for security (e.g., hide salary).
- **Multitable view**: JOIN of multiple tables. Use case: present a denormalized "report" shape. Updatability is limited.

### Domains (User-Defined Types)

A **domain** is a named constraint on a type. Example: `CREATE DOMAIN Color AS VARCHAR(20) CHECK (VALUE IN ('Red', 'White', 'Blue'))`. Any column of type Color inherits that constraint. Reuse across tables without repeating the CHECK. PostgreSQL supports domains; not all DBMSs do.

---

## 2. Why This Matters in Production

### Real-World System Example

An order entry system: DDL creates `customers`, `products`, `orders`, `order_items`. DML inserts orders, updates inventory, deletes cancelled orders. DCL grants `app_user` SELECT/INSERT/UPDATE on `orders` but not DELETE; `admin` gets full access. A failed payment triggers ROLLBACK so the order and inventory changes are undone together.

### Scalability Impact

- **DDL in production**: `ALTER TABLE ADD COLUMN` on a large table can lock the table or take time. Plan for maintenance windows or use online DDL where available.
- **Bulk DML**: Single-row INSERT in a loop is slow. Use multi-row INSERT or COPY for bulk load.
- **Privileges**: Overly broad GRANT (e.g., to PUBLIC) increases blast radius if credentials leak.

### Performance Impact

- **UPDATE/DELETE without WHERE**: Accidentally updates or deletes all rows. Always verify WHERE or use a transaction with a test run first.
- **Views**: Complex multitable views executed on every query. Materialize when the same heavy query runs repeatedly.

### Data Integrity Implications

- **Transactions**: Multi-statement operations (e.g., debit one account, credit another) must be in one transaction. Without it, partial failure leaves inconsistent state.
- **GRANT least privilege**: Users should have only the privileges they need. Reduces impact of compromised accounts.

### Production Failure Scenario

**Case: UPDATE without WHERE.** A developer ran `UPDATE orders SET status = 'shipped'` intending to add `WHERE id = 123`. They omitted the WHERE. All orders were marked shipped. Restore from backup; 4 hours of data lost. Lesson: Use transactions for risky operations; run SELECT with the same WHERE first to verify row count; consider a safety check (e.g., abort if rows affected > threshold).

---

## 3. PostgreSQL Implementation

### DDL: CREATE TABLE

```sql
CREATE TABLE customers (
  id         BIGSERIAL PRIMARY KEY,
  first_name VARCHAR(50),
  last_name  VARCHAR(50) NOT NULL,
  email      VARCHAR(255) UNIQUE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
```

### DDL: ALTER TABLE

```sql
ALTER TABLE customers ADD COLUMN phone VARCHAR(20);
ALTER TABLE customers DROP COLUMN phone;
ALTER TABLE customers ADD CONSTRAINT chk_email CHECK (email ~* '^[^@]+@[^@]+\.[^@]+$');
```

### DDL: View (Single-Table)

```sql
CREATE VIEW customer_contact AS
SELECT id, first_name, last_name, email, phone
FROM customers;
-- Hides sensitive columns; grant SELECT on view, not on base table
```

### DDL: View (Multitable)

```sql
CREATE VIEW order_summary AS
SELECT o.id, c.last_name, o.total, o.status
FROM orders o
JOIN customers c ON o.customer_id = c.id;
```

### DDL: Schema

```sql
CREATE SCHEMA retail;
CREATE TABLE retail.customers (...);
```

### DDL: Domain (PostgreSQL)

```sql
CREATE DOMAIN us_zip AS VARCHAR(10)
CHECK (VALUE ~ '^\d{5}(-\d{4})?$');

CREATE TABLE addresses (
  zip us_zip
);
```

### DML: INSERT

```sql
INSERT INTO customers (first_name, last_name, email)
VALUES ('Alice', 'Smith', 'alice@example.com');

INSERT INTO customers (first_name, last_name, email)
VALUES ('Bob', 'Jones', 'bob@example.com'),
       ('Carol', 'Lee', 'carol@example.com');

INSERT INTO orders (customer_id, status)
SELECT id, 'pending' FROM customers WHERE email = 'alice@example.com';
```

### DML: UPDATE

```sql
UPDATE products SET cost = 22.00 WHERE product_id = 1664;
UPDATE products SET category = 'Accessories' WHERE category IN ('Headgear', 'Gloves');
-- WARNING: No WHERE = all rows
```

### DML: DELETE

```sql
DELETE FROM transactions WHERE trans_date < '2019-01-01';
-- Always use WHERE for DELETE in production
```

### DCL: GRANT / REVOKE

```sql
GRANT SELECT ON customer_contact TO app_readonly;
GRANT SELECT, INSERT, UPDATE ON orders TO app_user;
REVOKE INSERT ON orders FROM app_user;
```

### Transactions

```sql
BEGIN;
INSERT INTO orders (customer_id, status) VALUES (1, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (currval('orders_id_seq'), 5, 2, 29.99);
COMMIT;
-- Or ROLLBACK; on error
```

---

## 4. Common Developer Mistakes

### Mistake 1: UPDATE/DELETE Without WHERE

Running `UPDATE t SET x = 1` or `DELETE FROM t` without a WHERE clause affects every row. Always include WHERE; validate with SELECT first.

### Mistake 2: Assuming DDL Is Instant

`ALTER TABLE ADD COLUMN` on a 100M-row table may take minutes and lock the table. Use `ADD COLUMN ... DEFAULT ...` with care; in PostgreSQL 11+, adding a column with a non-null DEFAULT can be fast when the default is a constant.

### Mistake 3: Updating Through Complex Views

`UPDATE order_summary SET total = 100` fails—the view is a JOIN; the DBMS cannot map the update to base tables. Update the base `orders` table instead.

### Mistake 4: Granting Excessive Privileges

`GRANT ALL ON DATABASE x TO PUBLIC` gives everyone full access. Grant only required privileges to specific roles.

### Mistake 5: Forgetting Transaction Boundaries

Two INSERTs in separate "transactions" (autocommit) are not atomic. If the second fails, the first is already committed. Wrap in BEGIN/COMMIT.

### Mistake 6: Using INSERT ... SELECT Without Verifying

`INSERT INTO t SELECT * FROM s` can insert millions of rows. Check row count with `SELECT COUNT(*) FROM s` first; use a transaction.

---

## 5. Interview Deep-Dive Section

### Conceptual Questions

**Q: What is the difference between DDL and DML?**  
A: DDL defines structure (CREATE, ALTER, DROP). DML operates on data (SELECT, INSERT, UPDATE, DELETE). DDL changes metadata; DML changes rows.

**Q: Why can't you always UPDATE a view?**  
A: A view is a stored query. Updates must map unambiguously to base tables. Multi-table JOINs and computed columns make that impossible. Update the base tables instead.

**Q: What is a transaction? Why use one?**  
A: A transaction is an atomic unit of work. Either all statements commit or all roll back. Use for multi-statement operations that must succeed or fail together (e.g., transfer: debit one account, credit another).

### Scenario-Based Questions

**Q: You need to add a NOT NULL column to a 10M-row table. How do you do it safely?**  
A: Add the column as nullable first. Backfill values in batches. Add a NOT NULL constraint. In PostgreSQL 11+, `ADD COLUMN x INT NOT NULL DEFAULT 0` can be fast (rewrites not required for constant default) but still locks. Test on a copy first.

**Q: How would you implement "soft delete" (mark as deleted, don't remove rows)?**  
A: Add a `deleted_at` column (nullable). UPDATE to set `deleted_at = NOW()` instead of DELETE. Queries add `WHERE deleted_at IS NULL`. Optionally use a view or partial index to hide deleted rows.

### Optimization Questions

**Q: What is faster: 1000 single-row INSERTs or one multi-row INSERT?**  
A: One multi-row INSERT (or INSERT ... SELECT) is much faster. Fewer round-trips, one parse, one plan. Use `INSERT INTO t VALUES (...), (...), ...` or COPY for bulk load.

---

## 6. Advanced Engineering Notes

### Internal Behavior

- **DDL and transactions**: In PostgreSQL, DDL is transactional. CREATE TABLE followed by ROLLBACK removes the table. Some DBMSs auto-commit DDL.
- **View expansion**: The view's SELECT is merged into the query. The planner optimizes the whole thing. No separate "view execution" step.

### Tradeoffs

| Approach | Pros | Cons |
|----------|------|------|
| Direct table access | Full control | Exposes schema; security harder |
| Views for security | Restrict columns/rows | Not all views updatable |
| GRANT per table | Fine-grained | Many grants to manage |
| Roles | Group privileges | Role hierarchy complexity |

### Design Alternatives

- **Stored procedures for writes**: Encapsulate INSERT/UPDATE/DELETE in a procedure. Grant EXECUTE instead of table privileges. Tighter control.
- **Row-level security (RLS)**: Filter rows by user/role. More complex than views but more flexible.

---

## 7. Mini Practical Exercise

### Hands-On SQL Task

1. Create a table `products` with columns id, name, category, cost.
2. Insert 3 rows.
3. Create a view `product_catalog` that shows only name and category (hides cost).
4. Grant SELECT on `product_catalog` to a role; deny SELECT on `products`.
5. Update a product's cost via the base table (view doesn't expose cost for update).

```sql
CREATE TABLE products (id SERIAL PRIMARY KEY, name VARCHAR(100), category VARCHAR(50), cost NUMERIC(10,2));
INSERT INTO products (name, category, cost) VALUES ('Helmet', 'Safety', 25), ('Gloves', 'Safety', 15), ('Socks', 'Footwear', 10);
CREATE VIEW product_catalog AS SELECT name, category FROM products;
CREATE ROLE catalog_viewer;
GRANT SELECT ON product_catalog TO catalog_viewer;
-- catalog_viewer cannot SELECT from products directly
UPDATE products SET cost = 22 WHERE name = 'Helmet';
```

### Schema Modification Task

Add a `discontinued` column to `products` (BOOLEAN, default false). Update one product to discontinued. Write a view `active_products` that filters `WHERE discontinued = false`. Demonstrate that the view hides discontinued products.

```sql
ALTER TABLE products ADD COLUMN discontinued BOOLEAN DEFAULT false;
UPDATE products SET discontinued = true WHERE name = 'Socks';
CREATE VIEW active_products AS SELECT * FROM products WHERE discontinued = false;
SELECT * FROM active_products;  -- 2 rows
```

### Query Challenge

Perform a "transfer" between two rows in a table (e.g., move quantity from product A to product B). Use a single transaction. Demonstrate that ROLLBACK undoes both changes.

```sql
BEGIN;
UPDATE products SET cost = cost - 5 WHERE id = 1;
UPDATE products SET cost = cost + 5 WHERE id = 2;
-- COMMIT;  -- or ROLLBACK; to undo
```

---

## 8. Summary in 10 Bullet Points

1. **DDL** defines structure (CREATE, ALTER, DROP); **DML** operates on data (SELECT, INSERT, UPDATE, DELETE); **DCL** controls access (GRANT, REVOKE).
2. **Containment hierarchy**: Database → Catalog → Schema → Table → Column.
3. **Views** are stored queries; no physical storage. Single-table views often updatable; multitable views usually not.
4. **Domains** are named constrained types; reuse CHECK logic across columns.
5. **UPDATE/DELETE without WHERE** affects all rows—always verify.
6. **Transactions** ensure atomicity; use BEGIN/COMMIT/ROLLBACK for multi-statement operations.
7. **GRANT least privilege**; avoid granting to PUBLIC or ALL.
8. **Bulk INSERT**: Prefer multi-row INSERT or COPY over single-row loops.
9. **DDL in PostgreSQL** is transactional; ROLLBACK undoes CREATE/ALTER.
10. **Production**: Use transactions for risky DML; validate WHERE; plan DDL for large tables.
