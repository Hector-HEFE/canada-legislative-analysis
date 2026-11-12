
-- How long do different types of bills take to receive Royal Assent, broken down by Prime Minister and majority/minority status?

SELECT
    prime_minister,
    government_status,
    bill_type,

    COUNT(*) AS bills_passed,

    ROUND(AVG(days_to_royal_assent), 1) AS average_days,

    ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY days_to_royal_assent)::NUMERIC,
        1
    ) AS median_days,

    ROUND(
        PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY days_to_royal_assent)::NUMERIC,
        1
    ) AS percentile_75_days,

    ROUND(
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (ORDER BY days_to_royal_assent)::NUMERIC,
        1
    ) AS percentile_90_days

FROM public.bills_with_government

WHERE received_royal_assent = TRUE
  AND days_to_royal_assent IS NOT NULL
  AND government_status IS NOT NULL
  AND bill_type IN (
      'House Government Bill',
      'Senate Government Bill',
      'Senate Public Bill'
  )

GROUP BY
    prime_minister,
    government_status,
    bill_type

ORDER BY
    bill_type,
    prime_minister,
    government_status;
