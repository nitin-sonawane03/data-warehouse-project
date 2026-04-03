/*
===============================================================================
DDL Script: Create Silver Layer Tables
===============================================================================
Script Purpose:
    Cleaned, typed, and standardized version of the Bronze layer.
    - Proper data types (VARCHAR → INT, DECIMAL, DATE, BIT)
    - Junk/invalid values handled via ETL transformation
    - Metadata columns added for data lineage tracking
    - Optimized for 1.3 million+ rows

Author      : Data Engineering Team
Created     : 2025
Database    : DataWarehouse
===============================================================================
*/

USE DataWarehouse;
GO

-- ============================================================
-- CRM TABLES
-- ============================================================

-- ------------------------------------------------------------
-- Table: silver.crm_customers
-- Source: bronze.crm_customers
-- ------------------------------------------------------------
IF OBJECT_ID('silver.crm_customers', 'U') IS NOT NULL
    DROP TABLE silver.crm_customers;
GO

CREATE TABLE silver.crm_customers (

    -- Business Columns
    customer_id             VARCHAR(50)         NOT NULL,
    first_name              NVARCHAR(100)       NULL,
    last_name               NVARCHAR(100)       NULL,
    full_name               NVARCHAR(200)       NULL,       -- Derived: first_name + last_name
    gender                  NVARCHAR(20)        NULL,       -- Standardized: Male/Female/Other/Not Specified
    dob                     DATE                NULL,       -- Cleaned from 10+ raw formats
    age                     AS (DATEDIFF(YEAR, dob, GETDATE())),  -- Computed column
    email                   NVARCHAR(255)       NULL,       -- Junk emails replaced with NULL
    phone                   CHAR(10)            NULL,       -- Validated 10-digit number only
    alternate_phone         CHAR(10)            NULL,
    city                    NVARCHAR(150)       NULL,       -- Proper case applied
    state                   NVARCHAR(150)       NULL,
    pincode                 CHAR(6)             NULL,       -- 6-digit validated
    country                 NVARCHAR(100)       NULL,       -- All variants standardized to 'India'
    address_line1           NVARCHAR(500)       NULL,       -- 'Same as above', '-' replaced with NULL
    company                 NVARCHAR(255)       NULL,
    industry                NVARCHAR(150)       NULL,
    annual_revenue          DECIMAL(18,2)       NULL,       -- '5.0 Lakh' converted to 500000.00
    employee_count          INT                 NULL,       -- Cast from VARCHAR
    lead_source             NVARCHAR(150)       NULL,
    lead_status             NVARCHAR(100)       NULL,
    assigned_to             NVARCHAR(150)       NULL,
    created_date            DATE                NULL,
    last_contact_date       DATE                NULL,
    next_followup           DATE                NULL,       -- 'Not Yet', 'TBD' replaced with NULL
    gst_number              VARCHAR(15)         NULL,       -- Uppercase, 15-char validated
    pan_number              VARCHAR(10)         NULL,       -- Uppercase, 10-char validated
    credit_limit            DECIMAL(18,2)       NULL,
    payment_terms           NVARCHAR(100)       NULL,
    customer_segment        NVARCHAR(100)       NULL,
    lifetime_value          DECIMAL(18,2)       NULL,
    notes                   NVARCHAR(MAX)       NULL,
    is_active               BIT                 NULL,       -- Y/Yes/1/Active → 1, N/No/0/Inactive → 0

    -- Metadata Columns
    dwh_created_date        DATETIME            NOT NULL DEFAULT GETDATE(),   -- Row insert timestamp
    dwh_modified_date       DATETIME            NOT NULL DEFAULT GETDATE(),   -- Last update timestamp
    dwh_source_system       NVARCHAR(50)        NOT NULL DEFAULT 'CRM',       -- Source system name
    dwh_source_table        NVARCHAR(100)       NOT NULL DEFAULT 'bronze.crm_customers',
    dwh_batch_id            NVARCHAR(50)        NULL,       -- ETL batch run identifier
    dwh_is_valid            BIT                 NOT NULL DEFAULT 1,           -- 0 = rejected record
    dwh_record_hash         VARBINARY(32)       NULL        -- SHA2_256 hash for change detection
);
GO
PRINT 'silver.crm_customers created successfully'
PRINT '============================================================'


