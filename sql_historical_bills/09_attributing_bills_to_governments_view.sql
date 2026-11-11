
-- Create the view
CREATE OR REPLACE VIEW public.bills_with_government AS

WITH bill_dates AS (
    SELECT
        b.*,
        CASE
            WHEN b.originating_chamber = 'House of Commons'
                THEN b.house_first_reading_date::DATE
            WHEN b.originating_chamber = 'Senate'
                THEN b.senate_first_reading_date::DATE
            ELSE NULL
        END AS introduction_date
    FROM public.bills_historical_clean b
)

SELECT
    b.*,
    g.government_id,
    g.prime_minister,
    g.governing_party,
    s.government_status

FROM bill_dates b

LEFT JOIN public.governments g
    ON b.introduction_date >= g.start_date
    AND (
        b.introduction_date < g.end_date
        OR g.end_date IS NULL
    )

LEFT JOIN public.government_seat_status s
    ON g.government_id = s.government_id
    AND b.introduction_date >= s.status_start_date
    AND (
        b.introduction_date < s.status_end_date
        OR s.status_end_date IS NULL
    );



-- See bills attributed to governments
SELECT
    prime_minister,
    governing_party,
    government_status,
    COUNT(*) AS total_bills
FROM public.bills_with_government
GROUP BY
    prime_minister,
    governing_party,
    government_status
ORDER BY
    MIN(introduction_date);


-- See bills NOT attributed to governments
SELECT
    COUNT(*) AS total_bills,
    COUNT(*) FILTER (
        WHERE introduction_date IS NULL
    ) AS missing_introduction_date,
    COUNT(*) FILTER (
        WHERE introduction_date IS NOT NULL
          AND government_id IS NULL
    ) AS no_matching_government,
    COUNT(*) FILTER (
        WHERE government_id IS NOT NULL
    ) AS attributed_to_government
FROM public.bills_with_government;