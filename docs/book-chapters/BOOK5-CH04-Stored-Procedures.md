# BOOK 5 – Chapter 4: Stored Procedures

---

## 1. Core Concept Explanation (Deep Technical Version)

### What Is a Stored Procedure?

A **stored procedure** is a named block of code stored in the database. It can contain SQL and procedural logic (variables, loops, conditionals). Invoked with **CALL** from application or another procedure. Does not return a value (unlike a function); can have OUT parameters.

**Function** vs **Procedure**:
- **Function**: Returns a value. Can be used in SELECT: `SELECT my_func(1)`. Transaction control: cannot COMMIT/ROLLBACK inside (in PostgreSQL).
- **Procedure**: No return value. Called with CALL. Can COMMIT/ROLLBACK inside (PostgreSQL 11+). Use for multi-step operations that need transaction control.

### Why Use Stored Procedures?

1. **Reduce round-trips**: Multi-step logic (insert order, insert items, update inventory) in one call. No app ↔ DB round-trips per step.
2. **Centralized logic**: All clients (Python, Java, admin tool) get same behavior. Single source of truth.
3. **Security**: Grant EXECUTE on procedure; revoke direct table access. Procedure enforces business rules.
4. **Performance**: Logic runs in DB. No network latency between steps.

### When Not to Use

- **Rapidly changing logic**: Procedure requires migration to change. Application code deploys faster.
- **Complex business rules**: Harder to unit test in DB. Application may be better.
- **Cross-database**: Procedure is DB-specific. Reduces portability.

### Transaction Control in Procedures

PostgreSQL procedures can contain COMMIT/ROLLBACK. **Caution**: Committing inside procedure ends the caller's transaction context. Caller cannot roll back what procedure committed. Design carefully: either procedure controls full transaction or caller does. Avoid mixing.

**Best practice**: Procedure does not COMMIT. Caller wraps CALL in transaction; commits or rolls back.

---

## 2. Why This Matters in Production

### Real-World System Example

Order creation: INSERT order, INSERT order_items (loop), UPDATE inventory. As procedure: one CALL. Atomic. Application doesn't need to know table structure.

### Scalability Impact

- **Round-trip reduction**: 5 steps = 5 round-trips. Procedure = 1. Latency reduction.
- **Connection hold**: Procedure holds connection for duration. Keep procedures short.

### Performance Impact

- **Network**: Logic in DB. No data transfer for intermediate steps.
- **Locking**: Procedure runs in one transaction. Locks held until COMMIT. Keep short.

### Data Integrity Implications

- **Atomicity**: Procedure can enforce multi-table consistency. All or nothing.
- **Access control**: Grant EXECUTE only. No direct INSERT on tables. Procedure enforces rules.

---

## 3. PostgreSQL Implementation

### Create Procedure

```sql
CREATE OR REPLACE PROCEDURE create_order(
  p_customer_id INT,
  p_items JSONB  -- [{"product_id": 1, "qty": 2}, ...]
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_order_id INT;
  v_item JSONB;
BEGIN
  INSERT INTO orders (customer_id, total) VALUES (p_customer_id, 0)
  RETURNING id INTO v_order_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    INSERT INTO order_items (order_id, product_id, quantity)
    VALUES (v_order_id, (v_item->>'product_id')::INT, (v_item->>'qty')::INT);
  END LOOP;

  UPDATE orders SET total = (SELECT SUM(quantity * unit_price) FROM order_items WHERE order_id = v_order_id)
  WHERE id = v_order_id;
  -- No COMMIT; caller controls transaction
END;
$$;
```

### Call from Application

```python
cur.execute("CALL create_order(%s, %s)", (customer_id, json.dumps(items)))
conn.commit()
```

### Function (Returns Value)

```sql
CREATE OR REPLACE FUNCTION get_customer_order_count(p_customer_id INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM orders WHERE customer_id = p_customer_id;
  RETURN v_count;
END;
$$;

-- Use in SELECT
SELECT get_customer_order_count(1);
```

### OUT Parameters

```sql
CREATE OR REPLACE PROCEDURE create_order(
  p_customer_id INT,
  p_items JSONB,
  OUT p_order_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO orders (customer_id, total) VALUES (p_customer_id, 0)
  RETURNING id INTO p_order_id;
  -- ... rest
END;
$$;

-- Call
CALL create_order(1, '[{"product_id":1,"qty":2}]', NULL);
-- Or with variable: CALL create_order(1, items, p_order_id);
```

---

## 4. Common Developer Mistakes

### Mistake 1: COMMIT Inside Procedure

Caller loses transaction control. Procedure commits; caller cannot roll back. Avoid unless procedure is designed as standalone.

### Mistake 2: Long-Running Procedure

Holds connection and locks. Keep logic short. Move heavy processing to application or batch job.

### Mistake 3: No Error Handling

Procedure fails mid-way. Use EXCEPTION block. Rollback or handle.

### Mistake 4: Procedure for Simple CRUD

One INSERT doesn't need a procedure. Overhead. Use for multi-step or when logic must be centralized.

### Mistake 5: Hardcoding in Procedure

Magic numbers, table names. Use parameters. Pass configuration.

---

## 5. Interview Deep-Dive Section

**Q: When would you use a stored procedure vs application code?**  
A: Procedure: multi-step logic that benefits from reduced round-trips, or logic that must run in DB context (all clients). Application: business logic that changes often, needs unit tests, or is complex.

**Q: Can a procedure return a value?**  
A: Procedures use OUT parameters. Functions return values. Procedure: CALL proc(a, b, OUT x). Function: SELECT func(a, b).

**Q: Should a procedure commit?**  
A: Generally no. Caller controls transaction. Exception: procedure designed as standalone (e.g., scheduled job).

---

## 6. Advanced Engineering Notes

### SECURITY DEFINER

Procedure runs with definer's privileges. Use for elevated operations. Document; audit.

### Grant Execute

```sql
GRANT EXECUTE ON PROCEDURE create_order TO app_role;
REVOKE INSERT ON orders FROM app_role;  -- Force use of procedure
```

---

## 7. Mini Practical Exercise

1. Create procedure: insert customer, return new id via OUT.
2. Create procedure: create order with items. Call from Python. Verify atomicity (rollback on error).
3. Compare: 3 round-trips (INSERT order, INSERT items, UPDATE) vs 1 CALL.

---

## 8. Summary in 10 Bullet Points

1. **Procedure**: Named block in DB. Called with CALL. No return; can have OUT params.
2. **Function**: Returns value. Used in SELECT. No COMMIT inside.
3. **Procedure vs function**: Procedure for multi-step, transaction control. Function for computation.
4. **Round-trip reduction**: One CALL vs many statements.
5. **Centralized logic**: All clients get same behavior.
6. **No COMMIT in procedure**: Caller controls transaction. Best practice.
7. **EXCEPTION block**: Handle errors. Rollback or handle.
8. **Grant EXECUTE**: Restrict table access; force procedure use.
9. **Keep short**: Avoid long-held connections and locks.
10. **Use when**: Multi-step, reduced round-trips, or shared logic. Not for simple CRUD.