-- ------------------------------------------------------------
-- Table: silver.crm_leads
-- Source: bronze.crm_leads
-- ------------------------------------------------------------
IF OBJECT_ID('silver.crm_leads', 'U') IS NOT NULL
    DROP TABLE silver.crm_leads;
GO

CREATE TABLE silver.crm_leads (

    -- Business Columns
    lead_id                 VARCHAR(50)         NOT NULL,
    lead_date               DATE                NULL,
    first_name              NVARCHAR(100)       NULL,
    last_name               NVARCHAR(100)       NULL,
    full_name               NVARCHAR(200)       NULL,       -- Derived: first_name + last_name
    email                   NVARCHAR(255)       NULL,       -- Junk emails replaced with NULL
    phone                   CHAR(10)            NULL,       -- Validated 10-digit number only
    company                 NVARCHAR(255)       NULL,
    city                    NVARCHAR(150)       NULL,
    state                   NVARCHAR(150)       NULL,
    country                 NVARCHAR(100)       NULL,       -- Standardized to 'India'
    lead_source             NVARCHAR(150)       NULL,
    status                  NVARCHAR(100)       NULL,
    stage                   NVARCHAR(100)       NULL,
    product_interest        NVARCHAR(255)       NULL,
    expected_value          DECIMAL(18,2)       NULL,       -- Cast from VARCHAR
    probability_pct         DECIMAL(5,2)        NULL,       -- 0.00 to 100.00
    assigned_to             NVARCHAR(150)       NULL,
    follow_up_date          DATE                NULL,
    last_activity           NVARCHAR(MAX)       NULL,
    converted               BIT                 NULL,       -- Y/N → 1/0
    converted_customer_id   VARCHAR(50)         NULL,       -- FK to crm_customers
    campaign_id             VARCHAR(50)         NULL,
    notes                   NVARCHAR(MAX)       NULL,

    -- Metadata Columns
    dwh_created_date        DATETIME            NOT NULL DEFAULT GETDATE(),
    dwh_modified_date       DATETIME            NOT NULL DEFAULT GETDATE(),
    dwh_source_system       NVARCHAR(50)        NOT NULL DEFAULT 'CRM',
    dwh_source_table        NVARCHAR(100)       NOT NULL DEFAULT 'bronze.crm_leads',
    dwh_batch_id            NVARCHAR(50)        NULL,
    dwh_is_valid            BIT                 NOT NULL DEFAULT 1,
    dwh_record_hash         VARBINARY(32)       NULL
);
GO
PRINT 'silver.crm_leads created successfully'
PRINT '============================================================'


-- ------------------------------------------------------------
-- Table: silver.support_tickets
-- Source: bronze.support_tickets
-- ------------------------------------------------------------
IF OBJECT_ID('silver.support_tickets', 'U') IS NOT NULL
    DROP TABLE silver.support_tickets;
GO

CREATE TABLE silver.support_tickets (

    -- Business Columns
    ticket_id               VARCHAR(50)         NOT NULL,
    customer_id             VARCHAR(50)         NULL,       -- FK to crm_customers
    customer_name           NVARCHAR(255)       NULL,
    ticket_type             NVARCHAR(150)       NULL,
    subject                 NVARCHAR(500)       NULL,
    priority                NVARCHAR(50)        NULL,       -- Low/Medium/High/Critical
    status                  NVARCHAR(100)       NULL,
    opened_date             DATE                NULL,
    resolved_date           DATE                NULL,
    resolution_days         AS (DATEDIFF(DAY, opened_date, resolved_date)),  -- Computed column
    sla_breached            BIT                 NULL,       -- Y/N → 1/0
    assigned_agent          NVARCHAR(150)       NULL,
    team                    NVARCHAR(150)       NULL,
    channel                 NVARCHAR(100)       NULL,
    resolution_notes        NVARCHAR(MAX)       NULL,
    rating                  TINYINT             NULL,       -- 1 to 5 validated
    first_response_hrs      DECIMAL(10,2)       NULL,       -- Cast from VARCHAR
    resolution_hrs          DECIMAL(10,2)       NULL,

    -- Metadata Columns
    dwh_created_date        DATETIME            NOT NULL DEFAULT GETDATE(),
    dwh_modified_date       DATETIME            NOT NULL DEFAULT GETDATE(),
    dwh_source_system       NVARCHAR(50)        NOT NULL DEFAULT 'CRM',
    dwh_source_table        NVARCHAR(100)       NOT NULL DEFAULT 'bronze.support_tickets',
    dwh_batch_id            NVARCHAR(50)        NULL,
    dwh_is_valid            BIT                 NOT NULL DEFAULT 1,
    dwh_record_hash         VARBINARY(32)       NULL
);
GO
PRINT 'silver.support_tickets created successfully'
PRINT '============================================================'


