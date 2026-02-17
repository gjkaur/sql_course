# BOOK 2 – Chapter 3: Avoiding Anomalies

---

## 1. Core Concept Explanation (Deep Technical Version)

### What Are Anomalies?

**Modification anomalies** are unintended side effects of insert, update, or delete operations. They arise from **redundancy**: storing the same fact in multiple places. When you update one copy, you must update all copies—or inconsistency results. Normalization eliminates redundancy and thus anomalies.

### Insert Anomaly

**Definition**: Cannot add a row without also providing unrelated data.

**Example**: If customers are embedded in an orders table (order_id, customer_id, customer_name, customer_email, product, quantity), you cannot add a new customer until they place an order. The table structure forces you to create a "dummy" order to record a customer.

**Root cause**: Mixing two entities (Customer, Order) in one table. The table's key is order-centric; customer data doesn't belong to the key.

**Fix**: Separate customers table. Insert customer first; insert order with customer_id when order occurs.

### Update Anomaly

**Definition**: Changing one fact requires updating multiple rows.

**Example**: Customer "Alice" changes her email from alice@old.com to alice@new.com. In a denormalized orders table, her email is stored in every order row. You must UPDATE every row where customer_id = Alice's ID. Miss one row → inconsistent data. Reports show different emails for the same customer.

**Root cause**: Same fact (customer email) stored redundantly. No single source of truth.

**Fix**: Store email only in customers table. One UPDATE. Orders reference customer_id; join to get email when needed.

### Delete Anomaly

**Definition**: Deleting a row removes unrelated data.

**Example**: Customer "Bob" has one order. You delete that order (e.g., cancelled). In a denormalized table, Bob's customer record (name, email, address) is stored only in that order row. Deleting the order deletes Bob. You've lost a customer record, not just an order.

**Root cause**: Dependent entity (Order) contains data for independent entity (Customer). Deleting the dependent removes the independent's only copy.

**Fix**: Separate customers table. Deleting an order does not touch customers. Customer exists independently.

### The Redundancy–Anomaly Link

All three anomalies stem from **redundancy**. Normalization decomposes tables so each fact is stored once. The trade-off: more tables, more JOINs. For OLTP, this is usually acceptable—integrity over convenience. For reporting, materialized views or denormalized reporting tables can be built on top.

---

## 2. Why This Matters in Production

### Real-World System Example

E-commerce: Denormalized (order_id, customer_name, customer_email, product_name, category, quantity). Insert anomaly: Can't add a product until it's ordered. Update anomaly: Product category change requires updating every order_item row. Delete anomaly: Deleting the last order for a product loses the product record. Normalized: customers, products, orders, order_items. Each entity has its own table. No anomalies.

### Scalability Impact

- **Update anomaly at scale**: 1M order rows with redundant customer_email. Customer changes email → 1M updates. Locks, log volume, replication lag.
- **Normalized**: 1 update in customers. Orders JOIN when needed. Index on customer_id makes join cheap.

### Performance Impact

- **Denormalization for reads**: Acceptable when reads dominate and you control writes. Use materialized views or summary tables. Document that they're derived; refresh strategy.
- **Anomalies from ad-hoc denormalization**: Adding "convenience" columns without migration strategy. Inconsistent data.

### Data Integrity Implications

- **Single source of truth**: Normalized design. Customer email lives in one place. No sync issues.
- **Audit trails**: Historical values (e.g., price at order time) are intentional snapshots, not redundancy. Store in order_items; never update from products.

### Production Failure Scenario

**Case: Delete anomaly in CRM.** Sales stored contact info (name, phone) only in "opportunity" rows. When the last opportunity for a contact was closed/lost, sales deleted it. Contact record disappeared. Lost leads, compliance issues. Fix: Separate contacts table. Opportunities reference contact_id. Deleting opportunity does not delete contact. Lesson: Model independent entities separately; never embed them in dependent tables.

---

## 3. PostgreSQL Implementation

### Denormalized (Anomaly-Prone)

```sql
-- BAD: Customers embedded in orders
CREATE TABLE orders_denorm (
  order_id      SERIAL PRIMARY KEY,
  customer_name VARCHAR(100),
  customer_email VARCHAR(255),
  product_name  VARCHAR(100),
  quantity      INT,
  total         NUMERIC(10,2)
);

-- Insert anomaly: Can't add customer without order
-- Update anomaly: Change email → update N rows
-- Delete anomaly: Delete last order → lose customer
```

### Normalized (Anomaly-Free)

```sql
CREATE TABLE customers (
  id     SERIAL PRIMARY KEY,
  name   VARCHAR(100) NOT NULL,
  email  VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE products (
  id   SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL
);

CREATE TABLE orders (
  id          SERIAL PRIMARY KEY,
  customer_id INT NOT NULL REFERENCES customers(id),
  order_date  DATE NOT NULL
);

CREATE TABLE order_items (
  order_id   INT NOT NULL REFERENCES orders(id),
  product_id INT NOT NULL REFERENCES products(id),
  quantity   INT NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(10,2) NOT NULL,
  PRIMARY KEY (order_id, product_id)
);

-- Insert: Add customer anytime. Add order when it occurs.
-- Update: Change customer email in one row.
-- Delete: Delete order; customer remains.
```

