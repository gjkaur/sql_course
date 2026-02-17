-- Capstone: E-Commerce Constraints
-- Run after 01_schema.sql

ALTER TABLE users ADD CONSTRAINT uq_users_email UNIQUE (email);
