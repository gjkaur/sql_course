# JSON Practical Use Cases

## 1. Audit Trail

Store before/after state as JSONB for flexible schema evolution.

```sql
CREATE TABLE audit_log (
  id BIGSERIAL PRIMARY KEY,
  table_name TEXT,
  old_row JSONB,
  new_row JSONB,
  changed_at TIMESTAMPTZ
);
```

## 2. Feature Flags / User Preferences

```sql
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email TEXT,
  preferences JSONB DEFAULT '{}'
);
-- preferences: {"theme": "dark", "notifications": true}
```

## 3. API Response Cache

Store external API responses for replay/debugging.

```sql
CREATE TABLE api_cache (
  id BIGSERIAL PRIMARY KEY,
  endpoint TEXT,
  response JSONB,
  cached_at TIMESTAMPTZ
);
```

## 4. E-commerce Product Variants

Products with varying attributes (size, color) without separate columns per variant.

```sql
-- attributes: {"sizes": ["S","M","L"], "colors": ["red","blue"]}
```

## 5. Event Sourcing Payload

Events with different structures per type.

```sql
-- payload varies by event_type
```

## Trade-offs

- **Pros**: Flexibility, schema evolution, less migration
- **Cons**: No FK into JSON, harder to enforce constraints, query complexity
