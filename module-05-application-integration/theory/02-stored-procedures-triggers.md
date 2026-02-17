# Stored Procedures and Triggers

## Stored Procedures

- Encapsulate logic in the database
- Can be called from application: `CALL create_order(...)`
- Transaction control inside procedure
- Reduce round-trips for multi-step operations

## Functions vs Procedures

- **Function**: Returns value; can be used in SELECT
- **Procedure**: No return; called with CALL; can commit/rollback internally

## Triggers

- Fire on INSERT, UPDATE, DELETE (before/after)
- Use for: audit logs, derived columns, validation
- **Caution**: Hidden logic; can make debugging hard. Document well.

## Example Trigger

```sql
CREATE OR REPLACE FUNCTION audit_trigger_fn()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_log (table_name, operation, old_data, new_data, changed_at)
  VALUES (TG_TABLE_NAME, TG_OP, row_to_json(OLD), row_to_json(NEW), NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER customers_audit
AFTER INSERT OR UPDATE OR DELETE ON customers
FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
```

## Interview Insight

**Q: When would you use a trigger vs application logic?**
A: Triggers for data integrity that must hold regardless of application (audit, derived columns). Application logic for business rules that may change or need to be testable in isolation.
