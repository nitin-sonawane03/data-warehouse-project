/*
===============================================================================
DDL Script: Create Gold Layer Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'gold' schema, dropping existing tables
    if they already exist.
    Run this script to re-define the DDL structure of 'gold' Tables.

WARNING:
    Running this script will drop and recreate all gold tables.
    All existing data in these tables will be permanently lost.
    Ensure you have proper backups before executing.

Usage:
    Run this script manually in SQL Server Management Studio (SSMS)
    against the 'DataWarehouse' database.
===============================================================================
*/

USE DataWarehouse;
GO

-- ============================================================
-- DIMENSION TABLES
-- ============================================================

-- ------------------------------------------------------------
-- Table: gold.dim_date
-- Source: Generated (no source table)
-- ------------------------------------------------------------
IF OBJECT_ID('gold.dim_date', 'U') IS NOT NULL
    DROP TABLE gold.dim_date;
GO

CREATE TABLE gold.dim_date (
    date_key            INT             NOT NULL,
    full_date           DATE            NOT NULL,
    day_of_week         TINYINT         NOT NULL,
    day_name            NVARCHAR(10)    NOT NULL,
    day_of_month        TINYINT         NOT NULL,
    day_of_year         SMALLINT        NOT NULL,
    week_of_year        TINYINT         NOT NULL,
    month_number        TINYINT         NOT NULL,
    month_name          NVARCHAR(10)    NOT NULL,
    month_short         NCHAR(3)        NOT NULL,
    quarter_number      TINYINT         NOT NULL,
    quarter_name        NCHAR(2)        NOT NULL,
    year_number         SMALLINT        NOT NULL,
    financial_year      NVARCHAR(10)    NOT NULL,
    financial_quarter   NCHAR(2)        NOT NULL,
    financial_month     TINYINT         NOT NULL,
    is_weekend          BIT             NOT NULL DEFAULT 0,
    is_month_start      BIT             NOT NULL DEFAULT 0,
    is_month_end        BIT             NOT NULL DEFAULT 0,
    is_quarter_start    BIT             NOT NULL DEFAULT 0,
    is_quarter_end      BIT             NOT NULL DEFAULT 0,
    is_fy_start         BIT             NOT NULL DEFAULT 0,
    is_fy_end           BIT             NOT NULL DEFAULT 0,

    CONSTRAINT PK_dim_date PRIMARY KEY (date_key)
);
GO
PRINT 'gold.dim_date created successfully'
PRINT '============================================================'


-- ------------------------------------------------------------
-- Table: gold.dim_customers
-- Source: silver.crm_customers
-- ------------------------------------------------------------
IF OBJECT_ID('gold.dim_customers', 'U') IS NOT NULL
    DROP TABLE gold.dim_customers;
GO

CREATE TABLE gold.dim_customers (
    customer_key        INT             NOT NULL IDENTITY(1,1),
    customer_id         VARCHAR(50)     NOT NULL,
    full_name           NVARCHAR(200)   NULL,
    first_name          NVARCHAR(100)   NULL,
    last_name           NVARCHAR(100)   NULL,
    gender              NVARCHAR(20)    NULL,
    dob                 DATE            NULL,
    age                 AS (DATEDIFF(YEAR, dob, GETDATE())),
    email               NVARCHAR(255)   NULL,
    phone               CHAR(10)        NULL,
    city                NVARCHAR(150)   NULL,
    state               NVARCHAR(150)   NULL,
    pincode             CHAR(6)         NULL,
    country             NVARCHAR(100)   NULL,
    company             NVARCHAR(255)   NULL,
    industry            NVARCHAR(150)   NULL,
    customer_segment    NVARCHAR(100)   NULL,
    lead_source         NVARCHAR(150)   NULL,
    assigned_to         NVARCHAR(150)   NULL,
    gst_number          VARCHAR(15)     NULL,
    pan_number          VARCHAR(10)     NULL,
    payment_terms       NVARCHAR(100)   NULL,
    credit_limit        DECIMAL(18,2)   NULL,
    lifetime_value      DECIMAL(18,2)   NULL,
    is_active           BIT             NULL,
    dwh_created_date    DATETIME        NOT NULL DEFAULT GETDATE(),
    dwh_modified_date   DATETIME        NOT NULL DEFAULT GETDATE(),
    dwh_source_table    NVARCHAR(100)   NOT NULL DEFAULT 'silver.crm_customers',

    CONSTRAINT PK_dim_customers PRIMARY KEY (customer_key)
);
GO
PRINT 'gold.dim_customers created successfully'
PRINT '============================================================'


-- ------------------------------------------------------------
-- Table: gold.dim_products
-- Source: silver.erp_inventory
-- ------------------------------------------------------------
IF OBJECT_ID('gold.dim_products', 'U') IS NOT NULL
    DROP TABLE gold.dim_products;
