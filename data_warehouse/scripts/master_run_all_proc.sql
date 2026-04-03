-- ============================================================
-- master_etl.sql
-- Run all bronze + Silver + Gold procedures in correct order
-- ============================================================

USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE master.run_full_etl
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start DATETIME = GETDATE();

    PRINT '============================================================';
    PRINT 'MASTER ETL STARTED: ' + CONVERT(NVARCHAR, @start, 120);
    PRINT '============================================================';


    -- ── BRONZE LAYER ──────────────────────────────────────
    PRINT ''; PRINT '>>> BRONZE LAYER';
    EXEC bronze.load_bronze_tables;

    -- ── SILVER LAYER ──────────────────────────────────────
    PRINT ''; PRINT '>>> SILVER LAYER';
    EXEC silver.load_crm_customers;
    EXEC silver.load_crm_leads;
    EXEC silver.load_support_tickets;
    EXEC silver.load_erp_employees;
    EXEC silver.load_erp_purchase_orders;
    EXEC silver.load_erp_sales_invoices;
    EXEC silver.load_erp_inventory;

    -- ── GOLD LAYER — Dimensions first ─────────────────────
    PRINT ''; PRINT '>>> GOLD LAYER — Dimensions';
    EXEC gold.load_dim_date;
    EXEC gold.load_dim_customers;
    EXEC gold.load_dim_products;
    EXEC gold.load_dim_employees;
    EXEC gold.load_dim_vendors;

    -- ── GOLD LAYER — Facts after dims ─────────────────────
    PRINT ''; PRINT '>>> GOLD LAYER — Facts';
    EXEC gold.load_fact_sales;
    EXEC gold.load_fact_purchases;
    EXEC gold.load_fact_support;
    EXEC gold.load_fact_leads;

    PRINT '';
    PRINT '============================================================';
    PRINT 'MASTER ETL COMPLETED';
    PRINT 'Total Duration: '
        + CAST(DATEDIFF(SECOND, @start, GETDATE()) AS NVARCHAR) + ' seconds';
    PRINT '============================================================';
END;
GO

-- Run karo:
EXEC master.run_full_etl;