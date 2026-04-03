/*
===============================================================================
Script: Bronze Layer - Data Quality Checks
===============================================================================
Script Purpose:
    This script performs data quality checks on all tables in the 'bronze'
    schema. The following checks are performed:
      - NULL or Empty Values Check
      - Duplicate Records Check
      - Unwanted Spaces Check
      - Data Standardization & Consistency Check
      - Date Format Validity Check

Usage:
    Run this script manually in SQL Server Management Studio (SSMS)
    against the 'DataWarehouse' database after loading the bronze layer.

Usage Example:
    Run after: EXEC bronze.load_bronze_tables;
===============================================================================
*/

USE DataWarehouse;
GO

-- ============================================================
PRINT '================================================';
PRINT 'Bronze Layer - Data Quality Checks';
PRINT '================================================';
-- ============================================================

-- ============================================================
PRINT '------------------------------------------------';
PRINT 'Checking CRM Tables';
PRINT '------------------------------------------------';
-- ============================================================

-- ------------------------------------------------------------
PRINT '>> Checking: bronze.crm_customers';
-- ------------------------------------------------------------

-- NULL or Empty Values Check
PRINT '>> [NULL CHECK] bronze.crm_customers';
SELECT
    'crm_customers'                                                     AS table_name,
    SUM(CASE WHEN customer_id      IS NULL OR customer_id      = '' THEN 1 ELSE 0 END) AS customer_id_nulls,
    SUM(CASE WHEN first_name       IS NULL OR first_name       = '' THEN 1 ELSE 0 END) AS first_name_nulls,
    SUM(CASE WHEN last_name        IS NULL OR last_name        = '' THEN 1 ELSE 0 END) AS last_name_nulls,
    SUM(CASE WHEN email            IS NULL OR email            = '' THEN 1 ELSE 0 END) AS email_nulls,
    SUM(CASE WHEN phone            IS NULL OR phone            = '' THEN 1 ELSE 0 END) AS phone_nulls,
    SUM(CASE WHEN city             IS NULL OR city             = '' THEN 1 ELSE 0 END) AS city_nulls,
    SUM(CASE WHEN country          IS NULL OR country          = '' THEN 1 ELSE 0 END) AS country_nulls,
    SUM(CASE WHEN lead_status      IS NULL OR lead_status      = '' THEN 1 ELSE 0 END) AS lead_status_nulls,
    SUM(CASE WHEN is_active        IS NULL OR is_active        = '' THEN 1 ELSE 0 END) AS is_active_nulls
FROM bronze.crm_customers;

-- Duplicate Records Check
PRINT '>> [DUPLICATE CHECK] bronze.crm_customers';
SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM bronze.crm_customers
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Unwanted Spaces Check
PRINT '>> [SPACES CHECK] bronze.crm_customers';
SELECT COUNT(*) AS records_with_spaces
FROM bronze.crm_customers
WHERE customer_id  != TRIM(customer_id)
   OR first_name   != TRIM(first_name)
   OR last_name    != TRIM(last_name)
   OR email        != TRIM(email);

-- Data Standardization Check
PRINT '>> [STANDARDIZATION CHECK] bronze.crm_customers - gender';
SELECT DISTINCT gender, COUNT(*) AS count
FROM bronze.crm_customers
GROUP BY gender
ORDER BY count DESC;

PRINT '>> [STANDARDIZATION CHECK] bronze.crm_customers - is_active';
SELECT DISTINCT is_active, COUNT(*) AS count
FROM bronze.crm_customers
GROUP BY is_active
ORDER BY count DESC;

PRINT '>> [STANDARDIZATION CHECK] bronze.crm_customers - customer_segment';
SELECT DISTINCT customer_segment, COUNT(*) AS count
FROM bronze.crm_customers
GROUP BY customer_segment
ORDER BY count DESC;

-- Date Validity Check
PRINT '>> [DATE CHECK] bronze.crm_customers';
SELECT COUNT(*) AS invalid_dob
FROM bronze.crm_customers
WHERE TRY_CONVERT(DATE, dob) IS NULL AND dob IS NOT NULL AND dob != '';

SELECT COUNT(*) AS invalid_created_date
FROM bronze.crm_customers
WHERE TRY_CONVERT(DATE, created_date) IS NULL AND created_date IS NOT NULL AND created_date != '';

PRINT '>> -------------';

