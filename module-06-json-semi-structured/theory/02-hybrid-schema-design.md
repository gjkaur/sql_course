# Hybrid Relational + JSON Schema Design

## When to Use JSON

- **Variable attributes**: Product specs that differ by category
- **Event payloads**: Logs, webhooks with varying structure
- **Configuration**: User preferences, feature flags
- **External data**: API responses stored for audit

## When to Stay Relational

- **Frequently queried/filtered**: Use columns and indexes
- **Referential integrity**: Use FKs
- **Strict schema**: Use CHECK constraints

## Hybrid Pattern

- **Core attributes**: Columns (id, name, created_at)
- **Flexible attributes**: JSONB (metadata, specs)
- **Query pattern**: Index JSON path if filtered often

## Example

```sql
CREATE TABLE products (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  price NUMERIC(10,2),
  attributes JSONB  -- {"color": "red", "size": "L", "material": "cotton"}
);
CREATE INDEX idx_products_attributes ON products USING GIN (attributes);
```
