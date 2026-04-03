/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external
    source files (CSV and JSON). It performs the following actions:
      - Truncates the bronze tables before loading fresh data.
      - Uses BULK INSERT to load CSV files into bronze tables.
      - Uses OPENROWSET + OPENJSON to load JSON files into bronze tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Source File Locations:
    CRM  -> E:\data_warehouse\data\crm\
    ERP  -> E:\data_warehouse\data\erp\

Usage Example:
    EXEC bronze.load_bronze_tables;
===============================================================================
*/

USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze_tables AS
BEGIN
    DECLARE @start_time      DATETIME,
            @end_time        DATETIME,
            @batch_start_time DATETIME,
            @batch_end_time  DATETIME,
            @json            NVARCHAR(MAX);

    BEGIN TRY
        SET @batch_start_time = GETDATE();

        PRINT '================================================';
        PRINT 'Loading Bronze Layer';
        PRINT '================================================';

        -- ====================================================
        PRINT '------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '------------------------------------------------';
        -- ====================================================

        -- ----------------------------------------------------
        -- bronze.crm_customers
        -- ----------------------------------------------------
        IF OBJECT_ID('bronze.crm_customers', 'U') IS NOT NULL
        BEGIN
            SET @start_time = GETDATE();
            PRINT '>> Truncating Table: bronze.crm_customers';
            TRUNCATE TABLE bronze.crm_customers;

            PRINT '>> Inserting Data Into: bronze.crm_customers';
            BULK INSERT bronze.crm_customers
            FROM 'E:\data_warehouse\data\crm\crm_customers.csv'
            WITH (
                FIRSTROW        = 2,
                FIELDTERMINATOR = ',',
                ROWTERMINATOR   = '\n',
                FORMAT          = 'CSV',
                CODEPAGE        = '65001',
                TABLOCK
            );
            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
            PRINT '>> -------------';
        END
        ELSE PRINT '>> ERROR: Table bronze.crm_customers does not exist!';

        -- ----------------------------------------------------
        -- bronze.crm_leads
        -- ----------------------------------------------------
        IF OBJECT_ID('bronze.crm_leads', 'U') IS NOT NULL
        BEGIN
            SET @start_time = GETDATE();
            PRINT '>> Truncating Table: bronze.crm_leads';
            TRUNCATE TABLE bronze.crm_leads;

            PRINT '>> Inserting Data Into: bronze.crm_leads';
            BULK INSERT bronze.crm_leads
            FROM 'E:\data_warehouse\data\crm\crm_leads.csv'
            WITH (
                FIRSTROW        = 2,
                FIELDTERMINATOR = ',',
                ROWTERMINATOR   = '\n',
                FORMAT          = 'CSV',
                CODEPAGE        = '65001',
                TABLOCK
            );
            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
            PRINT '>> -------------';
        END
        ELSE PRINT '>> ERROR: Table bronze.crm_leads does not exist!';

        -- ----------------------------------------------------
        -- bronze.support_tickets  [JSON Source]
        -- ----------------------------------------------------
        IF OBJECT_ID('bronze.support_tickets', 'U') IS NOT NULL
        BEGIN
            SET @start_time = GETDATE();
            PRINT '>> Truncating Table: bronze.support_tickets';
            TRUNCATE TABLE bronze.support_tickets;

            PRINT '>> Inserting Data Into: bronze.support_tickets';
            SELECT @json = BulkColumn
            FROM OPENROWSET(
                BULK 'E:\data_warehouse\data\crm\crm_support_tickets.json',
                SINGLE_CLOB
            ) AS j;

            INSERT INTO bronze.support_tickets (
                ticket_id, customer_id, customer_name, ticket_type,
                subject, priority, status, opened_date, resolved_date,
                sla_breached, assigned_agent, team, channel,
                resolution_notes, rating, first_response_hrs, resolution_hrs
            )
            SELECT
                ticket_id, customer_id, customer_name, ticket_type,
                subject, priority, status, opened_date, resolved_date,
                sla_breached, assigned_agent, team, channel,
                resolution_notes, rating, first_response_hrs, resolution_hrs
            FROM OPENJSON(@json)
            WITH (
                ticket_id          VARCHAR(50)    '$.ticket_id',
                customer_id        VARCHAR(50)    '$.customer_id',
                customer_name      NVARCHAR(255)  '$.customer_name',
                ticket_type        NVARCHAR(150)  '$.ticket_type',
                subject            NVARCHAR(500)  '$.subject',
                priority           NVARCHAR(50)   '$.priority',
                status             NVARCHAR(100)  '$.status',
                opened_date        VARCHAR(50)    '$.opened_date',
                resolved_date      VARCHAR(50)    '$.resolved_date',
                sla_breached       VARCHAR(20)    '$.sla_breached',
                assigned_agent     NVARCHAR(150)  '$.assigned_agent',
                team               NVARCHAR(150)  '$.team',
                channel            NVARCHAR(100)  '$.channel',
                resolution_notes   NVARCHAR(MAX)  '$.resolution_notes',
                rating             NVARCHAR(50)   '$.rating',
                first_response_hrs NVARCHAR(50)   '$.first_response_hrs',
                resolution_hrs     NVARCHAR(50)   '$.resolution_hrs'
            );
            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
            PRINT '>> -------------';
        END
        ELSE PRINT '>> ERROR: Table bronze.support_tickets does not exist!';

        -- ====================================================
        PRINT '------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '------------------------------------------------';
        -- ====================================================

        -- ----------------------------------------------------
        -- bronze.erp_employees
        -- ----------------------------------------------------
        IF OBJECT_ID('bronze.erp_employees', 'U') IS NOT NULL
        BEGIN
            SET @start_time = GETDATE();
            PRINT '>> Truncating Table: bronze.erp_employees';
            TRUNCATE TABLE bronze.erp_employees;

            PRINT '>> Inserting Data Into: bronze.erp_employees';
            BULK INSERT bronze.erp_employees
            FROM 'E:\data_warehouse\data\erp\erp_employees.csv'
            WITH (
                FIRSTROW        = 2,
                FIELDTERMINATOR = ',',
                ROWTERMINATOR   = '\n',
                FORMAT          = 'CSV',
                CODEPAGE        = '65001',
                TABLOCK
            );
            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
            PRINT '>> -------------';
        END
        ELSE PRINT '>> ERROR: Table bronze.erp_employees does not exist!';

        -- ----------------------------------------------------
        -- bronze.erp_purchase_orders
        -- ----------------------------------------------------
        IF OBJECT_ID('bronze.erp_purchase_orders', 'U') IS NOT NULL
        BEGIN
            SET @start_time = GETDATE();
            PRINT '>> Truncating Table: bronze.erp_purchase_orders';
            TRUNCATE TABLE bronze.erp_purchase_orders;

            PRINT '>> Inserting Data Into: bronze.erp_purchase_orders';
            BULK INSERT bronze.erp_purchase_orders
            FROM 'E:\data_warehouse\data\erp\erp_purchase_orders.csv'
            WITH (
                FIRSTROW        = 2,
                FIELDTERMINATOR = ',',
                ROWTERMINATOR   = '\n',
                FORMAT          = 'CSV',
                CODEPAGE        = '65001',
                TABLOCK
            );
            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
            PRINT '>> -------------';
        END
        ELSE PRINT '>> ERROR: Table bronze.erp_purchase_orders does not exist!';

        -- ----------------------------------------------------
        -- bronze.erp_sales_invoices
        -- ----------------------------------------------------
        IF OBJECT_ID('bronze.erp_sales_invoices', 'U') IS NOT NULL
        BEGIN
            SET @start_time = GETDATE();
            PRINT '>> Truncating Table: bronze.erp_sales_invoices';
            TRUNCATE TABLE bronze.erp_sales_invoices;

            PRINT '>> Inserting Data Into: bronze.erp_sales_invoices';
            BULK INSERT bronze.erp_sales_invoices
            FROM 'E:\data_warehouse\data\erp\erp_sales_invoices.csv'
            WITH (
                FIRSTROW        = 2,
                FIELDTERMINATOR = ',',
                ROWTERMINATOR   = '\n',
                FORMAT          = 'CSV',
                CODEPAGE        = '65001',
                TABLOCK
            );
            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
            PRINT '>> -------------';
        END
        ELSE PRINT '>> ERROR: Table bronze.erp_sales_invoices does not exist!';

        -- ----------------------------------------------------
        -- bronze.erp_inventory  [JSON Source]
        -- ----------------------------------------------------
        IF OBJECT_ID('bronze.erp_inventory', 'U') IS NOT NULL
        BEGIN
            SET @start_time = GETDATE();
            PRINT '>> Truncating Table: bronze.erp_inventory';
            TRUNCATE TABLE bronze.erp_inventory;

            PRINT '>> Inserting Data Into: bronze.erp_inventory';
            SELECT @json = BulkColumn
            FROM OPENROWSET(
                BULK 'E:\data_warehouse\data\erp\erp_inventory.json',
                SINGLE_CLOB
            ) AS j;

            INSERT INTO bronze.erp_inventory (
                inventory_id, product_code, product_name, category,
                warehouse_city, warehouse_code, rack_location,
                quantity_on_hand, quantity_reserved, quantity_in_transit,
                reorder_level, reorder_quantity, unit_cost, mrp,
                last_updated, last_purchase_date, manufacture_date,
                expiry_date, supplier_lead_days, batch_number,
                serial_number, quality_status
            )
            SELECT
                inventory_id, product_code, product_name, category,
                warehouse_city, warehouse_code, rack_location,
                quantity_on_hand, quantity_reserved, quantity_in_transit,
                reorder_level, reorder_quantity, unit_cost, mrp,
                last_updated, last_purchase_date, manufacture_date,
                expiry_date, supplier_lead_days, batch_number,
                serial_number, quality_status
            FROM OPENJSON(@json)
            WITH (
                inventory_id        VARCHAR(50)   '$.inventory_id',
                product_code        VARCHAR(50)   '$.product_code',
                product_name        NVARCHAR(500) '$.product_name',
                category            NVARCHAR(150) '$.category',
                warehouse_city      NVARCHAR(150) '$.warehouse_city',
                warehouse_code      VARCHAR(50)   '$.warehouse_code',
                rack_location       VARCHAR(50)   '$.rack_location',
                quantity_on_hand    NVARCHAR(50)  '$.quantity_on_hand',
                quantity_reserved   NVARCHAR(50)  '$.quantity_reserved',
                quantity_in_transit NVARCHAR(50)  '$.quantity_in_transit',
                reorder_level       NVARCHAR(50)  '$.reorder_level',
                reorder_quantity    NVARCHAR(50)  '$.reorder_quantity',
                unit_cost           NVARCHAR(50)  '$.unit_cost',
                mrp                 NVARCHAR(50)  '$.mrp',
                last_updated        VARCHAR(50)   '$.last_updated',
                last_purchase_date  VARCHAR(50)   '$.last_purchase_date',
                manufacture_date    VARCHAR(50)   '$.manufacture_date',
                expiry_date         VARCHAR(50)   '$.expiry_date',
                supplier_lead_days  NVARCHAR(50)  '$.supplier_lead_days',
                batch_number        VARCHAR(50)   '$.batch_number',
                serial_number       NVARCHAR(100) '$.serial_number',
                quality_status      NVARCHAR(100) '$.quality_status'
            );
            SET @end_time = GETDATE();
            PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
            PRINT '>> -------------';
        END
        ELSE PRINT '>> ERROR: Table bronze.erp_inventory does not exist!';

        -- ====================================================
        SET @batch_end_time = GETDATE();
        PRINT '================================================';
        PRINT 'Loading Bronze Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '================================================';

    END TRY
    BEGIN CATCH
        PRINT '================================================';
        PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
        PRINT 'Error Message : ' + ERROR_MESSAGE();
        PRINT 'Error Number  : ' + CAST(ERROR_NUMBER()  AS NVARCHAR);
        PRINT 'Error State   : ' + CAST(ERROR_STATE()   AS NVARCHAR);
        PRINT 'Error Line    : ' + CAST(ERROR_LINE()    AS NVARCHAR);
        PRINT '================================================';
    END CATCH
END;
GO

-- ============================================================
-- Execute
-- ============================================================
EXEC bronze.load_bronze_tables;