### Reconstituting Denormalized View (When Needed)

```sql
-- For reporting: create view or materialized view
CREATE VIEW order_report AS
SELECT o.id AS order_id, c.name AS customer_name, c.email AS customer_email,
       p.name AS product_name, oi.quantity, oi.unit_price
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id;
```

---

## 4. Common Developer Mistakes

### Mistake 1: "We'll Enforce in the Application"

Application code can have bugs. Database constraints and normalized design are the last line of defense. Anomalies can still occur if app logic is wrong or if data is modified outside the app (admin tools, migrations, other services).

### Mistake 2: Denormalizing "For Performance" Without Profiling

Adding redundant columns before measuring. Often the real bottleneck is missing indexes, not JOINs. Normalize first; denormalize only when profiling shows a clear need.

### Mistake 3: Confusing Historical Snapshot with Redundancy

order_items.unit_price is a snapshot—"price when ordered." Not redundant with products.price (current). Snapshot is intentional; redundancy is not. Don't "fix" by removing snapshot; you'd lose historical accuracy.

### Mistake 4: Embedding Independent Entity in Dependent

Storing customer details in orders. Customer is independent; order is dependent. Customer can exist without orders. Always separate.

### Mistake 5: Deleting "Orphan" Rows Without Understanding

Deleting customers with no orders to "clean up." May be valid (purge inactive). May be wrong (customers who haven't ordered yet). Understand business rules before bulk delete.

---

## 5. Interview Deep-Dive Section

### Conceptual Questions

**Q: Give an example of an update anomaly.**  
A: In a denormalized orders table with (order_id, customer_id, customer_name, customer_email), if a customer changes their email, you must UPDATE every order row for that customer. In a normalized design, you UPDATE one row in customers.

**Q: What causes anomalies?**  
A: Redundancy—storing the same fact in multiple places. When you update one copy, you must update all. Normalization eliminates redundancy by storing each fact once.

**Q: When is denormalization acceptable?**  
A: When a specific query is slow and profiling shows JOINs as the bottleneck. For read-heavy reporting. Use materialized views or summary tables. Document the trade-off; maintain consistency via refresh or triggers.

### Scenario-Based Questions

**Q: You have a table (student_id, course_id, instructor_name). What anomalies?**  
A: Update: Change instructor for a course → update all rows for that course. Delete: Delete the last enrollment for a course → lose instructor assignment. Insert: Can't add an instructor until they have a student. Fix: Separate instructors and courses; junction table for enrollment.

**Q: How do you handle "we need customer name on every order for reporting"?**  
A: Use a VIEW that JOINs orders and customers. Or a materialized view if the report is heavy and can tolerate staleness. Don't store customer_name in orders—that's redundancy and causes update anomaly.

---

## 6. Advanced Engineering Notes

### Anomaly vs Inconsistency

Anomaly refers to the *operation* (insert/update/delete) having unintended effects. Inconsistency is the *state* that results—multiple copies of a fact with different values. Anomalies cause inconsistency.

### Multi-Table "Anomalies"

Standard anomalies are single-table. Cross-table consistency (e.g., "order total must equal sum of order_items") requires CHECK constraints (if supported) or triggers. PostgreSQL doesn't support assertions; use triggers for multi-row checks.

### Event Sourcing Alternative

Instead of storing current state, store events (OrderPlaced, EmailChanged). State is derived. No update anomaly—you don't update; you append. Different trade-off: query complexity, storage growth. Used in high-event systems.

---

## 7. Mini Practical Exercise

### Hands-On Task

1. Create the denormalized orders_denorm table above. Insert 3 orders for 2 customers.
2. Simulate update anomaly: Change one customer's email. Did you update all rows?
3. Simulate delete anomaly: Delete one customer's only order. Is the customer gone?
4. Normalize. Repeat operations. Verify no anomalies.

### Analysis Task

For a library system (books, members, loans): If you had (loan_id, member_name, member_email, book_title, due_date), list one insert, one update, and one delete anomaly. Propose normalized tables.

---

## 8. Summary in 10 Bullet Points

1. **Insert anomaly**: Can't add row without unrelated data. Fix: Separate tables for independent entities.
2. **Update anomaly**: One fact change requires many row updates. Fix: Store each fact once (normalize).
3. **Delete anomaly**: Deleting a row removes unrelated data. Fix: Independent entities in separate tables.
4. **Root cause**: Redundancy. Same fact in multiple places.
5. **Normalization** eliminates redundancy by decomposition. Trade-off: more JOINs.
6. **Snapshot columns** (e.g., price at order time) are intentional, not redundancy. Don't update from source.
7. **Denormalize** only after profiling. Use materialized views or summary tables for reporting.
8. **Enforce in DB**: Constraints and schema protect against app bugs and ad-hoc updates.
9. **Independent vs dependent**: Customer is independent; Order is dependent. Never embed independent in dependent.
10. **Document trade-offs**: When denormalizing, document why, refresh strategy, and consistency approach.
