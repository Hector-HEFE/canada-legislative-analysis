
-- Check total records
SELECT COUNT(*) AS total_bills
FROM public.bills_clean;


-- Inspect the new table
SELECT *
FROM public.bills_clean
LIMIT 10;


-- Check government bill classification
SELECT
    bill_type,
    is_government_bill_derived,
    COUNT(*) AS total
FROM public.bills_clean
GROUP BY bill_type, is_government_bill_derived
ORDER BY total DESC;


-- Check bill outcomes
SELECT
    received_royal_assent,
    COUNT(*) AS total
FROM public.bills_clean
GROUP BY received_royal_assent;