-- ============================================================
-- ERP TABLES
-- ============================================================

-- ------------------------------------------------------------
-- Table: silver.erp_employees
-- Source: bronze.erp_employees
-- ------------------------------------------------------------
IF OBJECT_ID('silver.erp_employees', 'U') IS NOT NULL
    DROP TABLE silver.erp_employees;
GO

CREATE TABLE silver.erp_employees (

    -- Business Columns
    employee_id             VARCHAR(50)         NOT NULL,
    first_name              NVARCHAR(100)       NULL,
    last_name               NVARCHAR(100)       NULL,
    full_name               NVARCHAR(200)       NULL,       -- Derived: first_name + last_name
    gender                  NVARCHAR(20)        NULL,       -- Standardized: Male/Female/Other
    dob                     DATE                NULL,
    age                     AS (DATEDIFF(YEAR, dob, GETDATE())),  -- Computed column
    personal_email          NVARCHAR(255)       NULL,
    official_email          NVARCHAR(255)       NULL,
    phone                   CHAR(10)            NULL,       -- Validated 10-digit number only
    city                    NVARCHAR(150)       NULL,
    state                   NVARCHAR(150)       NULL,
    address                 NVARCHAR(500)       NULL,
    department              NVARCHAR(150)       NULL,
    designation             NVARCHAR(150)       NULL,
    joining_date            DATE                NULL,
    exit_date               DATE                NULL,       -- NULL = currently employed
    tenure_days             AS (DATEDIFF(DAY, joining_date, ISNULL(exit_date, GETDATE()))),  -- Computed
    employment_status       NVARCHAR(100)       NULL,       -- Active/Resigned/Terminated
    employment_type         NVARCHAR(100)       NULL,       -- Full-time/Part-time/Contract
    salary                  DECIMAL(18,2)       NULL,       -- Cast from VARCHAR
    grade                   NVARCHAR(50)        NULL,
    pan_number              VARCHAR(10)         NULL,       -- Uppercase, 10-char validated
    uan_number              VARCHAR(12)         NULL,       -- 12-digit validated
    bank_account            VARCHAR(20)         NULL,
    ifsc_code               VARCHAR(11)         NULL,       -- 11-char standard format
    bank_name               NVARCHAR(150)       NULL,
    manager_id              VARCHAR(50)         NULL,       -- FK to erp_employees (self-ref)
    branch_location         NVARCHAR(150)       NULL,
    cost_center             VARCHAR(50)         NULL,
    remarks                 NVARCHAR(MAX)       NULL,

    -- Metadata Columns
    dwh_created_date        DATETIME            NOT NULL DEFAULT GETDATE(),
    dwh_modified_date       DATETIME            NOT NULL DEFAULT GETDATE(),
    dwh_source_system       NVARCHAR(50)        NOT NULL DEFAULT 'ERP',
    dwh_source_table        NVARCHAR(100)       NOT NULL DEFAULT 'bronze.erp_employees',
    dwh_batch_id            NVARCHAR(50)        NULL,
    dwh_is_valid            BIT                 NOT NULL DEFAULT 1,
    dwh_record_hash         VARBINARY(32)       NULL
);
GO
PRINT 'silver.erp_employees created successfully'
PRINT '============================================================'


-- ------------------------------------------------------------
-- Table: silver.erp_purchase_orders
-- Source: bronze.erp_purchase_orders
-- ------------------------------------------------------------
IF OBJECT_ID('silver.erp_purchase_orders', 'U') IS NOT NULL
    DROP TABLE silver.erp_purchase_orders;
GO