-- ------------------------------------------------------------
PRINT '>> Checking: bronze.crm_leads';
-- ------------------------------------------------------------

-- NULL or Empty Values Check
PRINT '>> [NULL CHECK] bronze.crm_leads';
SELECT
    'crm_leads'                                                         AS table_name,
    SUM(CASE WHEN lead_id          IS NULL OR lead_id          = '' THEN 1 ELSE 0 END) AS lead_id_nulls,
    SUM(CASE WHEN first_name       IS NULL OR first_name       = '' THEN 1 ELSE 0 END) AS first_name_nulls,
    SUM(CASE WHEN email            IS NULL OR email            = '' THEN 1 ELSE 0 END) AS email_nulls,
    SUM(CASE WHEN status           IS NULL OR status           = '' THEN 1 ELSE 0 END) AS status_nulls,
    SUM(CASE WHEN lead_source      IS NULL OR lead_source      = '' THEN 1 ELSE 0 END) AS lead_source_nulls,
    SUM(CASE WHEN stage            IS NULL OR stage            = '' THEN 1 ELSE 0 END) AS stage_nulls,
    SUM(CASE WHEN converted        IS NULL OR converted        = '' THEN 1 ELSE 0 END) AS converted_nulls
FROM bronze.crm_leads;

-- Duplicate Records Check
PRINT '>> [DUPLICATE CHECK] bronze.crm_leads';
SELECT
    lead_id,
    COUNT(*) AS duplicate_count
FROM bronze.crm_leads
GROUP BY lead_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Unwanted Spaces Check
PRINT '>> [SPACES CHECK] bronze.crm_leads';
SELECT COUNT(*) AS records_with_spaces
FROM bronze.crm_leads
WHERE lead_id    != TRIM(lead_id)
   OR first_name != TRIM(first_name)
   OR email      != TRIM(email);

-- Data Standardization Check
PRINT '>> [STANDARDIZATION CHECK] bronze.crm_leads - status';
SELECT DISTINCT status, COUNT(*) AS count
FROM bronze.crm_leads
GROUP BY status
ORDER BY count DESC;

PRINT '>> [STANDARDIZATION CHECK] bronze.crm_leads - lead_source';
SELECT DISTINCT lead_source, COUNT(*) AS count
FROM bronze.crm_leads
GROUP BY lead_source
ORDER BY count DESC;

PRINT '>> [STANDARDIZATION CHECK] bronze.crm_leads - converted';
SELECT DISTINCT converted, COUNT(*) AS count
FROM bronze.crm_leads
GROUP BY converted
ORDER BY count DESC;

-- Date Validity Check
PRINT '>> [DATE CHECK] bronze.crm_leads';
SELECT COUNT(*) AS invalid_lead_date
FROM bronze.crm_leads
WHERE TRY_CONVERT(DATE, lead_date) IS NULL AND lead_date IS NOT NULL AND lead_date != '';

PRINT '>> -------------';

-- ------------------------------------------------------------
PRINT '>> Checking: bronze.support_tickets';
-- ------------------------------------------------------------

-- NULL or Empty Values Check
PRINT '>> [NULL CHECK] bronze.support_tickets';
SELECT
    'support_tickets'                                                   AS table_name,
    SUM(CASE WHEN ticket_id        IS NULL OR ticket_id        = '' THEN 1 ELSE 0 END) AS ticket_id_nulls,
    SUM(CASE WHEN customer_id      IS NULL OR customer_id      = '' THEN 1 ELSE 0 END) AS customer_id_nulls,
    SUM(CASE WHEN status           IS NULL OR status           = '' THEN 1 ELSE 0 END) AS status_nulls,
    SUM(CASE WHEN priority         IS NULL OR priority         = '' THEN 1 ELSE 0 END) AS priority_nulls,
    SUM(CASE WHEN ticket_type      IS NULL OR ticket_type      = '' THEN 1 ELSE 0 END) AS ticket_type_nulls,
    SUM(CASE WHEN channel          IS NULL OR channel          = '' THEN 1 ELSE 0 END) AS channel_nulls,
    SUM(CASE WHEN resolved_date    IS NULL OR resolved_date    = '' THEN 1 ELSE 0 END) AS resolved_date_nulls
FROM bronze.support_tickets;

-- Duplicate Records Check
PRINT '>> [DUPLICATE CHECK] bronze.support_tickets';
SELECT
    ticket_id,
    COUNT(*) AS duplicate_count
