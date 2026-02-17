# Production Failure Case Studies

## 1. Long Transaction Blocking Checkout

**Scenario**: Checkout process held a transaction open while calling a slow payment gateway. Other checkouts blocked on row locks.

**Fix**: Shorten transaction. Call payment API *after* COMMIT, or use async flow. Set lock_timeout.

## 2. Missing Index on FK

**Scenario**: JOIN on orders.customer_id caused Seq Scan on 10M-row orders table. Report timed out.

**Fix**: CREATE INDEX idx_orders_customer ON orders(customer_id). Query dropped from 30s to 0.5s.

## 3. Deadlock in Order Processing

**Scenario**: Two workers processed orders; one locked order then inventory, the other locked inventory then order. Deadlocks every few minutes.

**Fix**: Enforced lock order: always lock in (order_id ASC) order. Reduced deadlocks to zero.

## 4. Connection Pool Exhaustion

**Scenario**: App opened new connection per request; under load hit max_connections. All requests failed.

**Fix**: Implemented connection pooling (PgBouncer). Pool size 20; max_connections 100. Stable under 10x load.

## 5. JSONB Query Without Index

**Scenario**: Filter on JSONB field: `WHERE attributes->>'color' = 'red'`. Seq Scan on 1M products. 5s per query.

**Fix**: GIN index on attributes, or expression index on (attributes->>'color'). Query < 50ms.
