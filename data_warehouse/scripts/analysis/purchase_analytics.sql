-- ── 2A. Vendor Spend Analysis ─────────────────────────────
SELECT
    v.vendor_name,
    v.vendor_city,
    COUNT(DISTINCT f.po_number)             AS total_pos,
    SUM(f.total_amount)                     AS total_spend,
    AVG(f.total_amount)                     AS avg_po_value,
    AVG(f.delivery_delay_days)              AS avg_delay_days,
    SUM(CASE WHEN f.is_delayed = 1
             THEN 1 ELSE 0 END)             AS delayed_pos,
    CAST(SUM(CASE WHEN f.is_delayed = 1
                  THEN 1 ELSE 0 END) * 100.0
         / COUNT(*)
         AS DECIMAL(5,2))                   AS delay_pct
FROM gold.fact_purchases  f
JOIN gold.dim_vendors      v ON v.vendor_key = f.vendor_key
GROUP BY v.vendor_name, v.vendor_city
ORDER BY total_spend DESC;


-- ── 2B. Category-wise Purchase Summary ───────────────────
SELECT
    p.category,
    COUNT(DISTINCT f.po_number)             AS total_pos,
    SUM(f.quantity)                         AS total_qty_purchased,
    SUM(f.total_amount)                     AS total_spend,
    AVG(f.unit_price)                       AS avg_unit_price,
    AVG(f.gst_rate_pct)                     AS avg_gst_rate,
    SUM(f.total_gst)                        AS total_gst_paid
FROM gold.fact_purchases  f
JOIN gold.dim_products     p ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_spend DESC;
select distinct(warehouse_location) from gold.fact_purchases


-- ── 2C. Monthly PO Volume Trend ──────────────────────────
SELECT
    d.financial_year,
    d.month_name,
    d.financial_month,
    COUNT(DISTINCT f.po_number)             AS total_pos,
    SUM(f.total_amount)                     AS total_spend,
    AVG(f.delivery_delay_days)              AS avg_delay_days
FROM gold.fact_purchases  f
JOIN gold.dim_date         d ON d.date_key = f.date_key
GROUP BY d.financial_year, d.month_name, d.financial_month
ORDER BY d.financial_year, d.financial_month;