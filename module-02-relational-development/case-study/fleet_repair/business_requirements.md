# Fleet Repair System — Business Requirements

## Overview

A fleet management company operates repair shops. They need to track vehicles, their owners, repair orders, technicians, parts used, and labor.

## Functional Requirements

### Vehicles

- VIN (unique), make, model, year, license_plate
- Each vehicle belongs to one customer (fleet owner)

### Customers

- Company name, contact person, phone, address
- A customer can own multiple vehicles

### Technicians

- Name, specialization (e.g., engine, brakes), hire date
- A technician can work on many repair orders

### Repair Orders

- Vehicle, date opened, date completed, status (open, in_progress, completed, cancelled)
- Assigned to one primary technician
- Total labor hours, total parts cost

### Parts

- Part number (unique), description, unit cost, quantity in stock
- A part can be used in many repair orders

### Part Usage (Junction)

- Repair order, part, quantity used, unit price at time of use
- Tracks which parts were used in each repair

## Non-Functional

- Support 10,000+ vehicles, 50,000+ repair orders
- Fast queries: repair history by vehicle, parts usage reports, technician workload
