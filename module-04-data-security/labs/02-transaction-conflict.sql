-- Module 4: Transaction Conflict Demo
-- Demonstrates non-repeatable read (Read Committed)

-- ============================================
-- Setup: Use orders table from module-01
-- ============================================

-- SESSION 1
BEGIN;
SELECT id, status FROM orders WHERE id = 1;
-- Returns: 1, 'delivered' (or current value)

-- SESSION 2 (run before Session 1 commits)
BEGIN;
UPDATE orders SET status = 'pending' WHERE id = 1;
COMMIT;

-- SESSION 1 (same transaction)
SELECT id, status FROM orders WHERE id = 1;
-- Returns: 1, 'pending' (non-repeatable read: different value in same tx)
COMMIT;

-- ============================================
-- With REPEATABLE READ
-- ============================================

-- SESSION 1
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT id, status FROM orders WHERE id = 1;

-- SESSION 2
BEGIN;
UPDATE orders SET status = 'shipped' WHERE id = 1;
COMMIT;

-- SESSION 1
SELECT id, status FROM orders WHERE id = 1;
-- Still returns original value (snapshot isolation)
COMMIT;
