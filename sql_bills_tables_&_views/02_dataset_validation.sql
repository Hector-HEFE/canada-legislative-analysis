
-- Total records and unique bill IDs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT id) AS unique_bill_ids,
    COUNT(*) - COUNT(DISTINCT id) AS duplicate_ids,
    COUNT(*) FILTER (WHERE id IS NULL) AS missing_ids
FROM public.bills_historical_staging;



-- Confirm which parliamentary sessions are included
SELECT
    parliament_number,
    session_number,
    COUNT(*) AS total_bills
FROM public.bills_historical_staging
GROUP BY parliament_number, session_number
ORDER BY
    CAST(parliament_number AS INTEGER),
    CAST(session_number AS INTEGER);



-- Check completeness of important fields
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE number IS NULL OR TRIM(number) = '') AS missing_bill_number,
    COUNT(*) FILTER (WHERE long_title_en IS NULL OR TRIM(long_title_en) = '') AS missing_long_title,
    COUNT(*) FILTER (WHERE bill_document_type_name_en IS NULL OR TRIM(bill_document_type_name_en) = '') AS missing_bill_type,
    COUNT(*) FILTER (WHERE status_name_en IS NULL OR TRIM(status_name_en) = '') AS missing_status,
    COUNT(*) FILTER (WHERE received_royal_assent_date_time IS NULL OR TRIM(received_royal_assent_date_time) = '') AS missing_assent_date
FROM public.bills_historical_staging;



-- Inspect the bill_document_type_name_en classifications 
SELECT
    bill_document_type_name_en,
    COUNT(*) AS total_bills
FROM public.bills_historical_staging
GROUP BY bill_document_type_name_en
ORDER BY total_bills DESC;



-- Inspect the status_name_en classifications 
SELECT
    status_name_en,
    COUNT(*) AS total_bills
FROM public.bills_historical_staging
GROUP BY status_name_en
ORDER BY total_bills DESC;