FROM bronze.support_tickets
GROUP BY ticket_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Data Standardization Check
PRINT '>> [STANDARDIZATION CHECK] bronze.support_tickets - status';
SELECT DISTINCT status, COUNT(*) AS count
FROM bronze.support_tickets
GROUP BY status
ORDER BY count DESC;

PRINT '>> [STANDARDIZATION CHECK] bronze.support_tickets - priority';
SELECT DISTINCT priority, COUNT(*) AS count
FROM bronze.support_tickets
GROUP BY priority
ORDER BY count DESC;

PRINT '>> [STANDARDIZATION CHECK] bronze.support_tickets - sla_breached';
SELECT DISTINCT sla_breached, COUNT(*) AS count
FROM bronze.support_tickets
GROUP BY sla_breached
ORDER BY count DESC;

-- Date Validity Check
PRINT '>> [DATE CHECK] bronze.support_tickets';
SELECT COUNT(*) AS invalid_opened_date
FROM bronze.support_tickets
WHERE TRY_CONVERT(DATE, opened_date) IS NULL AND opened_date IS NOT NULL AND opened_date != '';

SELECT COUNT(*) AS invalid_resolved_date
FROM bronze.support_tickets
WHERE TRY_CONVERT(DATE, resolved_date) IS NULL AND resolved_date IS NOT NULL AND resolved_date != '';

PRINT '>> -------------';

-- ============================================================
PRINT '------------------------------------------------';
PRINT 'Checking ERP Tables';
PRINT '------------------------------------------------';
-- ============================================================

-- ------------------------------------------------------------
PRINT '>> Checking: bronze.erp_employees';
-- ------------------------------------------------------------

-- NULL or Empty Values Check
PRINT '>> [NULL CHECK] bronze.erp_employees';
SELECT
    'erp_employees'                                                     AS table_name,
    SUM(CASE WHEN employee_id       IS NULL OR employee_id       = '' THEN 1 ELSE 0 END) AS employee_id_nulls,
    SUM(CASE WHEN first_name        IS NULL OR first_name        = '' THEN 1 ELSE 0 END) AS first_name_nulls,
    SUM(CASE WHEN last_name         IS NULL OR last_name         = '' THEN 1 ELSE 0 END) AS last_name_nulls,
    SUM(CASE WHEN department        IS NULL OR department        = '' THEN 1 ELSE 0 END) AS department_nulls,
    SUM(CASE WHEN designation       IS NULL OR designation       = '' THEN 1 ELSE 0 END) AS designation_nulls,
    SUM(CASE WHEN employment_status IS NULL OR employment_status = '' THEN 1 ELSE 0 END) AS employment_status_nulls,
    SUM(CASE WHEN salary            IS NULL OR salary            = '' THEN 1 ELSE 0 END) AS salary_nulls
FROM bronze.erp_employees;

-- Duplicate Records Check
PRINT '>> [DUPLICATE CHECK] bronze.erp_employees';
SELECT
    employee_id,
    COUNT(*) AS duplicate_count
FROM bronze.erp_employees
GROUP BY employee_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Unwanted Spaces Check
PRINT '>> [SPACES CHECK] bronze.erp_employees';
SELECT COUNT(*) AS records_with_spaces
FROM bronze.erp_employees
WHERE employee_id != TRIM(employee_id)
   OR first_name  != TRIM(first_name)
   OR last_name   != TRIM(last_name);

-- Data Standardization Check
PRINT '>> [STANDARDIZATION CHECK] bronze.erp_employees - gender';
SELECT DISTINCT gender, COUNT(*) AS count
FROM bronze.erp_employees
GROUP BY gender
ORDER BY count DESC;

PRINT '>> [STANDARDIZATION CHECK] bronze.erp_employees - employment_status';
SELECT DISTINCT employment_status, COUNT(*) AS count
FROM bronze.erp_employees
GROUP BY employment_status
ORDER BY count DESC;

PRINT '>> [STANDARDIZATION CHECK] bronze.erp_employees - employment_type';
SELECT DISTINCT employment_type, COUNT(*) AS count
FROM bronze.erp_employees
GROUP BY employment_type
ORDER BY count DESC;

-- Date Validity Check
PRINT '>> [DATE CHECK] bronze.erp_employees';
SELECT COUNT(*) AS invalid_dob
FROM bronze.erp_employees
WHERE TRY_CONVERT(DATE, dob) IS NULL AND dob IS NOT NULL AND dob != '';

