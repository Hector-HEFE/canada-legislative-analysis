-- 1. Overall bill statistics
SELECT
    COUNT(*) AS total_bills,
    COUNT(*) FILTER (
        WHERE received_royal_assent
    ) AS bills_receiving_royal_assent,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE received_royal_assent
        ) / COUNT(*), 1
    ) AS royal_assent_rate_pct
FROM public.bills_clean;


-- 2. Bills by type
SELECT
    bill_type,
    COUNT(*) AS total_bills,
    COUNT(*) FILTER (
        WHERE received_royal_assent
    ) AS bills_receiving_royal_assent,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE received_royal_assent
        ) / COUNT(*), 1
    ) AS royal_assent_rate_pct
FROM public.bills_clean
GROUP BY bill_type
ORDER BY total_bills DESC;


-- 3. Bills by originating chamber
SELECT
    originating_chamber,
    COUNT(*) AS total_bills,
    COUNT(*) FILTER (
        WHERE received_royal_assent
    ) AS bills_receiving_royal_assent,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE received_royal_assent
        ) / COUNT(*), 1
    ) AS royal_assent_rate_pct
FROM public.bills_clean
GROUP BY originating_chamber
ORDER BY total_bills DESC;


-- 4. Bills by current legislative status
SELECT
    bill_status,
    COUNT(*) AS total_bills
FROM public.bills_clean
GROUP BY bill_status
ORDER BY total_bills DESC;