CREATE OR ALTER PROCEDURE gold.load_dim_date
    @start_date DATE = '2015-01-01',
    @end_date   DATE = '2030-12-31'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @proc_name  NVARCHAR(100) = 'gold.load_dim_date';
    DECLARE @start_time DATETIME      = GETDATE();
    DECLARE @error_msg  NVARCHAR(MAX);

    BEGIN TRY
        PRINT '============================================================';
        PRINT 'Starting: ' + @proc_name;

        IF OBJECT_ID('gold.dim_date','U') IS NOT NULL
            TRUNCATE TABLE gold.dim_date;
        ELSE BEGIN
            SET @error_msg = 'gold.dim_date does not exist.';
            RAISERROR(@error_msg,16,1); RETURN;
        END;

        -- Generate all dates using recursive CTE
        WITH date_series AS (
            SELECT @start_date AS d
            UNION ALL
            SELECT DATEADD(DAY,1,d)
            FROM date_series
            WHERE d < @end_date
        )
        INSERT INTO gold.dim_date (
            date_key, full_date,
            day_of_week, day_name,
            day_of_month, day_of_year, week_of_year,
            month_number, month_name, month_short,
            quarter_number, quarter_name, year_number,
            financial_year, financial_quarter, financial_month,
            is_weekend, is_month_start, is_month_end,
            is_quarter_start, is_quarter_end,
            is_fy_start, is_fy_end
        )
        SELECT
            CAST(FORMAT(d,'yyyyMMdd') AS INT)       AS date_key,
            d                                        AS full_date,
            -- Day
            CASE DATENAME(WEEKDAY,d)
                WHEN 'Monday'    THEN 1 WHEN 'Tuesday'   THEN 2
                WHEN 'Wednesday' THEN 3 WHEN 'Thursday'  THEN 4
                WHEN 'Friday'    THEN 5 WHEN 'Saturday'  THEN 6
                ELSE 7 END                           AS day_of_week,
            DATENAME(WEEKDAY,d)                      AS day_name,
            DAY(d)                                   AS day_of_month,
            DATEPART(DAYOFYEAR,d)                    AS day_of_year,
            DATEPART(WEEK,d)                         AS week_of_year,
            -- Month
            MONTH(d)                                 AS month_number,
            DATENAME(MONTH,d)                        AS month_name,
            LEFT(DATENAME(MONTH,d),3)                AS month_short,
            -- Quarter
            DATEPART(QUARTER,d)                      AS quarter_number,
            'Q' + CAST(DATEPART(QUARTER,d) AS NCHAR(1)) AS quarter_name,
            YEAR(d)                                  AS year_number,
            -- Indian Financial Year (Apr–Mar)
            CASE WHEN MONTH(d) >= 4
                 THEN 'FY' + CAST(YEAR(d)   AS VARCHAR(4))
                           + '-' + RIGHT(CAST(YEAR(d)+1 AS VARCHAR(4)),2)
                 ELSE 'FY' + CAST(YEAR(d)-1 AS VARCHAR(4))
                           + '-' + RIGHT(CAST(YEAR(d)   AS VARCHAR(4)),2)
            END                                      AS financial_year,
            -- FY Quarter (Q1=Apr-Jun, Q2=Jul-Sep, Q3=Oct-Dec, Q4=Jan-Mar)
            CASE
                WHEN MONTH(d) IN (4,5,6)   THEN 'Q1'
                WHEN MONTH(d) IN (7,8,9)   THEN 'Q2'
                WHEN MONTH(d) IN (10,11,12) THEN 'Q3'
                ELSE 'Q4'
            END                                      AS financial_quarter,
            -- FY Month (1=Apr … 12=Mar)
            CASE WHEN MONTH(d) >= 4
                 THEN MONTH(d) - 3
                 ELSE MONTH(d) + 9
            END                                      AS financial_month,
            -- Flags
            CASE WHEN DATENAME(WEEKDAY,d) IN ('Saturday','Sunday')
                 THEN 1 ELSE 0 END                  AS is_weekend,
            CASE WHEN DAY(d) = 1 THEN 1 ELSE 0 END  AS is_month_start,
            CASE WHEN d = EOMONTH(d) THEN 1 ELSE 0 END AS is_month_end,
            CASE WHEN DAY(d) = 1
                  AND MONTH(d) IN (1,4,7,10)
                 THEN 1 ELSE 0 END                  AS is_quarter_start,
            CASE WHEN d = EOMONTH(d)
                  AND MONTH(d) IN (3,6,9,12)
                 THEN 1 ELSE 0 END                  AS is_quarter_end,
            CASE WHEN MONTH(d) = 4 AND DAY(d) = 1
                 THEN 1 ELSE 0 END                  AS is_fy_start,
            CASE WHEN MONTH(d) = 3 AND DAY(d) = 31
                 THEN 1 ELSE 0 END                  AS is_fy_end
        FROM date_series
        OPTION (MAXRECURSION 10000);

        PRINT 'Rows Inserted : ' + CAST(@@ROWCOUNT AS NVARCHAR);
        PRINT 'Duration      : ' + CAST(DATEDIFF(SECOND,@start_time,GETDATE()) AS NVARCHAR) + 's';
        PRINT '============================================================';

    END TRY
    BEGIN CATCH
        SET @error_msg = 'ERROR in ' + @proc_name + CHAR(13)
            + 'Line: '    + CAST(ERROR_LINE()    AS NVARCHAR) + CHAR(13)
            + 'Message: ' + ERROR_MESSAGE();
        PRINT @error_msg; RAISERROR(@error_msg,16,1);
    END CATCH