GO

CREATE TABLE gold.dim_products (
    product_key         INT             NOT NULL IDENTITY(1,1),
    product_code        VARCHAR(50)     NOT NULL,
    product_name        NVARCHAR(500)   NULL,
    category            NVARCHAR(150)   NULL,
    unit_cost           DECIMAL(18,2)   NULL,
    mrp                 DECIMAL(18,2)   NULL,
    margin_pct          AS (
                            CASE WHEN unit_cost > 0
                            THEN CAST((mrp - unit_cost) * 100.0 / unit_cost AS DECIMAL(5,2))
                            ELSE NULL END
                        ),
    reorder_level       DECIMAL(18,3)   NULL,
    quality_status      NVARCHAR(100)   NULL,
    dwh_created_date    DATETIME        NOT NULL DEFAULT GETDATE(),
    dwh_modified_date   DATETIME        NOT NULL DEFAULT GETDATE(),
    dwh_source_table    NVARCHAR(100)   NOT NULL DEFAULT 'silver.erp_inventory',

    CONSTRAINT PK_dim_products PRIMARY KEY (product_key)
);
GO
PRINT 'gold.dim_products created successfully'
PRINT '============================================================'


-- ------------------------------------------------------------
-- Table: gold.dim_employees
-- Source: silver.erp_employees
-- ------------------------------------------------------------
IF OBJECT_ID('gold.dim_employees', 'U') IS NOT NULL
    DROP TABLE gold.dim_employees;
GO

CREATE TABLE gold.dim_employees (
    employee_key        INT             NOT NULL IDENTITY(1,1),
    employee_id         VARCHAR(50)     NOT NULL,
    full_name           NVARCHAR(200)   NULL,
    first_name          NVARCHAR(100)   NULL,
    last_name           NVARCHAR(100)   NULL,
    gender              NVARCHAR(20)    NULL,
    dob                 DATE            NULL,
    age                 AS (DATEDIFF(YEAR, dob, GETDATE())),
    department          NVARCHAR(150)   NULL,
    designation         NVARCHAR(150)   NULL,
    grade               NVARCHAR(50)    NULL,
    employment_status   NVARCHAR(100)   NULL,
    employment_type     NVARCHAR(100)   NULL,
    joining_date        DATE            NULL,
    exit_date           DATE            NULL,
    tenure_days         AS (DATEDIFF(DAY, joining_date, ISNULL(exit_date, GETDATE()))),
    salary              DECIMAL(18,2)   NULL,
    city                NVARCHAR(150)   NULL,
    state               NVARCHAR(150)   NULL,
    branch_location     NVARCHAR(150)   NULL,
    manager_id          VARCHAR(50)     NULL,
    dwh_created_date    DATETIME        NOT NULL DEFAULT GETDATE(),
    dwh_modified_date   DATETIME        NOT NULL DEFAULT GETDATE(),
    dwh_source_table    NVARCHAR(100)   NOT NULL DEFAULT 'silver.erp_employees',

    CONSTRAINT PK_dim_employees PRIMARY KEY (employee_key)
);
GO
PRINT 'gold.dim_employees created successfully'
PRINT '============================================================'


-- ------------------------------------------------------------
-- Table: gold.dim_vendors
-- Source: silver.erp_purchase_orders
-- ------------------------------------------------------------
IF OBJECT_ID('gold.dim_vendors', 'U') IS NOT NULL
    DROP TABLE gold.dim_vendors;
GO

CREATE TABLE gold.dim_vendors (
    vendor_key          INT             NOT NULL IDENTITY(1,1),
    vendor_id           VARCHAR(50)     NOT NULL,
    vendor_name         NVARCHAR(255)   NULL,
    vendor_gstin        VARCHAR(15)     NULL,
    vendor_city         NVARCHAR(150)   NULL,
    total_orders        INT             NULL,
    total_spend         DECIMAL(18,2)   NULL,
    avg_delivery_delay  DECIMAL(10,2)   NULL,
    dwh_created_date    DATETIME        NOT NULL DEFAULT GETDATE(),
    dwh_modified_date   DATETIME        NOT NULL DEFAULT GETDATE(),
    dwh_source_table    NVARCHAR(100)   NOT NULL DEFAULT 'silver.erp_purchase_orders',

    CONSTRAINT PK_dim_vendors PRIMARY KEY (vendor_key)
);
GO
PRINT 'gold.dim_vendors created successfully'
PRINT '============================================================'


-- ============================================================
-- FACT TABLES
-- ============================================================

-- ------------------------------------------------------------
-- Table: gold.fact_sales
-- Source: silver.erp_sales_invoices
-- ------------------------------------------------------------
IF OBJECT_ID('gold.fact_sales', 'U') IS NOT NULL
    DROP TABLE gold.fact_sales;
