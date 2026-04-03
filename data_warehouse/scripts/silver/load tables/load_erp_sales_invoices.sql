CREATE OR ALTER PROCEDURE silver.load_erp_sales_invoices
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @batch_id   NVARCHAR(50)  = CONVERT(NVARCHAR(50), NEWID());
    DECLARE @proc_name  NVARCHAR(100) = 'silver.load_erp_sales_invoices';
    DECLARE @start_time DATETIME      = GETDATE();
    DECLARE @rows_inserted INT        = 0;
    DECLARE @error_msg  NVARCHAR(MAX);

    BEGIN TRY
        PRINT '============================================================';
        PRINT 'Starting: ' + @proc_name;
        PRINT 'Batch ID: ' + @batch_id;
        PRINT 'Start Time: ' + CONVERT(NVARCHAR, @start_time, 120);
        PRINT '============================================================';

        IF OBJECT_ID('silver.erp_sales_invoices', 'U') IS NOT NULL
            TRUNCATE TABLE silver.erp_sales_invoices;
        ELSE BEGIN
            SET @error_msg = 'Table silver.erp_sales_invoices does not exist.';
            RAISERROR(@error_msg, 16, 1); RETURN;
        END

        INSERT INTO silver.erp_sales_invoices (
            invoice_number, invoice_date, due_date, financial_year,
            customer_id, customer_name,
            billing_city, billing_state, billing_pincode, customer_gstin,
            product_code, product_name, hsn_code,
            quantity, unit_price, discount_amount, taxable_value,
            gst_rate, cgst_amount, sgst_amount, igst_amount,
            invoice_total, amount_paid, balance_due,
            payment_date, payment_mode, utr_number,
            status, sales_person, branch, region, channel,
            tds_applicable, tds_amount, remarks,
            dwh_created_date, dwh_modified_date, dwh_source_system,
            dwh_source_table, dwh_batch_id, dwh_is_valid, dwh_record_hash
        )
        SELECT
            invoice_number,

            TRY_CONVERT(DATE, LTRIM(RTRIM(invoice_date)), 105),

            CASE
                WHEN UPPER(LTRIM(RTRIM(due_date))) IN ('NULL','N/A','NA','PENDING','')
                  OR due_date IS NULL
                THEN NULL
                ELSE TRY_CONVERT(DATE, LTRIM(RTRIM(due_date)), 105)
            END,

            -- financial_year: NA → NULL
            CASE
                WHEN UPPER(LTRIM(RTRIM(financial_year))) IN ('NULL','N/A','NA','')
                  OR financial_year IS NULL
                THEN NULL
                ELSE LTRIM(RTRIM(financial_year))
            END,

            -- customer_id: CASH/WALK-IN/UNKNOWN → NULL
            CASE
                WHEN customer_id IS NULL
                  OR UPPER(LTRIM(RTRIM(customer_id))) IN
                     ('NULL','N/A','NA','CASH','WALK-IN','UNKNOWN','')
                THEN NULL
                ELSE LTRIM(RTRIM(customer_id))
            END,

            -- customer_name: PROPER case, trim, remove trailing dot
            CASE
                WHEN customer_name IS NULL
                  OR LTRIM(RTRIM(customer_name)) = ''
                  OR UPPER(LTRIM(RTRIM(customer_name))) IN ('NULL','N/A','CASH CUSTOMER')
                THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(REPLACE(customer_name,'.',''))),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(REPLACE(customer_name,'.',''))),2,200))
            END,

            -- billing_city: dash → NULL, PROPER
            CASE
                WHEN billing_city IS NULL
                  OR LTRIM(RTRIM(billing_city)) IN ('-','')
                  OR UPPER(LTRIM(RTRIM(billing_city))) IN ('NULL','N/A','NA')
                THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(billing_city)),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(billing_city)),2,100))
            END,

            CASE
                WHEN billing_state IS NULL
                  OR UPPER(LTRIM(RTRIM(billing_state))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(billing_state))
            END,

            -- billing_pincode: 000000/invalid → NULL
            CASE
                WHEN REPLACE(LTRIM(RTRIM(billing_pincode)),' ','')
                     IN ('000000','','NULL','N/A','NA')
                  OR billing_pincode IS NULL
                THEN NULL
                WHEN LEN(REPLACE(LTRIM(RTRIM(billing_pincode)),' ','')) = 6
                 AND REPLACE(LTRIM(RTRIM(billing_pincode)),' ','')
                     NOT LIKE '%[^0-9]%'
                THEN REPLACE(LTRIM(RTRIM(billing_pincode)),' ','')
                ELSE NULL
            END,

            -- customer_gstin: lowercase/invalid → NULL or UPPER
            CASE
                WHEN customer_gstin IS NULL
                  OR UPPER(LTRIM(RTRIM(customer_gstin))) IN
                     ('NULL','N/A','NA','GSTIN PENDING','EXEMPT',
                      'NOT REGISTERED','APPLIED','UNDER PROCESS','')
                THEN NULL
                ELSE UPPER(LTRIM(RTRIM(customer_gstin)))
            END,

            product_code,

            -- product_name: ALL CAPS fix, NA → NULL, PROPER
            CASE
                WHEN product_name IS NULL
                  OR UPPER(LTRIM(RTRIM(product_name))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(product_name)),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(product_name)),2,200))
            END,

            -- hsn_code: NA → NULL
            CASE
                WHEN hsn_code IS NULL
                  OR UPPER(LTRIM(RTRIM(hsn_code))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(hsn_code))
            END,

            -- quantity: strip "Nos" etc
            TRY_CAST(
                LTRIM(RTRIM(
                    REPLACE(REPLACE(REPLACE(REPLACE(
                        UPPER(LTRIM(RTRIM(ISNULL(quantity,'')))),
                    ' NOS',''),' PCS',''),' LTRS',''),' ','')
                ))
            AS DECIMAL(18,3)),

            TRY_CAST(LTRIM(RTRIM(unit_price)) AS DECIMAL(18,2)),

            -- discount_amount: N/A → NULL
            CASE
                WHEN UPPER(LTRIM(RTRIM(discount_amount))) IN ('NULL','N/A','NA','')
                  OR discount_amount IS NULL
                THEN NULL
                ELSE TRY_CAST(LTRIM(RTRIM(discount_amount)) AS DECIMAL(18,2))
            END,

            TRY_CAST(LTRIM(RTRIM(taxable_value)) AS DECIMAL(18,2)),

            -- gst_rate: "18%", "Exempt" → DECIMAL/NULL
            CASE
                WHEN UPPER(LTRIM(RTRIM(gst_rate))) IN
                     ('NULL','N/A','NA','EXEMPT','')
                  OR gst_rate IS NULL
                THEN NULL
                ELSE TRY_CAST(REPLACE(LTRIM(RTRIM(gst_rate)),'%','') AS DECIMAL(5,2))
            END,

            -- cgst/sgst/igst: "Nil" → 0
            CASE
                WHEN UPPER(LTRIM(RTRIM(cgst_amount))) IN ('NIL','NULL','N/A','NA','')
                  OR cgst_amount IS NULL
                THEN 0
                ELSE TRY_CAST(LTRIM(RTRIM(cgst_amount)) AS DECIMAL(18,2))
            END,

            CASE
                WHEN UPPER(LTRIM(RTRIM(sgst_amount))) IN ('NIL','NULL','N/A','NA','')
                  OR sgst_amount IS NULL
                THEN 0
                ELSE TRY_CAST(LTRIM(RTRIM(sgst_amount)) AS DECIMAL(18,2))
            END,

            CASE
                WHEN UPPER(LTRIM(RTRIM(igst_amount))) IN ('NIL','NULL','N/A','NA','')
                  OR igst_amount IS NULL
                THEN 0
                ELSE TRY_CAST(LTRIM(RTRIM(igst_amount)) AS DECIMAL(18,2))
            END,

            -- invoice_total: strip "INR", "Rs.", "INR 8332362.0"
            CASE
                WHEN UPPER(LTRIM(RTRIM(invoice_total))) IN ('NULL','N/A','NA','RS','INR','')
                  OR invoice_total IS NULL
                THEN NULL
                ELSE TRY_CAST(
                    LTRIM(RTRIM(
                        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                            invoice_total,
                        'INR ',''),'INR',''),'Rs.',''),'Rs',''),' ','')
                    ))
                AS DECIMAL(18,2))
            END,

            -- amount_paid: "Pending" → NULL
            CASE
                WHEN UPPER(LTRIM(RTRIM(amount_paid))) IN
                     ('NULL','N/A','NA','PENDING','')
                  OR amount_paid IS NULL
                THEN NULL
                ELSE TRY_CAST(LTRIM(RTRIM(amount_paid)) AS DECIMAL(18,2))
            END,

            -- balance_due: "TBD"/NA → NULL
            CASE
                WHEN UPPER(LTRIM(RTRIM(balance_due))) IN
                     ('NULL','N/A','NA','TBD','')
                  OR balance_due IS NULL
                THEN NULL
                ELSE TRY_CAST(LTRIM(RTRIM(balance_due)) AS DECIMAL(18,2))
            END,

            -- payment_date: "Pending"/NA → NULL
            CASE
                WHEN UPPER(LTRIM(RTRIM(payment_date))) IN
                     ('NULL','N/A','NA','PENDING','')
                  OR payment_date IS NULL
                THEN NULL
                ELSE TRY_CONVERT(DATE, LTRIM(RTRIM(payment_date)), 105)
            END,

            LTRIM(RTRIM(payment_mode)),

            -- utr_number: N/A → NULL
            CASE
                WHEN utr_number IS NULL
                  OR UPPER(LTRIM(RTRIM(utr_number))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(utr_number))
            END,

            LTRIM(RTRIM(status)),
            LTRIM(RTRIM(sales_person)),

            -- branch: "Online"/"HO" are valid, keep as-is
            CASE
                WHEN branch IS NULL
                  OR UPPER(LTRIM(RTRIM(branch))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(branch))
            END,

            CASE
                WHEN region IS NULL
                  OR UPPER(LTRIM(RTRIM(region))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(region))
            END,

            CASE
                WHEN channel IS NULL
                  OR UPPER(LTRIM(RTRIM(channel))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(channel))
            END,

            -- tds_applicable: Y/Yes/y → 1, N/No → 0
            CASE
                WHEN UPPER(LTRIM(RTRIM(tds_applicable))) IN ('Y','YES') THEN 1
                WHEN UPPER(LTRIM(RTRIM(tds_applicable))) IN ('N','NO')  THEN 0
                ELSE NULL
            END,

            TRY_CAST(LTRIM(RTRIM(tds_amount)) AS DECIMAL(18,2)),

            CASE
                WHEN remarks IS NULL
                  OR UPPER(LTRIM(RTRIM(remarks))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(remarks))
            END,

            GETDATE(), GETDATE(), 'ERP', 'bronze.erp_sales_invoices',
            @batch_id, 1,
            HASHBYTES('SHA2_256',
                ISNULL(invoice_number,'') + '|' +
                ISNULL(customer_id,'')    + '|' +
                ISNULL(product_code,'')   + '|' +
                ISNULL(status,'')
            )

        FROM bronze.erp_sales_invoices;

        SET @rows_inserted = @@ROWCOUNT;
        PRINT 'Rows Inserted : ' + CAST(@rows_inserted AS NVARCHAR);
        PRINT 'Duration      : ' + CAST(DATEDIFF(SECOND,@start_time,GETDATE()) AS NVARCHAR) + 's';
        PRINT '============================================================';

    END TRY
    BEGIN CATCH
        SET @error_msg =
            'ERROR in ' + @proc_name + CHAR(13) +
            'Batch: '    + @batch_id                         + CHAR(13) +
            'Error No: ' + CAST(ERROR_NUMBER() AS NVARCHAR)  + CHAR(13) +
            'Line: '     + CAST(ERROR_LINE()   AS NVARCHAR)  + CHAR(13) +
            'Message: '  + ERROR_MESSAGE();
        PRINT @error_msg;
        RAISERROR(@error_msg, 16, 1);
    END CATCH
END;
GO
PRINT 'Procedure silver.load_erp_sales_invoices created successfully';

EXEC silver.load_erp_sales_invoices