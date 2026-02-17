# BOOK 6 – Chapter 4: Hybrid Schema Design

---

## 1. Core Concept Explanation (Deep Technical Version)

### The Hybrid Approach

**Hybrid schema** combines relational columns (fixed, indexed, constrained) with semi-structured columns (JSONB for variable attributes). Core attributes are columns; flexible attributes are JSONB. Best of both: queryability and flexibility.

### When to Use JSONB

- **Variable attributes**: Product specs differ by category. Electronics: wattage, voltage. Clothing: size, material. One `attributes` JSONB column.
- **Event payloads**: Logs, webhooks. Structure varies by event type. Store as-is.
- **Configuration**: User preferences, feature flags. Key-value with varying keys.
- **External data**: API responses for audit, replay. Structure controlled externally.

### When to Stay Relational

- **Frequently queried/filtered**: Use columns. Indexed. Fast.
- **Referential integrity**: Foreign keys. Cannot FK into JSONB.
- **Strict schema**: CHECK constraints, NOT NULL. Enforce in columns.
- **Aggregations**: GROUP BY, SUM on columns. Simpler than JSON path.

### Hybrid Pattern

```
Core attributes (columns): id, name, created_at, status, customer_id
Flexible attributes (JSONB): metadata, specs, preferences, payload
```

Query pattern: Filter on columns. Extract from JSONB when needed. Index JSON path only if filtered often.

### Design Decisions

1. **What goes in columns?** Attributes used in WHERE, JOIN, ORDER BY, GROUP BY.
2. **What goes in JSONB?** Variable schema, rarely filtered, or external.
3. **Index JSONB?** Only paths used in WHERE. GIN for containment; expression for equality.
4. **Validation?** Application validates JSON structure. CHECK for critical invariants if possible.

---

## 2. Why This Matters in Production

### Real-World System Example

Products: id, name, price, category_id (columns). attributes (JSONB): {"color": "red", "size": "L", "material": "cotton"} for clothing; {"wattage": 100, "voltage": 220} for electronics. Filter by category (column). Display attributes (JSONB). Index attributes with GIN if filtering by color/size.

### Scalability Impact

- **Schema evolution**: New product type with new attributes. No ALTER TABLE. Add keys to JSONB.
- **Migration**: Adding column = backfill. JSONB: new keys, old rows have NULL for that key. Gradual adoption.

### Performance Impact

- **Column vs JSONB filter**: Column with btree index: O(log n). JSONB with expression index: similar. JSONB without index: O(n).
- **Selective index**: Index only JSONB paths that are filtered. Don't over-index.

### Data Integrity Implications

- **No FK into JSONB**: Store customer_id in column if orders reference customers. Don't put ID only in JSONB.
- **Constraint on JSONB**: Limited. `CHECK (jsonb_typeof(attributes->'price') = 'number')` for simple checks. Complex validation in app or trigger.

---

## 3. PostgreSQL Implementation

### Hybrid Products Table

```sql
CREATE TABLE products (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  price NUMERIC(10,2),
  category_id INT REFERENCES categories(id),
  attributes JSONB DEFAULT '{}'
);

CREATE INDEX idx_products_attributes ON products USING GIN (attributes);
CREATE INDEX idx_products_color ON products ((attributes->>'color')) WHERE attributes ? 'color';
```

### Audit Trail (Full Row as JSONB)

```sql
CREATE TABLE audit_log (
  id BIGSERIAL PRIMARY KEY,
  table_name TEXT,
  old_row JSONB,
  new_row JSONB,
  changed_at TIMESTAMPTZ,
  changed_by TEXT
);
```

### User Preferences

```sql
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  preferences JSONB DEFAULT '{}'
);
-- preferences: {"theme": "dark", "notifications": true, "language": "en"}
```

### Event Table (Variable Payload)

```sql
CREATE TABLE events (
  id BIGSERIAL PRIMARY KEY,
  event_type TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  payload JSONB
);

CREATE INDEX idx_events_type_created ON events (event_type, created_at);
CREATE INDEX idx_events_payload_user ON events ((payload->>'user_id')) WHERE payload ? 'user_id';
```

---

## 4. Common Developer Mistakes

### Mistake 1: Putting Everything in JSONB

Core, filtered attributes should be columns. JSONB for variable part only.

### Mistake 2: No Index on Filtered JSON Path

Query `WHERE attributes->>'color' = 'red'` without index. Seq scan. Add expression index.

### Mistake 3: Storing IDs Only in JSONB

Need to JOIN to customers? Store customer_id as column. Cannot FK into JSONB.

### Mistake 4: Over-Normalizing JSONB

Splitting JSONB into multiple tables defeats flexibility. Keep as single column when structure varies.

### Mistake 5: No Documentation of JSON Structure

JSONB has no schema. Document expected keys, types. Use in API docs, README.

---

## 5. Interview Deep-Dive Section

**Q: When would you use JSONB vs relational columns?**  
A: JSONB: variable schema, rarely filtered, external data. Relational: frequently filtered, need FK, strict schema.

**Q: What are the downsides of storing data in JSONB?**  
A: No FK into nested values, harder to enforce constraints, more complex queries, indexing only on known paths.

**Q: How do you design a hybrid schema?**  
A: Core attributes (id, name, dates, FKs) as columns. Variable attributes (specs, metadata, payload) as JSONB. Index JSON paths that are filtered. Document structure.

---

## 6. Advanced Engineering Notes

### CHECK on JSONB

```sql
ALTER TABLE products ADD CONSTRAINT chk_attributes
CHECK (attributes ? 'color' OR attributes ? 'size' OR attributes ? 'wattage');
```

### Generated Column from JSONB

```sql
ALTER TABLE events ADD COLUMN user_id BIGINT 
GENERATED ALWAYS AS ((payload->>'user_id')::bigint) STORED;
CREATE INDEX ON events (user_id);
```

Enables FK, standard indexing. Use when one path is primary.

### EAV vs JSONB

EAV (Entity-Attribute-Value): Rows for each attribute. More normalized but complex queries. JSONB: One column. Simpler for variable attributes. Prefer JSONB for flexibility.

---

## 7. Mini Practical Exercise

1. Design hybrid products table. Columns: id, name, price, category_id. JSONB: attributes. Insert products with different attribute sets.
2. Add GIN index. Query by containment. Add expression index for specific key. Compare.
3. Create audit_log with old_row, new_row JSONB. Trigger to populate.
4. Document: when to add new column vs new JSON key.

---

## 8. Summary in 10 Bullet Points

1. **Hybrid**: Columns for core, JSONB for variable. Balance structure and flexibility.
2. **Columns**: Frequently filtered, JOIN, FK, strict schema.
3. **JSONB**: Variable attributes, event payloads, config, external data.
4. **Index JSONB**: Only paths used in WHERE. GIN or expression.
5. **No FK into JSONB**: Store IDs in columns for referential integrity.
6. **Document structure**: JSONB has no schema. Document keys, types.
7. **Audit**: Store old/new row as JSONB. Flexible for schema evolution.
8. **Generated column**: Extract JSON path to column. Enables FK, index.
9. **CHECK**: Limited validation on JSONB. Use for critical invariants.
10. **Evolution**: New attribute = new JSON key. New core attribute = ALTER TABLE.
