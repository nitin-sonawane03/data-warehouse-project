CREATE OR ALTER PROCEDURE silver.load_support_tickets
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @batch_id   NVARCHAR(50)  = CONVERT(NVARCHAR(50), NEWID());
    DECLARE @proc_name  NVARCHAR(100) = 'silver.load_support_tickets';
    DECLARE @start_time DATETIME      = GETDATE();
    DECLARE @rows_inserted INT        = 0;
    DECLARE @error_msg  NVARCHAR(MAX);

    BEGIN TRY
        PRINT '============================================================';
        PRINT 'Starting: ' + @proc_name;
        PRINT 'Batch ID: ' + @batch_id;
        PRINT 'Start Time: ' + CONVERT(NVARCHAR, @start_time, 120);
        PRINT '============================================================';

        IF OBJECT_ID('silver.support_tickets', 'U') IS NOT NULL
            TRUNCATE TABLE silver.support_tickets;
        ELSE BEGIN
            SET @error_msg = 'Table silver.support_tickets does not exist.';
            RAISERROR(@error_msg, 16, 1); RETURN;
        END

        INSERT INTO silver.support_tickets (
            ticket_id, customer_id, customer_name,
            ticket_type, subject, priority, status,
            opened_date, resolved_date,
            sla_breached, assigned_agent, team, channel,
            resolution_notes, rating,
            first_response_hrs, resolution_hrs,
            dwh_created_date, dwh_modified_date, dwh_source_system,
            dwh_source_table, dwh_batch_id, dwh_is_valid, dwh_record_hash
        )
        SELECT
            ticket_id,

            -- customer_id: UNKNOWN/WALK-IN/empty → NULL
            CASE
                WHEN customer_id IS NULL
                  OR UPPER(LTRIM(RTRIM(customer_id))) IN
                     ('NULL','N/A','NA','UNKNOWN','WALK-IN','')
                THEN NULL
                ELSE LTRIM(RTRIM(customer_id))
            END,

            -- customer_name: CAPS, leading spaces, dot → PROPER
            CASE
                WHEN customer_name IS NULL
                  OR LTRIM(RTRIM(customer_name)) = ''
                  OR UPPER(LTRIM(RTRIM(customer_name))) IN ('NULL','N/A')
                THEN NULL
                ELSE UPPER(LEFT(LTRIM(RTRIM(REPLACE(customer_name,'.',''))),1))
                   + LOWER(SUBSTRING(LTRIM(RTRIM(REPLACE(customer_name,'.',''))),2,200))
            END,

            -- ticket_type: trim
            CASE
                WHEN ticket_type IS NULL
                  OR UPPER(LTRIM(RTRIM(ticket_type))) IN ('NULL','N/A','')
                THEN NULL
                ELSE LTRIM(RTRIM(ticket_type))
            END,

            -- subject: trim + NULL
            CASE
                WHEN subject IS NULL
                  OR UPPER(LTRIM(RTRIM(subject))) IN ('NULL','N/A','')
                THEN NULL
                ELSE LTRIM(RTRIM(subject))
            END,

            -- priority: P1→Critical, P2→High, P3→Medium, Urgent→Urgent
            CASE
                WHEN UPPER(LTRIM(RTRIM(priority))) IN ('P1','CRITICAL') THEN 'Critical'
                WHEN UPPER(LTRIM(RTRIM(priority))) IN ('P2','HIGH')     THEN 'High'
                WHEN UPPER(LTRIM(RTRIM(priority))) IN ('P3','MEDIUM')   THEN 'Medium'
                WHEN UPPER(LTRIM(RTRIM(priority))) = 'LOW'              THEN 'Low'
                WHEN UPPER(LTRIM(RTRIM(priority))) = 'URGENT'           THEN 'Urgent'
                ELSE NULL
            END,

            LTRIM(RTRIM(status)),

            -- opened_date: multi-format → DATE
            CASE
                WHEN UPPER(LTRIM(RTRIM(opened_date))) IN ('NULL','N/A','NA','')
                  OR opened_date IS NULL
                THEN NULL
                ELSE TRY_CONVERT(DATE, LTRIM(RTRIM(opened_date)), 105)
            END,

            -- resolved_date: "Pending" → NULL
            CASE
                WHEN UPPER(LTRIM(RTRIM(resolved_date))) IN
                     ('NULL','N/A','NA','PENDING','')
                  OR resolved_date IS NULL
                THEN NULL
                ELSE TRY_CONVERT(DATE, LTRIM(RTRIM(resolved_date)), 105)
            END,

            -- sla_breached: Y/Yes → 1, N/No → 0, NA → NULL
            CASE
                WHEN UPPER(LTRIM(RTRIM(sla_breached))) IN ('Y','YES') THEN 1
                WHEN UPPER(LTRIM(RTRIM(sla_breached))) IN ('N','NO')  THEN 0
                ELSE NULL
            END,

            -- assigned_agent: PROPER case
            CASE
                WHEN assigned_agent IS NULL
                  OR UPPER(LTRIM(RTRIM(assigned_agent))) IN ('NULL','N/A','')
                THEN NULL
                ELSE LTRIM(RTRIM(assigned_agent))
            END,

            -- team: NULL/empty → NULL
            CASE
                WHEN team IS NULL
                  OR UPPER(LTRIM(RTRIM(team))) IN ('NULL','N/A','')
                THEN NULL
                ELSE LTRIM(RTRIM(team))
            END,

            -- channel: NULL/empty → NULL
            CASE
                WHEN channel IS NULL
                  OR UPPER(LTRIM(RTRIM(channel))) IN ('NULL','N/A','')
                THEN NULL
                ELSE LTRIM(RTRIM(channel))
            END,

            -- resolution_notes: trim + NULL
            CASE
                WHEN resolution_notes IS NULL
                  OR UPPER(LTRIM(RTRIM(resolution_notes))) IN ('NULL','N/A','')
                THEN NULL
                ELSE LTRIM(RTRIM(resolution_notes))
            END,

            -- rating: N/A → NULL, cast TINYINT, validate 1-5
            CASE
                WHEN rating IS NULL
                  OR UPPER(LTRIM(RTRIM(rating))) IN ('NULL','N/A','NA','')
                THEN NULL
                WHEN TRY_CAST(LTRIM(RTRIM(rating)) AS TINYINT) BETWEEN 1 AND 5
                THEN TRY_CAST(LTRIM(RTRIM(rating)) AS TINYINT)
                ELSE NULL
            END,

            -- first_response_hrs: N/A → NULL
            CASE
                WHEN first_response_hrs IS NULL
                  OR UPPER(LTRIM(RTRIM(first_response_hrs))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE TRY_CAST(LTRIM(RTRIM(first_response_hrs)) AS DECIMAL(10,2))
            END,

            -- resolution_hrs: N/A → NULL
            CASE
                WHEN resolution_hrs IS NULL
                  OR UPPER(LTRIM(RTRIM(resolution_hrs))) IN ('NULL','N/A','NA','')
                THEN NULL
                ELSE TRY_CAST(LTRIM(RTRIM(resolution_hrs)) AS DECIMAL(10,2))
            END,

            GETDATE(), GETDATE(), 'CRM', 'bronze.support_tickets',
            @batch_id, 1,
            HASHBYTES('SHA2_256',
                ISNULL(ticket_id,'')    + '|' +
                ISNULL(customer_id,'')  + '|' +
                ISNULL(status,'')       + '|' +
                ISNULL(priority,'')
            )

        FROM bronze.support_tickets;

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
PRINT 'Procedure silver.load_support_tickets created successfully';

EXEC silver.load_support_tickets;
