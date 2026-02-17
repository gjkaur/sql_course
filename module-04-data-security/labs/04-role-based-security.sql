-- Module 4: Role-Based Security Lab
-- Run as superuser (e.g., sqlcourse or postgres)

-- ============================================
-- Create roles
-- ============================================
CREATE ROLE app_readonly NOLOGIN;
CREATE ROLE app_readwrite NOLOGIN;
CREATE ROLE dba_admin NOLOGIN;

-- ============================================
-- Grant schema usage
-- ============================================
GRANT USAGE ON SCHEMA public TO app_readonly;
GRANT USAGE ON SCHEMA public TO app_readwrite;
GRANT ALL ON SCHEMA public TO dba_admin;

-- ============================================
-- Read-only: SELECT on all tables in public
-- ============================================
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO app_readonly;

-- ============================================
-- Read-write: SELECT, INSERT, UPDATE, DELETE
-- ============================================
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_readwrite;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_readwrite;

-- ============================================
-- DBA: Full access
-- ============================================
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dba_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO dba_admin;

-- ============================================
-- Create login roles that inherit
-- ============================================
CREATE ROLE app_user LOGIN PASSWORD 'changeme' IN ROLE app_readwrite;
CREATE ROLE report_user LOGIN PASSWORD 'changeme' IN ROLE app_readonly;

-- ============================================
-- Test (as app_user)
-- ============================================
-- SET ROLE app_user;
-- SELECT * FROM customers;  -- Should work
-- DELETE FROM customers;    -- Should work (if app_readwrite)

-- ============================================
-- Test (as report_user)
-- ============================================
-- SET ROLE report_user;
-- SELECT * FROM customers;  -- Should work
-- INSERT INTO customers (...) VALUES (...);  -- Should fail

-- ============================================
-- Revoke example
-- ============================================
-- REVOKE INSERT ON customers FROM app_readwrite;
