SELECT
    bill_type,

    COUNT(*) AS bills_with_assent,

    ROUND(
        AVG(
            EXTRACT(EPOCH FROM (
                royal_assent_date -
                CASE
                    WHEN originating_chamber = 'House of Commons'
                        THEN house_first_reading_date
                    WHEN originating_chamber = 'Senate'
                        THEN senate_first_reading_date
                END
            )) / 86400
        )::NUMERIC,
        1
    ) AS average_days_to_assent,

    ROUND(
        (
            PERCENTILE_CONT(0.5) WITHIN GROUP (
                ORDER BY EXTRACT(EPOCH FROM (
                    royal_assent_date -
                    CASE
                        WHEN originating_chamber = 'House of Commons'
                            THEN house_first_reading_date
                        WHEN originating_chamber = 'Senate'
                            THEN senate_first_reading_date
                    END
                )) / 86400
            )
        )::NUMERIC,
        1
    ) AS median_days_to_assent

FROM public.bills_clean

WHERE received_royal_assent = TRUE
  AND royal_assent_date IS NOT NULL
  AND CASE
        WHEN originating_chamber = 'House of Commons'
            THEN house_first_reading_date
        WHEN originating_chamber = 'Senate'
            THEN senate_first_reading_date
      END IS NOT NULL

GROUP BY bill_type
ORDER BY average_days_to_assent;