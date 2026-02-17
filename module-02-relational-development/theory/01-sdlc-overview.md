# System Development Life Cycle (SDLC)

## Overview

SDLC provides a structured approach to building systems. For databases, we focus on requirements, design, implementation, and maintenance.

## Phases

### 1. Requirements Gathering

- **Stakeholders**: Business users, developers, DBAs
- **Deliverables**: Functional requirements, data flows, use cases
- **Questions**: What data? Who accesses it? What queries/reports?

### 2. Analysis & Design

- **Logical design**: ER model, normalization
- **Physical design**: Tables, indexes, partitioning
- **Deliverables**: ER diagram, schema DDL

### 3. Implementation

- Create schema, load data, build indexes
- Migrations for version control
- Testing: unit, integration, performance

### 4. Deployment & Maintenance

- Backup/recovery procedures
- Monitoring, tuning
- Schema evolution (ALTER, migrations)

## Database-Specific Considerations

- **Iterative**: Schema changes are costly; get design right early
- **Performance**: Design for actual query patterns, not hypothetical ones
- **Security**: Model roles and privileges during design

## Interview Insight

**Q: How do you approach a new database design?**

A: Start with requirements—who, what, when. Build an ER model, normalize to 3NF, then denormalize only where performance demands it. Validate with real query patterns. Use migrations for version control.
