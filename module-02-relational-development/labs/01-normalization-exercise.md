# Lab 1: Normalization Exercise

## Scenario

You have a single table `orders_denormalized`:

| order_id | customer_name | customer_email | product_name | category | quantity | unit_price |
|----------|---------------|----------------|--------------|----------|----------|------------|
| 1 | Alice | alice@x.com | Mouse | Electronics | 2 | 29.99 |
| 1 | Alice | alice@x.com | Keyboard | Electronics | 1 | 89.99 |
| 2 | Bob | bob@x.com | Mouse | Electronics | 1 | 29.99 |

## Tasks

1. **Identify anomalies**
   - Insert: Can you add a new customer without an order?
   - Update: If Alice changes email, how many rows to update?
   - Delete: If you delete Bob's only order, what happens to Bob?

2. **Identify functional dependencies**
   - order_id → customer_name?
   - product_name → category?
   - (order_id, product_name) → quantity?

3. **Normalize to 3NF**
   - List the tables you would create
   - Draw the ER diagram
   - Write the CREATE TABLE statements

4. **Compare**
   - How many JOINs for "orders with customer and product names"?
   - Is the trade-off worth it for this schema?
