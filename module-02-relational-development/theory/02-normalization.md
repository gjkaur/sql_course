# Normalization

## Purpose

Reduce redundancy and anomalies by decomposing tables based on functional dependencies.

## Normal Forms

### 1NF (First Normal Form)

- Atomic values: no repeating groups or arrays in a cell
- Each column has a single value
- Each row is unique (has a primary key)

**Violation**: A column with comma-separated values (e.g., "tag1, tag2, tag3")

### 2NF (Second Normal Form)

- In 1NF
- No partial dependencies: every non-key attribute depends on the *whole* primary key

**Violation**: In (order_id, product_id) → product_name, product_name depends only on product_id. Move product_name to products table.

### 3NF (Third Normal Form)

- In 2NF
- No transitive dependencies: no non-key attribute depends on another non-key attribute

**Violation**: customer_id → city, city → region. Region depends on city, not directly on customer_id. Extract (city, region) to a separate table.

### BCNF (Boyce-Codd Normal Form)

- Every determinant is a candidate key
- Stricter than 3NF; handles overlapping candidate keys

**Violation**: (student, course) → instructor, instructor → course. Instructor determines course, but instructor isn't a key. Split tables.

## When to Denormalize

- **Reporting**: Pre-join or materialize for heavy analytics
- **Read-heavy**: Accept redundancy for faster reads
- **Trade-off**: More writes, risk of inconsistency. Use triggers or app logic to maintain.

## Interview Insight

**Q: What's the difference between 2NF and 3NF?**

A: 2NF removes partial dependencies (non-key depends on part of key). 3NF removes transitive dependencies (non-key depends on another non-key). Example: order_id, product_id → product_name is 2NF violation; customer_id → city → region is 3NF violation.
