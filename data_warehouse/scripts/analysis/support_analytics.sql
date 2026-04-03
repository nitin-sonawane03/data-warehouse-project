-- ── 3A. Ticket Volume & Resolution Summary ───────────────
SELECT
    d.financial_year,
    d.month_name,
    d.financial_month,
    COUNT(*)                                AS total_tickets,
    SUM(f.is_resolved)                      AS resolved,
    COUNT(*) - SUM(f.is_resolved)           AS pending,
    AVG(f.first_response_hrs)               AS avg_first_response_hrs,
    AVG(f.resolution_hrs)                   AS avg_resolution_hrs,
    SUM(f.sla_breached)                     AS sla_breaches,
    CAST(SUM(f.sla_breached) * 100.0
         / COUNT(*) AS DECIMAL(5,2))        AS sla_breach_pct,
    AVG(CAST(f.rating AS DECIMAL(4,2)))     AS avg_csat_rating
FROM gold.fact_support  f
JOIN gold.dim_date       d ON d.date_key = f.date_key
GROUP BY d.financial_year, d.month_name, d.financial_month
ORDER BY d.financial_year, d.financial_month;


-- ── 3B. Priority-wise SLA Performance ────────────────────
SELECT
    f.priority,
    COUNT(*)                                AS total_tickets,
    SUM(f.sla_breached)                     AS sla_breached,
    CAST(SUM(f.sla_breached) * 100.0
         / COUNT(*) AS DECIMAL(5,2))        AS breach_pct,
    AVG(f.first_response_hrs)               AS avg_first_response_hrs,
    AVG(f.resolution_hrs)                   AS avg_resolution_hrs,
    AVG(CAST(f.rating AS DECIMAL(4,2)))     AS avg_rating
FROM gold.fact_support
GROUP BY priority
ORDER BY
    CASE priority
        WHEN 'Critical' THEN 1
        WHEN 'High'     THEN 2
        WHEN 'Medium'   THEN 3
        WHEN 'Low'      THEN 4
        ELSE 5 END;


-- ── 3C. Agent Performance ────────────────────────────────
SELECT
    e.full_name                             AS agent_name,
    e.team,
    COUNT(*)                                AS total_tickets,
    SUM(f.is_resolved)                      AS resolved,
    CAST(SUM(f.is_resolved) * 100.0
         / COUNT(*) AS DECIMAL(5,2))        AS resolution_rate_pct,
    AVG(f.first_response_hrs)               AS avg_response_hrs,
    AVG(f.resolution_hrs)                   AS avg_resolution_hrs,
    SUM(f.sla_breached)                     AS sla_breaches,
    AVG(CAST(f.rating AS DECIMAL(4,2)))     AS avg_csat
FROM gold.fact_support   f
JOIN gold.dim_employees  e ON e.employee_key = f.employee_key
GROUP BY e.full_name, e.team
ORDER BY total_tickets DESC;