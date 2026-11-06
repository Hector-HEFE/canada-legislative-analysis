
-- Inspect all columns in the staging table
SELECT
    ordinal_position,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'bills_staging'
ORDER BY ordinal_position;

/*
Category	                Columns Analytical purpose
Bill identification	        1–10	Identify and describe bills
Status and progression	    11–37	Track legislative progress
Parliament and session	    38–39	Historical comparisons
Bill type and origin	    40–50	Government vs private, House vs Senate
Sponsor information	        51–71	Who introduced bills
Latest event	            72–88	Most recent recorded legislative event
Reading dates	            89–95	Measure legislative timelines
Passage indicators	        96–110	Track readings, reinstatement and outcomes
Bill form and descriptions	111–123	Classify and describe legislation
Detailed records	        124–133	Stages, publications, votes and other nested information
Session metadata	        134–135	Additional session context
*/

-- Count non-empty values in every column
SELECT
    COUNT(*) AS total_rows
FROM public.bills_staging;

SELECT
    COUNT(id) AS populated_ids,
    COUNT(number_code) AS populated_bill_numbers,
    COUNT(long_title_en) AS populated_titles,
    COUNT(status_name_en) AS populated_statuses,
    COUNT(received_royal_assent_date_time) AS populated_assent_dates
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


-- delete this line later