-- ── 1A. Monthly Revenue Trend (FY-wise) ──────────────────
SELECT
    d.financial_year,
    d.month_name,
    d.financial_month,
    COUNT(DISTINCT f.invoice_number)        AS total_invoices,
    SUM(f.invoice_total)                    AS total_revenue,
    SUM(f.amount_paid)                      AS total_collected,
    SUM(f.balance_due)                      AS total_outstanding,
    SUM(f.total_gst)                        AS total_gst_collected,
    CAST(SUM(f.amount_paid) * 100.0
         / NULLIF(SUM(f.invoice_total),0)
         AS DECIMAL(5,2))                   AS collection_pct
FROM gold.fact_sales f
JOIN gold.dim_date   d ON d.date_key = f.date_key
WHERE f.invoice_status NOT IN ('Cancelled','Credit Note Issued')
GROUP BY d.financial_year, d.month_name, d.financial_month
ORDER BY d.financial_year, d.financial_month;


-- ── 1B. Top 10 Customers by Revenue ──────────────────────
SELECT TOP 10
    c.customer_id,
    c.full_name,
    c.customer_segment,
    c.city,
    c.state,
    COUNT(DISTINCT f.invoice_number)        AS total_invoices,
    SUM(f.invoice_total)                    AS total_revenue,
    SUM(f.amount_paid)                      AS total_paid,
    SUM(f.balance_due)                      AS outstanding,
    AVG(f.invoice_total)                    AS avg_invoice_value
FROM gold.fact_sales     f
JOIN gold.dim_customers  c ON c.customer_key = f.customer_key
WHERE f.invoice_status NOT IN ('Cancelled')
GROUP BY c.customer_id, c.full_name, c.customer_segment, c.city, c.state
ORDER BY total_revenue DESC;


-- ── 1C. Revenue by Product Category ──────────────────────
SELECT
    p.category,
    COUNT(DISTINCT f.invoice_number)        AS total_invoices,
    SUM(f.quantity)                         AS total_qty_sold,
    SUM(f.invoice_total)                    AS total_revenue,
    AVG(f.unit_price)                       AS avg_unit_price,
    SUM(f.discount_amount)                  AS total_discount_given,
    CAST(SUM(f.discount_amount) * 100.0
         / NULLIF(SUM(f.invoice_total),0)
         AS DECIMAL(5,2))                   AS discount_pct
FROM gold.fact_sales    f
JOIN gold.dim_products  p ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;


-- ── 1D. Overdue Invoice Report ────────────────────────────
SELECT
    f.invoice_number,
    c.full_name,
    c.customer_segment,
    f.invoice_date,
    f.due_date,
    f.invoice_total,
    f.amount_paid,
    f.balance_due,
    f.days_overdue,
    CASE
        WHEN f.days_overdue BETWEEN 1  AND 30  THEN '1-30 days'
        WHEN f.days_overdue BETWEEN 31 AND 60  THEN '31-60 days'
        WHEN f.days_overdue BETWEEN 61 AND 90  THEN '61-90 days'
        ELSE '90+ days'
    END                                     AS aging_bucket
FROM gold.fact_sales     f
JOIN gold.dim_customers  c ON c.customer_key = f.customer_key
WHERE f.days_overdue > 0
  AND f.invoice_status NOT IN ('Paid','Cancelled')
ORDER BY f.days_overdue DESC;


-- ── 1E. Salesperson Performance ──────────────────────────
SELECT
    e.full_name                             AS sales_person,
    e.department,
    e.branch_location,
    COUNT(DISTINCT f.invoice_number)        AS total_invoices,
    SUM(f.invoice_total)                    AS total_revenue,
    SUM(f.amount_paid)                      AS total_collected,
    AVG(f.days_to_pay)                      AS avg_days_to_pay,
    CAST(SUM(f.amount_paid) * 100.0
         / NULLIF(SUM(f.invoice_total),0)
         AS DECIMAL(5,2))                   AS collection_rate_pct
FROM gold.fact_sales     f
JOIN gold.dim_employees  e ON e.employee_key = f.employee_key
GROUP BY e.full_name, e.department, e.branch_location
ORDER BY total_revenue DESC;