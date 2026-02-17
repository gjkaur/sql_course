# Module 2: Relational Database Development

**Book 2** of SQL All-In-One For Dummies | **Level:** Intermediate

## Learning Objectives

- Apply SDLC to database design
- Understand normalization (1NF, 2NF, 3NF, BCNF) and anomalies
- Balance integrity vs performance
- Design indexes with rationale
- Analyze execution plans with EXPLAIN

## Case Study: Fleet Repair System

A fleet management company tracks vehicles, customers, technicians, repair orders, parts, and part usage. This domain offers rich normalization scenarios and clear functional dependencies.

## Structure

```
module-02-relational-development/
├── theory/           # SDLC, normalization, anomalies
├── case-study/       # Fleet Repair System
├── labs/             # Normalization, index design
└── interview_questions.md
```

## Quick Start

```bash
psql -h localhost -U sqlcourse -d sqlcourse -f module-02-relational-development/case-study/fleet_repair/schema_normalized.sql
psql -h localhost -U sqlcourse -d sqlcourse -f module-02-relational-development/case-study/fleet_repair/index_strategy.sql
```