END;
GO


-- ── 2. dim_customers ────────────────────────────────────
CREATE OR ALTER PROCEDURE gold.load_dim_customers
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @batch_id  NVARCHAR(50) = CONVERT(NVARCHAR(50),NEWID());
    DECLARE @start_time DATETIME    = GETDATE();
    DECLARE @error_msg  NVARCHAR(MAX);

    BEGIN TRY
        PRINT 'Starting: gold.load_dim_customers | Batch: ' + @batch_id;

        IF OBJECT_ID('gold.dim_customers','U') IS NOT NULL
            TRUNCATE TABLE gold.dim_customers;

        INSERT INTO gold.dim_customers (
            customer_id, full_name, first_name, last_name,
            gender, dob, email, phone,
            city, state, pincode, country,
            company, industry, customer_segment,
            lead_source, assigned_to,
            gst_number, pan_number,
            payment_terms, credit_limit, lifetime_value, is_active
        )
        SELECT
            customer_id,
            full_name, first_name, last_name,
            gender, dob, email, phone,
            city, state, pincode, country,
            company, industry, customer_segment,
            lead_source, assigned_to,
            gst_number, pan_number,
            payment_terms, credit_limit, lifetime_value, is_active
        FROM silver.crm_customers;

        PRINT 'Rows: ' + CAST(@@ROWCOUNT AS NVARCHAR)
            + ' | Duration: ' + CAST(DATEDIFF(SECOND,@start_time,GETDATE()) AS NVARCHAR) + 's';

    END TRY
    BEGIN CATCH
        SET @error_msg = 'ERROR gold.load_dim_customers: ' + ERROR_MESSAGE();
        PRINT @error_msg; RAISERROR(@error_msg,16,1);
    END CATCH
END;
GO


-- ── 3. dim_products ─────────────────────────────────────
CREATE OR ALTER PROCEDURE gold.load_dim_products
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME = GETDATE();
    DECLARE @error_msg  NVARCHAR(MAX);

    BEGIN TRY
        PRINT 'Starting: gold.load_dim_products';

        IF OBJECT_ID('gold.dim_products','U') IS NOT NULL
            TRUNCATE TABLE gold.dim_products;

        -- Distinct products from inventory (latest record per product_code)
        INSERT INTO gold.dim_products (
            product_code, product_name, category,
            unit_cost, mrp, reorder_level, quality_status
        )
        SELECT
            product_code,
            -- If same product_code has multiple names, take most common
            MAX(product_name)       AS product_name,
            MAX(category)           AS category,
            AVG(unit_cost)          AS unit_cost,
            AVG(mrp)                AS mrp,
            AVG(reorder_level)      AS reorder_level,
            MAX(quality_status)     AS quality_status
        FROM silver.erp_inventory
        WHERE product_code IS NOT NULL
        GROUP BY product_code;

        PRINT 'Rows: ' + CAST(@@ROWCOUNT AS NVARCHAR)
            + ' | Duration: ' + CAST(DATEDIFF(SECOND,@start_time,GETDATE()) AS NVARCHAR) + 's';

    END TRY
    BEGIN CATCH
        SET @error_msg = 'ERROR gold.load_dim_products: ' + ERROR_MESSAGE();
        PRINT @error_msg; RAISERROR(@error_msg,16,1);
    END CATCH
