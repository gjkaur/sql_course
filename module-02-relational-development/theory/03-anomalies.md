# Database Anomalies

## Types

### Insert Anomaly

Cannot add a row without unrelated data.

**Example**: If customer is embedded in orders, you can't add a new customer until they place an order. **Fix**: Separate customers table.

### Update Anomaly

Changing one fact requires updating multiple rows.

**Example**: Customer changes address; it's stored in every order row. Update 1000 orders instead of 1 customer. **Fix**: Store address only in customers.

### Delete Anomaly

Deleting a row removes unrelated data.

**Example**: Delete the last order for a customer and you lose the customer record. **Fix**: Separate customers table.

## Root Cause

Redundancy: same fact stored in multiple places. Normalization eliminates redundancy and thus anomalies.

## Trade-off

Over-normalization → many JOINs → slower queries. Under-normalization → anomalies. Balance based on access patterns.

## Interview Insight

**Q: Give an example of an update anomaly.**

A: In a denormalized orders table with (order_id, customer_id, customer_name, customer_email), if a customer changes their email, you must UPDATE every order row for that customer. In a normalized design, you UPDATE one row in customers.
