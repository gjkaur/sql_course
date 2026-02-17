# BOOK 2 – Chapter 1: System Development Life Cycle

---

## 1. Core Concept Explanation (Deep Technical Version)

### SDLC as a Risk-Reduction Framework

The **System Development Life Cycle (SDLC)** is a phased approach to building software. For databases, the stakes are higher: schema changes are costly, data outlives code, and mistakes compound over time. SDLC provides checkpoints to catch errors before they become production failures.

**Waterfall** (sequential phases) vs **Agile** (iterative sprints): Both apply to databases. Waterfall suits greenfield projects with clear requirements. Agile suits evolving domains—but database schema changes still require migrations, testing, and coordination. The key is **intentional design**, not ad-hoc table creation.

### Phases in Database Context

**1. Requirements Gathering**

- **Stakeholders**: Business users, product owners, developers, DBAs, compliance.
- **Deliverables**: Functional requirements, data flows, use cases, query patterns.
- **Critical questions**: What entities? Who accesses what? What reports? What SLAs? What retention?
- **Common failure**: Building for hypothetical queries. Real systems have 3–5 dominant access patterns; design for those first.

**2. Analysis & Logical Design**

- **ER modeling**: Entities, attributes, relationships, cardinality. Implementation-agnostic.
- **Normalization**: Decompose to 3NF (or BCNF) to eliminate redundancy and anomalies.
- **Deliverables**: ER diagram, logical schema (tables, keys, dependencies).
- **Common failure**: Skipping normalization, then discovering anomalies in production.

**3. Physical Design**

- **Tables, indexes, partitioning**: Map logical schema to physical structures.
- **Data types, constraints**: Choose types for correctness and performance.
- **Deliverables**: DDL scripts, index strategy, partitioning plan.
- **Common failure**: Indexing for hypothetical queries; missing indexes for actual hot paths.

**4. Implementation**

- **Schema creation**: Run DDL; apply migrations.
- **Data loading**: ETL, seed data, backfill.
- **Testing**: Unit (constraints, triggers), integration (app + DB), performance (load tests).
- **Deliverables**: Deployable schema, migration scripts, test suite.

**5. Deployment & Maintenance**

- **Backup/recovery**: Full, incremental, point-in-time.
- **Monitoring**: Query latency, lock contention, disk usage.
- **Schema evolution**: ALTER TABLE, migrations. Version control for DDL.

### Database-Specific Considerations

- **Iterative refinement**: Get the core schema right early. Adding columns is easier than splitting tables.
- **Query-driven design**: Design for actual access patterns. A schema that looks elegant but requires 7 JOINs for the main report is wrong.
- **Security by design**: Model roles and privileges during design, not as an afterthought.

---

## 2. Why This Matters in Production

### Real-World System Example

A fleet repair system: Requirements capture vehicles, customers, technicians, repair orders, parts. ER model identifies many-to-many between repair orders and parts (junction table). Normalization separates customers from vehicles. Physical design adds indexes on `vehicle_id`, `customer_id`, `opened_date`. Implementation uses migrations; deployment includes backup verification.

### Scalability Impact

- **Skipping requirements**: Building without understanding query patterns leads to wrong indexes, wrong partitioning.
- **Skipping physical design**: Default indexes may miss composite keys for common filters.

### Performance Impact

- **Late normalization**: Denormalized schema requires full-table scans for updates. Refactoring in production is risky.
- **Late indexing**: Adding indexes on large tables can lock; plan during design.

### Data Integrity Implications

- **No constraints in design**: Application assumes valid data; bad data propagates. Constraints are the last line of defense.
- **No backup strategy**: Data loss is unrecoverable. Define RPO/RTO during design.

### Production Failure Scenario

**Case: Schema without requirements.** A team built a "flexible" schema with JSONB for all attributes. No constraints, no indexes on JSON keys. Queries were slow; data quality was poor. Refactoring required 6 months. Lesson: Requirements and logical design first; flexibility is a trade-off, not a default.

---

## 3. PostgreSQL Implementation

### Requirements → ER → DDL Workflow

```sql
-- After ER modeling: customers, vehicles, repair_orders, technicians, parts, part_usage
CREATE TABLE customers (
  id         SERIAL PRIMARY KEY,
  company    VARCHAR(200) NOT NULL,
  contact    VARCHAR(100),
  phone      VARCHAR(20),
  address    TEXT
);

CREATE TABLE vehicles (
  id           SERIAL PRIMARY KEY,
  customer_id  INTEGER NOT NULL REFERENCES customers(id),
  vin          VARCHAR(17) UNIQUE NOT NULL,
  make         VARCHAR(50),
  model        VARCHAR(50),
  year         INTEGER CHECK (year BETWEEN 1900 AND 2100)
);

CREATE TABLE technicians (
  id             SERIAL PRIMARY KEY,
  name           VARCHAR(100) NOT NULL,
  specialization VARCHAR(50),
  hire_date      DATE
);

CREATE TABLE repair_orders (
  id            SERIAL PRIMARY KEY,
  vehicle_id    INTEGER NOT NULL REFERENCES vehicles(id),
  technician_id INTEGER REFERENCES technicians(id),
  opened_date   DATE NOT NULL,
  completed_date DATE,
  status        VARCHAR(20) CHECK (status IN ('open', 'in_progress', 'completed', 'cancelled')),
  labor_hours   NUMERIC(6,2),
  parts_cost    NUMERIC(10,2)
);

CREATE TABLE parts (
  id          SERIAL PRIMARY KEY,
  part_number VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  unit_cost   NUMERIC(10,2),
  qty_stock   INTEGER DEFAULT 0
);

CREATE TABLE part_usage (
  repair_order_id INTEGER NOT NULL REFERENCES repair_orders(id),
  part_id         INTEGER NOT NULL REFERENCES parts(id),
  quantity        INTEGER NOT NULL CHECK (quantity > 0),
  unit_price      NUMERIC(10,2) NOT NULL,
  PRIMARY KEY (repair_order_id, part_id)
);
```