END;
GO


-- ── 4. dim_employees ────────────────────────────────────
CREATE OR ALTER PROCEDURE gold.load_dim_employees
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME = GETDATE();
    DECLARE @error_msg  NVARCHAR(MAX);

    BEGIN TRY
        PRINT 'Starting: gold.load_dim_employees';

        IF OBJECT_ID('gold.dim_employees','U') IS NOT NULL
            TRUNCATE TABLE gold.dim_employees;

        INSERT INTO gold.dim_employees (
            employee_id, full_name, first_name, last_name,
            gender, dob, department, designation, grade,
            employment_status, employment_type,
            joining_date, exit_date, salary,
            city, state, branch_location, manager_id
        )
        SELECT
            employee_id, full_name, first_name, last_name,
            gender, dob, department, designation, grade,
            employment_status, employment_type,
            joining_date, exit_date, salary,
            city, state, branch_location, manager_id
        FROM silver.erp_employees;

        PRINT 'Rows: ' + CAST(@@ROWCOUNT AS NVARCHAR)
            + ' | Duration: ' + CAST(DATEDIFF(SECOND,@start_time,GETDATE()) AS NVARCHAR) + 's';

    END TRY
    BEGIN CATCH
        SET @error_msg = 'ERROR gold.load_dim_employees: ' + ERROR_MESSAGE();
        PRINT @error_msg; RAISERROR(@error_msg,16,1);
    END CATCH
END;
GO


-- ── 5. dim_vendors ──────────────────────────────────────
CREATE OR ALTER PROCEDURE gold.load_dim_vendors
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME = GETDATE();
    DECLARE @error_msg  NVARCHAR(MAX);

    BEGIN TRY
        PRINT 'Starting: gold.load_dim_vendors';

        IF OBJECT_ID('gold.dim_vendors','U') IS NOT NULL
            TRUNCATE TABLE gold.dim_vendors;

        INSERT INTO gold.dim_vendors (
            vendor_id, vendor_name, vendor_gstin, vendor_city,
            total_orders, total_spend, avg_delivery_delay
        )
        SELECT
            vendor_id,
            MAX(vendor_name)                                    AS vendor_name,
            MAX(vendor_gstin)                                   AS vendor_gstin,
            MAX(vendor_city)                                    AS vendor_city,
            COUNT(*)                                            AS total_orders,
            SUM(ISNULL(total_amount,0))                         AS total_spend,
            AVG(DATEDIFF(DAY,expected_delivery,actual_delivery)) AS avg_delivery_delay
        FROM silver.erp_purchase_orders
        WHERE vendor_id IS NOT NULL
        GROUP BY vendor_id;

        PRINT 'Rows: ' + CAST(@@ROWCOUNT AS NVARCHAR)
            + ' | Duration: ' + CAST(DATEDIFF(SECOND,@start_time,GETDATE()) AS NVARCHAR) + 's';

    END TRY
    BEGIN CATCH
        SET @error_msg = 'ERROR gold.load_dim_vendors: ' + ERROR_MESSAGE();
        PRINT @error_msg; RAISERROR(@error_msg,16,1);
    END CATCH
END;
GO


