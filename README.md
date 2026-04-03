# 🏗️ Data Warehouse Project — SQL Server

![SQL Server](https://img.shields.io/badge/SQL%20Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=for-the-badge)
![Architecture](https://img.shields.io/badge/Architecture-Medallion-blue?style=for-the-badge)
![Layer](https://img.shields.io/badge/Layers-Bronze%20%7C%20Silver%20%7C%20Gold-gold?style=for-the-badge)

A complete, production-style **Data Warehouse** built on **Microsoft SQL Server** using the **Medallion Architecture** (Bronze → Silver → Gold).

This project consolidates data from two business systems — CRM and ERP — into a clean, analytics-ready Star Schema with full data lineage, quality checks, and stored procedures.

---

## 📌 Project Overview

| Item | Detail |
|------|--------|
|  Database** | Microsoft SQL Server |
| **Architecture** | Medallion (Bronze → Silver → Gold) |
| **Source Systems** | CRM (CSV) + ERP (CSV / JSON) |
| **Total Source Tables** | 7 |
| **Total Warehouse Tables** | 23 (7 Bronze + 7 Silver + 9 Gold) |
| **Gold Schema** | Star Schema (5 Dims + 4 Facts) |
| **Language** | T-SQL (Stored Procedures) |
| **Tool** | SQL Server Management Studio (SSMS) |

---

## 🎯 Objective

Raw business data from CSV and JSON files had serious quality issues that made direct analysis unreliable:

- **10+ different date formats** in a single column
- **Phone numbers** with `+91`, spaces, hyphens, `(W)` suffix
- **Country** stored as `india`, `INDIA`, `IN`, `IND`, `Bharat`, `Hind`
- **Revenue** stored as text — `"5.0 Lakh"`, `"Confidential"`
- **NULL values** stored as text — `"N/A"`, `"Not Available"`, `"TBD"`
- **Inconsistent casing** — `MAHESH`, `mahesh`, `Mahesh`

This project solves all these problems and delivers a single trusted source of truth for business analytics.

---

## 🏛️ Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                    DataWarehouse (SQL Server)                  │
│                                                                │
│  ┌───────────────┐    ┌───────────────┐    ┌───────────────┐   │
│  │ BRONZE LAYER  │───▶│ SILVER LAYER  │───▶│  GOLD LAYER   │  │
│  │               │    │               │    │               │   │
│  │  Raw data     │    │  Cleaned &    │    │  Star Schema  │   │
│  │  as-is from   │    │  standardized │    │  business-    │   │
│  │  source files │    │  data         │    │  ready data   │   │
│  │               │    │               │    │               │   │
│  │  7 tables     │    │  7 tables     │    │  5 dims       │   │
│  │  No transform │    │  7 procedures │    │  4 facts      │   │
│  └───────────────┘    └───────────────┘    └───────────────┘   │
└────────────────────────────────────────────────────────────────┘
         ▲                                           │
         │                                           ▼
   CRM + ERP                                BI & Reporting
   CSV / JSON                           (Power BI / SQL Queries)
```

---

## 📂 Repository Structure

```
data-warehouse-project/
│
├── README.md                         
│
├── docs/
│   ├── data_catalog.md               ← All columns documented with examples
│   ├── architecture.png              ← High level architecture diagram
│   ├── data_flow.png                 ← Data lineage diagram
│   ├── data_integration.png          ← Table relationships diagram
│   ├── data_layers.png               ← Layer comparison table
│   └── data_model.png                ← Star schema diagram
│
├── scripts/
│   ├── bronze/
│   │   └── ddl_bronze.sql            ← Raw layer — CREATE TABLE scripts
│   │
│   ├── silver/
│   │   ├── ddl_silver.sql            ← Clean layer — CREATE TABLE scripts
│   │   ├── proc_load_crm_customers.sql
│   │   ├── proc_load_crm_leads.sql
│   │   ├── proc_load_support_tickets.sql
│   │   ├── proc_load_erp_employees.sql
│   │   ├── proc_load_erp_purchase_orders.sql
│   │   ├── proc_load_erp_sales_invoices.sql
│   │   └── proc_load_erp_inventory.sql
│   │
│   ├── gold/
│   │   ├── ddl_gold.sql              ← Star schema — CREATE TABLE scripts
│   │   ├── proc_load_dim_date.sql
│   │   ├── proc_load_dim_customers.sql
│   │   ├── proc_load_dim_products.sql
│   │   ├── proc_load_dim_employees.sql
│   │   ├── proc_load_dim_vendors.sql
│   │   ├── proc_load_fact_sales.sql
│   │   ├── proc_load_fact_purchases.sql
│   │   ├── proc_load_fact_support.sql
│   │   └── proc_load_fact_leads.sql
│   │
│   ├── analytics/
│   │   ├── sales_analytics.sql       ← Revenue, overdue, salesperson reports
│   │   ├── purchase_analytics.sql    ← Vendor spend, delivery analysis
│   │   ├── support_analytics.sql     ← SLA, CSAT, agent performance
│   │   ├── lead_analytics.sql        ← Funnel, conversion, campaign ROI
│   │   └── customer_360.sql          ← Full customer profile view
│   │
│   └── master/
│       └── master_etl.sql            ← Run everything in one click
```

---

## 🔄 Data Flow

```
CRM System (CSV)          ERP System (CSV/JSON)
      │                          │
      └──────────┬───────────────┘
                 ▼
        ┌─────────────────┐
        │  BRONZE LAYER   │  ← Raw ingestion (as-is)
        │  7 source tables│
        └────────┬────────┘
                 │  Stored Procedures (Truncate & Insert)
                 ▼
        ┌─────────────────┐
        │  SILVER LAYER   │  ← Cleaning & standardization
        │  7 clean tables │
        └────────┬────────┘
                 │  Stored Procedures (Joins & Integration)
                 ▼
        ┌─────────────────┐
        │   GOLD LAYER    │  ← Business-ready Star Schema
        │  5 dims + 4 fct │
        └────────┬────────┘
                 │
                 ▼
        BI Tools / Reports
```

---

## 🧹 Silver Layer — Data Quality Transformations

| Problem Found | Example | Solution Applied |
|---------------|---------|-----------------|
| Mixed date formats | `10/19/1962`, `1996-03-01`, `29-Jan-95` | `TRY_CONVERT(DATE, ..., 105)` |
| Phone number mess | `+91-74994-46327`, `9872830248(W)` | Strip prefix → 10-digit validate |
| Country variants | `india`, `IN`, `IND`, `Bharat`, `Hind` | Standardized to `'India'` |
| Revenue as text | `"5.0 Lakh"`, `"Confidential"` | `× 100000` → `DECIMAL(18,2)` |
| NULL as text | `"N/A"`, `"Not Available"`, `"TBD"` | → actual `NULL` |
| Mixed casing | `MAHESH`, `rajkot`, `  Harish  ` | `PROPER case + TRIM` |
| Boolean variants | `Y`, `Yes`, `1`, `Active` | → `BIT 1` or `0` |
| Amount with prefix | `"Rs.471610"`, `"INR 8332362"` | Strip prefix → `DECIMAL` |
| Invalid emails | `na@na.com`, `test@test`, `#N/A` | → `NULL` |
| Priority inconsistency | `P1`, `P2`, `High`, `Critical` | `P1→Critical`, `P2→High` |
| GST invalid values | `lowercase`, `"GSTIN Pending"` | `UPPER` + invalid → `NULL` |
| Self-referencing manager | `employee_id = manager_id` | → `NULL` |

---

## ⭐ Gold Layer — Star Schema

```
                      gold.dim_date
                           │
                      date_key (FK)
                           │
gold.dim_customers ────────┼──────── gold.dim_products
   customer_key (FK)       │           product_key (FK)
                           │
                    ┌──────┴──────┐
                    │  FACT TABLE │
                    │  fact_sales │
                    │ fact_purch  │
                    │ fact_support│
                    │ fact_leads  │
                    └──────┬──────┘
                           │
gold.dim_employees ────────┴──────── gold.dim_vendors
   employee_key (FK)                   vendor_key (FK)
```

### Dimension Tables

| Table | Source | Purpose |
|-------|--------|---------|
| `gold.dim_date` | Generated | Calendar — day, month, quarter, Indian FY |
| `gold.dim_customers` | silver.crm_customers | Customer master with segments |
| `gold.dim_products` | silver.erp_inventory | Product master with pricing |
| `gold.dim_employees` | silver.erp_employees | Employee master with HR data |
| `gold.dim_vendors` | silver.erp_purchase_orders | Vendor master with spend metrics |

### Fact Tables

| Table | Source | Key Measures |
|-------|--------|-------------|
| `gold.fact_sales` | silver.erp_sales_invoices | Revenue, GST, balance due, days overdue |
| `gold.fact_purchases` | silver.erp_purchase_orders | PO value, delivery delay, is_delayed |
| `gold.fact_support` | silver.support_tickets | Resolution hrs, SLA breached, CSAT rating |
| `gold.fact_leads` | silver.crm_leads | Pipeline value, weighted value, conversion |

---

## 🚀 How to Run

### Prerequisites
- Microsoft SQL Server (2016 or later)
- SQL Server Management Studio (SSMS)
- Source CSV/JSON files loaded into Bronze tables

### Execution Steps

```sql
-- Step 1: Create schemas
CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;

-- Step 2: Create Bronze tables
-- Run: scripts/bronze/ddl_bronze.sql

-- Step 3: Load raw data into Bronze
-- Use SSMS Import Wizard or BULK INSERT

-- Step 4: Create Silver tables
-- Run: scripts/silver/ddl_silver.sql
-- Run: all scripts/silver/proc_load_*.sql files

-- Step 5: Create Gold tables
-- Run: scripts/gold/ddl_gold.sql
-- Run: all scripts/gold/proc_load_*.sql files

-- Step 6: Run full ETL in one click
EXEC master.run_full_etl;
```

---

## 📊 Sample Analytical Queries

```sql
-- Monthly revenue by financial year
SELECT d.financial_year, d.month_name,
       SUM(f.invoice_total) AS revenue
FROM gold.fact_sales f
JOIN gold.dim_date d ON d.date_key = f.date_key
GROUP BY d.financial_year, d.month_name, d.financial_month
ORDER BY d.financial_year, d.financial_month;

-- Top 10 customers by revenue
SELECT TOP 10 c.full_name, c.customer_segment,
       SUM(f.invoice_total) AS total_revenue
FROM gold.fact_sales f
JOIN gold.dim_customers c ON c.customer_key = f.customer_key
GROUP BY c.full_name, c.customer_segment
ORDER BY total_revenue DESC;

-- SLA breach rate by priority
SELECT priority,
       COUNT(*) AS total_tickets,
       CAST(SUM(sla_breached) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS breach_pct
FROM gold.fact_support
GROUP BY priority;
```

---




## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| Microsoft SQL Server | Database engine |
| T-SQL | Stored procedures, DDL, DML |
| SSMS | Development & execution |
| Medallion Architecture | Data warehouse design pattern |
| Star Schema | Gold layer data modeling |

---

## 🗂️ Source Systems

### CRM System
| Table | Rows (approx) | Description |
|-------|--------------|-------------|
| crm_customers | 13,00,000+ | Customer master with demographics |
| crm_leads | 13,00,000+ | Sales pipeline and lead tracking |
| support_tickets | 13,00,000+ | Customer support and complaints |

### ERP System
| Table | Rows (approx) | Description |
|-------|--------------|-------------|
| erp_employees | 13,00,000+ | HR master — employee records |
| erp_purchase_orders | 13,00,000+ | Vendor procurement |
| erp_sales_invoices | 13,00,000+ | Customer invoicing and GST |
| erp_inventory | 13,00,000+ | Product stock and warehouse data |

---

## 👤 Author
-Nitin Sonawane

**Data Engineering Project — 2025**

Built as a complete end-to-end data engineering portfolio project demonstrating:
- Data ingestion from multiple source formats
- Data cleaning and standardization at scale
- Dimensional modeling (Star Schema)
- SQL Server stored procedure development
- Data quality validation
- Documentation and data lineage

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

> ⭐ If this project helped you, please give it a star!
