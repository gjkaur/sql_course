-- Module 4: Deadlock Reproduction
-- Run in TWO sessions. Execute in order to create deadlock.

-- ============================================
-- Create test table
-- ============================================
CREATE TABLE IF NOT EXISTS deadlock_test (
  id INT PRIMARY KEY,
  val INT
);
INSERT INTO deadlock_test (id, val) VALUES (1, 100), (2, 200)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- SESSION 1
-- ============================================
BEGIN;
UPDATE deadlock_test SET val = val + 1 WHERE id = 1;
-- Pause here. Run Session 2's first UPDATE.

UPDATE deadlock_test SET val = val + 1 WHERE id = 2;
-- Session 1 now waits for Session 2's lock on id=2

-- ============================================
-- SESSION 2 (run after Session 1's first UPDATE)
-- ============================================
BEGIN;
UPDATE deadlock_test SET val = val + 1 WHERE id = 2;
-- Session 2 has lock on id=2

UPDATE deadlock_test SET val = val + 1 WHERE id = 1;
-- Session 2 waits for Session 1's lock on id=1
-- DEADLOCK: S1 holds 1, wants 2. S2 holds 2, wants 1.
-- PostgreSQL aborts one transaction: "deadlock detected"

-- ============================================
-- Resolution
-- ============================================
-- The aborted session should ROLLBACK and retry.
-- To avoid: always lock in same order (id=1 before id=2).
