SELECT TOP 100

    customer_id,

    CASE
        WHEN UPPER(LTRIM(RTRIM(first_name))) IN ('NULL','N/A','')
          OR first_name IS NULL
        THEN NULL
        ELSE UPPER(LEFT(LTRIM(RTRIM(REPLACE(first_name,'.',''))),1))
           + LOWER(SUBSTRING(LTRIM(RTRIM(REPLACE(first_name,'.',''))),2,100))
    END AS first_name,

    CASE
        WHEN UPPER(LTRIM(RTRIM(last_name))) IN ('NULL','N/A','')
          OR last_name IS NULL
        THEN NULL
        ELSE UPPER(LEFT(LTRIM(RTRIM(REPLACE(last_name,'.',''))),1))
           + LOWER(SUBSTRING(LTRIM(RTRIM(REPLACE(last_name,'.',''))),2,100))
    END AS last_name,

    CASE
        WHEN UPPER(LTRIM(RTRIM(gender))) IN ('M','MALE')       THEN 'Male'
        WHEN UPPER(LTRIM(RTRIM(gender))) IN ('F','FEMALE')     THEN 'Female'
        WHEN UPPER(LTRIM(RTRIM(gender))) IN ('OTHER','T')      THEN 'Other'
        WHEN UPPER(LTRIM(RTRIM(gender))) IN ('NOT SPECIFIED')  THEN 'Not Specified'
        ELSE NULL
    END AS gender,

    TRY_CONVERT(DATE, LTRIM(RTRIM(dob)), 105) AS dob,

    CASE
        WHEN email IS NULL
          OR UPPER(LTRIM(RTRIM(email))) IN ('NULL','N/A','NOT PROVIDED','#N/A')
          OR LOWER(LTRIM(RTRIM(email))) IN ('na@na.com','test@test','not provided')
          OR email NOT LIKE '%@%.%'
        THEN NULL
        ELSE LOWER(LTRIM(RTRIM(email)))
    END AS email,

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
    END AS phone,

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
    END AS alternate_phone,

    CASE
        WHEN LTRIM(RTRIM(city)) IN ('-','','NA') OR city IS NULL THEN NULL
        ELSE UPPER(LEFT(LTRIM(RTRIM(city)),1)) + LOWER(SUBSTRING(LTRIM(RTRIM(city)),2,100))
    END AS city,

    CASE
        WHEN UPPER(LTRIM(RTRIM(state))) IN ('NULL','N/A','') OR state IS NULL THEN NULL
        ELSE UPPER(LEFT(LTRIM(RTRIM(state)),1)) + LOWER(SUBSTRING(LTRIM(RTRIM(state)),2,100))
    END AS state,

    CASE
        WHEN REPLACE(LTRIM(RTRIM(pincode)),' ','') IN ('000000','','NULL','N/A')
          OR pincode IS NULL THEN NULL
        WHEN LEN(REPLACE(LTRIM(RTRIM(pincode)),' ','')) = 6
         AND REPLACE(LTRIM(RTRIM(pincode)),' ','') NOT LIKE '%[^0-9]%'
        THEN REPLACE(LTRIM(RTRIM(pincode)),' ','')
        ELSE NULL
    END AS pincode,

    CASE
        WHEN UPPER(LTRIM(RTRIM(country))) IN ('INDIA','IN','IND','BHARAT','HIND') THEN 'India'
        WHEN country IS NULL
          OR UPPER(LTRIM(RTRIM(country))) IN ('NULL','N/A','') THEN NULL
        ELSE LTRIM(RTRIM(country))
    END AS country,

    -- address_line1 — "NA", "Same as above", "-" → NULL
    CASE
        WHEN UPPER(LTRIM(RTRIM(address_line1))) IN ('NULL','N/A','NA','SAME AS ABOVE',
                                                     'SAME ABOVE','-','')
          OR address_line1 IS NULL
        THEN NULL
        ELSE LTRIM(RTRIM(address_line1))
    END AS address_line1,

    -- company — trim + NULL junk
    CASE
        WHEN UPPER(LTRIM(RTRIM(company))) IN ('NULL','N/A','NA','')
          OR company IS NULL
        THEN NULL
        ELSE LTRIM(RTRIM(company))
    END AS company,

    -- industry — trim + NULL
    CASE
        WHEN UPPER(LTRIM(RTRIM(industry))) IN ('NULL','N/A','NA','UNKNOWN','')
          OR industry IS NULL
        THEN NULL
        ELSE LTRIM(RTRIM(industry))
    END AS industry,

    -- annual_revenue — "5.0 Lakh" → number
    CASE
        WHEN annual_revenue IS NULL
          OR UPPER(LTRIM(RTRIM(annual_revenue))) IN ('NULL','N/A','CONFIDENTIAL','')
        THEN NULL
        WHEN UPPER(annual_revenue) LIKE '% LAKH'
        THEN TRY_CAST(
                REPLACE(REPLACE(UPPER(LTRIM(RTRIM(annual_revenue))),' LAKH',''),' ','')
             AS DECIMAL(18,2)) * 100000
        ELSE TRY_CAST(LTRIM(RTRIM(annual_revenue)) AS DECIMAL(18,2))
    END AS annual_revenue,

    -- employee_count — N/A → NULL
    CASE
        WHEN UPPER(LTRIM(RTRIM(employee_count))) IN ('NULL','N/A','NA','')
          OR employee_count IS NULL
        THEN NULL
        ELSE TRY_CAST(LTRIM(RTRIM(employee_count)) AS INT)
    END AS employee_count,

    LTRIM(RTRIM(lead_source))  AS lead_source,
    LTRIM(RTRIM(lead_status))  AS lead_status,
    LTRIM(RTRIM(assigned_to))  AS assigned_to,

    TRY_CONVERT(DATE, LTRIM(RTRIM(created_date)), 105)      AS created_date,

    CASE
        WHEN UPPER(LTRIM(RTRIM(last_contact_date))) IN ('NULL','N/A','NA','NOT YET','TBD','')
          OR last_contact_date IS NULL
        THEN NULL
        ELSE TRY_CONVERT(DATE, LTRIM(RTRIM(last_contact_date)), 105)
    END AS last_contact_date,

    CASE
        WHEN UPPER(LTRIM(RTRIM(next_followup))) IN ('NULL','N/A','NA','NOT YET','TBD','')
          OR next_followup IS NULL
        THEN NULL
        ELSE TRY_CONVERT(DATE, LTRIM(RTRIM(next_followup)), 105)
    END AS next_followup,

    CASE
        WHEN gst_number IS NULL
          OR UPPER(LTRIM(RTRIM(gst_number))) IN ('NULL','N/A','GSTIN PENDING','EXEMPT',
                                                  'NOT REGISTERED','APPLIED','')
        THEN NULL
        ELSE UPPER(LTRIM(RTRIM(gst_number)))
    END AS gst_number,

    CASE
        WHEN pan_number IS NULL
          OR UPPER(LTRIM(RTRIM(pan_number))) IN ('NULL','N/A','APPLIED','NOT SET','')
        THEN NULL
        ELSE UPPER(LTRIM(RTRIM(pan_number)))
    END AS pan_number,

    CASE
        WHEN credit_limit IS NULL
          OR UPPER(LTRIM(RTRIM(credit_limit))) IN ('NULL','N/A','NOT SET','NA','')
        THEN NULL
        ELSE TRY_CAST(LTRIM(RTRIM(credit_limit)) AS DECIMAL(18,2))
    END AS credit_limit,

    CASE
        WHEN UPPER(LTRIM(RTRIM(payment_terms))) IN ('NULL','N/A','NA','NOT SET','')
          OR payment_terms IS NULL
        THEN NULL
        ELSE LTRIM(RTRIM(payment_terms))
    END AS payment_terms,

    CASE
        WHEN UPPER(LTRIM(RTRIM(customer_segment))) IN ('NULL','N/A','')
          OR customer_segment IS NULL
        THEN NULL
        ELSE LTRIM(RTRIM(customer_segment))
    END AS customer_segment,

    -- lifetime_value — 0 rakho, N/A → NULL
    CASE
        WHEN UPPER(LTRIM(RTRIM(lifetime_value))) IN ('NULL','N/A','NA','')
          OR lifetime_value IS NULL
        THEN NULL
        ELSE TRY_CAST(LTRIM(RTRIM(lifetime_value)) AS DECIMAL(18,2))
    END AS lifetime_value,

    -- notes — trim only, keep as-is
    CASE
        WHEN UPPER(LTRIM(RTRIM(notes))) IN ('NULL','N/A','NA','')
          OR notes IS NULL
        THEN NULL
        ELSE LTRIM(RTRIM(notes))
    END AS notes,

    CASE
        WHEN UPPER(LTRIM(RTRIM(is_active))) IN ('Y','YES','1','ACTIVE')  THEN 1
        WHEN UPPER(LTRIM(RTRIM(is_active))) IN ('N','NO','0','INACTIVE') THEN 0
        ELSE NULL
    END AS is_active

FROM bronze.crm_customers;