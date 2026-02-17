# BOOK 1 – Chapter 6: Drilling Down to the SQL Nitty-Gritty

---

## 1. Core Concept Explanation (Deep Technical Version)

### Execution Modes: Interactive, Embedded, Module

**Interactive SQL**: Statements entered directly (psql, pgAdmin, SQL Editor). Immediate execution, immediate results. Good for ad-hoc queries, administration, prototyping. Not for production application logic.

**Embedded SQL**: SQL statements embedded in host language (C, Java, COBOL). Precompiler translates `EXEC SQL` blocks before the host compiler runs. Variables passed via host variables (`:varname`). Declared in `EXEC SQL BEGIN DECLARE SECTION`. Debugging is harder because the debugger doesn't understand SQL. Many vendors have deprecated embedded SQL in favor of call-level interfaces (CLI) like ODBC, JDBC.

**Module language**: SQL procedures in a separate module; host program calls them. Cleaner separation—SQL experts write procedures, application developers write host code. No precompiler in the main program. Modern equivalent: stored procedures + application drivers.

### Reserved Words

**Reserved words** have special meaning in SQL. You cannot use them as identifiers (table names, column names) without quoting. Examples: SELECT, FROM, WHERE, TABLE, ORDER, GROUP, USER, KEY. Appendix A of the standard lists hundreds.

**Quoting**: PostgreSQL uses double quotes for identifiers: `"order"` (if you must use a reserved word as a table name). Single quotes are for string literals. Best practice: avoid reserved words as identifiers; use `orders` instead of `order`.

### Data Types: Exact vs Approximate Numerics

**Exact numerics** store values precisely within a range. No rounding error. Types: INTEGER (or INT), SMALLINT, BIGINT, NUMERIC(p,s), DECIMAL(p,s). Use for money, counts, IDs.

**Approximate numerics** (floating-point) use mantissa + exponent. Can represent very large/small numbers but with rounding error. Types: REAL, DOUBLE PRECISION, FLOAT. Use for scientific data, not money.

**NUMERIC(10,2)**: 10 total digits, 2 after decimal. Max value 99,999,999.99. Stored exactly.

**DECIMAL vs NUMERIC**: In practice, synonymous in PostgreSQL. Standard says DECIMAL may use extra precision if the system supports it; NUMERIC enforces exact precision. For portability, NUMERIC is safer.

**Never use FLOAT/REAL for money**: 0.1 + 0.2 ≠ 0.3 in floating-point. Use NUMERIC.

### Character Types

**CHAR(n)**: Fixed length. Padded with spaces to n. "Joe" in CHAR(15) stores "Joe            ". Comparison ignores trailing spaces in some contexts. Rarely needed.

**VARCHAR(n)**: Variable length, max n. No padding. "Joe" stores "Joe". Preferred for most text.

**TEXT** (PostgreSQL): Unlimited length. No performance penalty vs VARCHAR. Use for arbitrary-length text.

**CLOB**: Character large object. For very long text (documents). Limited operations (equality, substring in some implementations). Cannot be primary key.

### Boolean and Three-Valued Logic

**BOOLEAN**: TRUE, FALSE, or NULL (unknown). SQL uses **three-valued logic**: TRUE, FALSE, UNKNOWN. Any comparison with NULL yields UNKNOWN. `WHERE x = NULL` matches nothing—use `WHERE x IS NULL`. `NULL = NULL` is UNKNOWN, not TRUE.

### Datetime Types

**DATE**: Year-month-day. No time. Format: yyyy-mm-dd.

**TIME WITHOUT TIME ZONE**: Hours, minutes, seconds. No date, no timezone. Use for "store opens at 09:00" (same every day).

**TIME WITH TIME ZONE**: Time + timezone offset. Rarely used.

**TIMESTAMP WITHOUT TIME ZONE**: Date + time, no timezone. Ambiguous for distributed systems—"2024-02-15 14:00" in what zone?

**TIMESTAMP WITH TIME ZONE** (TIMESTAMPTZ): Date + time, stored in UTC, displayed in session timezone. **Use for user-facing timestamps.** PostgreSQL converts on input/output.

