-- Create table
CREATE TABLE public.bills_historical_staging
(
    LIKE public.bills_staging
);


-- Validate it has 135 columns
SELECT COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'bills_historical_staging';



-- Validate it has all 7155 rows
  SELECT COUNT(*) AS total_historical_bills
FROM public.bills_historical_staging;



-- Validate sample records
SELECT *
FROM public.bills_historical_staging
LIMIT 5;