-- ── 6. fact_sales ───────────────────────────────────────
CREATE OR ALTER PROCEDURE gold.load_fact_sales
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @batch_id   NVARCHAR(50) = CONVERT(NVARCHAR(50),NEWID());
    DECLARE @start_time DATETIME     = GETDATE();
    DECLARE @error_msg  NVARCHAR(MAX);

    BEGIN TRY
        PRINT 'Starting: gold.load_fact_sales | Batch: ' + @batch_id;

        IF OBJECT_ID('gold.fact_sales','U') IS NOT NULL
            TRUNCATE TABLE gold.fact_sales;

        INSERT INTO gold.fact_sales (
            date_key, customer_key, product_key, employee_key,
            invoice_number, financial_year,
            payment_mode, channel, region, branch, invoice_status,
            quantity, unit_price, discount_amount, taxable_value,
            gst_rate, cgst_amount, sgst_amount, igst_amount,
            invoice_total, amount_paid, balance_due,
            tds_amount, tds_applicable,
            invoice_date, due_date, payment_date,
            dwh_batch_id
        )
        SELECT
            -- date_key: join to dim_date
            dd.date_key,
            -- customer_key: join to dim_customers
            dc.customer_key,
            -- product_key: join to dim_products
            dp.product_key,
            -- employee_key: match sales_person name to dim_employees full_name
            de.employee_key,
            -- Degenerate dims
            s.invoice_number,
            s.financial_year,
            s.payment_mode,
            s.channel,
            s.region,
            s.branch,
            s.status                    AS invoice_status,
            -- Measures
            s.quantity,
            s.unit_price,
            s.discount_amount,
            s.taxable_value,
            s.gst_rate,
            s.cgst_amount,
            s.sgst_amount,
            s.igst_amount,
            s.invoice_total,
            s.amount_paid,
            s.balance_due,
            s.tds_amount,
            s.tds_applicable,
            -- Dates
            s.invoice_date,
            s.due_date,
            s.payment_date,
            @batch_id
        FROM silver.erp_sales_invoices s
        -- Join to dim_date on invoice_date
        LEFT JOIN gold.dim_date       dd ON dd.full_date   = s.invoice_date
        -- Join to dim_customers on customer_id
        LEFT JOIN gold.dim_customers  dc ON dc.customer_id = s.customer_id
        -- Join to dim_products on product_code
        LEFT JOIN gold.dim_products   dp ON dp.product_code= s.product_code
        -- Join to dim_employees on sales_person name
        LEFT JOIN gold.dim_employees  de ON de.full_name   = s.sales_person;

        PRINT 'Rows: ' + CAST(@@ROWCOUNT AS NVARCHAR)
            + ' | Duration: ' + CAST(DATEDIFF(SECOND,@start_time,GETDATE()) AS NVARCHAR) + 's';

    END TRY
    BEGIN CATCH
        SET @error_msg = 'ERROR gold.load_fact_sales: ' + ERROR_MESSAGE();
        PRINT @error_msg; RAISERROR(@error_msg,16,1);
    END CATCH
END;
GO


-- ── 7. fact_purchases ───────────────────────────────────
CREATE OR ALTER PROCEDURE gold.load_fact_purchases
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @batch_id   NVARCHAR(50) = CONVERT(NVARCHAR(50),NEWID());
    DECLARE @start_time DATETIME     = GETDATE();
    DECLARE @error_msg  NVARCHAR(MAX);

    BEGIN TRY
        PRINT 'Starting: gold.load_fact_purchases | Batch: ' + @batch_id;

        IF OBJECT_ID('gold.fact_purchases','U') IS NOT NULL
            TRUNCATE TABLE gold.fact_purchases;

        INSERT INTO gold.fact_purchases (
            date_key, product_key, vendor_key,
            po_number, purchase_type, department,
            cost_center, warehouse_location, po_status,
            currency, payment_terms,
            quantity, unit_price, discount_pct,
            taxable_amount, gst_rate_pct, cgst, sgst, igst,
            total_amount,
            po_date, expected_delivery, actual_delivery,
            dwh_batch_id
        )
        SELECT
            dd.date_key,
            dp.product_key,
            dv.vendor_key,
            p.po_number,
            p.purchase_type,
            p.department,
            p.cost_center,
            p.warehouse_location,
            p.status                    AS po_status,
            p.currency,
            p.payment_terms,
            p.quantity,
            p.unit_price,
            p.discount_pct,
            p.taxable_amount,
            p.gst_rate_pct,
            p.cgst, p.sgst, p.igst,
            p.total_amount,
            p.po_date,
            p.expected_delivery,
            p.actual_delivery,
            @batch_id
        FROM silver.erp_purchase_orders p
        LEFT JOIN gold.dim_date     dd ON dd.full_date    = p.po_date
        LEFT JOIN gold.dim_products dp ON dp.product_code = p.product_code
        LEFT JOIN gold.dim_vendors  dv ON dv.vendor_id    = p.vendor_id;

        PRINT 'Rows: ' + CAST(@@ROWCOUNT AS NVARCHAR)
            + ' | Duration: ' + CAST(DATEDIFF(SECOND,@start_time,GETDATE()) AS NVARCHAR) + 's';

    END TRY
    BEGIN CATCH
        SET @error_msg = 'ERROR gold.load_fact_purchases: ' + ERROR_MESSAGE();
        PRINT @error_msg; RAISERROR(@error_msg,16,1);
    END CATCH
END;
GO