SELECT COUNT(*) AS invalid_joining_date
FROM bronze.erp_employees
WHERE TRY_CONVERT(DATE, joining_date) IS NULL AND joining_date IS NOT NULL AND joining_date != '';

PRINT '>> -------------';

-- ------------------------------------------------------------
PRINT '>> Checking: bronze.erp_purchase_orders';
-- ------------------------------------------------------------

-- NULL or Empty Values Check
PRINT '>> [NULL CHECK] bronze.erp_purchase_orders';
SELECT
    'erp_purchase_orders'                                               AS table_name,
    SUM(CASE WHEN po_number    IS NULL OR po_number    = '' THEN 1 ELSE 0 END) AS po_number_nulls,
    SUM(CASE WHEN vendor_id    IS NULL OR vendor_id    = '' THEN 1 ELSE 0 END) AS vendor_id_nulls,
    SUM(CASE WHEN product_code IS NULL OR product_code = '' THEN 1 ELSE 0 END) AS product_code_nulls,
    SUM(CASE WHEN total_amount IS NULL OR total_amount = '' THEN 1 ELSE 0 END) AS total_amount_nulls,
    SUM(CASE WHEN status       IS NULL OR status       = '' THEN 1 ELSE 0 END) AS status_nulls,
    SUM(CASE WHEN currency     IS NULL OR currency     = '' THEN 1 ELSE 0 END) AS currency_nulls
FROM bronze.erp_purchase_orders;

-- Duplicate Records Check
PRINT '>> [DUPLICATE CHECK] bronze.erp_purchase_orders';
SELECT
    po_number,
    product_code,
    COUNT(*) AS duplicate_count
FROM bronze.erp_purchase_orders
GROUP BY po_number, product_code
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Data Standardization Check
PRINT '>> [STANDARDIZATION CHECK] bronze.erp_purchase_orders - status';
SELECT DISTINCT status, COUNT(*) AS count
FROM bronze.erp_purchase_orders
GROUP BY status
ORDER BY count DESC;

PRINT '>> [STANDARDIZATION CHECK] bronze.erp_purchase_orders - currency';
SELECT DISTINCT currency, COUNT(*) AS count
FROM bronze.erp_purchase_orders
GROUP BY currency
ORDER BY count DESC;

-- Date Validity Check
PRINT '>> [DATE CHECK] bronze.erp_purchase_orders';
SELECT COUNT(*) AS invalid_po_date
FROM bronze.erp_purchase_orders
WHERE TRY_CONVERT(DATE, po_date) IS NULL AND po_date IS NOT NULL AND po_date != '';

PRINT '>> -------------';

-- ------------------------------------------------------------
PRINT '>> Checking: bronze.erp_sales_invoices';
-- ------------------------------------------------------------

-- NULL or Empty Values Check
PRINT '>> [NULL CHECK] bronze.erp_sales_invoices';
SELECT
    'erp_sales_invoices'                                                AS table_name,
    SUM(CASE WHEN invoice_number IS NULL OR invoice_number = '' THEN 1 ELSE 0 END) AS invoice_number_nulls,
    SUM(CASE WHEN customer_id    IS NULL OR customer_id    = '' THEN 1 ELSE 0 END) AS customer_id_nulls,
    SUM(CASE WHEN product_code   IS NULL OR product_code   = '' THEN 1 ELSE 0 END) AS product_code_nulls,
    SUM(CASE WHEN invoice_total  IS NULL OR invoice_total  = '' THEN 1 ELSE 0 END) AS invoice_total_nulls,
    SUM(CASE WHEN status         IS NULL OR status         = '' THEN 1 ELSE 0 END) AS status_nulls,
    SUM(CASE WHEN payment_mode   IS NULL OR payment_mode   = '' THEN 1 ELSE 0 END) AS payment_mode_nulls,
    SUM(CASE WHEN balance_due    IS NULL OR balance_due    = '' THEN 1 ELSE 0 END) AS balance_due_nulls
FROM bronze.erp_sales_invoices;

-- Duplicate Records Check
PRINT '>> [DUPLICATE CHECK] bronze.erp_sales_invoices';
SELECT
    invoice_number,
    product_code,
    COUNT(*) AS duplicate_count
