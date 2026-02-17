# BOOK 2 – Chapter 2: Building a Database Model

---

## 1. Core Concept Explanation (Deep Technical Version)

### From ER to Relations: The Translation Rules

An ER model is conceptual; a **relational model** is a set of tables with columns and keys. Translation is systematic:

- **Entity** → Table. Entity name becomes table name (singular or plural by convention).
- **Attribute** → Column. Simple attributes map 1:1. Composite attributes (e.g., address with street, city, zip) can be one column or split—design choice.
- **Identifier** → Primary key. Simple identifier → single column PK. Composite identifier → composite PK.
- **1:1 relationship** → FK in either table with UNIQUE constraint. Typically put FK in the "dependent" side (e.g., license references person).
- **1:N relationship** → FK in the "many" side. Order references Customer.
- **N:M relationship** → Junction table with two FKs. Composite PK (or surrogate + UNIQUE) on the FK pair.

### Functional Dependencies: The Foundation of Normalization

A **functional dependency (FD)** X → Y means: for any two rows with the same X values, Y values must be the same. In other words, X determines Y.

- **Full dependency**: Non-key attribute depends on the *entire* primary key. (order_id, product_id) → quantity is full if quantity is determined by both.
- **Partial dependency**: Non-key depends on only *part* of the key. (order_id, product_id) → product_name is partial—product_name depends only on product_id. Violates 2NF.
- **Transitive dependency**: Non-key A depends on non-key B, which depends on the key. customer_id → city → region. Region depends on city, not directly on customer_id. Violates 3NF.

**Candidate key**: Minimal set of attributes that uniquely identifies a row. **Primary key**: Chosen candidate key. **Determinant**: Left side of an FD. In BCNF, every determinant must be a candidate key.

### Normal Forms: Progressive Elimination of Anomalies

| Form | Rule | Violation Example |
|------|------|-------------------|
| **1NF** | Atomic values; no repeating groups; unique rows | Comma-separated list in a column |
| **2NF** | 1NF + no partial dependencies | product_name in (order_id, product_id) table |
| **3NF** | 2NF + no transitive dependencies | region in customers when city → region |
| **BCNF** | Every determinant is a candidate key | (student, course) → instructor when instructor → course |

**Decomposition**: Split a table to eliminate a violation. Ensure **lossless join**—rejoining decomposed tables yields the original. Use the FD that causes the violation to guide the split.

### Surrogate vs Natural Keys

**Natural key**: Business identifier (SSN, email, VIN). Stable if business rules don't change; can be composite or long.

**Surrogate key**: System-generated (SERIAL, UUID). Stable, compact, no business meaning. Use when natural key is composite, volatile, or sensitive.

**Recommendation**: Use surrogate for primary key; add UNIQUE on natural key when it exists. Simplifies FKs and joins.

---

## 2. Why This Matters in Production

### Real-World System Example

Fleet repair: ER has Customer, Vehicle, RepairOrder, Technician, Part, PartUsage. Translation: 6 tables. PartUsage is junction (RepairOrder ↔ Part). PartUsage stores unit_price at time of use—snapshot, not current price—avoiding transitive dependency on parts.unit_cost.

### Scalability Impact

- **Partial dependencies**: Redundant product_name in order_items. Update product name → update N rows. Wastes storage.
- **Transitive dependencies**: Redundant region in customers. Same. Normalization reduces redundancy and update scope.

### Performance Impact

- **Over-normalization**: 6NF-style decomposition. Every non-key depends only on the key. Too many JOINs for common queries. Denormalize for hot paths.
- **Under-normalization**: Update anomaly forces full-table scans or many updates. Balance: 3NF base, denormalize where profiling shows need.

### Data Integrity Implications

- **Lossy decomposition**: Splitting without preserving FDs can lose information. Always verify lossless join.
- **Surrogate keys**: Simplify FKs; no cascading updates when natural key changes (e.g., email).

### Production Failure Scenario

**Case: Partial dependency in production.** Order_items had (order_id, product_id, product_name). Product names were updated in products but not in order_items. Invoices showed old names. Fix: Remove product_name from order_items; JOIN to products for display. Lesson: Enforce 2NF; historical display may need snapshot column (e.g., product_name_at_purchase) with different semantics.

---

## 3. PostgreSQL Implementation

### Identifying and Fixing 2NF Violation

```sql
-- BAD: product_name depends only on product_id
CREATE TABLE order_items_bad (
  order_id    INT,
  product_id  INT,
  product_name VARCHAR(100),  -- Partial dependency!
  quantity    INT,
  PRIMARY KEY (order_id, product_id)
);

-- GOOD: product_name in products only
CREATE TABLE products (
  id   SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL
);

CREATE TABLE order_items (
  order_id   INT NOT NULL REFERENCES orders(id),
  product_id INT NOT NULL REFERENCES products(id),
  quantity   INT NOT NULL,
  PRIMARY KEY (order_id, product_id)
);
```

### Identifying and Fixing 3NF Violation

```sql
-- BAD: region depends on city, not customer_id
CREATE TABLE customers_bad (
  id     SERIAL PRIMARY KEY,
  name   VARCHAR(100),
  city   VARCHAR(50),
  region VARCHAR(50)  -- Transitive: customer_id -> city -> region
);

-- GOOD: Extract city-region
CREATE TABLE regions (
  city   VARCHAR(50) PRIMARY KEY,
  region VARCHAR(50) NOT NULL
);

CREATE TABLE customers (
  id   SERIAL PRIMARY KEY,
  name VARCHAR(100),
  city VARCHAR(50) REFERENCES regions(city)
);
```

### Junction Table with Snapshot (Historical Price)

