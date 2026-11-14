# SQL Data Warehouse – Medallion Architecture

Modern data warehouse built in **PostgreSQL** using the **Medallion Architecture** (Bronze → Silver → Gold). It consolidates sales data from two source systems (CRM and ERP, delivered as CSV files) into a star schema ready for analytics and reporting.

## Architecture

| Layer  | Purpose                        | Object type | Load                     |
|--------|--------------------------------|-------------|--------------------------|
| Bronze | Raw data, as received          | Tables      | Full load (truncate & insert) via `COPY` |
| Silver | Cleaned and standardized data  | Tables      | Full load (truncate & insert) |
| Gold   | Business-ready star schema     | Views       | None                     |

## Project structure

```
sql-data-warehouse-medallion/
├── 00_setup/        Setup guide
├── 01_datasets/     Source CSV files (source_crm, source_erp)
├── 02_docs/         Naming conventions and data catalog
├── 03_scripts/      init_database.sql, bronze/, silver/, gold/
└── 04_tests/        Data quality checks for Silver and Gold
```

## Quick start

See [`00_setup/README.md`](00_setup/README.md) for the step-by-step run order.
