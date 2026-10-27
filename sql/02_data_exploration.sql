-- validate all rows were uploaded
SELECT COUNT(*)
FROM public.bills_staging;


-- validate random columns are populated correctly
SELECT
    id,
    number_code,
    long_title_en,
    status_name_en,
    parliament_number,
    session_number,
    received_royal_assent_date_time
FROM public.bills_staging
LIMIT 10;


-- 1. How many bills are in the dataset?
SELECT COUNT(*) AS total_rows
FROM public.bills_staging;

-- 2. Are bill IDs unique?
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT id) AS unique_ids,
    COUNT(*) - COUNT(DISTINCT id) AS duplicate_ids
FROM public.bills_staging;

-- 3. Which bill statuses appear, and how often?
SELECT
    status_name_en,
    COUNT(*) AS bill_count
FROM public.bills_staging
GROUP BY status_name_en
ORDER BY bill_count DESC;

-- 4. Which bill types appear?
SELECT
    bill_type_name_en,
    COUNT(*) AS bill_count
FROM public.bills_staging
GROUP BY bill_type_name_en
ORDER BY bill_count DESC;

-- 5. Check the Parliament and session represented
SELECT
    parliament_number,
    session_number,
    COUNT(*) AS bill_count
FROM public.bills_staging
GROUP BY parliament_number, session_number
ORDER BY parliament_number, session_number;