```sql
-- PartUsage: N:M between RepairOrder and Part
-- unit_price = price at time of use (snapshot), not current parts.unit_cost
CREATE TABLE part_usage (
  repair_order_id INT NOT NULL REFERENCES repair_orders(id),
  part_id         INT NOT NULL REFERENCES parts(id),
  quantity        INT NOT NULL CHECK (quantity > 0),
  unit_price      NUMERIC(10,2) NOT NULL,  -- Snapshot; no FD to parts.unit_cost
  PRIMARY KEY (repair_order_id, part_id)
);
```

### Checking Normal Form

```sql
-- List columns and their dependencies (manual analysis)
-- 1NF: No arrays/comma-separated in columns
-- 2NF: For composite PK (a,b), no column depends only on a or only on b
-- 3NF: No column A depends on column B where B is not a key
```

---

## 4. Common Developer Mistakes

### Mistake 1: Storing Derived Data Without Snapshot Semantics

Storing product_name in order_items for "convenience" without treating it as historical snapshot. Updates to products don't propagate. Either remove it (JOIN) or document "as of order date" and never update from products.

### Mistake 2: Ignoring Transitive Dependencies

city → region in customers. "It's just one extra column." Until you have 10 such columns and update anomalies multiply. Extract early.

### Mistake 3: Over-Decomposing for Purity

Splitting every FD into its own table. 3NF is sufficient for most cases. BCNF and beyond add complexity; use only when the anomaly is real.

### Mistake 4: Natural Key as PK When It Can Change

Email as PK. User changes email → update all FKs. Use surrogate; put UNIQUE on email.

### Mistake 5: Junction Table Without Proper Key

part_usage with only repair_order_id and part_id, no PK. Allows duplicate (same part twice in same order). Use composite PK or UNIQUE.

---

## 5. Interview Deep-Dive Section

### Conceptual Questions

**Q: What's the difference between 2NF and 3NF?**  
A: 2NF removes partial dependencies (non-key depends on part of composite key). 3NF removes transitive dependencies (non-key depends on another non-key). Example: (order_id, product_id) → product_name is 2NF violation; customer_id → city → region is 3NF violation.

**Q: When would you use a surrogate key vs natural key?**  
A: Surrogate when natural key is composite, long, or may change. Natural when it's stable and simple (e.g., country code). Often: surrogate PK, UNIQUE on natural.

**Q: What is lossless join decomposition?**  
A: Splitting a table such that joining the parts back yields the original. Achieved when the decomposition is based on an FD and the shared attribute(s) form a key in one of the resulting tables.

### Scenario-Based Questions

**Q: You have (student_id, course_id, instructor_name). What's wrong?**  
A: If instructor determines course (one instructor per course), then (student, course) → instructor is redundant. Instructor depends on course. Either instructor → course (instructor teaches one course) or course → instructor. If instructor → course, then instructor_name should be in a courses table. BCNF violation.

**Q: How do you handle "price at time of order" vs "current price"?**  
A: Store both. order_items.unit_price = snapshot at order time. products.price = current. Never update order_items.unit_price from products. Historical accuracy vs current state.

---

## 6. Advanced Engineering Notes

### BCNF vs 3NF

BCNF is stricter. A table can be in 3NF but not BCNF when there are overlapping candidate keys. Example: (student, course) and (student, instructor) as candidate keys, with instructor → course. BCNF would split further. In practice, 3NF is often enough.

### Denormalization Decision Matrix

| Scenario | Action |
|----------|--------|
| OLTP, high writes | Stay normalized |
| Reporting, read-heavy | Materialized view or summary table |
| Hot path with 5+ JOINs | Consider redundant column or materialized view |
| Real-time consistency required | Normalize; use caching carefully |

### Schema Evolution

- **Add column**: ALTER TABLE ADD COLUMN. Use DEFAULT for backfill.
- **Split table**: Create new table, backfill, add FK, migrate app, drop old column.
- **Change PK**: Rare; usually add new surrogate, backfill FKs, switch.

---

## 7. Mini Practical Exercise

### Hands-On Task

Given this denormalized table:

| order_id | customer_name | customer_email | product_name | category | quantity | unit_price |
|----------|---------------|----------------|--------------|----------|----------|------------|
| 1 | Alice | alice@x.com | Mouse | Electronics | 2 | 29.99 |
| 1 | Alice | alice@x.com | Keyboard | Electronics | 1 | 89.99 |

1. Identify FDs: order_id → customer_name? (order_id, product_name) → quantity?
2. Identify 2NF violation: customer_name depends on order_id only? product_name → category?
3. Decompose to 3NF. List tables and keys.
4. Write CREATE TABLE statements.

### Verification Task

For your decomposed schema, verify: (a) lossless join—can you reconstruct the original? (b) No partial or transitive dependencies.

---

## 8. Summary in 10 Bullet Points

1. **ER → Relations**: Entity→table, attribute→column, identifier→PK, 1:1→FK+UNIQUE, 1:N→FK on many side, N:M→junction table.
2. **Functional dependency** X→Y: X determines Y. Foundation for normalization.
3. **1NF**: Atomic values, no repeating groups, unique rows.
4. **2NF**: No partial dependencies. Non-key must depend on full key.
5. **3NF**: No transitive dependencies. Non-key must not depend on another non-key.
6. **BCNF**: Every determinant is a candidate key. Stricter than 3NF.
7. **Surrogate keys**: Use for PK when natural key is composite, volatile, or long.
8. **Junction tables**: Resolve N:M. Composite PK on (FK1, FK2). Add attributes (e.g., quantity) as needed.
9. **Snapshot columns**: For historical values (price at order time), store in child table; never update from source.
10. **Denormalize** only after profiling; document trade-offs; maintain consistency via triggers or ETL.
