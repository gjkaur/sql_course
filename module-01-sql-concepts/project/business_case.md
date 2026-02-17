# Online Retail System — Business Case

## Overview

A small online retailer sells products to customers. Orders are placed through a web store, and each order can contain multiple products with quantities and prices.

## Requirements

### Functional

1. **Customers**: Store name, email, phone, shipping address. Each customer has a unique email.
2. **Products**: Name, description, unit price, category. Products can be inactive (discontinued).
3. **Orders**: Each order belongs to one customer. Track order date, status (pending, shipped, delivered, cancelled).
4. **Order Items**: Each order has one or more line items. Each line item references a product, with quantity and unit price at time of order (price may change later).

### Non-Functional

- Support 10,000+ customers and 100,000+ orders
- Fast queries for: order history, product search, sales reports
- Data integrity: no orphan orders, no negative quantities

## Entities

| Entity | Description |
|--------|-------------|
| Customer | Person who places orders |
| Product | Item for sale |
| Order | Purchase transaction |
| Order Item | Line item in an order (product + quantity + price) |

## Relationships

- Customer 1:N Order (one customer, many orders)
- Order 1:N Order Item (one order, many line items)
- Product 1:N Order Item (one product can appear in many order items)

## Out of Scope (for Module 1)

- Payments
- Inventory/stock
- Reviews
- Multiple addresses per customer