-- ── 8. fact_support ─────────────────────────────────────
CREATE OR ALTER PROCEDURE gold.load_fact_support
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @batch_id   NVARCHAR(50) = CONVERT(NVARCHAR(50),NEWID());
    DECLARE @start_time DATETIME     = GETDATE();
    DECLARE @error_msg  NVARCHAR(MAX);

    BEGIN TRY
        PRINT 'Starting: gold.load_fact_support | Batch: ' + @batch_id;

        IF OBJECT_ID('gold.fact_support','U') IS NOT NULL
            TRUNCATE TABLE gold.fact_support;

        INSERT INTO gold.fact_support (
            date_key, customer_key, employee_key,
            ticket_id, ticket_type, subject,
            priority, ticket_status, team, channel, resolution_notes,
            rating, first_response_hrs, resolution_hrs,
            sla_breached, opened_date, resolved_date,
            dwh_batch_id
        )
        SELECT
            dd.date_key,
            dc.customer_key,
            de.employee_key,
            t.ticket_id,
            t.ticket_type,
            t.subject,
            t.priority,
            t.status                    AS ticket_status,
            t.team,
            t.channel,
            t.resolution_notes,
            t.rating,
            t.first_response_hrs,
            t.resolution_hrs,
            t.sla_breached,
            t.opened_date,
            t.resolved_date,
            @batch_id
        FROM silver.support_tickets t
        LEFT JOIN gold.dim_date      dd ON dd.full_date   = t.opened_date
        LEFT JOIN gold.dim_customers dc ON dc.customer_id = t.customer_id
        LEFT JOIN gold.dim_employees de ON de.full_name   = t.assigned_agent;

        PRINT 'Rows: ' + CAST(@@ROWCOUNT AS NVARCHAR)
            + ' | Duration: ' + CAST(DATEDIFF(SECOND,@start_time,GETDATE()) AS NVARCHAR) + 's';

    END TRY
    BEGIN CATCH
        SET @error_msg = 'ERROR gold.load_fact_support: ' + ERROR_MESSAGE();
        PRINT @error_msg; RAISERROR(@error_msg,16,1);
    END CATCH
END;
GO


-- ── 9. fact_leads ───────────────────────────────────────
CREATE OR ALTER PROCEDURE gold.load_fact_leads
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @batch_id   NVARCHAR(50) = CONVERT(NVARCHAR(50),NEWID());
    DECLARE @start_time DATETIME     = GETDATE();
    DECLARE @error_msg  NVARCHAR(MAX);

    BEGIN TRY
        PRINT 'Starting: gold.load_fact_leads | Batch: ' + @batch_id;

        IF OBJECT_ID('gold.fact_leads','U') IS NOT NULL
            TRUNCATE TABLE gold.fact_leads;

        INSERT INTO gold.fact_leads (
            date_key, customer_key, employee_key,
            lead_id, lead_source, lead_status, stage,
            product_interest, city, state, country, campaign_id,
            expected_value, probability_pct,
            converted, converted_customer_id,
            lead_date, follow_up_date,
            dwh_batch_id
        )
        SELECT
            dd.date_key,
            -- If converted, link to dim_customers via converted_customer_id
            dc.customer_key,
            de.employee_key,
            l.lead_id,
            l.lead_source,
            l.status                    AS lead_status,
            l.stage,
            l.product_interest,
            l.city, l.state, l.country,
            l.campaign_id,
            l.expected_value,
            l.probability_pct,
            l.converted,
            l.converted_customer_id,
            l.lead_date,
            l.follow_up_date,
            @batch_id
        FROM silver.crm_leads l
        LEFT JOIN gold.dim_date      dd ON dd.full_date   = l.lead_date
        LEFT JOIN gold.dim_customers dc ON dc.customer_id = l.converted_customer_id
        LEFT JOIN gold.dim_employees de ON de.full_name   = l.assigned_to;

        PRINT 'Rows: ' + CAST(@@ROWCOUNT AS NVARCHAR)
            + ' | Duration: ' + CAST(DATEDIFF(SECOND,@start_time,GETDATE()) AS NVARCHAR) + 's';

    END TRY
    BEGIN CATCH
        SET @error_msg = 'ERROR gold.load_fact_leads: ' + ERROR_MESSAGE();
        PRINT @error_msg; RAISERROR(@error_msg,16,1);
    END CATCH
END;
GO
PRINT 'All Gold Layer procedures created successfully'
PRINT '============================================================'