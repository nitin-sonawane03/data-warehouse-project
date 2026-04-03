CREATE OR ALTER PROCEDURE silver.load_erp_purchase_orders
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @batch_id   NVARCHAR(50)  = CONVERT(NVARCHAR(50), NEWID());
    DECLARE @proc_name  NVARCHAR(100) = 'silver.load_erp_purchase_orders';
    DECLARE @start_time DATETIME      = GETDATE();
    DECLARE @rows_inserted INT        = 0;
    DECLARE @error_msg  NVARCHAR(MAX);

    BEGIN TRY
        PRINT '============================================================';
        PRINT 'Starting: ' + @proc_name;
        PRINT 'Batch ID: ' + @batch_id;
        PRINT 'Start Time: ' + CONVERT(NVARCHAR, @start_time, 120);
        PRINT '============================================================';

        IF OBJECT_ID('silver.erp_purchase_orders', 'U') IS NOT NULL
            TRUNCATE TABLE silver.erp_purchase_orders;
        ELSE BEGIN
            SET @error_msg = 'Table silver.erp_purchase_orders does not exist.';
            RAISERROR(@error_msg, 16, 1); RETURN;
        END

        INSERT INTO silver.erp_purchase_orders (
            po_number, po_date, vendor_id, vendor_name, vendor_gstin, vendor_city,
            product_code, product_description, category,
            quantity, unit, unit_price, discount_pct,
            taxable_amount, gst_rate_pct, cgst, sgst, igst, total_amount,
            currency, payment_terms,
            expected_delivery, actual_delivery,
            status, approved_by, department, cost_center,
            warehouse_location, purchase_type, contract_ref, remarks,
            dwh_created_date, dwh_modified_date, dwh_source_system,
            dwh_source_table, dwh_batch_id, dwh_is_valid, dwh_record_hash
        )
        SELECT
            po_number,

            -- po_date: multi-format → DATE
            TRY_CONVERT(DATE, LTRIM(RTRIM(po_date)), 105),

            vendor_id,

            -- vendor_name: CAPS, trailing spaces → PROPER
            CASE
                WHEN vendor_name IS NULL
                  OR UPPER(LTRIM(RTRIM(vendor_name))) IN ('NULL','N/A','')
                THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(vendor_name)),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(vendor_name)),2,200))
            END,

            -- vendor_gstin: lowercase/Pending/Exempt/Applied → NULL or UPPER
            CASE
                WHEN vendor_gstin IS NULL
                  OR UPPER(LTRIM(RTRIM(vendor_gstin))) IN
                     ('NULL','N/A','NA','GSTIN PENDING','EXEMPT',
                      'NOT REGISTERED','APPLIED','UNDER PROCESS','')
                THEN NULL
                ELSE UPPER(LTRIM(RTRIM(vendor_gstin)))
            END,

            -- vendor_city: proper case
            CASE
                WHEN vendor_city IS NULL
                  OR UPPER(LTRIM(RTRIM(vendor_city))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(vendor_city)),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(vendor_city)),2,100))
            END,

            product_code,

            -- product_description: "As discussed"/"As per sample" → NULL
            CASE
                WHEN product_description IS NULL
                  OR UPPER(LTRIM(RTRIM(product_description))) IN
                     ('NULL','N/A','NA','AS DISCUSSED','AS PER SAMPLE',
                      'AS DISCUSSED.','')
                THEN NULL
                ELSE LTRIM(RTRIM(product_description))
            END,

            LTRIM(RTRIM(category)),

            -- quantity: strip "811 Nos" → 811
            TRY_CAST(
                LTRIM(RTRIM(
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        UPPER(LTRIM(RTRIM(ISNULL(quantity,'')))),
                    ' NOS',''),' PCS',''),' KGS',''),' LTRS','')
                ))
            AS DECIMAL(18,3)),

            LTRIM(RTRIM(unit)),

            TRY_CAST(LTRIM(RTRIM(unit_price)) AS DECIMAL(18,2)),

            -- discount_pct: "10%", "N/A" → DECIMAL
            CASE
                WHEN UPPER(LTRIM(RTRIM(discount_pct))) IN ('NULL','N/A','NA','')
                  OR discount_pct IS NULL
                THEN NULL
                ELSE TRY_CAST(REPLACE(LTRIM(RTRIM(discount_pct)),'%','') AS DECIMAL(5,2))
            END,

            TRY_CAST(LTRIM(RTRIM(taxable_amount)) AS DECIMAL(18,2)),

            -- gst_rate_pct: "18%", "Exempt", "5%" → DECIMAL / NULL
            CASE
                WHEN UPPER(LTRIM(RTRIM(gst_rate_pct))) IN
                     ('NULL','N/A','NA','EXEMPT','')
                  OR gst_rate_pct IS NULL
                THEN NULL
                ELSE TRY_CAST(REPLACE(LTRIM(RTRIM(gst_rate_pct)),'%','') AS DECIMAL(5,2))
            END,

            TRY_CAST(LTRIM(RTRIM(cgst)) AS DECIMAL(18,2)),
            TRY_CAST(LTRIM(RTRIM(sgst)) AS DECIMAL(18,2)),
            TRY_CAST(LTRIM(RTRIM(igst)) AS DECIMAL(18,2)),

            -- total_amount: strip "Rs.", "INR ", "TBD" → DECIMAL
            CASE
                WHEN UPPER(LTRIM(RTRIM(total_amount))) IN ('NULL','N/A','TBD','RS','INR','')
                  OR total_amount IS NULL
                THEN NULL
                ELSE TRY_CAST(
                    LTRIM(RTRIM(
                        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                            total_amount,
                        'Rs.',''),'Rs',''),'INR ',''),'INR',''),' ','')
                    ))
                AS DECIMAL(18,2))
            END,

            -- currency: "?" → NULL
            CASE
                WHEN currency IS NULL
                  OR LTRIM(RTRIM(currency)) IN ('?','NULL','N/A','NA','RS','RS.','')
                THEN NULL
                ELSE UPPER(LTRIM(RTRIM(currency)))
            END,

            LTRIM(RTRIM(payment_terms)),

            -- expected_delivery: "Immediate"/"Pending" → NULL
            CASE
                WHEN UPPER(LTRIM(RTRIM(expected_delivery))) IN
                     ('NULL','N/A','NA','TBD','IMMEDIATE','PENDING','')
                  OR expected_delivery IS NULL
                THEN NULL
                ELSE TRY_CONVERT(DATE, LTRIM(RTRIM(expected_delivery)), 105)
            END,

            -- actual_delivery: "Pending" → NULL
            CASE
                WHEN UPPER(LTRIM(RTRIM(actual_delivery))) IN
                     ('NULL','N/A','NA','TBD','PENDING','')
                  OR actual_delivery IS NULL
                THEN NULL
                ELSE TRY_CONVERT(DATE, LTRIM(RTRIM(actual_delivery)), 105)
            END,

            LTRIM(RTRIM(status)),

            -- approved_by: "Auto-approved"/"Pending" → NULL
            CASE
                WHEN approved_by IS NULL
                  OR UPPER(LTRIM(RTRIM(approved_by))) IN
                     ('NULL','N/A','NA','PENDING','AUTO-APPROVED','')
                THEN NULL
                ELSE LTRIM(RTRIM(approved_by))
            END,

            CASE
                WHEN department IS NULL
                  OR UPPER(LTRIM(RTRIM(department))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(department))
            END,

            CASE
                WHEN cost_center IS NULL
                  OR UPPER(LTRIM(RTRIM(cost_center))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(cost_center))
            END,

            CASE
                WHEN UPPER(LTRIM(RTRIM(warehouse_location))) IN
                     ('NULL','N/A','NA','TBD','')
                  OR warehouse_location IS NULL
                THEN NULL
                ELSE LTRIM(RTRIM(warehouse_location))
            END,

            LTRIM(RTRIM(purchase_type)),

            CASE
                WHEN UPPER(LTRIM(RTRIM(contract_ref))) IN
                     ('NULL','N/A','NA','SPOT PURCHASE','')
                  OR contract_ref IS NULL
                THEN NULL
                ELSE LTRIM(RTRIM(contract_ref))
            END,

            CASE
                WHEN remarks IS NULL
                  OR UPPER(LTRIM(RTRIM(remarks))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(remarks))
            END,

            GETDATE(), GETDATE(), 'ERP', 'bronze.erp_purchase_orders',
            @batch_id, 1,
            HASHBYTES('SHA2_256',
                ISNULL(po_number,'')    + '|' +
                ISNULL(vendor_id,'')    + '|' +
                ISNULL(product_code,'') + '|' +
                ISNULL(status,'')
            )

        FROM bronze.erp_purchase_orders;

        SET @rows_inserted = @@ROWCOUNT;
        PRINT 'Rows Inserted : ' + CAST(@rows_inserted AS NVARCHAR);
        PRINT 'Duration      : ' + CAST(DATEDIFF(SECOND,@start_time,GETDATE()) AS NVARCHAR) + 's';
        PRINT '============================================================';

    END TRY
    BEGIN CATCH
        SET @error_msg =
            'ERROR in ' + @proc_name + CHAR(13) +
            'Batch: '       + @batch_id                          + CHAR(13) +
            'Error No: '    + CAST(ERROR_NUMBER()  AS NVARCHAR)  + CHAR(13) +
            'Line: '        + CAST(ERROR_LINE()    AS NVARCHAR)  + CHAR(13) +
            'Message: '     + ERROR_MESSAGE();
        PRINT @error_msg;
        RAISERROR(@error_msg, 16, 1);
    END CATCH
END;
GO
PRINT 'Procedure silver.load_erp_purchase_orders created successfully';

EXEC silver.load_erp_purchase_orders
