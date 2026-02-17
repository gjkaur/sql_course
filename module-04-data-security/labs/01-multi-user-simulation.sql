-- Module 4: Multi-User Simulation
-- Run in TWO separate psql sessions to demonstrate isolation

-- ============================================
-- SESSION 1
-- ============================================
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Update a row
UPDATE orders SET status = 'shipped' WHERE id = 1;

-- Don't commit yet. Switch to Session 2.

-- ============================================
-- SESSION 2 (in another terminal)
-- ============================================
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- This will BLOCK until Session 1 commits or rolls back
SELECT * FROM orders WHERE id = 1;
-- You won't see Session 1's uncommitted change (no dirty read)

-- Try to update same row - will block
UPDATE orders SET status = 'delivered' WHERE id = 1;

-- ============================================
-- SESSION 1: COMMIT
-- ============================================
COMMIT;

-- Now Session 2's SELECT returns the updated row.
-- Session 2's UPDATE proceeds (or conflicts if same row).

-- ============================================
-- REPEATABLE READ demo
-- ============================================
-- Session 1:
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT status FROM orders WHERE id = 1;  -- e.g., 'shipped'

-- Session 2: UPDATE and COMMIT
-- Session 1:
SELECT status FROM orders WHERE id = 1;  -- Still 'shipped' (same snapshot)
COMMIT;