CREATE TABLE silver.erp_purchase_orders (

    -- Business Columns
    po_number               VARCHAR(100)        NOT NULL,
    po_date                 DATE                NULL,
    vendor_id               VARCHAR(50)         NULL,
    vendor_name             NVARCHAR(255)       NULL,
    vendor_gstin            VARCHAR(15)         NULL,       -- Uppercase, 15-char validated
    vendor_city             NVARCHAR(150)       NULL,
    product_code            VARCHAR(50)         NULL,
    product_description     NVARCHAR(500)       NULL,
    category                NVARCHAR(150)       NULL,
    quantity                DECIMAL(18,3)       NULL,       -- 3 decimal places for units
    unit                    NVARCHAR(50)        NULL,
    unit_price              DECIMAL(18,2)       NULL,
    discount_pct            DECIMAL(5,2)        NULL,       -- 0.00 to 100.00
    taxable_amount          DECIMAL(18,2)       NULL,
    gst_rate_pct            DECIMAL(5,2)        NULL,
    cgst                    DECIMAL(18,2)       NULL,
    sgst                    DECIMAL(18,2)       NULL,
    igst                    DECIMAL(18,2)       NULL,
    total_amount            DECIMAL(18,2)       NULL,
    currency                VARCHAR(10)         NULL DEFAULT 'INR',
    payment_terms           NVARCHAR(100)       NULL,
    expected_delivery       DATE                NULL,
    actual_delivery         DATE                NULL,
    delivery_delay_days     AS (DATEDIFF(DAY, expected_delivery, actual_delivery)),  -- Computed
    status                  NVARCHAR(100)       NULL,
    approved_by             NVARCHAR(150)       NULL,
    department              NVARCHAR(150)       NULL,
    cost_center             VARCHAR(50)         NULL,
    warehouse_location      NVARCHAR(150)       NULL,
    purchase_type           NVARCHAR(100)       NULL,
    contract_ref            NVARCHAR(100)       NULL,
    remarks                 NVARCHAR(MAX)       NULL,

    -- Metadata Columns
    dwh_created_date        DATETIME            NOT NULL DEFAULT GETDATE(),
    dwh_modified_date       DATETIME            NOT NULL DEFAULT GETDATE(),
    dwh_source_system       NVARCHAR(50)        NOT NULL DEFAULT 'ERP',
    dwh_source_table        NVARCHAR(100)       NOT NULL DEFAULT 'bronze.erp_purchase_orders',
    dwh_batch_id            NVARCHAR(50)        NULL,
    dwh_is_valid            BIT                 NOT NULL DEFAULT 1,
    dwh_record_hash         VARBINARY(32)       NULL
);
GO
PRINT 'silver.erp_purchase_orders created successfully'
PRINT '============================================================'


-- ------------------------------------------------------------
-- Table: silver.erp_sales_invoices
-- Source: bronze.erp_sales_invoices
-- ------------------------------------------------------------
IF OBJECT_ID('silver.erp_sales_invoices', 'U') IS NOT NULL
    DROP TABLE silver.erp_sales_invoices;
GO

CREATE TABLE silver.erp_sales_invoices (

    -- Business Columns
    invoice_number          VARCHAR(100)        NOT NULL,
    invoice_date            DATE                NULL,
    due_date                DATE                NULL,
    days_overdue            AS (CASE WHEN status != 'Paid'
                                THEN DATEDIFF(DAY, due_date, GETDATE())
                                ELSE 0 END),               -- Computed column
    financial_year          VARCHAR(20)         NULL,       -- e.g. 2024-25
    customer_id             VARCHAR(50)         NULL,       -- FK to crm_customers
    customer_name           NVARCHAR(255)       NULL,
    billing_city            NVARCHAR(150)       NULL,
    billing_state           NVARCHAR(150)       NULL,
    billing_pincode         CHAR(6)             NULL,
    customer_gstin          VARCHAR(15)         NULL,       -- Uppercase, 15-char validated
    product_code            VARCHAR(50)         NULL,
    product_name            NVARCHAR(500)       NULL,
    hsn_code                VARCHAR(50)         NULL,
    quantity                DECIMAL(18,3)       NULL,
    unit_price              DECIMAL(18,2)       NULL,
    discount_amount         DECIMAL(18,2)       NULL,
    taxable_value           DECIMAL(18,2)       NULL,
    gst_rate                DECIMAL(5,2)        NULL,
    cgst_amount             DECIMAL(18,2)       NULL,
    sgst_amount             DECIMAL(18,2)       NULL,
    igst_amount             DECIMAL(18,2)       NULL,
    invoice_total           DECIMAL(18,2)       NULL,
    amount_paid             DECIMAL(18,2)       NULL,
    balance_due             DECIMAL(18,2)       NULL,
    payment_date            DATE                NULL,
    payment_mode            NVARCHAR(100)       NULL,
    utr_number              VARCHAR(100)        NULL,
    status                  NVARCHAR(100)       NULL,       -- Paid/Unpaid/Partial/Overdue
    sales_person            NVARCHAR(150)       NULL,
    branch                  NVARCHAR(150)       NULL,
    region                  NVARCHAR(100)       NULL,
    channel                 NVARCHAR(100)       NULL,
    tds_applicable          BIT                 NULL,       -- Y/N → 1/0
    tds_amount              DECIMAL(18,2)       NULL,
    remarks                 NVARCHAR(MAX)       NULL,

    -- Metadata Columns
    dwh_created_date        DATETIME            NOT NULL DEFAULT GETDATE(),
    dwh_modified_date       DATETIME            NOT NULL DEFAULT GETDATE(),
    dwh_source_system       NVARCHAR(50)        NOT NULL DEFAULT 'ERP',
    dwh_source_table        NVARCHAR(100)       NOT NULL DEFAULT 'bronze.erp_sales_invoices',
    dwh_batch_id            NVARCHAR(50)        NULL,
    dwh_is_valid            BIT                 NOT NULL DEFAULT 1,
    dwh_record_hash         VARBINARY(32)       NULL
);
GO
PRINT 'silver.erp_sales_invoices created successfully'
PRINT '============================================================'


