# Apartment Rental System

An SQL-based flat rental management project built around day-to-day apartment operations. The system manages flat listings, tenant records, bookings, lease agreements, rent payments, and availability reporting from a single relational database.

This repo uses SQLite so the project is easy to run locally without extra infrastructure, while still demonstrating practical database design, constraints, triggers, and reporting views.

## Features

- Manage apartment buildings and flat inventory.
- Store tenant contact, identity, and emergency details.
- Track booking requests and confirmed reservations.
- Convert bookings into signed leases.
- Record monthly rent invoices and payments.
- Flag overdue rent automatically.
- Check flat availability with current occupancy and reservation logic.
- Generate operational reports for leasing and collections.

## Database Modules

### Core tables

- `buildings`: high-level property records.
- `flats`: unit inventory, rent, furnishing, and listing details.
- `tenants`: renter profiles and contact information.
- `bookings`: reservation requests and pre-lease pipeline.
- `leases`: signed agreements linked to flats and tenants.
- `rent_payments`: invoice and payment tracking by billing month.

### Integrity rules

- Confirmed bookings cannot overlap for the same flat.
- Leases cannot overlap for the same flat.
- Overpayments are blocked by trigger-based validation.
- Payment status is auto-derived as `pending`, `partial`, `paid`, `overdue`, or `waived`.
- When a lease is created from a booking, the booking is automatically marked as `converted`.

### Reporting views

- `vw_flat_availability`: availability and next available date per flat.
- `vw_active_leases`: active lease roster with tenant contact details.
- `vw_overdue_rent`: outstanding balances and days overdue.
- `vw_monthly_revenue`: billed, collected, and outstanding revenue by month.

## Project Structure

```text
.
├── scripts/
│   └── init_db.sh
└── sql/
    ├── schema.sql
    ├── triggers.sql
    ├── views.sql
    ├── seed.sql
    ├── reports.sql
    └── operations.sql
```

## Quick Start

### 1. Initialize the demo database

```bash
sh scripts/init_db.sh apartment_rental.db
```

### 2. Run the demo reports

```bash
sqlite3 -header -column apartment_rental.db < sql/reports.sql
```

### 3. Inspect example operational queries

`sql/operations.sql` contains example statements for:

- onboarding a new tenant
- searching available flats for a stay window
- creating a confirmed booking
- converting a booking into a lease
- generating rent invoices
- recording rent payments

Run those statements one at a time against the initialized database.

## Sample Use Cases

### Check flat availability

```sql
SELECT *
FROM vw_flat_availability
WHERE availability_status = 'available'
ORDER BY monthly_rent;
```

### View overdue rent

```sql
SELECT tenant_name, flat_number, outstanding_balance, days_overdue
FROM vw_overdue_rent
ORDER BY days_overdue DESC;
```

### View active tenants

```sql
SELECT building_name, flat_number, tenant_name, monthly_rent
FROM vw_active_leases
ORDER BY building_name, flat_number;
```

## Skills Demonstrated

- relational database design
- normalization of rental operations data
- SQL constraints and foreign-key modeling
- trigger-based business rule enforcement
- reporting via reusable SQL views
- seeded demo data for portfolio-ready presentation

## Tech Stack

- SQL dialect: SQLite 3
- Tooling: `sqlite3` CLI

## Future Extensions

- user authentication and role-based access
- maintenance request tracking
- automated invoice generation procedures
- dashboards in a web frontend
- lease renewal reminders and vacancy forecasting