FROM bronze.erp_sales_invoices
GROUP BY invoice_number, product_code
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Data Standardization Check
PRINT '>> [STANDARDIZATION CHECK] bronze.erp_sales_invoices - status';
SELECT DISTINCT status, COUNT(*) AS count
FROM bronze.erp_sales_invoices
GROUP BY status
ORDER BY count DESC;

PRINT '>> [STANDARDIZATION CHECK] bronze.erp_sales_invoices - payment_mode';
SELECT DISTINCT payment_mode, COUNT(*) AS count
FROM bronze.erp_sales_invoices
GROUP BY payment_mode
ORDER BY count DESC;

PRINT '>> [STANDARDIZATION CHECK] bronze.erp_sales_invoices - tds_applicable';
SELECT DISTINCT tds_applicable, COUNT(*) AS count
FROM bronze.erp_sales_invoices
GROUP BY tds_applicable
ORDER BY count DESC;

-- Date Validity Check
PRINT '>> [DATE CHECK] bronze.erp_sales_invoices';
SELECT COUNT(*) AS invalid_invoice_date
FROM bronze.erp_sales_invoices
WHERE TRY_CONVERT(DATE, invoice_date) IS NULL AND invoice_date IS NOT NULL AND invoice_date != '';

SELECT COUNT(*) AS invalid_due_date
FROM bronze.erp_sales_invoices
WHERE TRY_CONVERT(DATE, due_date) IS NULL AND due_date IS NOT NULL AND due_date != '';

PRINT '>> -------------';

-- ------------------------------------------------------------
PRINT '>> Checking: bronze.erp_inventory';
-- ------------------------------------------------------------

-- NULL or Empty Values Check
PRINT '>> [NULL CHECK] bronze.erp_inventory';
SELECT
    'erp_inventory'                                                     AS table_name,
    SUM(CASE WHEN inventory_id     IS NULL OR inventory_id     = '' THEN 1 ELSE 0 END) AS inventory_id_nulls,
    SUM(CASE WHEN product_code     IS NULL OR product_code     = '' THEN 1 ELSE 0 END) AS product_code_nulls,
    SUM(CASE WHEN product_name     IS NULL OR product_name     = '' THEN 1 ELSE 0 END) AS product_name_nulls,
    SUM(CASE WHEN category         IS NULL OR category         = '' THEN 1 ELSE 0 END) AS category_nulls,
    SUM(CASE WHEN warehouse_code   IS NULL OR warehouse_code   = '' THEN 1 ELSE 0 END) AS warehouse_code_nulls,
    SUM(CASE WHEN quantity_on_hand IS NULL OR quantity_on_hand = '' THEN 1 ELSE 0 END) AS quantity_on_hand_nulls,
    SUM(CASE WHEN quality_status   IS NULL OR quality_status   = '' THEN 1 ELSE 0 END) AS quality_status_nulls
FROM bronze.erp_inventory;

-- Duplicate Records Check
PRINT '>> [DUPLICATE CHECK] bronze.erp_inventory';
SELECT
    inventory_id,
    COUNT(*) AS duplicate_count
FROM bronze.erp_inventory
GROUP BY inventory_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Data Standardization Check
PRINT '>> [STANDARDIZATION CHECK] bronze.erp_inventory - quality_status';
SELECT DISTINCT quality_status, COUNT(*) AS count
FROM bronze.erp_inventory
GROUP BY quality_status
ORDER BY count DESC;

PRINT '>> [STANDARDIZATION CHECK] bronze.erp_inventory - category';
SELECT DISTINCT category, COUNT(*) AS count
FROM bronze.erp_inventory
GROUP BY category
ORDER BY count DESC;

-- Date Validity Check
PRINT '>> [DATE CHECK] bronze.erp_inventory';
SELECT COUNT(*) AS invalid_last_updated
FROM bronze.erp_inventory
WHERE TRY_CONVERT(DATE, last_updated) IS NULL AND last_updated IS NOT NULL AND last_updated != '';

SELECT COUNT(*) AS invalid_expiry_date
FROM bronze.erp_inventory
WHERE TRY_CONVERT(DATE, expiry_date) IS NULL AND expiry_date IS NOT NULL AND expiry_date != '';

PRINT '>> -------------';

-- ============================================================
PRINT '================================================';
PRINT 'Bronze Layer - Data Quality Checks Completed';
PRINT '================================================';
-- ============================================================