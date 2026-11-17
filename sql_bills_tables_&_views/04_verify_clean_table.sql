-- Compare row counts and check duplicates
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT bill_id) AS unique_bill_ids,
    COUNT(*) - COUNT(DISTINCT bill_id) AS duplicate_ids,
    COUNT(*) FILTER (WHERE bill_id IS NULL) AS missing_ids
FROM public.bills_historical_clean;



-- Check the new data types
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'bills_historical_clean'
ORDER BY ordinal_position;



-- Check the derived classifications
SELECT
    bill_type,
    is_government_bill_derived,
    originating_chamber,
    COUNT(*) AS total_bills
FROM public.bills_historical_clean
GROUP BY
    bill_type,
    is_government_bill_derived,
    originating_chamber
ORDER BY total_bills DESC;



-- Check the Royal Assent calculation
SELECT
    COUNT(*) FILTER (
        WHERE received_royal_assent IS TRUE
    ) AS bills_with_assent,

    COUNT(*) FILTER (
        WHERE days_to_royal_assent IS NOT NULL
    ) AS bills_with_calculated_duration,

    COUNT(*) FILTER (
        WHERE days_to_royal_assent < 0
    ) AS negative_durations,

    ROUND(AVG(days_to_royal_assent), 1) AS average_days,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY days_to_royal_assent)::NUMERIC,
        1
    ) AS median_days

FROM public.bills_historical_clean;