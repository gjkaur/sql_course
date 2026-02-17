# BOOK 5 – Chapter 5: Triggers

---

## 1. Core Concept Explanation (Deep Technical Version)

### What Is a Trigger?

A **trigger** is a block of code that runs automatically when a specified event occurs on a table. Events: INSERT, UPDATE, DELETE. Timing: BEFORE or AFTER (or INSTEAD OF for views). Granularity: FOR EACH ROW or FOR EACH STATEMENT.

**Trigger function**: The code that runs. Returns TRIGGER type. In PostgreSQL, uses special variables: NEW, OLD, TG_OP, TG_TABLE_NAME, etc.

**Trigger**: Binds trigger function to table and event. `CREATE TRIGGER ... AFTER INSERT ON t FOR EACH ROW EXECUTE FUNCTION fn();`

### When to Use Triggers

- **Audit logging**: Record who changed what, when. INSERT into audit_log on every change.
- **Derived columns**: Maintain redundant data (e.g., order total) when child rows change.
- **Validation**: Enforce rules that can't be expressed in CHECK (e.g., cross-row, cross-table).
- **Data sync**: Keep summary table in sync. Trigger on detail table updates summary.

### When Not to Use

- **Business logic that changes often**: Triggers are in DB; migration to change. Application is easier to iterate.
- **Complex logic**: Hard to test, debug. Hidden from application developers.
- **Cascading side effects**: Trigger fires trigger. Can be hard to reason about.

### BEFORE vs AFTER

- **BEFORE**: Runs before the change is applied. Can modify NEW (for INSERT/UPDATE). Use for validation, defaulting.
- **AFTER**: Runs after change. NEW/OLD reflect final state. Use for audit, derived columns, notifications.

### FOR EACH ROW vs FOR EACH STATEMENT

- **FOR EACH ROW**: Fires once per affected row. NEW/OLD are row values.
- **FOR EACH STATEMENT**: Fires once per statement. NEW/OLD are NULL (use transition tables if needed). Use for statement-level logic (e.g., "after any insert into t").

---

## 2. Why This Matters in Production

### Real-World System Example

Audit: Every change to customers, orders logged to audit_log. Trigger captures OLD, NEW, user, timestamp. Compliance requirement. Application doesn't need to remember to log.

### Scalability Impact

- **Trigger overhead**: Every INSERT/UPDATE/DELETE runs trigger. Adds latency. Keep trigger logic fast.
- **Cascading**: Trigger that inserts can fire another trigger. Chain can be slow.

### Performance Impact

- **Synchronous**: Trigger runs in same transaction. Blocks commit until trigger completes. No async.

### Data Integrity Implications

- **Enforcement**: Trigger can reject (BEFORE, RAISE EXCEPTION) or fix (BEFORE, modify NEW). Ensures rule holds regardless of application.
- **Hidden logic**: Developers may not know trigger exists. Document. Name clearly (e.g., audit_*, validate_*).

### Production Failure Scenario

**Case: Trigger caused deadlock.** Trigger on orders updated inventory. Two transactions: one inserted order then updated inventory; other updated inventory then inserted order. Trigger order differed. Deadlock. Fix: Consistent lock order. Or move inventory update to application with explicit locking.

---

## 3. PostgreSQL Implementation

### Audit Trigger

```sql
CREATE OR REPLACE FUNCTION audit_trigger_fn()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_log (table_name, operation, old_data, new_data, changed_at, changed_by)
  VALUES (
    TG_TABLE_NAME,
    TG_OP,
    CASE WHEN TG_OP = 'DELETE' THEN row_to_json(OLD) ELSE NULL END,
    CASE WHEN TG_OP = 'INSERT' THEN row_to_json(NEW) ELSE row_to_json(NEW) END,
    NOW(),
    current_user
  );
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER customers_audit
AFTER INSERT OR UPDATE OR DELETE ON customers
FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
```

### Validation Trigger (BEFORE)

```sql
CREATE OR REPLACE FUNCTION validate_order_dates()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.ship_date < NEW.order_date THEN
    RAISE EXCEPTION 'ship_date cannot be before order_date';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER orders_validate_dates
BEFORE INSERT OR UPDATE ON orders
FOR EACH ROW EXECUTE FUNCTION validate_order_dates();
```

