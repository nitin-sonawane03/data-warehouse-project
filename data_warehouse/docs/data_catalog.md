# Data Catalog — DataWarehouse Gold Layer

> **Purpose:** This document describes every column in the Gold Layer tables with its name, data type, description, and example value.
> **Database:** DataWarehouse | **Schema:** gold | **Updated:** 2025

---

## Table of Contents
1. [gold.dim_date](#1-golddim_date)
2. [gold.dim_customers](#2-golddim_customers)
3. [gold.dim_products](#3-golddim_products)
4. [gold.dim_employees](#4-golddim_employees)
5. [gold.dim_vendors](#5-golddim_vendors)
6. [gold.fact_sales](#6-goldfact_sales)
7. [gold.fact_purchases](#7-goldfact_purchases)
8. [gold.fact_support](#8-goldfact_support)
9. [gold.fact_leads](#9-goldfact_leads)

---

## 1. gold.dim_date

**Purpose:** Calendar dimension table. Contains one row per date from 2015 to 2030. Used to analyze trends by day, month, quarter, and Indian Financial Year.

**Source:** Generated (no source table — created via stored procedure)

| Column Name | Data Type | Key | Description | Example |
|---|---|---|---|---|
| date_key | INT | PK | Unique integer key in YYYYMMDD format | `20240315` |
| full_date | DATE | | The actual calendar date | `2024-03-15` |
| day_of_week | TINYINT | | Day number (1=Monday, 7=Sunday) | `5` |
| day_name | NVARCHAR(10) | | Full name of the day | `Friday` |
| day_of_month | TINYINT | | Day number within the month (1–31) | `15` |
| day_of_year | SMALLINT | | Day number within the year (1–366) | `75` |
| week_of_year | TINYINT | | ISO week number (1–53) | `11` |
| month_number | TINYINT | | Month number (1=January, 12=December) | `3` |
| month_name | NVARCHAR(10) | | Full name of the month | `March` |
| month_short | NCHAR(3) | | 3-letter abbreviation of the month | `Mar` |
| quarter_number | TINYINT | | Calendar quarter (1–4) | `1` |
| quarter_name | NCHAR(2) | | Quarter label | `Q1` |
| year_number | SMALLINT | | 4-digit calendar year | `2024` |
| financial_year | NVARCHAR(10) | | Indian Financial Year (Apr–Mar) | `FY2023-24` |
| financial_quarter | NCHAR(2) | | FY quarter (Q1=Apr–Jun, Q4=Jan–Mar) | `Q4` |
| financial_month | TINYINT | | Month position in FY (1=April, 12=March) | `12` |
| is_weekend | BIT | | 1 if Saturday or Sunday, else 0 | `0` |
| is_month_start | BIT | | 1 if first day of the calendar month | `0` |
| is_month_end | BIT | | 1 if last day of the calendar month | `0` |
| is_quarter_start | BIT | | 1 if first day of calendar quarter | `0` |
| is_quarter_end | BIT | | 1 if last day of calendar quarter | `0` |
| is_fy_start | BIT | | 1 if April 1st (start of Indian FY) | `0` |
| is_fy_end | BIT | | 1 if March 31st (end of Indian FY) | `0` |

---

## 2. gold.dim_customers

**Purpose:** Customer master dimension. One row per unique customer. Enriched with demographic, geographic, and business attributes.

**Source:** silver.crm_customers

| Column Name | Data Type | Key | Description | Example |
|---|---|---|---|---|
| customer_key | INT | PK | Surrogate key — auto-generated integer, unique per row | `1` |
| customer_id | VARCHAR(50) | NK | Natural key from source CRM system | `CRM-CUST-000001` |
| full_name | NVARCHAR(200) | | Full name = first_name + last_name | `Amit Sen` |
| first_name | NVARCHAR(100) | | Customer's first name (proper case) | `Amit` |
| last_name | NVARCHAR(100) | | Customer's last name (proper case) | `Sen` |
| gender | NVARCHAR(20) | | Standardized gender value | `Male` |
| dob | DATE | | Date of birth in YYYY-MM-DD format | `1962-10-19` |
| age | Computed | | Age in years, auto-calculated from dob | `62` |
| email | NVARCHAR(255) | | Validated email address (lowercase) | `amit96@gmail.com` |
| phone | CHAR(10) | | 10-digit Indian mobile number (no prefix) | `8642621108` |
| city | NVARCHAR(150) | | City of residence (proper case) | `Indore` |
| state | NVARCHAR(150) | | State of residence | `Madhya Pradesh` |
| pincode | CHAR(6) | | 6-digit Indian PIN code | `452001` |
| country | NVARCHAR(100) | | Standardized country name | `India` |
| company | NVARCHAR(255) | | Company or organization name | `Singhania Pharma Works` |
| industry | NVARCHAR(150) | | Industry sector of the customer | `Pharma` |
| customer_segment | NVARCHAR(100) | | Business segment tier | `Silver` |
| lead_source | NVARCHAR(150) | | Channel through which customer was acquired | `Email Campaign` |
| assigned_to | NVARCHAR(150) | | Name of the sales rep managing this customer | `Gurpreet Agarwal` |
| gst_number | VARCHAR(15) | | 15-character GSTIN (uppercase, validated) | `23BFHCG1263L1ZM` |
| pan_number | VARCHAR(10) | | 10-character PAN number (uppercase) | `ABCDE1234F` |
| payment_terms | NVARCHAR(100) | | Agreed payment terms | `Net 30` |
| credit_limit | DECIMAL(18,2) | | Maximum credit extended to customer (INR) | `500000.00` |
| lifetime_value | DECIMAL(18,2) | | Total historical revenue from this customer | `125000.00` |
| is_active | BIT | | 1 = active customer, 0 = inactive | `1` |
| dwh_created_date | DATETIME | | Timestamp when row was inserted into Gold | `2025-01-15 10:30:00` |
| dwh_modified_date | DATETIME | | Timestamp of last update | `2025-01-15 10:30:00` |
| dwh_source_table | NVARCHAR(100) | | Source Silver table name | `silver.crm_customers` |

---

## 3. gold.dim_products

**Purpose:** Product master dimension. One row per unique product code. Contains pricing, category, and quality information.

**Source:** silver.erp_inventory

| Column Name | Data Type | Key | Description | Example |
|---|---|---|---|---|
| product_key | INT | PK | Surrogate key — auto-generated integer | `1` |
| product_code | VARCHAR(50) | NK | Natural key — product identifier from ERP | `PRD001` |
| product_name | NVARCHAR(500) | | Full product name (proper case) | `Laptop Hp 15` |
| category | NVARCHAR(150) | | Product category grouping | `Electronics` |
| unit_cost | DECIMAL(18,2) | | Purchase/manufacturing cost per unit (INR) | `45000.00` |
| mrp | DECIMAL(18,2) | | Maximum Retail Price per unit (INR) | `52000.00` |
| margin_pct | Computed | | Profit margin % = (mrp - unit_cost) / unit_cost × 100 | `15.56` |
| reorder_level | DECIMAL(18,3) | | Minimum stock quantity before reorder is triggered | `50.000` |
| quality_status | NVARCHAR(100) | | Current quality state of product | `Approved` |
| dwh_created_date | DATETIME | | Row insert timestamp | `2025-01-15 10:30:00` |
| dwh_modified_date | DATETIME | | Last update timestamp | `2025-01-15 10:30:00` |
| dwh_source_table | NVARCHAR(100) | | Source Silver table | `silver.erp_inventory` |

---

## 4. gold.dim_employees

**Purpose:** Employee master dimension. One row per employee. Contains HR, organizational, and banking information.

**Source:** silver.erp_employees

| Column Name | Data Type | Key | Description | Example |
|---|---|---|---|---|
| employee_key | INT | PK | Surrogate key — auto-generated integer | `1` |
| employee_id | VARCHAR(50) | NK | Natural key — employee identifier from ERP | `EMP-00001` |
| full_name | NVARCHAR(200) | | Full name = first_name + last_name | `Neha Krishnan` |
| first_name | NVARCHAR(100) | | Employee's first name (proper case) | `Neha` |
| last_name | NVARCHAR(100) | | Employee's last name (proper case) | `Krishnan` |
| gender | NVARCHAR(20) | | Standardized gender value | `Female` |
| dob | DATE | | Date of birth | `1975-08-11` |
| age | Computed | | Current age in years (auto-calculated) | `49` |
| department | NVARCHAR(150) | | Department the employee belongs to | `Sales` |
| designation | NVARCHAR(150) | | Job title or role of the employee | `Trainee` |
| grade | NVARCHAR(50) | | Pay grade or band | `G3` |
| employment_status | NVARCHAR(100) | | Current employment state | `Active` |
| employment_type | NVARCHAR(100) | | Nature of employment contract | `Full Time` |
| joining_date | DATE | | Date when employee joined the organization | `2005-06-05` |
| exit_date | DATE | | Date of exit (NULL if still employed) | `NULL` |
| tenure_days | Computed | | Days from joining to exit (or today if active) | `7152` |
| salary | DECIMAL(18,2) | | Monthly gross salary (INR) | `259782.00` |
| city | NVARCHAR(150) | | City of posting | `Surat` |
| state | NVARCHAR(150) | | State of posting | `Gujarat` |
| branch_location | NVARCHAR(150) | | Office branch name | `Head Office` |
| manager_id | VARCHAR(50) | FK | employee_id of the reporting manager | `EMP-00001` |
| dwh_created_date | DATETIME | | Row insert timestamp | `2025-01-15 10:30:00` |
| dwh_modified_date | DATETIME | | Last update timestamp | `2025-01-15 10:30:00` |
| dwh_source_table | NVARCHAR(100) | | Source Silver table | `silver.erp_employees` |

---

## 5. gold.dim_vendors

**Purpose:** Vendor master dimension. One row per vendor. Pre-aggregated with spend and delivery performance metrics.

**Source:** silver.erp_purchase_orders

| Column Name | Data Type | Key | Description | Example |
|---|---|---|---|---|
| vendor_key | INT | PK | Surrogate key — auto-generated integer | `1` |
| vendor_id | VARCHAR(50) | NK | Natural key — vendor identifier from ERP | `VND058` |
| vendor_name | NVARCHAR(255) | | Vendor company name (proper case) | `Eaton India` |
| vendor_gstin | VARCHAR(15) | | 15-character GSTIN of vendor (uppercase) | `23BFHCG1263L1ZM` |
| vendor_city | NVARCHAR(150) | | City where vendor is located | `Mumbai` |
| total_orders | INT | | Total number of purchase orders placed with vendor | `12` |
| total_spend | DECIMAL(18,2) | | Total amount spent with vendor (INR) | `4500000.00` |
| avg_delivery_delay | DECIMAL(10,2) | | Average delivery delay in days (negative = early) | `3.50` |
| dwh_created_date | DATETIME | | Row insert timestamp | `2025-01-15 10:30:00` |
| dwh_modified_date | DATETIME | | Last update timestamp | `2025-01-15 10:30:00` |
| dwh_source_table | NVARCHAR(100) | | Source Silver table | `silver.erp_purchase_orders` |

---

## 6. gold.fact_sales

**Purpose:** Sales transaction fact table. One row per invoice line item. Contains all revenue, tax, and payment measures for analytical reporting.

**Source:** silver.erp_sales_invoices

| Column Name | Data Type | Key | Description | Example |
|---|---|---|---|---|
| sale_key | INT | PK | Surrogate key — auto-generated | `1` |
| date_key | INT | FK | Links to dim_date (invoice date) | `20240315` |
| customer_key | INT | FK | Links to dim_customers | `42` |
| product_key | INT | FK | Links to dim_products | `7` |
| employee_key | INT | FK | Links to dim_employees (sales person) | `3` |
| invoice_number | VARCHAR(100) | DD | Degenerate dim — original invoice number | `INV/2024/MH/0000001` |
| financial_year | VARCHAR(20) | | Indian financial year of the invoice | `FY2023-24` |
| payment_mode | NVARCHAR(100) | | How payment was made | `NEFT` |
| channel | NVARCHAR(100) | | Sales channel used | `Online` |
| region | NVARCHAR(100) | | Geographic sales region | `West` |
| branch | NVARCHAR(150) | | Branch that processed the sale | `HO` |
| invoice_status | NVARCHAR(100) | | Current status of the invoice | `Paid` |
| quantity | DECIMAL(18,3) | | Number of units sold | `147.000` |
| unit_price | DECIMAL(18,2) | | Price per unit (INR) | `12160.34` |
| discount_amount | DECIMAL(18,2) | | Total discount given (INR) | `273501.63` |
| taxable_value | DECIMAL(18,2) | | Taxable amount after discount (INR) | `1514067.85` |
| gst_rate | DECIMAL(5,2) | | GST percentage applied | `12.00` |
| cgst_amount | DECIMAL(18,2) | | Central GST component (INR) | `90844.07` |
| sgst_amount | DECIMAL(18,2) | | State GST component (INR) | `90844.07` |
| igst_amount | DECIMAL(18,2) | | Integrated GST for interstate sales (INR) | `0.00` |
| total_gst | Computed | | Sum of CGST + SGST + IGST (auto-calculated) | `181688.14` |
| invoice_total | DECIMAL(18,2) | | Total invoice value including GST (INR) | `1695755.99` |
| amount_paid | DECIMAL(18,2) | | Amount already received from customer (INR) | `1695755.99` |
| balance_due | DECIMAL(18,2) | | Outstanding amount yet to be collected (INR) | `0.00` |
| tds_amount | DECIMAL(18,2) | | Tax Deducted at Source amount (INR) | `0.00` |
| tds_applicable | BIT | | 1 = TDS applicable on this invoice | `0` |
| invoice_date | DATE | | Date invoice was raised | `2024-03-15` |
| due_date | DATE | | Payment due date | `2024-04-14` |
| payment_date | DATE | | Actual date payment was received | `2024-04-10` |
| days_to_pay | Computed | | Days taken to pay = payment_date - invoice_date | `26` |
| days_overdue | Computed | | Days past due date (0 if paid or not overdue) | `0` |
| dwh_created_date | DATETIME | | Row insert timestamp | `2025-01-15 10:30:00` |
| dwh_source_table | NVARCHAR(100) | | Source Silver table | `silver.erp_sales_invoices` |
| dwh_batch_id | NVARCHAR(50) | | ETL batch run ID for traceability | `a3f2b1c0-...` |

---

## 7. gold.fact_purchases

**Purpose:** Purchase order fact table. One row per PO line. Contains procurement spend, tax, and delivery performance measures.

**Source:** silver.erp_purchase_orders

| Column Name | Data Type | Key | Description | Example |
|---|---|---|---|---|
| purchase_key | INT | PK | Surrogate key — auto-generated | `1` |
| date_key | INT | FK | Links to dim_date (PO date) | `20220315` |
| product_key | INT | FK | Links to dim_products | `19` |
| vendor_key | INT | FK | Links to dim_vendors | `5` |
| po_number | VARCHAR(100) | DD | Degenerate dim — original PO number | `PO/2022/HYD/000001` |
| purchase_type | NVARCHAR(100) | | Type of purchase | `Regular` |
| department | NVARCHAR(150) | | Department that raised the PO | `Procurement` |
| cost_center | VARCHAR(50) | | Cost center code for accounting | `CC-736` |
| warehouse_location | NVARCHAR(150) | | Delivery warehouse location | `Meerut` |
| po_status | NVARCHAR(100) | | Current status of the purchase order | `Fully Received` |
| currency | VARCHAR(10) | | Currency of the transaction | `INR` |
| payment_terms | NVARCHAR(100) | | Payment terms agreed with vendor | `Net 60` |
| quantity | DECIMAL(18,3) | | Quantity ordered | `811.000` |
| unit_price | DECIMAL(18,2) | | Price per unit (INR) | `1806.93` |
| discount_pct | DECIMAL(5,2) | | Discount percentage applied | `0.00` |
| taxable_amount | DECIMAL(18,2) | | Amount before tax (INR) | `1465422.68` |
| gst_rate_pct | DECIMAL(5,2) | | GST rate applied | `0.00` |
| cgst | DECIMAL(18,2) | | CGST amount (INR) | `0.00` |
| sgst | DECIMAL(18,2) | | SGST amount (INR) | `0.00` |
| igst | DECIMAL(18,2) | | IGST amount (INR) | `0.00` |
| total_gst | Computed | | Total GST = CGST + SGST + IGST | `0.00` |
| total_amount | DECIMAL(18,2) | | Total PO value including GST (INR) | `1670131.50` |
| po_date | DATE | | Date PO was raised | `2022-03-15` |
| expected_delivery | DATE | | Contracted delivery date | `2022-04-14` |
| actual_delivery | DATE | | Actual date goods were received | `2022-04-18` |
| delivery_delay_days | Computed | | Days late = actual - expected (negative = early) | `4` |
| is_delayed | Computed | | 1 if actual delivery was after expected date | `1` |
| dwh_created_date | DATETIME | | Row insert timestamp | `2025-01-15 10:30:00` |
| dwh_source_table | NVARCHAR(100) | | Source Silver table | `silver.erp_purchase_orders` |
| dwh_batch_id | NVARCHAR(50) | | ETL batch run ID | `a3f2b1c0-...` |

---

## 8. gold.fact_support

**Purpose:** Support ticket fact table. One row per customer support ticket. Contains resolution time, SLA compliance, and satisfaction measures.

**Source:** silver.support_tickets

| Column Name | Data Type | Key | Description | Example |
|---|---|---|---|---|
| support_key | INT | PK | Surrogate key — auto-generated | `1` |
| date_key | INT | FK | Links to dim_date (ticket opened date) | `20220422` |
| customer_key | INT | FK | Links to dim_customers | `15` |
| employee_key | INT | FK | Links to dim_employees (assigned agent) | `8` |
| ticket_id | VARCHAR(50) | DD | Degenerate dim — original ticket number | `TKT-0000001` |
| ticket_type | NVARCHAR(150) | | Category of the support request | `Delivery Delay` |
| subject | NVARCHAR(500) | | Short description of the issue | `Payment failed` |
| priority | NVARCHAR(50) | | Standardized priority level | `High` |
| ticket_status | NVARCHAR(100) | | Current status of the ticket | `Resolved` |
| team | NVARCHAR(150) | | Team that handled the ticket | `L2 Support` |
| channel | NVARCHAR(100) | | Channel through which ticket was raised | `Chat` |
| resolution_notes | NVARCHAR(MAX) | | Final resolution summary | `Replacement sent` |
| rating | TINYINT | | Customer satisfaction score (1–5) | `4` |
| first_response_hrs | DECIMAL(10,2) | | Hours taken for first response | `2.50` |
| resolution_hrs | DECIMAL(10,2) | | Total hours taken to resolve the ticket | `48.00` |
| resolution_days | Computed | | Days between opened and resolved date | `2` |
| sla_breached | BIT | | 1 = SLA was breached, 0 = within SLA | `0` |
| opened_date | DATE | | Date ticket was created | `2022-04-22` |
| resolved_date | DATE | | Date ticket was closed | `2022-04-24` |
| is_resolved | Computed | | 1 if resolved_date is not NULL | `1` |
| dwh_created_date | DATETIME | | Row insert timestamp | `2025-01-15 10:30:00` |
| dwh_source_table | NVARCHAR(100) | | Source Silver table | `silver.support_tickets` |
| dwh_batch_id | NVARCHAR(50) | | ETL batch run ID | `a3f2b1c0-...` |

---

## 9. gold.fact_leads

**Purpose:** Lead funnel fact table. One row per CRM lead. Contains pipeline value, conversion status, and probability measures.

**Source:** silver.crm_leads

| Column Name | Data Type | Key | Description | Example |
|---|---|---|---|---|
| lead_key | INT | PK | Surrogate key — auto-generated | `1` |
| date_key | INT | FK | Links to dim_date (lead creation date) | `20210425` |
| customer_key | INT | FK | Links to dim_customers (if lead was converted) | `42` |
| employee_key | INT | FK | Links to dim_employees (assigned sales rep) | `6` |
| lead_id | VARCHAR(50) | DD | Degenerate dim — original lead identifier | `LEAD-000001` |
| lead_source | NVARCHAR(150) | | Channel through which lead was acquired | `Event` |
| lead_status | NVARCHAR(100) | | Current stage of the lead | `Qualified` |
| stage | NVARCHAR(100) | | Sales pipeline stage | `Proposal` |
| product_interest | NVARCHAR(255) | | Product or service the lead is interested in | `EPABX System 32Line` |
| city | NVARCHAR(150) | | City of the lead | `Unknown` |
| state | NVARCHAR(150) | | State of the lead | `Tamil Nadu` |
| country | NVARCHAR(100) | | Country of the lead | `India` |
| campaign_id | VARCHAR(50) | | Marketing campaign that generated the lead | `CAMP-0375` |
| expected_value | DECIMAL(18,2) | | Estimated deal value (INR) | `2500143.00` |
| probability_pct | INT | | Probability of conversion (0–100) | `50` |
| weighted_value | Computed | | expected_value × probability / 100 | `1250071.50` |
| converted | BIT | | 1 = lead converted to customer, 0 = not yet | `0` |
| converted_customer_id | VARCHAR(50) | | customer_id if converted (FK to dim_customers) | `NULL` |
| lead_date | DATE | | Date lead was created | `2021-04-25` |
| follow_up_date | DATE | | Scheduled follow-up date | `NULL` |
| days_in_pipeline | Computed | | Days from lead_date to follow_up (or today) | `1438` |
| dwh_created_date | DATETIME | | Row insert timestamp | `2025-01-15 10:30:00` |
| dwh_source_table | NVARCHAR(100) | | Source Silver table | `silver.crm_leads` |
| dwh_batch_id | NVARCHAR(50) | | ETL batch run ID | `a3f2b1c0-...` |

---

## Key Concepts

| Term | Meaning |
|---|---|
| PK | Primary Key — uniquely identifies each row |
| FK | Foreign Key — links to another dimension table |
| NK | Natural Key — original ID from source system |
| DD | Degenerate Dimension — stored in fact, no separate dim table |
| Computed | Auto-calculated column, not stored separately |
| Surrogate Key | Warehouse-generated integer (not from source) |
| BIT | Boolean — 1 = Yes/True, 0 = No/False |
| DECIMAL(18,2) | Monetary value with 2 decimal places |

---

*Generated by DataWarehouse Project — 2025*
