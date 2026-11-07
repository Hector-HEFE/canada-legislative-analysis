SELECT
    bill_id,
    bill_number,
    bill_title,
    bill_type,
    originating_chamber,

    CASE
        WHEN originating_chamber = 'House of Commons'
            THEN house_first_reading_date
        WHEN originating_chamber = 'Senate'
            THEN senate_first_reading_date
    END AS first_reading_date,

    royal_assent_date,

    ROUND(
        (
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
    ) AS days_to_assent

FROM public.bills_clean

WHERE received_royal_assent = TRUE
  AND royal_assent_date IS NOT NULL
  AND CASE
        WHEN originating_chamber = 'House of Commons'
            THEN house_first_reading_date
        WHEN originating_chamber = 'Senate'
            THEN senate_first_reading_date
      END IS NOT NULL

ORDER BY days_to_assent DESC;