**INTERVAL**: Difference between two datetimes. Year-month vs day-time intervals (cannot mix—months vary in length).

### NULL Semantics

**NULL** means "unknown" or "not applicable." It is not zero, not empty string, not FALSE. It is the absence of a value.

**Reasons for NULL**: Value unknown; not yet assigned; not applicable for this row; deleted but not replaced.

**Impedance mismatch**: Host languages (Java, Python) often use null/None. Mapping must be explicit. ORMs handle this; raw SQL + host code must check for NULL and convert.

**Aggregates**: COUNT(*) counts rows; COUNT(column) excludes NULLs. SUM, AVG, etc. ignore NULL. Result of SUM over all-NULL column is NULL.

### Constraints: Column vs Table

**Column constraints**: Apply to a single column. NOT NULL, UNIQUE, CHECK.

**Table constraints**: Apply to the table. PRIMARY KEY (can be composite), FOREIGN KEY, CHECK (can reference multiple columns).

**PRIMARY KEY** implies UNIQUE and NOT NULL. One per table. Identifies rows.

**FOREIGN KEY**: Column(s) reference another table's primary key. Enforces referential integrity. Options: ON DELETE CASCADE, SET NULL, RESTRICT; ON UPDATE similar.

**CHECK**: Boolean expression. Must be true for row to be valid. Can reference multiple columns: `CHECK (end_date > start_date)`.

**Assertions** (SQL standard): Constraints spanning multiple tables. Not implemented in PostgreSQL, Oracle, SQL Server, MySQL. Use triggers or application logic instead.

---

## 2. Why This Matters in Production

### Real-World System Example

A billing system: `amount` as NUMERIC(10,2), not FLOAT—avoids rounding errors. `created_at` as TIMESTAMPTZ—users in different zones see correct local time. `customer_id` NOT NULL and FOREIGN KEY—no orphan invoices. CHECK (amount >= 0)—no negative charges.

### Scalability Impact

- **Wrong types**: VARCHAR(10) for IDs that grow (e.g., UUIDs) causes truncation. BIGINT for IDs avoids overflow at 2^31.
- **NULL in indexes**: In PostgreSQL, NULLs are included in B-tree indexes. Sparse columns (many NULLs) can use partial indexes: `CREATE INDEX ... WHERE column IS NOT NULL`.

### Performance Impact

- **CHAR vs VARCHAR**: CHAR pads; can waste space and complicate comparisons. VARCHAR/TEXT preferred.
- **NUMERIC vs INTEGER**: NUMERIC has overhead. Use INTEGER for counts, IDs; NUMERIC for money.

### Data Integrity Implications

- **Missing constraints**: Application assumes data is valid; bad data causes logic errors. Enforce in DB—single source of truth.
- **NULL in NOT NULL column**: Rejected. Protects against incomplete inserts.
- **FOREIGN KEY**: Prevents orphan rows. Cascade options affect bulk deletes—CASCADE can delete more than intended.

### Production Failure Scenario

**Case: FLOAT for currency.** A finance team used REAL for account balances. After many transactions, rounding errors accumulated. One account showed -0.0000001 instead of 0. Balance checks failed. Fix: migrate to NUMERIC, backfill from transaction log. Lesson: Never use floating-point for money.

---

## 3. PostgreSQL Implementation

### Numeric Types

```sql
CREATE TABLE products (
  id          BIGSERIAL PRIMARY KEY,      -- 8-byte integer
  quantity    INTEGER,                     -- 4-byte
  price       NUMERIC(10, 2) NOT NULL,     -- Exact decimal
  discount_pct REAL                         -- Approximate; avoid for money
);
```

### Character Types

```sql
CREATE TABLE users (
  name  VARCHAR(100),
  bio   TEXT,                    -- Unlimited
  code  CHAR(5)                  -- Fixed, e.g. country code
);
```

### Datetime Types

```sql
CREATE TABLE events (
  id        BIGSERIAL PRIMARY KEY,
  event_date DATE,
  event_ts   TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP  -- Prefer for user-facing
);
```

### Boolean

```sql
CREATE TABLE flags (
  is_active BOOLEAN DEFAULT true
);
-- TRUE, FALSE, NULL
```