GO

CREATE TABLE gold.fact_sales (
    sale_key            INT             NOT NULL IDENTITY(1,1),
    -- Foreign Keys
    date_key            INT             NULL,
    customer_key        INT             NULL,
    product_key         INT             NULL,
    employee_key        INT             NULL,
    -- Degenerate Dimensions
    invoice_number      VARCHAR(100)    NOT NULL,
    financial_year      VARCHAR(20)     NULL,
    payment_mode        NVARCHAR(100)   NULL,
    channel             NVARCHAR(100)   NULL,
    region              NVARCHAR(100)   NULL,
    branch              NVARCHAR(150)   NULL,
    invoice_status      NVARCHAR(100)   NULL,
    -- Measures
    quantity            DECIMAL(18,3)   NULL,
    unit_price          DECIMAL(18,2)   NULL,
    discount_amount     DECIMAL(18,2)   NULL,
    taxable_value       DECIMAL(18,2)   NULL,
    gst_rate            DECIMAL(5,2)    NULL,
    cgst_amount         DECIMAL(18,2)   NULL,
    sgst_amount         DECIMAL(18,2)   NULL,
    igst_amount         DECIMAL(18,2)   NULL,
    total_gst           AS (
                            ISNULL(cgst_amount, 0)
                          + ISNULL(sgst_amount, 0)
                          + ISNULL(igst_amount, 0)
                        ),
    invoice_total       DECIMAL(18,2)   NULL,
    amount_paid         DECIMAL(18,2)   NULL,
    balance_due         DECIMAL(18,2)   NULL,
    tds_amount          DECIMAL(18,2)   NULL,
    tds_applicable      BIT             NULL,
    -- Dates
    invoice_date        DATE            NULL,
    due_date            DATE            NULL,
    payment_date        DATE            NULL,
    days_to_pay         AS (DATEDIFF(DAY, invoice_date, payment_date)),
    days_overdue        AS (
                            CASE
                                WHEN invoice_status NOT IN ('Paid', 'Cancelled')
                                 AND due_date < GETDATE()
                                THEN DATEDIFF(DAY, due_date, GETDATE())
                                ELSE 0
                            END
                        ),
    -- Metadata
    dwh_created_date    DATETIME        NOT NULL DEFAULT GETDATE(),
    dwh_source_table    NVARCHAR(100)   NOT NULL DEFAULT 'silver.erp_sales_invoices',
    dwh_batch_id        NVARCHAR(50)    NULL,

    CONSTRAINT PK_fact_sales PRIMARY KEY (sale_key)
);
GO
PRINT 'gold.fact_sales created successfully'
PRINT '============================================================'


-- ------------------------------------------------------------
-- Table: gold.fact_purchases
-- Source: silver.erp_purchase_orders
-- ------------------------------------------------------------
IF OBJECT_ID('gold.fact_purchases', 'U') IS NOT NULL
    DROP TABLE gold.fact_purchases;
GO

CREATE TABLE gold.fact_purchases (
    purchase_key        INT             NOT NULL IDENTITY(1,1),
    -- Foreign Keys
    date_key            INT             NULL,
    product_key         INT             NULL,
    vendor_key          INT             NULL,
    -- Degenerate Dimensions
    po_number           VARCHAR(100)    NOT NULL,
    purchase_type       NVARCHAR(100)   NULL,
    department          NVARCHAR(150)   NULL,
    cost_center         VARCHAR(50)     NULL,
    warehouse_location  NVARCHAR(150)   NULL,
    po_status           NVARCHAR(100)   NULL,
    currency            VARCHAR(10)     NULL,
    payment_terms       NVARCHAR(100)   NULL,
    -- Measures
    quantity            DECIMAL(18,3)   NULL,
    unit_price          DECIMAL(18,2)   NULL,
    discount_pct        DECIMAL(5,2)    NULL,
    taxable_amount      DECIMAL(18,2)   NULL,
    gst_rate_pct        DECIMAL(5,2)    NULL,
    cgst                DECIMAL(18,2)   NULL,
    sgst                DECIMAL(18,2)   NULL,
    igst                DECIMAL(18,2)   NULL,
    total_gst           AS (ISNULL(cgst, 0) + ISNULL(sgst, 0) + ISNULL(igst, 0)),
    total_amount        DECIMAL(18,2)   NULL,
    -- Dates
    po_date             DATE            NULL,
    expected_delivery   DATE            NULL,
    actual_delivery     DATE            NULL,
    delivery_delay_days AS (DATEDIFF(DAY, expected_delivery, actual_delivery)),
    is_delayed          AS (
                            CASE WHEN actual_delivery > expected_delivery
                                 THEN 1 ELSE 0 END
                        ),
    -- Metadata
    dwh_created_date    DATETIME        NOT NULL DEFAULT GETDATE(),
    dwh_source_table    NVARCHAR(100)   NOT NULL DEFAULT 'silver.erp_purchase_orders',
    dwh_batch_id        NVARCHAR(50)    NULL,

    CONSTRAINT PK_fact_purchases PRIMARY KEY (purchase_key)
);
GO
PRINT 'gold.fact_purchases created successfully'
PRINT '============================================================'


