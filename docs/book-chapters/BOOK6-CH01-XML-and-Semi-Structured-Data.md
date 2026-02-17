# BOOK 6 – Chapter 1: XML and Semi-Structured Data

---

## 1. Core Concept Explanation (Deep Technical Version)

### Structured vs Semi-Structured Data

**Structured data** (relational) has a fixed schema. Tables, columns, types. Every row has the same shape. Schema is explicit and enforced.

**Semi-structured data** has a flexible or self-describing schema. Structure can vary per record. Examples: XML, JSON. Used when schema varies (e.g., different product types have different attributes) or when integrating external data with unknown structure.

### XML in Databases

**XML** (eXtensible Markup Language) is a hierarchical, tag-based format. Elements, attributes, nesting. SQL standard added XML type and functions (SQL:2003). PostgreSQL supports `xml` type and XPath queries.

**Use cases**: Legacy integrations, document storage, SOAP/XML APIs. XML has declined in favor of JSON for most new systems, but remains in enterprise and regulatory contexts.

**XML type**: Stores well-formed XML. Can validate against schema (optional). Supports XPath extraction.

### Why Semi-Structured in Relational DB?

- **Variable attributes**: Product specs differ by category. Electronics have "wattage"; clothing has "size." One table with JSON/XML column avoids many nullable columns or EAV (Entity-Attribute-Value) tables.
- **External data**: API responses, webhooks. Structure controlled by external system. Store as-is for audit or replay.
- **Schema evolution**: Adding attributes without ALTER TABLE. New keys in JSON; old rows unaffected.
- **Document storage**: Contracts, configs. Hierarchical structure. Query specific paths.

### Trade-offs

**Pros**: Flexibility, less migration, integrate heterogeneous data.  
**Cons**: No referential integrity into nested values, harder to constrain, more complex queries, indexing limitations.

---

## 2. Why This Matters in Production

### Real-World System Example

E-commerce: Product attributes vary. Electronics: voltage, wattage. Clothing: size, material. Single `attributes` column (JSON/XML) stores variable fields. Core columns (id, name, price) stay relational. Hybrid approach.

### Scalability Impact

- **Querying nested data**: Without index, full scan. GIN index (JSONB) or expression index helps. XML has limited indexing in PostgreSQL.
- **Storage**: JSON/XML can bloat if storing large documents. Consider compression, external storage for very large payloads.

### Performance Impact

- **Parsing**: XML/JSON parsed on read (unless JSONB—binary). Large documents = parse cost.
- **Extraction**: XPath, JSON path. Can be optimized with indexes when supported.

### Data Integrity Implications

- **No FK into JSON/XML**: Cannot reference nested id. Store IDs in relational columns if you need joins.
- **Validation**: CHECK constraints on JSON/XML are limited. Application or triggers for complex validation.

---

## 3. PostgreSQL Implementation

### XML Type

```sql
CREATE TABLE documents (
  id SERIAL PRIMARY KEY,
  content XML
);

INSERT INTO documents (content) VALUES (
  '<order><id>1</id><customer>Alice</customer><items><item qty="2">Widget</item></items></order>'::xml
);

-- XPath extraction
SELECT xpath('//customer/text()', content) FROM documents;
SELECT xpath('//item/@qty', content) FROM documents;
```

### XML Functions

```sql
SELECT xmlparse(CONTENT '<root><a>1</a></root>');
SELECT xmlelement(name "order", xmlattributes(1 as id), xmlelement(name "total", 99.99));
```

### JSON (Text) Type

```sql
CREATE TABLE events (
  id SERIAL PRIMARY KEY,
  payload JSON
);
INSERT INTO events (payload) VALUES ('{"event": "click", "page": "/home", "user_id": 123}');
SELECT payload->>'event' FROM events;  -- 'click'
```

---

## 4. Common Developer Mistakes

### Mistake 1: Using XML When JSON Would Do

JSON is dominant for APIs, configs. Use JSON/JSONB unless XML is required (legacy, schema validation).

### Mistake 2: Storing Everything in JSON

Core, frequently-queried attributes should be columns. JSON for variable/extensible parts only.

### Mistake 3: No Index on Queried Paths

Filtering on JSON key without index = seq scan. Add GIN or expression index.

### Mistake 4: Assuming Schema in Application

JSON has no enforced schema. Validate in application. Document expected structure.

---

## 5. Interview Deep-Dive Section

**Q: When would you use semi-structured (JSON/XML) vs relational columns?**  
A: Semi-structured for variable schema, rarely filtered, external data. Relational for frequently filtered, need FK, strict schema.

**Q: What are the downsides of storing data in JSON/XML?**  
A: No FK into nested values, harder to enforce constraints, more complex queries, indexing limitations.

---

## 6. Advanced Engineering Notes

### XML Schema Validation

PostgreSQL can validate XML against a schema. Adds overhead. Use when strict validation required.

### JSON vs XML

JSON: Lighter, native to JavaScript, widely used in APIs. XML: Schema support, namespaces, XSLT. Choose based on ecosystem.

---

## 7. Mini Practical Exercise

1. Create table with XML column. Insert sample. Extract values with xpath.
2. Create table with JSON column. Insert. Extract with -> and ->>.
3. Compare: query performance with and without index on JSON path.

---

## 8. Summary in 10 Bullet Points

1. **Semi-structured**: Flexible schema. XML, JSON. Variable per record.
2. **XML**: Tag-based, hierarchical. Legacy, document storage.
3. **JSON**: Key-value, arrays. Dominant for APIs, configs.
4. **Use when**: Variable attributes, external data, schema evolution.
5. **Trade-offs**: Flexibility vs integrity, query complexity.
6. **No FK into nested**: Store IDs in columns for joins.
7. **Indexing**: GIN for JSONB. Expression index for specific path.
8. **Hybrid**: Core columns + JSON/XML for variable parts.
9. **Validate in app**: No enforced schema in JSON. Document structure.
10. **XML declining**: Prefer JSON for new systems unless required.
