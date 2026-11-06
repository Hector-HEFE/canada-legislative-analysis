
-- Count populated and missing values across all 135 columns
SELECT
    x.key AS column_name,
    COUNT(*) FILTER (
        WHERE x.value IS NOT NULL
        AND TRIM(x.value) <> ''
    ) AS populated_rows,
    COUNT(*) FILTER (
        WHERE x.value IS NULL
        OR TRIM(x.value) = ''
    ) AS missing_rows,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE x.value IS NOT NULL
            AND TRIM(x.value) <> ''
        ) / COUNT(*),
        1
    ) AS populated_percentage
FROM public.bills_staging b
CROSS JOIN LATERAL jsonb_each_text(to_jsonb(b)) AS x(key, value)
GROUP BY x.key
ORDER BY populated_percentage ASC, column_name;



-- Inspect the values and frequency of key categorical fields
SELECT
    'Bill status' AS field,
    status_name_en AS value,
    COUNT(*) AS records
FROM public.bills_staging
GROUP BY status_name_en

UNION ALL

SELECT
    'Bill type',
    bill_document_type_name_en,
    COUNT(*)
FROM public.bills_staging
GROUP BY bill_document_type_name_en

UNION ALL

SELECT
    'Government bill',
    is_government_bill,
    COUNT(*)
FROM public.bills_staging
GROUP BY is_government_bill

UNION ALL

SELECT
    'Originating chamber',
    originating_chamber_name_en,
    COUNT(*)
FROM public.bills_staging
GROUP BY originating_chamber_name_en

UNION ALL

SELECT
    'Bill form',
    bill_form_name_en,
    COUNT(*)
FROM public.bills_staging
GROUP BY bill_form_name_en

ORDER BY field, records DESC;


-- Let's see what the nested fields actually look like
SELECT
    id,
    number_code,
    bill_stages,
    house_vote_details,
    senate_vote_details,
    publications
FROM public.bills_staging
LIMIT 3;