### NULL Handling

```sql
SELECT * FROM customers WHERE email IS NULL;
SELECT * FROM customers WHERE email IS NOT NULL;
SELECT COALESCE(phone, 'N/A') FROM customers;  -- Replace NULL with default
SELECT NULLIF(column, '') FROM t;               -- Treat '' as NULL
```

### Column Constraints

```sql
CREATE TABLE tests (
  test_name   VARCHAR(30) NOT NULL,
  charge      NUMERIC(6,2) CHECK (charge >= 0 AND charge <= 200),
  email       VARCHAR(255) UNIQUE
);
```

### Table Constraints

```sql
CREATE TABLE invoices (
  id            SERIAL PRIMARY KEY,
  customer_id   INTEGER NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
  salesperson_id INTEGER REFERENCES salespersons(id) ON DELETE SET NULL,
  total         NUMERIC(10,2) CHECK (total >= 0),
  CONSTRAINT valid_dates CHECK (due_date >= invoice_date)
);
```

### Composite Primary Key

```sql
CREATE TABLE enrollments (
  student_id INT NOT NULL REFERENCES students(id),
  course_id  INT NOT NULL REFERENCES courses(id),
  grade      VARCHAR(2),
  PRIMARY KEY (student_id, course_id)
);
```

---

## 4. Common Developer Mistakes

### Mistake 1: Using FLOAT for Money

Causes rounding errors. Use NUMERIC or DECIMAL.

### Mistake 2: TIMESTAMP Without Time Zone for User Data

"2024-02-15 14:00" is ambiguous. Use TIMESTAMPTZ; store UTC, display in user's zone.

### Mistake 3: WHERE x = NULL

Always false. Use `WHERE x IS NULL`.

### Mistake 4: NOT NULL on Optional Columns

Forcing a value when none exists leads to placeholder values ("N/A", -1) that pollute data. Use NULL for "unknown" or "not applicable."

### Mistake 5: Skipping Foreign Keys

"We'll enforce in the application." Applications have bugs; DB constraints are the last line of defense. Add FKs.

### Mistake 6: Using Reserved Words as Identifiers

`CREATE TABLE order (...)` fails in some DBMSs. Use `orders` or quote: `"order"`.

### Mistake 7: CHAR for Variable-Length Text

Wastes space, complicates comparisons. Use VARCHAR or TEXT.

---

## 5. Interview Deep-Dive Section

### Conceptual Questions

**Q: What is the difference between NULL and empty string?**  
A: NULL = unknown/absent. Empty string '' = known value, zero-length. They are distinct. `WHERE col = ''` does not match NULL.

**Q: Why not use FLOAT for money?**  
A: Floating-point uses binary representation; decimal fractions like 0.1 have no exact representation. Accumulated rounding causes errors. NUMERIC stores exactly.

**Q: What does PRIMARY KEY imply?**  
A: UNIQUE + NOT NULL. No duplicates, no nulls. One PK per table. Often creates an index automatically.

**Q: When would you use ON DELETE CASCADE?**  
A: When child rows have no meaning without the parent. E.g., order_items without an order. Caution: cascading can delete more than expected; use sparingly.

### Scenario-Based Questions

**Q: You have a column that can be 0 or NULL. What does each mean?**  
A: Design decision. 0 = "known to be zero." NULL = "unknown" or "not applicable." Document the semantics. For "no value," prefer NULL; for "explicitly zero," use 0.

**Q: How do you enforce "end_date must be after start_date"?**  
A: CHECK (end_date > start_date) or CHECK (end_date >= start_date) if same-day is valid. Table-level CHECK constraint.

### Optimization Questions

**Q: Does VARCHAR(100) vs TEXT affect performance in PostgreSQL?**  
A: No meaningful difference. Both use same storage. VARCHAR(n) adds length check on insert. TEXT is often preferred for flexibility.

**Q: How do NULLs affect indexes?**  
A: In PostgreSQL B-tree, NULLs are included. For "find non-NULL" queries, index is used. Partial index `WHERE col IS NOT NULL` can be smaller if many NULLs.

---

## 6. Advanced Engineering Notes