### Derived Column (Update Parent on Child Change)

```sql
CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE orders
  SET total = (SELECT COALESCE(SUM(quantity * unit_price), 0) FROM order_items WHERE order_id = COALESCE(NEW.order_id, OLD.order_id))
  WHERE id = COALESCE(NEW.order_id, OLD.order_id);
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER order_items_update_total
AFTER INSERT OR UPDATE OR DELETE ON order_items
FOR EACH ROW EXECUTE FUNCTION update_order_total();
```

### Trigger Variables

- **NEW**: New row (INSERT, UPDATE). NULL for DELETE.
- **OLD**: Old row (UPDATE, DELETE). NULL for INSERT.
- **TG_OP**: 'INSERT', 'UPDATE', 'DELETE'
- **TG_TABLE_NAME**: Table name
- **TG_WHEN**: 'BEFORE', 'AFTER'

---

## 4. Common Developer Mistakes

### Mistake 1: Trigger Without Documentation

Hidden logic. Developers don't know. Document in schema, README. Name triggers clearly.

### Mistake 2: Slow Trigger

Heavy logic (API call, complex query) in trigger. Blocks commit. Move to async job.

### Mistake 3: Trigger That Modifies Same Table

UPDATE on same table in trigger. Can cause recursion or deadlock. Use AFTER; avoid self-update when possible.

### Mistake 4: RAISE in AFTER Trigger

After change is applied. Rollback undoes change. Prefer BEFORE for validation.

### Mistake 5: Forgetting RETURN

Trigger function must RETURN. RETURN NEW (or OLD for DELETE). RETURN NULL in BEFORE suppresses row (INSERT/UPDATE).

---

## 5. Interview Deep-Dive Section

**Q: What is a trigger? When would you use one?**  
A: Code that runs automatically on INSERT/UPDATE/DELETE. Use for audit logs, derived columns, validation that must hold regardless of application.

**Q: When would you use a trigger vs application logic?**  
A: Triggers for data integrity that must hold regardless of application (audit, derived columns). Application for business rules that may change or need to be testable in isolation.

**Q: What are the downsides of triggers?**  
A: Hidden logic, harder to debug, can cause cascading effects. Document well. Keep fast.

---

## 6. Advanced Engineering Notes

### INSTEAD OF Triggers (Views)

For updatable views. INSTEAD OF replaces the default behavior. Translate view update to base table updates.

### Transition Tables (FOR EACH STATEMENT)

```sql
CREATE TRIGGER t_after_stmt
AFTER INSERT ON t
REFERENCING NEW TABLE AS new_rows
FOR EACH STATEMENT EXECUTE FUNCTION fn();
-- fn() can access new_rows (set of inserted rows)
```

### Disable Trigger

```sql
ALTER TABLE t DISABLE TRIGGER trigger_name;
-- Bulk load without trigger
ALTER TABLE t ENABLE TRIGGER trigger_name;
```

---

## 7. Mini Practical Exercise

1. Create audit_log table. Create audit trigger on customers. INSERT, UPDATE, DELETE. Verify audit rows.
2. Create BEFORE trigger: reject negative quantity in order_items.
3. Create trigger: update orders.total when order_items change.

---

## 8. Summary in 10 Bullet Points

1. **Trigger**: Fires on INSERT/UPDATE/DELETE. BEFORE or AFTER. FOR EACH ROW or STATEMENT.
2. **Trigger function**: Returns TRIGGER. Uses NEW, OLD, TG_OP, etc.
3. **BEFORE**: Can modify NEW. Use for validation, defaulting.
4. **AFTER**: Change applied. Use for audit, derived columns.
5. **Audit**: Log OLD, NEW, user, timestamp. Compliance.
6. **Validation**: BEFORE trigger, RAISE EXCEPTION to reject.
7. **Derived columns**: Trigger updates parent when child changes.
8. **Hidden logic**: Document. Name clearly.
9. **Keep fast**: No API calls, heavy queries. Blocks commit.
10. **EXECUTE FUNCTION**: PostgreSQL 11+ syntax. Replaces EXECUTE PROCEDURE.
