-- Module 5: Stored Procedure Lab
-- Uses Online Retail schema

-- ============================================
-- Procedure: create_order
-- Creates an order with items in a single transaction
-- ============================================

CREATE OR REPLACE PROCEDURE create_order(
  p_customer_id BIGINT,
  p_items JSONB  -- [{"product_id": 1, "quantity": 2}, ...]
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_order_id BIGINT;
  item JSONB;
BEGIN
  INSERT INTO orders (customer_id, status) VALUES (p_customer_id, 'pending')
  RETURNING id INTO v_order_id;

  FOR item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    SELECT v_order_id,
           (item->>'product_id')::BIGINT,
           (item->>'quantity')::INT,
           p.price
    FROM products p
    WHERE p.id = (item->>'product_id')::BIGINT;
  END LOOP;
END;
$$;

-- Call: CALL create_order(1, '[{"product_id": 1, "quantity": 1}, {"product_id": 2, "quantity": 2}]');


-- ============================================
-- Function: get_order_total
-- Returns total for an order
-- ============================================

CREATE OR REPLACE FUNCTION get_order_total(p_order_id BIGINT)
RETURNS NUMERIC
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(SUM(quantity * unit_price), 0)
  FROM order_items
  WHERE order_id = p_order_id;
$$;

-- Call: SELECT get_order_total(1);
