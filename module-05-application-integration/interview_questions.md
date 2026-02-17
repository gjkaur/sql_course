# Module 5: Interview Questions

## Parameterized Queries

1. **How do you prevent SQL injection?**
   - Use parameterized queries. Never concatenate user input into SQL.

2. **What are the benefits of parameterized queries beyond security?**
   - Query plan caching, type validation by the database.

## Stored Procedures & Triggers

3. **When would you use a stored procedure vs application code?**
   - Procedure: multi-step logic that benefits from reduced round-trips, or logic that must run in DB context. Application: business logic that changes often, needs unit tests.

4. **What is a trigger? When would you use one?**
   - Fires on INSERT/UPDATE/DELETE. Use for audit logs, derived columns, validation that must hold regardless of application.

5. **What are the downsides of triggers?**
   - Hidden logic, harder to debug, can cause cascading effects. Document well.

## Connection Pooling

6. **Why use connection pooling?**
   - Reduce connection overhead, stay within max_connections, improve latency.

7. **How do you size a connection pool?**
   - Consider max_connections, app concurrency, and workload. Rule of thumb: (cores * 2) + disks for CPU-bound.

## Transaction Management

8. **How do you handle transaction rollback in application code?**
   - try/except: on error, conn.rollback(). On success, conn.commit(). Use context managers when possible.

9. **What is the difference between autocommit and explicit transactions?**
   - Autocommit: each statement is a transaction. Explicit: BEGIN, multiple statements, COMMIT/ROLLBACK.