-- ------------------------------------------------------------
-- Table: gold.fact_support
-- Source: silver.support_tickets
-- ------------------------------------------------------------
IF OBJECT_ID('gold.fact_support', 'U') IS NOT NULL
    DROP TABLE gold.fact_support;
GO

CREATE TABLE gold.fact_support (
    support_key         INT             NOT NULL IDENTITY(1,1),
    -- Foreign Keys
    date_key            INT             NULL,
    customer_key        INT             NULL,
    employee_key        INT             NULL,
    -- Degenerate Dimensions
    ticket_id           VARCHAR(50)     NOT NULL,
    ticket_type         NVARCHAR(150)   NULL,
    subject             NVARCHAR(500)   NULL,
    priority            NVARCHAR(50)    NULL,
    ticket_status       NVARCHAR(100)   NULL,
    team                NVARCHAR(150)   NULL,
    channel             NVARCHAR(100)   NULL,
    resolution_notes    NVARCHAR(MAX)   NULL,
    -- Measures
    rating              TINYINT         NULL,
    first_response_hrs  DECIMAL(10,2)   NULL,
    resolution_hrs      DECIMAL(10,2)   NULL,
    resolution_days     AS (DATEDIFF(DAY, opened_date, resolved_date)),
    sla_breached        BIT             NULL,
    -- Dates
    opened_date         DATE            NULL,
    resolved_date       DATE            NULL,
    is_resolved         AS (CASE WHEN resolved_date IS NOT NULL THEN 1 ELSE 0 END),
    -- Metadata
    dwh_created_date    DATETIME        NOT NULL DEFAULT GETDATE(),
    dwh_source_table    NVARCHAR(100)   NOT NULL DEFAULT 'silver.support_tickets',
    dwh_batch_id        NVARCHAR(50)    NULL,

    CONSTRAINT PK_fact_support PRIMARY KEY (support_key)
);
GO
PRINT 'gold.fact_support created successfully'
PRINT '============================================================'


-- ------------------------------------------------------------
-- Table: gold.fact_leads
-- Source: silver.crm_leads
-- ------------------------------------------------------------
IF OBJECT_ID('gold.fact_leads', 'U') IS NOT NULL
    DROP TABLE gold.fact_leads;
GO

CREATE TABLE gold.fact_leads (
    lead_key            INT             NOT NULL IDENTITY(1,1),
    -- Foreign Keys
    date_key            INT             NULL,
    customer_key        INT             NULL,
    employee_key        INT             NULL,
    -- Degenerate Dimensions
    lead_id             VARCHAR(50)     NOT NULL,
    lead_source         NVARCHAR(150)   NULL,
    lead_status         NVARCHAR(100)   NULL,
    stage               NVARCHAR(100)   NULL,
    product_interest    NVARCHAR(255)   NULL,
    city                NVARCHAR(150)   NULL,
    state               NVARCHAR(150)   NULL,
    country             NVARCHAR(100)   NULL,
    campaign_id         VARCHAR(50)     NULL,
    -- Measures
    expected_value      DECIMAL(18,2)   NULL,
    probability_pct     INT             NULL,
    weighted_value      AS (
                            CASE
                                WHEN probability_pct IS NOT NULL
                                 AND expected_value  IS NOT NULL
                                THEN expected_value * probability_pct / 100.0
                                ELSE NULL
                            END
                        ),
    converted           BIT             NULL,
    converted_customer_id VARCHAR(50)   NULL,
    -- Dates
    lead_date           DATE            NULL,
    follow_up_date      DATE            NULL,
    days_in_pipeline    AS (DATEDIFF(DAY, lead_date, ISNULL(follow_up_date, GETDATE()))),
    -- Metadata
    dwh_created_date    DATETIME        NOT NULL DEFAULT GETDATE(),
    dwh_source_table    NVARCHAR(100)   NOT NULL DEFAULT 'silver.crm_leads',
    dwh_batch_id        NVARCHAR(50)    NULL,

    CONSTRAINT PK_fact_leads PRIMARY KEY (lead_key)
);
GO
PRINT 'gold.fact_leads created successfully'
PRINT '============================================================'
PRINT 'All Gold Layer tables created successfully'
PRINT '============================================================'