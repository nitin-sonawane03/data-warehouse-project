/*
===============================================================================
Stored Procedure: silver.load_crm_customers
===============================================================================
Purpose : Load and clean data from bronze.crm_customers into
          silver.crm_customers with full error handling.
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_crm_customers
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @batch_id       NVARCHAR(50)  = CONVERT(NVARCHAR(50), NEWID());
    DECLARE @proc_name      NVARCHAR(100) = 'silver.load_crm_customers';
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
        -- Step 1: Truncate existing silver data
        -- ----------------------------------------------------------------
        PRINT 'Step 1: Truncating silver.crm_customers...';

        IF OBJECT_ID('silver.crm_customers', 'U') IS NOT NULL
            TRUNCATE TABLE silver.crm_customers;
        ELSE
        BEGIN
            SET @error_msg = 'Table silver.crm_customers does not exist. Run Silver DDL first.';
            RAISERROR(@error_msg, 16, 1);
            RETURN;
        END

        PRINT 'Step 1: Truncate complete.';

        -- ----------------------------------------------------------------
        -- Step 2: Insert cleaned data
        -- ----------------------------------------------------------------
        PRINT 'Step 2: Inserting cleaned data...';

        INSERT INTO silver.crm_customers (
            customer_id, first_name, last_name, full_name,
            gender, dob,
            email, phone, alternate_phone,
            city, state, pincode, country, address_line1,
            company, industry, annual_revenue, employee_count,
            lead_source, lead_status, assigned_to,
            created_date, last_contact_date, next_followup,
            gst_number, pan_number, credit_limit, payment_terms,
            customer_segment, lifetime_value, notes, is_active,
            dwh_created_date, dwh_modified_date,
            dwh_source_system, dwh_source_table,
            dwh_batch_id, dwh_is_valid, dwh_record_hash
        )
        SELECT
            customer_id,

            -- first_name: trim, remove dot, proper case
            CASE
                WHEN UPPER(LTRIM(RTRIM(first_name))) IN ('NULL','N/A','') OR first_name IS NULL THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(REPLACE(first_name,'.',''))),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(REPLACE(first_name,'.',''))),2,100))
            END,

            -- last_name: trim, remove dot, proper case
            CASE
                WHEN UPPER(LTRIM(RTRIM(last_name))) IN ('NULL','N/A','') OR last_name IS NULL THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(REPLACE(last_name,'.',''))),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(REPLACE(last_name,'.',''))),2,100))
            END,

            -- full_name: derived from cleaned first + last
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

            -- gender: standardize to Male/Female/Other/Not Specified
            CASE
                WHEN UPPER(LTRIM(RTRIM(gender))) IN ('M','MALE')      THEN 'Male'
                WHEN UPPER(LTRIM(RTRIM(gender))) IN ('F','FEMALE')    THEN 'Female'
                WHEN UPPER(LTRIM(RTRIM(gender))) IN ('OTHER','T')     THEN 'Other'
                WHEN UPPER(LTRIM(RTRIM(gender))) IN ('NOT SPECIFIED') THEN 'Not Specified'
                ELSE NULL
            END,

            -- dob: multi-format → DATE
            TRY_CONVERT(DATE, LTRIM(RTRIM(dob)), 105),

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

            -- alternate_phone: same as phone + 'Same'/'Not Available' → NULL
            CASE
                WHEN alternate_phone IS NULL
                  OR UPPER(LTRIM(RTRIM(alternate_phone))) IN ('NULL','N/A','NOT AVAILABLE','SAME','')
                THEN NULL
                ELSE
                    CASE
                        WHEN LEN(RIGHT(
                            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                                LTRIM(RTRIM(alternate_phone)),
                            '+91',''),'+91-',''),'+91 ',''),' ',''),'-',''),'(W)',''),'91','')
                        ,10)) = 10
                        AND RIGHT(
                            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                                LTRIM(RTRIM(alternate_phone)),
                            '+91',''),'+91-',''),'+91 ',''),' ',''),'-',''),'(W)',''),'91','')
                        ,10) NOT LIKE '%[^0-9]%'
                        THEN RIGHT(
                            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                                LTRIM(RTRIM(alternate_phone)),
                            '+91',''),'+91-',''),'+91 ',''),' ',''),'-',''),'(W)',''),'91','')
                        ,10)
                        ELSE NULL
                    END
            END,

            -- city: dash/NA → NULL, proper case
            CASE
                WHEN LTRIM(RTRIM(city)) IN ('-','','NA') OR city IS NULL THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(city)),1)) + LOWER(SUBSTRING(LTRIM(RTRIM(city)),2,100))
            END,

            -- state: N/A → NULL, proper case
            CASE
                WHEN UPPER(LTRIM(RTRIM(state))) IN ('NULL','N/A','') OR state IS NULL THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(state)),1)) + LOWER(SUBSTRING(LTRIM(RTRIM(state)),2,100))
            END,

            -- pincode: remove spaces, 000000 → NULL, validate 6 digits
            CASE
                WHEN REPLACE(LTRIM(RTRIM(pincode)),' ','') IN ('000000','','NULL','N/A')
                  OR pincode IS NULL THEN NULL
                WHEN LEN(REPLACE(LTRIM(RTRIM(pincode)),' ','')) = 6
                 AND REPLACE(LTRIM(RTRIM(pincode)),' ','') NOT LIKE '%[^0-9]%'
                THEN REPLACE(LTRIM(RTRIM(pincode)),' ','')
                ELSE NULL
            END,

            -- country: all variants → 'India'
            CASE
                WHEN UPPER(LTRIM(RTRIM(country))) IN ('INDIA','IN','IND','BHARAT','HIND') THEN 'India'
                WHEN country IS NULL
                  OR UPPER(LTRIM(RTRIM(country))) IN ('NULL','N/A','') THEN NULL
                ELSE LTRIM(RTRIM(country))
            END,

            -- address_line1: 'Same as above'/NA/dash → NULL
            CASE
                WHEN UPPER(LTRIM(RTRIM(address_line1))) IN
                    ('NULL','N/A','NA','SAME AS ABOVE','SAME ABOVE','-','')
                  OR address_line1 IS NULL THEN NULL
                ELSE LTRIM(RTRIM(address_line1))
            END,

            -- company: junk → NULL
            CASE
                WHEN UPPER(LTRIM(RTRIM(company))) IN ('NULL','N/A','NA','')
                  OR company IS NULL THEN NULL
                ELSE LTRIM(RTRIM(company))
            END,

            -- industry: Unknown → NULL
            CASE
                WHEN UPPER(LTRIM(RTRIM(industry))) IN ('NULL','N/A','NA','UNKNOWN','')
                  OR industry IS NULL THEN NULL
                ELSE LTRIM(RTRIM(industry))
            END,

            -- annual_revenue: '5.0 Lakh' → 500000.00
            CASE
                WHEN annual_revenue IS NULL
                  OR UPPER(LTRIM(RTRIM(annual_revenue))) IN ('NULL','N/A','CONFIDENTIAL','')
                THEN NULL
                WHEN UPPER(annual_revenue) LIKE '% LAKH'
                THEN TRY_CAST(
                        REPLACE(REPLACE(UPPER(LTRIM(RTRIM(annual_revenue))),' LAKH',''),' ','')
                     AS DECIMAL(18,2)) * 100000
                ELSE TRY_CAST(LTRIM(RTRIM(annual_revenue)) AS DECIMAL(18,2))
            END,

            -- employee_count: N/A → NULL, cast to INT
            CASE
                WHEN UPPER(LTRIM(RTRIM(employee_count))) IN ('NULL','N/A','NA','')
                  OR employee_count IS NULL THEN NULL
                ELSE TRY_CAST(LTRIM(RTRIM(employee_count)) AS INT)
            END,

            LTRIM(RTRIM(lead_source)),
            LTRIM(RTRIM(lead_status)),
            LTRIM(RTRIM(assigned_to)),

            -- created_date
            TRY_CONVERT(DATE, LTRIM(RTRIM(created_date)), 105),

            -- last_contact_date: 'Not Yet'/'TBD' → NULL
            CASE
                WHEN UPPER(LTRIM(RTRIM(last_contact_date))) IN ('NULL','N/A','NA','NOT YET','TBD','')
                  OR last_contact_date IS NULL THEN NULL
                ELSE TRY_CONVERT(DATE, LTRIM(RTRIM(last_contact_date)), 105)
            END,

            -- next_followup: 'Not Yet'/'TBD' → NULL
            CASE
                WHEN UPPER(LTRIM(RTRIM(next_followup))) IN ('NULL','N/A','NA','NOT YET','TBD','')
                  OR next_followup IS NULL THEN NULL
                ELSE TRY_CONVERT(DATE, LTRIM(RTRIM(next_followup)), 105)
            END,

            -- gst_number: invalid statuses → NULL, valid → UPPERCASE
            CASE
                WHEN gst_number IS NULL
                  OR UPPER(LTRIM(RTRIM(gst_number))) IN
                    ('NULL','N/A','GSTIN PENDING','EXEMPT','NOT REGISTERED','APPLIED','')
                THEN NULL
                ELSE UPPER(LTRIM(RTRIM(gst_number)))
            END,

            -- pan_number: invalid → NULL, valid → UPPERCASE
            CASE
                WHEN pan_number IS NULL
                  OR UPPER(LTRIM(RTRIM(pan_number))) IN ('NULL','N/A','APPLIED','NOT SET','')
                THEN NULL
                ELSE UPPER(LTRIM(RTRIM(pan_number)))
            END,

            -- credit_limit: 'Not Set'/NA → NULL, cast to DECIMAL
            CASE
                WHEN credit_limit IS NULL
                  OR UPPER(LTRIM(RTRIM(credit_limit))) IN ('NULL','N/A','NOT SET','NA','')
                THEN NULL
                ELSE TRY_CAST(LTRIM(RTRIM(credit_limit)) AS DECIMAL(18,2))
            END,

            -- payment_terms: NA/Not Set → NULL
            CASE
                WHEN UPPER(LTRIM(RTRIM(payment_terms))) IN ('NULL','N/A','NA','NOT SET','')
                  OR payment_terms IS NULL THEN NULL
                ELSE LTRIM(RTRIM(payment_terms))
            END,

            -- customer_segment
            CASE
                WHEN UPPER(LTRIM(RTRIM(customer_segment))) IN ('NULL','N/A','')
                  OR customer_segment IS NULL THEN NULL
                ELSE LTRIM(RTRIM(customer_segment))
            END,

            -- lifetime_value
            CASE
                WHEN UPPER(LTRIM(RTRIM(lifetime_value))) IN ('NULL','N/A','NA','')
                  OR lifetime_value IS NULL THEN NULL
                ELSE TRY_CAST(LTRIM(RTRIM(lifetime_value)) AS DECIMAL(18,2))
            END,

            -- notes
            CASE
                WHEN UPPER(LTRIM(RTRIM(notes))) IN ('NULL','N/A','NA','')
                  OR notes IS NULL THEN NULL
                ELSE LTRIM(RTRIM(notes))
            END,

            -- is_active: Y/Yes/1/Active → 1, N/No/0/Inactive → 0
            CASE
                WHEN UPPER(LTRIM(RTRIM(is_active))) IN ('Y','YES','1','ACTIVE')   THEN 1
                WHEN UPPER(LTRIM(RTRIM(is_active))) IN ('N','NO','0','INACTIVE')  THEN 0
                ELSE NULL
            END,

            -- Metadata columns
            GETDATE(),                          -- dwh_created_date
            GETDATE(),                          -- dwh_modified_date
            'CRM',                              -- dwh_source_system
            'bronze.crm_customers',             -- dwh_source_table
            @batch_id,                          -- dwh_batch_id
            1,                                  -- dwh_is_valid
            HASHBYTES('SHA2_256',               -- dwh_record_hash
                ISNULL(customer_id,'')      + '|' +
                ISNULL(first_name,'')       + '|' +
                ISNULL(last_name,'')        + '|' +
                ISNULL(email,'')            + '|' +
                ISNULL(phone,'')            + '|' +
                ISNULL(is_active,'')
            )

        FROM bronze.crm_customers;

        SET @rows_inserted = @@ROWCOUNT;

        -- ----------------------------------------------------------------
        -- Step 3: Summary
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
            'ERROR in ' + @proc_name + CHAR(13) +
            'Batch ID    : ' + @batch_id          + CHAR(13) +
            'Error Number: ' + CAST(ERROR_NUMBER()    AS NVARCHAR) + CHAR(13) +
            'Error Line  : ' + CAST(ERROR_LINE()      AS NVARCHAR) + CHAR(13) +
            'Error Msg   : ' + ERROR_MESSAGE();

        PRINT @error_msg;
        RAISERROR(@error_msg, 16, 1);

    END CATCH
END;
GO

PRINT 'Procedure silver.load_crm_customers created successfully';
PRINT '============================================================';

EXEC silver.load_crm_customers;