### Migration Versioning

```sql
-- migrations/001_initial_schema.sql
-- migrations/002_add_indexes.sql
CREATE INDEX idx_repair_orders_vehicle ON repair_orders(vehicle_id);
CREATE INDEX idx_repair_orders_opened ON repair_orders(opened_date);
CREATE INDEX idx_part_usage_repair ON part_usage(repair_order_id);
```

---

## 4. Common Developer Mistakes

### Mistake 1: Building Tables Before Requirements

Creating tables from a quick sketch leads to wrong entities, missing relationships, and costly refactors.

### Mistake 2: Skipping ER Modeling

Jumping to DDL without an ER diagram makes it hard to validate with stakeholders and to reason about dependencies.

### Mistake 3: Ignoring Query Patterns

Designing for "flexibility" without knowing the top 5 queries results in slow, unindexed access paths.

### Mistake 4: No Migration Strategy

Ad-hoc ALTER in production. Use migration tools (Flyway, Liquibase, Alembic) and version DDL.

### Mistake 5: Deploying Without Backup Verification

Assume backups work. Test restore regularly.

---

## 5. Interview Deep-Dive Section

### Conceptual Questions

**Q: How do you approach a new database design?**  
A: Start with requirements—who, what, when. Build an ER model, normalize to 3NF, then denormalize only where profiling shows a bottleneck. Validate with real query patterns. Use migrations for version control.

**Q: What's the difference between logical and physical design?**  
A: Logical design is implementation-agnostic (ER, normalization). Physical design maps to a specific DBMS (tables, indexes, partitioning, data types).

**Q: When would you skip normalization?**  
A: Rarely at design time. Denormalize only after profiling shows a specific query is slow and JOINs are the cause. Document the trade-off.

### Scenario-Based Questions

**Q: Stakeholders keep changing requirements. How do you handle schema changes?**  
A: Use migrations. Add columns with DEFAULT where possible (avoids full rewrite). For breaking changes, multi-phase migration: add new structure, backfill, switch, deprecate old.

**Q: You inherit a schema with no documentation. How do you reverse-engineer the design?**  
A: Use `information_schema` and `pg_catalog` to extract tables, columns, constraints, FKs. Draw ER from FKs. Identify query patterns from slow query log or app code.

---

## 6. Advanced Engineering Notes

### SDLC Variants for Databases

- **Database-first**: Design schema before application. Good for data-centric systems.
- **Code-first (ORM)**: Schema from models. Migrations generated. Good for rapid iteration; watch for ORM limitations (N+1, missing constraints).
- **Contract-first**: API contract defines data shape; schema follows. Good for microservices.

### Tradeoffs

| Approach | Pros | Cons |
|----------|------|------|
| Waterfall | Clear phases, documented | Slow, rigid |
| Agile | Responsive to change | Schema churn, migration overhead |
| Database-first | Strong data integrity | Can delay app development |

---

## 7. Mini Practical Exercise

### Hands-On Task

1. Pick a domain (e.g., library, gym, restaurant).
2. List 5 entities and their attributes.
3. Draw relationships with cardinality (1:1, 1:N, N:M).
4. Write CREATE TABLE statements.
5. Identify 3 main query patterns and add indexes.

### Schema Review Task

Review the fleet repair schema above. Identify: (a) missing constraints, (b) missing indexes for "repairs by customer" and "parts used in last 30 days."

---

## 8. Summary in 10 Bullet Points

1. **SDLC** reduces risk through phased design: requirements → analysis → physical design → implementation → maintenance.
2. **Requirements first**: Understand entities, access patterns, SLAs before writing DDL.
3. **ER modeling** bridges user intent and relational schema; validate with stakeholders.
4. **Logical design**: Normalize to 3NF; physical design adds indexes and partitioning.
5. **Query-driven**: Design for actual access patterns, not hypothetical ones.
6. **Migrations**: Version DDL; use migration tools for repeatable deployments.
7. **Backup verification**: Test restore regularly; define RPO/RTO.
8. **Security by design**: Model roles and privileges during design.
9. **Schema evolution**: Add columns with DEFAULT; use multi-phase migrations for breaking changes.
10. **Document trade-offs**: Denormalization, caching, replication—document why and maintain consistency.
