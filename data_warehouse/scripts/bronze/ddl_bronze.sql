/*
===============================================================================
DDL Script: Create Bronze Layer Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables
    if they already exist.
    Run this script to re-define the DDL structure of 'bronze' Tables.

WARNING:
    Running this script will drop and recreate all bronze tables.
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
-- CRM TABLES
-- ============================================================

-- ------------------------------------------------------------
-- Table: bronze.crm_customers
-- Source: E:\data_warehouse\data\crm\crm_customers.csv
-- ------------------------------------------------------------
IF OBJECT_ID('bronze.crm_customers', 'U') IS NOT NULL
    DROP TABLE bronze.crm_customers;
GO

CREATE TABLE bronze.crm_customers (
    customer_id             VARCHAR(50),
    first_name              NVARCHAR(100),
    last_name               NVARCHAR(100),
    gender                  NVARCHAR(50),
    dob                     VARCHAR(50),
    email                   NVARCHAR(255),
    phone                   VARCHAR(50),
    alternate_phone         VARCHAR(50),
    city                    NVARCHAR(150),
    state                   NVARCHAR(150),
    pincode                 VARCHAR(20),
    country                 NVARCHAR(150),
    address_line1           NVARCHAR(500),
    company                 NVARCHAR(255),
    industry                NVARCHAR(150),
    annual_revenue          NVARCHAR(50),
    employee_count          VARCHAR(50),
    lead_source             NVARCHAR(150),
    lead_status             NVARCHAR(100),
    assigned_to             NVARCHAR(150),
    created_date            VARCHAR(50),
    last_contact_date       VARCHAR(50),
    next_followup           VARCHAR(50),
    gst_number              VARCHAR(50),
    pan_number              VARCHAR(50),
    credit_limit            NVARCHAR(50),
    payment_terms           NVARCHAR(100),
    customer_segment        NVARCHAR(100),
    lifetime_value          NVARCHAR(50),
    notes                   NVARCHAR(MAX),
    is_active               VARCHAR(20)
);
GO

-- ------------------------------------------------------------
-- Table: bronze.crm_leads
-- Source: E:\data_warehouse\data\crm\crm_leads.csv
-- ------------------------------------------------------------
IF OBJECT_ID('bronze.crm_leads', 'U') IS NOT NULL
    DROP TABLE bronze.crm_leads;
GO

CREATE TABLE bronze.crm_leads (
    lead_id                 VARCHAR(50),
    lead_date               VARCHAR(50),
    first_name              NVARCHAR(100),
    last_name               NVARCHAR(100),
    email                   NVARCHAR(255),
    phone                   VARCHAR(50),
    company                 NVARCHAR(255),
    city                    NVARCHAR(150),
    state                   NVARCHAR(150),
    country                 NVARCHAR(150),
    lead_source             NVARCHAR(150),
    status                  NVARCHAR(100),
    stage                   NVARCHAR(100),
    product_interest        NVARCHAR(255),
    expected_value          NVARCHAR(50),
    probability_pct         NVARCHAR(50),
    assigned_to             NVARCHAR(150),
    follow_up_date          VARCHAR(50),
    last_activity           NVARCHAR(MAX),
    converted               VARCHAR(20),
    converted_customer_id   VARCHAR(50),
    campaign_id             VARCHAR(50),
    notes                   NVARCHAR(MAX)
);
GO

-- ------------------------------------------------------------
-- Table: bronze.support_tickets
-- Source: E:\data_warehouse\data\crm\crm_support_tickets.json
-- ------------------------------------------------------------
IF OBJECT_ID('bronze.support_tickets', 'U') IS NOT NULL
    DROP TABLE bronze.support_tickets;
GO

CREATE TABLE bronze.support_tickets (
    ticket_id               VARCHAR(50),
    customer_id             VARCHAR(50),
    customer_name           NVARCHAR(255),
    ticket_type             NVARCHAR(150),
    subject                 NVARCHAR(500),
    priority                NVARCHAR(50),
    status                  NVARCHAR(100),
    opened_date             VARCHAR(50),
    resolved_date           VARCHAR(50),
    sla_breached            VARCHAR(20),
    assigned_agent          NVARCHAR(150),
    team                    NVARCHAR(150),
    channel                 NVARCHAR(100),
    resolution_notes        NVARCHAR(MAX),
    rating                  NVARCHAR(50),
    first_response_hrs      NVARCHAR(50),
    resolution_hrs          NVARCHAR(50)
);
GO

-- ============================================================
-- ERP TABLES
-- ============================================================

-- ------------------------------------------------------------
-- Table: bronze.erp_employees
-- Source: E:\data_warehouse\data\erp\erp_employees.csv
-- ------------------------------------------------------------
IF OBJECT_ID('bronze.erp_employees', 'U') IS NOT NULL
    DROP TABLE bronze.erp_employees;
GO

CREATE TABLE bronze.erp_employees (
    employee_id             VARCHAR(50),
    first_name              NVARCHAR(100),
    last_name               NVARCHAR(100),
    gender                  NVARCHAR(50),
    dob                     VARCHAR(50),
    personal_email          NVARCHAR(255),
    official_email          NVARCHAR(255),
    phone                   VARCHAR(50),
    city                    NVARCHAR(150),
    state                   NVARCHAR(150),
    address                 NVARCHAR(500),
    department              NVARCHAR(150),
    designation             NVARCHAR(150),
    joining_date            VARCHAR(50),
    exit_date               VARCHAR(50),
    employment_status       NVARCHAR(100),
    employment_type         NVARCHAR(100),
    salary                  NVARCHAR(50),
    grade                   NVARCHAR(50),
    pan_number              VARCHAR(50),
    uan_number              VARCHAR(50),
    bank_account            VARCHAR(50),
    ifsc_code               VARCHAR(20),
    bank_name               NVARCHAR(150),
    manager_id              VARCHAR(50),
    branch_location         NVARCHAR(150),
    cost_center             VARCHAR(50),
    remarks                 NVARCHAR(MAX)
);
GO

-- ------------------------------------------------------------
-- Table: bronze.erp_purchase_orders
-- Source: E:\data_warehouse\data\erp\erp_purchase_orders.csv
-- ------------------------------------------------------------
IF OBJECT_ID('bronze.erp_purchase_orders', 'U') IS NOT NULL
    DROP TABLE bronze.erp_purchase_orders;
GO

CREATE TABLE bronze.erp_purchase_orders (
    po_number               VARCHAR(100),
    po_date                 VARCHAR(50),
    vendor_id               VARCHAR(50),
    vendor_name             NVARCHAR(255),
    vendor_gstin            VARCHAR(50),
    vendor_city             NVARCHAR(150),
    product_code            VARCHAR(50),
    product_description     NVARCHAR(500),
    category                NVARCHAR(150),
    quantity                NVARCHAR(50),
    unit                    NVARCHAR(50),
    unit_price              NVARCHAR(50),
    discount_pct            NVARCHAR(50),
    taxable_amount          NVARCHAR(50),
    gst_rate_pct            NVARCHAR(50),
    cgst                    NVARCHAR(50),
    sgst                    NVARCHAR(50),
    igst                    NVARCHAR(50),
    total_amount            NVARCHAR(50),
    currency                VARCHAR(20),
    payment_terms           NVARCHAR(100),
    expected_delivery       VARCHAR(50),
    actual_delivery         VARCHAR(50),
    status                  NVARCHAR(100),
    approved_by             NVARCHAR(150),
    department              NVARCHAR(150),
    cost_center             VARCHAR(50),
    warehouse_location      NVARCHAR(150),
    purchase_type           NVARCHAR(100),
    contract_ref            NVARCHAR(100),
    remarks                 NVARCHAR(MAX)
);
GO

-- ------------------------------------------------------------
-- Table: bronze.erp_sales_invoices
-- Source: E:\data_warehouse\data\erp\erp_sales_invoices.csv
-- ------------------------------------------------------------
IF OBJECT_ID('bronze.erp_sales_invoices', 'U') IS NOT NULL
    DROP TABLE bronze.erp_sales_invoices;
GO

CREATE TABLE bronze.erp_sales_invoices (
    invoice_number          VARCHAR(100),
    invoice_date            VARCHAR(50),
    due_date                VARCHAR(50),
    financial_year          VARCHAR(20),
    customer_id             VARCHAR(50),
    customer_name           NVARCHAR(255),
    billing_city            NVARCHAR(150),
    billing_state           NVARCHAR(150),
    billing_pincode         VARCHAR(20),
    customer_gstin          VARCHAR(50),
    product_code            VARCHAR(50),
    product_name            NVARCHAR(500),
    hsn_code                VARCHAR(50),
    quantity                NVARCHAR(50),
    unit_price              NVARCHAR(50),
    discount_amount         NVARCHAR(50),
    taxable_value           NVARCHAR(50),
    gst_rate                NVARCHAR(50),
    cgst_amount             NVARCHAR(50),
    sgst_amount             NVARCHAR(50),
    igst_amount             NVARCHAR(50),
    invoice_total           NVARCHAR(50),
    amount_paid             NVARCHAR(50),
    balance_due             NVARCHAR(50),
    payment_date            VARCHAR(50),
    payment_mode            NVARCHAR(100),
    utr_number              VARCHAR(100),
    status                  NVARCHAR(100),
    sales_person            NVARCHAR(150),
    branch                  NVARCHAR(150),
    region                  NVARCHAR(100),
    channel                 NVARCHAR(100),
    tds_applicable          VARCHAR(20),
    tds_amount              NVARCHAR(50),
    remarks                 NVARCHAR(MAX)
);
GO

-- ------------------------------------------------------------
-- Table: bronze.erp_inventory
-- Source: E:\data_warehouse\data\erp\erp_inventory.json
-- ------------------------------------------------------------
IF OBJECT_ID('bronze.erp_inventory', 'U') IS NOT NULL
    DROP TABLE bronze.erp_inventory;
GO

CREATE TABLE bronze.erp_inventory (
    inventory_id            VARCHAR(50),
    product_code            VARCHAR(50),
    product_name            NVARCHAR(500),
    category                NVARCHAR(150),
    warehouse_city          NVARCHAR(150),
    warehouse_code          VARCHAR(50),
    rack_location           VARCHAR(50),
    quantity_on_hand        NVARCHAR(50),
    quantity_reserved       NVARCHAR(50),
    quantity_in_transit     NVARCHAR(50),
    reorder_level           NVARCHAR(50),
    reorder_quantity        NVARCHAR(50),
    unit_cost               NVARCHAR(50),
    mrp                     NVARCHAR(50),
    last_updated            VARCHAR(50),
    last_purchase_date      VARCHAR(50),
    manufacture_date        VARCHAR(50),
    expiry_date             VARCHAR(50),
    supplier_lead_days      NVARCHAR(50),
    batch_number            VARCHAR(50),
    serial_number           NVARCHAR(100),
    quality_status          NVARCHAR(100)
);
GO