-- SQL Mastery Course - Database Bootstrap
-- Runs on first container startup

-- Create extensions useful for the course
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Log successful initialization
DO $$
BEGIN
  RAISE NOTICE 'SQL Mastery Course database initialized successfully.';
  RAISE NOTICE 'Connect with: psql -h localhost -U sqlcourse -d sqlcourse';
END $$;