-- ------------------------------------------------------------
-- Table: silver.erp_inventory
-- Source: bronze.erp_inventory
-- ------------------------------------------------------------
IF OBJECT_ID('silver.erp_inventory', 'U') IS NOT NULL
    DROP TABLE silver.erp_inventory;
GO

CREATE TABLE silver.erp_inventory (

    -- Business Columns
    inventory_id            VARCHAR(50)         NOT NULL,
    product_code            VARCHAR(50)         NULL,
    product_name            NVARCHAR(500)       NULL,
    category                NVARCHAR(150)       NULL,
    warehouse_city          NVARCHAR(150)       NULL,
    warehouse_code          VARCHAR(50)         NULL,
    rack_location           VARCHAR(50)         NULL,
    quantity_on_hand        DECIMAL(18,3)       NULL,
    quantity_reserved       DECIMAL(18,3)       NULL,
    quantity_in_transit     DECIMAL(18,3)       NULL,
    quantity_available      AS (ISNULL(quantity_on_hand,0)
                               - ISNULL(quantity_reserved,0)),  -- Computed: available stock
    reorder_level           DECIMAL(18,3)       NULL,
    reorder_quantity        DECIMAL(18,3)       NULL,
    is_below_reorder        AS (CASE WHEN quantity_on_hand < reorder_level
                                THEN 1 ELSE 0 END),             -- Computed: reorder alert flag
    unit_cost               DECIMAL(18,2)       NULL,
    mrp                     DECIMAL(18,2)       NULL,
    stock_value             AS (ISNULL(quantity_on_hand,0)
                               * ISNULL(unit_cost,0)),          -- Computed: total stock value
    last_updated            DATE                NULL,
    last_purchase_date      DATE                NULL,
    manufacture_date        DATE                NULL,
    expiry_date             DATE                NULL,
    days_to_expiry          AS (DATEDIFF(DAY, GETDATE(), expiry_date)),  -- Computed
    supplier_lead_days      INT                 NULL,
    batch_number            VARCHAR(50)         NULL,
    serial_number           NVARCHAR(100)       NULL,
    quality_status          NVARCHAR(100)       NULL,           -- Approved/Rejected/Quarantine

    -- Metadata Columns
    dwh_created_date        DATETIME            NOT NULL DEFAULT GETDATE(),
    dwh_modified_date       DATETIME            NOT NULL DEFAULT GETDATE(),
    dwh_source_system       NVARCHAR(50)        NOT NULL DEFAULT 'ERP',
    dwh_source_table        NVARCHAR(100)       NOT NULL DEFAULT 'bronze.erp_inventory',
    dwh_batch_id            NVARCHAR(50)        NULL,
    dwh_is_valid            BIT                 NOT NULL DEFAULT 1,
    dwh_record_hash         VARBINARY(32)       NULL
);
GO
PRINT 'silver.erp_inventory created successfully'
PRINT '============================================================'
PRINT 'All Silver Layer tables created successfully'
PRINT '============================================================'