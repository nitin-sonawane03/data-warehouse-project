/*
===============================================================================
Stored Procedure: silver.load_erp_employees
===============================================================================
Purpose : Load and clean data from bronze.erp_employees into
          silver.erp_employees with full error handling.
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_erp_employees
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @batch_id       NVARCHAR(50)  = CONVERT(NVARCHAR(50), NEWID());
    DECLARE @proc_name      NVARCHAR(100) = 'silver.load_erp_employees';
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
        PRINT 'Step 1: Truncating silver.erp_employees...';

        IF OBJECT_ID('silver.erp_employees', 'U') IS NOT NULL
            TRUNCATE TABLE silver.erp_employees;
        ELSE
        BEGIN
            SET @error_msg = 'Table silver.erp_employees does not exist. Run Silver DDL first.';
            RAISERROR(@error_msg, 16, 1);
            RETURN;
        END

        PRINT 'Step 1: Truncate complete.';

        -- ----------------------------------------------------------------
        -- Step 2: Insert cleaned data
        -- ----------------------------------------------------------------
        PRINT 'Step 2: Inserting cleaned data...';

        INSERT INTO silver.erp_employees (
            employee_id,
            first_name, last_name, full_name,
            gender, dob,
            personal_email, official_email, phone,
            city, state, address,
            department, designation,
            joining_date, exit_date,
            employment_status, employment_type,
            salary, grade,
            pan_number, uan_number,
            bank_account, ifsc_code, bank_name,
            manager_id, branch_location, cost_center, remarks,
            dwh_created_date, dwh_modified_date,
            dwh_source_system, dwh_source_table,
            dwh_batch_id, dwh_is_valid, dwh_record_hash
        )
        SELECT
            -- employee_id: as-is
            employee_id,

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

            -- gender: M/F/Male/Female/Other → standard
            CASE
                WHEN UPPER(LTRIM(RTRIM(gender))) IN ('M','MALE')      THEN 'Male'
                WHEN UPPER(LTRIM(RTRIM(gender))) IN ('F','FEMALE')    THEN 'Female'
                WHEN UPPER(LTRIM(RTRIM(gender))) IN ('OTHER')         THEN 'Other'
                ELSE NULL
            END,

            -- dob: multi-format → DATE
            TRY_CONVERT(DATE, LTRIM(RTRIM(dob)), 105),

            -- personal_email: junk → NULL, valid → lowercase
            CASE
                WHEN personal_email IS NULL
                  OR UPPER(LTRIM(RTRIM(personal_email))) IN ('NULL','N/A','NOT PROVIDED','#N/A')
                  OR LOWER(LTRIM(RTRIM(personal_email))) IN ('na@na.com','test@test','not provided')
                  OR personal_email NOT LIKE '%@%.%'
                THEN NULL
                ELSE LOWER(LTRIM(RTRIM(personal_email)))
            END,

            -- official_email: NA → NULL, valid → lowercase
            CASE
                WHEN official_email IS NULL
                  OR UPPER(LTRIM(RTRIM(official_email))) IN ('NULL','N/A','NA','')
                  OR official_email NOT LIKE '%@%.%'
                THEN NULL
                ELSE LOWER(LTRIM(RTRIM(official_email)))
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

            -- city: proper case
            CASE
                WHEN city IS NULL
                  OR UPPER(LTRIM(RTRIM(city))) IN ('NULL','N/A','')
                THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(city)),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(city)),2,100))
            END,

            -- state: proper case
            CASE
                WHEN state IS NULL
                  OR UPPER(LTRIM(RTRIM(state))) IN ('NULL','N/A','')
                THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(state)),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(state)),2,100))
            END,

            -- address: NA → NULL
            CASE
                WHEN address IS NULL
                  OR UPPER(LTRIM(RTRIM(address))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(address))
            END,

            -- department: NULL trim
            CASE
                WHEN department IS NULL
                  OR UPPER(LTRIM(RTRIM(department))) IN ('NULL','N/A','')
                THEN NULL
                ELSE LTRIM(RTRIM(department))
            END,

            -- designation: trim only
            LTRIM(RTRIM(designation)),

            -- joining_date: multi-format → DATE, "Active" → NULL
            CASE
                WHEN joining_date IS NULL
                  OR UPPER(LTRIM(RTRIM(joining_date))) IN ('NULL','N/A','NA','ACTIVE','')
                THEN NULL
                ELSE TRY_CONVERT(DATE, LTRIM(RTRIM(joining_date)), 105)
            END,

            -- exit_date: "Active"/NA → NULL, rest → DATE
            CASE
                WHEN exit_date IS NULL
                  OR UPPER(LTRIM(RTRIM(exit_date))) IN ('NULL','N/A','NA','ACTIVE','')
                THEN NULL
                ELSE TRY_CONVERT(DATE, LTRIM(RTRIM(exit_date)), 105)
            END,

            -- employment_status: trim + NULL
            CASE
                WHEN employment_status IS NULL
                  OR UPPER(LTRIM(RTRIM(employment_status))) IN ('NULL','N/A','')
                THEN NULL
                ELSE LTRIM(RTRIM(employment_status))
            END,

            -- employment_type: trim + NULL
            CASE
                WHEN employment_type IS NULL
                  OR UPPER(LTRIM(RTRIM(employment_type))) IN ('NULL','N/A','')
                THEN NULL
                ELSE LTRIM(RTRIM(employment_type))
            END,

            -- salary: "Confidential"/"As per CTC" → NULL
            --         "186646 PM" → strip PM → DECIMAL
            CASE
                WHEN salary IS NULL
                  OR UPPER(LTRIM(RTRIM(salary))) IN
                     ('NULL','N/A','CONFIDENTIAL','AS PER CTC','')
                THEN NULL
                ELSE TRY_CAST(
                        LTRIM(RTRIM(
                            REPLACE(REPLACE(UPPER(salary),' PM',''),' ','')
                        ))
                     AS DECIMAL(18,2))
            END,

            -- grade: trim + NULL
            CASE
                WHEN grade IS NULL
                  OR UPPER(LTRIM(RTRIM(grade))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(grade))
            END,

            -- pan_number: Applied/N/A → NULL, valid → UPPERCASE
            CASE
                WHEN pan_number IS NULL
                  OR UPPER(LTRIM(RTRIM(pan_number))) IN
                     ('NULL','N/A','APPLIED','NOT SET','NA','')
                THEN NULL
                ELSE UPPER(LTRIM(RTRIM(pan_number)))
            END,

            -- uan_number: "Not Enrolled"/"Not Submitted"/NA → NULL
            CASE
                WHEN uan_number IS NULL
                  OR UPPER(LTRIM(RTRIM(uan_number))) IN
                     ('NULL','N/A','NA','NOT ENROLLED','NOT SUBMITTED','')
                THEN NULL
                ELSE LTRIM(RTRIM(uan_number))
            END,

            -- bank_account: NA/"Not Submitted" → NULL
            CASE
                WHEN bank_account IS NULL
                  OR UPPER(LTRIM(RTRIM(bank_account))) IN
                     ('NULL','N/A','NA','NOT SUBMITTED','')
                THEN NULL
                ELSE LTRIM(RTRIM(bank_account))
            END,

            -- ifsc_code: NA → NULL, UPPERCASE, validate 11 chars
            CASE
                WHEN ifsc_code IS NULL
                  OR UPPER(LTRIM(RTRIM(ifsc_code))) IN ('NULL','N/A','NA','')
                THEN NULL
                WHEN LEN(LTRIM(RTRIM(ifsc_code))) = 11
                THEN UPPER(LTRIM(RTRIM(ifsc_code)))
                ELSE NULL
            END,

            -- bank_name: NA → NULL, trim
            CASE
                WHEN bank_name IS NULL
                  OR UPPER(LTRIM(RTRIM(bank_name))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(bank_name))
            END,

            -- manager_id: "HOD"/"NA" → NULL (not a valid EMP id)
            CASE
                WHEN manager_id IS NULL
                  OR UPPER(LTRIM(RTRIM(manager_id))) IN ('NULL','N/A','NA','HOD','')
                THEN NULL
                -- self-reference check: employee cannot be their own manager
                WHEN LTRIM(RTRIM(manager_id)) = employee_id
                THEN NULL
                ELSE LTRIM(RTRIM(manager_id))
            END,

            -- branch_location: trim + NULL
            CASE
                WHEN branch_location IS NULL
                  OR UPPER(LTRIM(RTRIM(branch_location))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(branch_location))
            END,

            -- cost_center: trim + NULL
            CASE
                WHEN cost_center IS NULL
                  OR UPPER(LTRIM(RTRIM(cost_center))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(cost_center))
            END,

            -- remarks: trim + NULL
            CASE
                WHEN remarks IS NULL
                  OR UPPER(LTRIM(RTRIM(remarks))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE LTRIM(RTRIM(remarks))
            END,

            -- Metadata columns
            GETDATE(),
            GETDATE(),
            'ERP',
            'bronze.erp_employees',
            @batch_id,
            1,
            HASHBYTES('SHA2_256',
                ISNULL(employee_id,'')   + '|' +
                ISNULL(first_name,'')    + '|' +
                ISNULL(last_name,'')     + '|' +
                ISNULL(pan_number,'')    + '|' +
                ISNULL(uan_number,'')    + '|' +
                ISNULL(bank_account,'')
            )

        FROM bronze.erp_employees;

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

PRINT 'Procedure silver.load_erp_employees created successfully';
PRINT '============================================================';


EXEC silver.load_erp_employees;