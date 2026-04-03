/*
===============================================================================
Stored Procedure: silver.load_erp_inventory
===============================================================================
Purpose : Load and clean data from bronze.erp_inventory into
          silver.erp_inventory with full error handling.
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_erp_inventory
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @batch_id       NVARCHAR(50)  = CONVERT(NVARCHAR(50), NEWID());
    DECLARE @proc_name      NVARCHAR(100) = 'silver.load_erp_inventory';
    DECLARE @start_time     DATETIME      = GETDATE();
    DECLARE @rows_inserted  INT           = 0;
    DECLARE @error_msg      NVARCHAR(MAX);

    BEGIN TRY

        PRINT '============================================================';
        PRINT 'Starting: ' + @proc_name;
        PRINT 'Batch ID: ' + @batch_id;
        PRINT 'Start Time: ' + CONVERT(NVARCHAR, @start_time, 120);
        PRINT '============================================================';

        -- ----------------------------------------------------------------
        -- Step 1: Table existence check + truncate
        -- ----------------------------------------------------------------
        PRINT 'Step 1: Truncating silver.erp_inventory...';

        IF OBJECT_ID('silver.erp_inventory', 'U') IS NOT NULL
            TRUNCATE TABLE silver.erp_inventory;
        ELSE
        BEGIN
            SET @error_msg = 'Table silver.erp_inventory does not exist. Run Silver DDL first.';
            RAISERROR(@error_msg, 16, 1);
            RETURN;
        END

        PRINT 'Step 1: Truncate complete.';

        -- ----------------------------------------------------------------
        -- Step 2: Insert cleaned data
        -- ----------------------------------------------------------------
        PRINT 'Step 2: Inserting cleaned data...';

        INSERT INTO silver.erp_inventory (
            inventory_id,
            product_code, product_name, category,
            warehouse_city, warehouse_code, rack_location,
            quantity_on_hand, quantity_reserved, quantity_in_transit,
            reorder_level, reorder_quantity,
            unit_cost, mrp,
            last_updated, last_purchase_date,
            manufacture_date, expiry_date,
            supplier_lead_days,
            batch_number, serial_number, quality_status,
            dwh_created_date, dwh_modified_date,
            dwh_source_system, dwh_source_table,
            dwh_batch_id, dwh_is_valid, dwh_record_hash
        )
        SELECT
            -- inventory_id: as-is
            inventory_id,

            -- product_code: as-is
            product_code,

            -- product_name: ALL CAPS fix, trailing spaces trim, proper case
            CASE
                WHEN product_name IS NULL
                  OR UPPER(LTRIM(RTRIM(product_name))) IN ('NULL','N/A','')
                THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(product_name)),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(product_name)),2,200))
            END,

            -- category: trim + proper case
            CASE
                WHEN category IS NULL
                  OR UPPER(LTRIM(RTRIM(category))) IN ('NULL','N/A','')
                THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(category)),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(category)),2,100))
            END,

            -- warehouse_city: trim + proper case
            CASE
                WHEN warehouse_city IS NULL
                  OR UPPER(LTRIM(RTRIM(warehouse_city))) IN ('NULL','N/A','')
                THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(warehouse_city)),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(warehouse_city)),2,100))
            END,

            -- warehouse_code: trim + UPPER
            CASE
                WHEN warehouse_code IS NULL
                  OR UPPER(LTRIM(RTRIM(warehouse_code))) IN ('NULL','N/A','')
                THEN NULL
                ELSE UPPER(LTRIM(RTRIM(warehouse_code)))
            END,

            -- rack_location: TBD/empty → NULL
            CASE
                WHEN rack_location IS NULL
                  OR UPPER(LTRIM(RTRIM(rack_location))) IN ('NULL','N/A','TBD','')
                THEN NULL
                ELSE LTRIM(RTRIM(rack_location))
            END,

            -- quantity_on_hand: NULL/empty → 0
            ISNULL(TRY_CAST(LTRIM(RTRIM(quantity_on_hand)) AS DECIMAL(18,3)), 0),

            -- quantity_reserved: NULL/empty → 0
            ISNULL(TRY_CAST(LTRIM(RTRIM(quantity_reserved)) AS DECIMAL(18,3)), 0),

            -- quantity_in_transit: NULL/NA/empty → 0
            CASE
                WHEN quantity_in_transit IS NULL
                  OR UPPER(LTRIM(RTRIM(quantity_in_transit))) IN ('NULL','N/A','NA','')
                THEN 0
                ELSE ISNULL(TRY_CAST(LTRIM(RTRIM(quantity_in_transit)) AS DECIMAL(18,3)), 0)
            END,

            -- reorder_level: NULL/NA/empty → 0
            CASE
                WHEN reorder_level IS NULL
                  OR UPPER(LTRIM(RTRIM(reorder_level))) IN ('NULL','N/A','NA','')
                THEN 0
                ELSE ISNULL(TRY_CAST(LTRIM(RTRIM(reorder_level)) AS DECIMAL(18,3)), 0)
            END,

            -- reorder_quantity: TBD/NULL → NULL, cast DECIMAL
            CASE
                WHEN reorder_quantity IS NULL
                  OR UPPER(LTRIM(RTRIM(reorder_quantity))) IN ('NULL','N/A','NA','TBD','')
                THEN NULL
                ELSE TRY_CAST(LTRIM(RTRIM(reorder_quantity)) AS DECIMAL(18,3))
            END,

            -- unit_cost: NULL/empty → NULL, cast DECIMAL
            CASE
                WHEN unit_cost IS NULL
                  OR UPPER(LTRIM(RTRIM(unit_cost))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE TRY_CAST(LTRIM(RTRIM(unit_cost)) AS DECIMAL(18,2))
            END,

            -- mrp: NULL/empty → NULL, cast DECIMAL
            CASE
                WHEN mrp IS NULL
                  OR UPPER(LTRIM(RTRIM(mrp))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE TRY_CAST(LTRIM(RTRIM(mrp)) AS DECIMAL(18,2))
            END,

            -- last_updated: multi-format → DATE, NA → NULL
            CASE
                WHEN last_updated IS NULL
                  OR UPPER(LTRIM(RTRIM(last_updated))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE TRY_CONVERT(DATE, LTRIM(RTRIM(last_updated)), 105)
            END,

            -- last_purchase_date: multi-format → DATE, NA → NULL
            CASE
                WHEN last_purchase_date IS NULL
                  OR UPPER(LTRIM(RTRIM(last_purchase_date))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE TRY_CONVERT(DATE, LTRIM(RTRIM(last_purchase_date)), 105)
            END,

            -- manufacture_date: multi-format → DATE, NA → NULL
            CASE
                WHEN manufacture_date IS NULL
                  OR UPPER(LTRIM(RTRIM(manufacture_date))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE TRY_CONVERT(DATE, LTRIM(RTRIM(manufacture_date)), 105)
            END,

            -- expiry_date: multi-format → DATE, NA → NULL
            CASE
                WHEN expiry_date IS NULL
                  OR UPPER(LTRIM(RTRIM(expiry_date))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE TRY_CONVERT(DATE, LTRIM(RTRIM(expiry_date)), 105)
            END,

            -- supplier_lead_days: NA/empty → NULL, cast INT
            CASE
                WHEN supplier_lead_days IS NULL
                  OR UPPER(LTRIM(RTRIM(supplier_lead_days))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE TRY_CAST(LTRIM(RTRIM(supplier_lead_days)) AS INT)
            END,

            -- batch_number: N/A/empty → NULL
            CASE
                WHEN batch_number IS NULL
                  OR UPPER(LTRIM(RTRIM(batch_number))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(batch_number))
            END,

            -- serial_number: "Multiple"/NA/empty → NULL
            CASE
                WHEN serial_number IS NULL
                  OR UPPER(LTRIM(RTRIM(serial_number))) IN
                     ('NULL','N/A','NA','MULTIPLE','')
                THEN NULL
                ELSE LTRIM(RTRIM(serial_number))
            END,

            -- quality_status: empty string → NULL, standardize casing
            CASE
                WHEN quality_status IS NULL
                  OR LTRIM(RTRIM(quality_status)) = ''
                  OR UPPER(LTRIM(RTRIM(quality_status))) IN ('NULL','N/A','NA')
                THEN NULL
                WHEN UPPER(LTRIM(RTRIM(quality_status))) = 'OK'              THEN 'Approved'
                WHEN UPPER(LTRIM(RTRIM(quality_status))) = 'HOLD'            THEN 'Hold'
                WHEN UPPER(LTRIM(RTRIM(quality_status))) = 'REJECTED'        THEN 'Rejected'
                WHEN UPPER(LTRIM(RTRIM(quality_status))) = 'QUARANTINE'      THEN 'Quarantine'
                WHEN UPPER(LTRIM(RTRIM(quality_status))) = 'UNDER INSPECTION'THEN 'Under Inspection'
                ELSE LTRIM(RTRIM(quality_status))
            END,

            -- Metadata columns
            GETDATE(),
            GETDATE(),
            'ERP',
            'bronze.erp_inventory',
            @batch_id,
            1,
            HASHBYTES('SHA2_256',
                ISNULL(inventory_id,'')   + '|' +
                ISNULL(product_code,'')   + '|' +
                ISNULL(warehouse_code,'') + '|' +
                ISNULL(rack_location,'')  + '|' +
                ISNULL(batch_number,'')   + '|' +
                ISNULL(serial_number,'')
            )

        FROM bronze.erp_inventory;

        SET @rows_inserted = @@ROWCOUNT;

        -- ----------------------------------------------------------------
        -- Step 3: Summary log
        -- ----------------------------------------------------------------
        PRINT 'Step 2: Insert complete.';
        PRINT '============================================================';
        PRINT 'Batch ID      : ' + @batch_id;
        PRINT 'Rows Inserted : ' + CAST(@rows_inserted AS NVARCHAR);
        PRINT 'Duration      : ' + CAST(DATEDIFF(SECOND, @start_time, GETDATE()) AS NVARCHAR) + ' seconds';
        PRINT 'End Time      : ' + CONVERT(NVARCHAR, GETDATE(), 120);
        PRINT '============================================================';

    END TRY
    BEGIN CATCH

        SET @error_msg =
            'ERROR in ' + @proc_name               + CHAR(13) +
            'Batch ID    : ' + @batch_id            + CHAR(13) +
            'Error Number: ' + CAST(ERROR_NUMBER()  AS NVARCHAR) + CHAR(13) +
            'Error Line  : ' + CAST(ERROR_LINE()    AS NVARCHAR) + CHAR(13) +
            'Error Msg   : ' + ERROR_MESSAGE();

        PRINT @error_msg;
        RAISERROR(@error_msg, 16, 1);

    END CATCH
END;
GO

PRINT 'Procedure silver.load_erp_inventory created successfully';
PRINT '============================================================';


EXEC silver.load_erp_inventory;