### Internal Behavior

- **NUMERIC storage**: Variable length. More digits = more storage. Exact representation.
- **TIMESTAMPTZ**: Stored as UTC. Session `timezone` setting affects display. `AT TIME ZONE` converts explicitly.
- **CHECK constraints**: Evaluated per row. Cannot reference other rows (use trigger for that).

### Tradeoffs

| Choice | Pros | Cons |
|--------|------|------|
| NULL vs default | NULL = unknown | NULL complicates queries (IS NULL, COALESCE) |
| NUMERIC vs INTEGER | Exact for decimals | Slower than INTEGER |
| FK CASCADE vs RESTRICT | CASCADE: auto-cleanup | CASCADE: unexpected deletes |
| CHECK in DB vs app | Single source of truth | Some logic hard to express in CHECK |

### Design Alternatives

- **Soft delete**: `deleted_at TIMESTAMPTZ` instead of DELETE. Queries add `WHERE deleted_at IS NULL`. Preserves history.
- **JSONB for flexible schema**: When attributes vary by row. Trade-off: less type safety, harder to constrain.

---

## 7. Mini Practical Exercise

### Hands-On SQL Task

1. Create a table with columns of type INTEGER, NUMERIC(10,2), VARCHAR(100), DATE, TIMESTAMPTZ, BOOLEAN.
2. Insert a row with a NULL in an optional column.
3. Add NOT NULL to a column; attempt to insert NULL—observe error.
4. Add CHECK (price >= 0); attempt to insert -1—observe error.

```sql
CREATE TABLE demo (
  id INT PRIMARY KEY,
  amount NUMERIC(10,2),
  name VARCHAR(100),
  birth_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  active BOOLEAN DEFAULT true
);
INSERT INTO demo (id, name) VALUES (1, 'Test');  -- NULLs in optional columns
ALTER TABLE demo ALTER COLUMN amount SET NOT NULL;  -- Fails if existing NULLs
ALTER TABLE demo ADD CONSTRAINT chk_amount CHECK (amount >= 0);
INSERT INTO demo (id, amount) VALUES (2, -1);  -- Fails
```

### Schema Modification Task

Add a FOREIGN KEY to an existing table. If orphan rows exist, the ADD will fail. Fix by deleting orphans or updating to valid references, then add the FK.

```sql
-- Assume orders has customer_id with some invalid values
DELETE FROM orders WHERE customer_id NOT IN (SELECT id FROM customers);
ALTER TABLE orders ADD CONSTRAINT fk_customer
  FOREIGN KEY (customer_id) REFERENCES customers(id);
```

### Query Challenge

Write a query that returns "Unknown" for NULL names, "Inactive" for false active flag, and the actual value otherwise. Use COALESCE and CASE.

```sql
SELECT COALESCE(name, 'Unknown') AS display_name,
       CASE WHEN active = false THEN 'Inactive' ELSE 'Active' END AS status
FROM demo;
```

---

## 8. Summary in 10 Bullet Points

1. **Execution modes**: Interactive (ad-hoc), embedded (in host code), module (stored procedures). Modern apps use drivers + stored procs or ORM.
2. **Reserved words**: Cannot use as identifiers without quoting. Avoid; choose non-reserved names.
3. **Exact vs approximate numerics**: NUMERIC for money; never FLOAT. INTEGER for IDs, counts.
4. **VARCHAR/TEXT over CHAR**: Variable length preferred. TEXT in PostgreSQL has no practical penalty.
5. **TIMESTAMPTZ for user-facing timestamps**: Store UTC; display in user's zone.
6. **NULL semantics**: Unknown, not zero/empty. Use IS NULL, not = NULL. Three-valued logic.
7. **Constraints**: NOT NULL, UNIQUE, CHECK, PRIMARY KEY, FOREIGN KEY. Enforce in DB.
8. **PRIMARY KEY**: UNIQUE + NOT NULL. One per table. Use surrogate (BIGSERIAL) when natural keys are unstable.
9. **FOREIGN KEY**: Referential integrity. ON DELETE CASCADE with care.
10. **Assertions**: Not in PostgreSQL. Use triggers or application logic for cross-table constraints.
