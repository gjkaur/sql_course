-- Module 5: Trigger-Based Audit System
-- Uses Online Retail schema

-- ============================================
-- Audit log table
-- ============================================

CREATE TABLE IF NOT EXISTS audit_log (
  id BIGSERIAL PRIMARY KEY,
  table_name TEXT NOT NULL,
  operation TEXT NOT NULL,  -- INSERT, UPDATE, DELETE
  old_data JSONB,
  new_data JSONB,
  changed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  changed_by TEXT DEFAULT current_user
);

-- ============================================
-- Audit trigger function
-- ============================================

CREATE OR REPLACE FUNCTION audit_trigger_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO audit_log (table_name, operation, new_data)
    VALUES (TG_TABLE_NAME, 'INSERT', to_jsonb(NEW));
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_log (table_name, operation, old_data, new_data)
    VALUES (TG_TABLE_NAME, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO audit_log (table_name, operation, old_data)
    VALUES (TG_TABLE_NAME, 'DELETE', to_jsonb(OLD));
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

-- ============================================
-- Attach trigger to customers
-- ============================================

DROP TRIGGER IF EXISTS customers_audit ON customers;
CREATE TRIGGER customers_audit
  AFTER INSERT OR UPDATE OR DELETE ON customers
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- ============================================
-- Test
-- ============================================
-- UPDATE customers SET name = 'Alice Updated' WHERE id = 1;
-- SELECT * FROM audit_log ORDER BY id DESC LIMIT 5;
