/*
===============================================================================
Stored Procedure: silver.load_crm_leads
===============================================================================
Purpose : Load and clean data from bronze.crm_leads into
          silver.crm_leads with full error handling.
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_crm_leads
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @batch_id       NVARCHAR(50)  = CONVERT(NVARCHAR(50), NEWID());
    DECLARE @proc_name      NVARCHAR(100) = 'silver.load_crm_leads';
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
        PRINT 'Step 1: Truncating silver.crm_leads...';

        IF OBJECT_ID('silver.crm_leads', 'U') IS NOT NULL
            TRUNCATE TABLE silver.crm_leads;
        ELSE
        BEGIN
            SET @error_msg = 'Table silver.crm_leads does not exist. Run Silver DDL first.';
            RAISERROR(@error_msg, 16, 1);
            RETURN;
        END

        PRINT 'Step 1: Truncate complete.';

        -- ----------------------------------------------------------------
        -- Step 2: Insert cleaned data
        -- ----------------------------------------------------------------
        PRINT 'Step 2: Inserting cleaned data...';

        INSERT INTO silver.crm_leads (
            lead_id, lead_date,
            first_name, last_name, full_name,
            email, phone,
            company, city, state, country,
            lead_source, status, stage,
            product_interest, expected_value, probability_pct,
            assigned_to, follow_up_date, last_activity,
            converted, converted_customer_id, campaign_id, notes,
            dwh_created_date, dwh_modified_date,
            dwh_source_system, dwh_source_table,
            dwh_batch_id, dwh_is_valid, dwh_record_hash
        )
        SELECT
            -- lead_id: as-is
            lead_id,

            -- lead_date: multi-format → DATE
            TRY_CONVERT(DATE, LTRIM(RTRIM(lead_date)), 105),

            -- first_name: trim, dot remove, proper case
            CASE
                WHEN first_name IS NULL
                  OR UPPER(LTRIM(RTRIM(first_name))) IN ('NULL','N/A','')
                THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(REPLACE(first_name,'.',''))),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(REPLACE(first_name,'.',''))),2,100))
            END,

            -- last_name: trim, dot remove, proper case
            CASE
                WHEN last_name IS NULL
                  OR UPPER(LTRIM(RTRIM(last_name))) IN ('NULL','N/A','')
                THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(REPLACE(last_name,'.',''))),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(REPLACE(last_name,'.',''))),2,100))
            END,

            -- full_name: derived
            CASE
                WHEN first_name IS NULL AND last_name IS NULL THEN NULL
                WHEN first_name IS NULL
                THEN UPPER(LEFT(LTRIM(RTRIM(REPLACE(last_name,'.',''))),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(REPLACE(last_name,'.',''))),2,100))
                WHEN last_name IS NULL
                THEN UPPER(LEFT(LTRIM(RTRIM(REPLACE(first_name,'.',''))),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(REPLACE(first_name,'.',''))),2,100))
                ELSE UPPER(LEFT(LTRIM(RTRIM(REPLACE(first_name,'.',''))),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(REPLACE(first_name,'.',''))),2,100))
                   + ' '
                   + UPPER(LEFT(LTRIM(RTRIM(REPLACE(last_name,'.',''))),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(REPLACE(last_name,'.',''))),2,100))
            END,

            -- email: junk → NULL, valid → lowercase
            CASE
                WHEN email IS NULL
                  OR UPPER(LTRIM(RTRIM(email))) IN ('NULL','N/A','NOT PROVIDED','#N/A')
                  OR LOWER(LTRIM(RTRIM(email))) IN ('na@na.com','test@test','not provided')
                  OR email NOT LIKE '%@%.%'
                THEN NULL
                ELSE LOWER(LTRIM(RTRIM(email)))
            END,

            -- phone: strip +91/spaces/hyphens/(W), validate 10 digits
            CASE
                WHEN phone IS NULL
                  OR UPPER(LTRIM(RTRIM(phone))) IN ('NULL','N/A','NOT AVAILABLE','')
                THEN NULL
                ELSE
                    CASE
                        WHEN LEN(RIGHT(
                            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                                LTRIM(RTRIM(phone)),
                            '+91',''),'+91-',''),'+91 ',''),' ',''),'-',''),'(W)',''),'91','')
                        ,10)) = 10
                        AND RIGHT(
                            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                                LTRIM(RTRIM(phone)),
                            '+91',''),'+91-',''),'+91 ',''),' ',''),'-',''),'(W)',''),'91','')
                        ,10) NOT LIKE '%[^0-9]%'
                        THEN RIGHT(
                            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                                LTRIM(RTRIM(phone)),
                            '+91',''),'+91-',''),'+91 ',''),' ',''),'-',''),'(W)',''),'91','')
                        ,10)
                        ELSE NULL
                    END
            END,

            -- company: "-" / "Individual" → NULL, trim rest
            CASE
                WHEN company IS NULL
                  OR UPPER(LTRIM(RTRIM(company))) IN ('NULL','N/A','NA','-','')
                THEN NULL
                ELSE LTRIM(RTRIM(company))
            END,

            -- city: "-" / "Unknown" → NULL, proper case
            CASE
                WHEN city IS NULL
                  OR UPPER(LTRIM(RTRIM(city))) IN ('NULL','N/A','NA','-','UNKNOWN','')
                THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(city)),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(city)),2,100))
            END,

            -- state: NULL/N/A → NULL, proper case
            CASE
                WHEN state IS NULL
                  OR UPPER(LTRIM(RTRIM(state))) IN ('NULL','N/A','')
                THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(state)),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(state)),2,100))
            END,

            -- country: IN/INDIA/BHARAT/HIND → 'India'
            CASE
                WHEN UPPER(LTRIM(RTRIM(country))) IN ('INDIA','IN','IND','BHARAT','HIND')
                THEN 'India'
                WHEN country IS NULL
                  OR UPPER(LTRIM(RTRIM(country))) IN ('NULL','N/A','')
                THEN NULL
                ELSE LTRIM(RTRIM(country))
            END,

            -- lead_source: trim + NULL
            CASE
                WHEN lead_source IS NULL
                  OR UPPER(LTRIM(RTRIM(lead_source))) IN ('NULL','N/A','')
                THEN NULL
                ELSE LTRIM(RTRIM(lead_source))
            END,

            -- status: trim only
            LTRIM(RTRIM(status)),

            -- stage: trim only
            LTRIM(RTRIM(stage)),

            -- product_interest: TBD/NULL → NULL, trim rest
            CASE
                WHEN product_interest IS NULL
                  OR UPPER(LTRIM(RTRIM(product_interest))) IN ('NULL','N/A','TBD','')
                THEN NULL
                ELSE LTRIM(RTRIM(product_interest))
            END,

            -- expected_value: "469 Lakhs" → number, TBD/0 → NULL
            CASE
                WHEN expected_value IS NULL
                  OR UPPER(LTRIM(RTRIM(expected_value))) IN ('NULL','N/A','TBD','')
                THEN NULL
                WHEN CAST(TRY_CAST(LTRIM(RTRIM(expected_value)) AS DECIMAL(18,2)) AS DECIMAL(18,2)) = 0
                THEN NULL
                WHEN UPPER(expected_value) LIKE '% LAKHS'
                  OR UPPER(expected_value) LIKE '% LAKH'
                THEN TRY_CAST(
                        REPLACE(REPLACE(REPLACE(
                            UPPER(LTRIM(RTRIM(expected_value))),
                        ' LAKHS',''),' LAKH',''),' ','')
                     AS DECIMAL(18,2)) * 100000
                ELSE TRY_CAST(LTRIM(RTRIM(expected_value)) AS DECIMAL(18,2))
            END,

            -- probability_pct: "?" → NULL, cast to INT
            CASE
                WHEN probability_pct IS NULL
                  OR LTRIM(RTRIM(probability_pct)) IN ('?','NULL','N/A','')
                THEN NULL
                ELSE TRY_CAST(LTRIM(RTRIM(probability_pct)) AS INT)
            END,

            -- assigned_to: trim only
            LTRIM(RTRIM(assigned_to)),

            -- follow_up_date: NA/Scheduled/TBD → NULL, rest → DATE
            CASE
                WHEN follow_up_date IS NULL
                  OR UPPER(LTRIM(RTRIM(follow_up_date))) IN
                     ('NULL','N/A','NA','TBD','SCHEDULED','NOT YET','')
                THEN NULL
                ELSE TRY_CONVERT(DATE, LTRIM(RTRIM(follow_up_date)), 105)
            END,

            -- last_activity: trim + NULL
            CASE
                WHEN last_activity IS NULL
                  OR UPPER(LTRIM(RTRIM(last_activity))) IN ('NULL','N/A','')
                THEN NULL
                ELSE LTRIM(RTRIM(last_activity))
            END,

            -- converted: Yes/Y/1/Partial → 1, No/N/0 → 0, NULL → NULL
            CASE
                WHEN UPPER(LTRIM(RTRIM(converted))) IN ('YES','Y','1','PARTIAL') THEN 1
                WHEN UPPER(LTRIM(RTRIM(converted))) IN ('NO','N','0')            THEN 0
                ELSE NULL
            END,

            -- converted_customer_id: trim + NULL
            CASE
                WHEN converted_customer_id IS NULL
                  OR UPPER(LTRIM(RTRIM(converted_customer_id))) IN ('NULL','N/A','')
                THEN NULL
                ELSE LTRIM(RTRIM(converted_customer_id))
            END,

            -- campaign_id: NA → NULL
            CASE
                WHEN campaign_id IS NULL
                  OR UPPER(LTRIM(RTRIM(campaign_id))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(campaign_id))
            END,

            -- notes: trim + NULL
            CASE
                WHEN notes IS NULL
                  OR UPPER(LTRIM(RTRIM(notes))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(notes))
            END,

            -- Metadata columns
            GETDATE(),
            GETDATE(),
            'CRM',
            'bronze.crm_leads',
            @batch_id,
            1,
            HASHBYTES('SHA2_256',
                ISNULL(lead_id,'')    + '|' +
                ISNULL(email,'')      + '|' +
                ISNULL(phone,'')      + '|' +
                ISNULL(converted,'')  + '|' +
                ISNULL(status,'')
            )

        FROM bronze.crm_leads;

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

PRINT 'Procedure silver.load_crm_leads created successfully';
PRINT '============================================================';



EXEC silver.load_crm_leads;