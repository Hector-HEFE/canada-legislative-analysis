
-- Senate Public Bill difference by Prime Minister and majority/minority status.
WITH date_bounds AS (
    SELECT
        MIN(introduction_date) AS first_date,
        MAX(introduction_date) AS last_date
    FROM public.bills_with_government
    WHERE introduction_date IS NOT NULL
),

status_periods AS (
    SELECT
        g.government_id,
        g.prime_minister,
        s.government_status,
        GREATEST(s.status_start_date, d.first_date) AS period_start,
        LEAST(
            COALESCE(s.status_end_date, d.last_date + 1),
            d.last_date + 1
        ) AS period_end
    FROM public.government_seat_status s
    JOIN public.governments g
        ON g.government_id = s.government_id
    CROSS JOIN date_bounds d
    WHERE s.status_start_date < d.last_date + 1
      AND COALESCE(s.status_end_date, d.last_date + 1) > d.first_date
),

status_days AS (
    SELECT
        government_id,
        prime_minister,
        government_status,
        SUM(period_end - period_start) AS observed_days
    FROM status_periods
    WHERE period_start < period_end
    GROUP BY
        government_id,
        prime_minister,
        government_status
),

bill_counts AS (
    SELECT
        government_id,
        prime_minister,
        government_status,
        COUNT(*) AS bills_introduced
    FROM public.bills_with_government
    WHERE introduction_date IS NOT NULL
      AND government_id IS NOT NULL
      AND government_status IS NOT NULL
      AND bill_type = 'Senate Public Bill'
    GROUP BY
        government_id,
        prime_minister,
        government_status
)

SELECT
    sd.prime_minister,
    sd.government_status,
    sd.observed_days,
    COALESCE(bc.bills_introduced, 0) AS bills_introduced,
    ROUND(
        COALESCE(bc.bills_introduced, 0) * 30.4375
        / sd.observed_days,
        2
    ) AS average_monthly_introductions
FROM status_days sd
LEFT JOIN bill_counts bc
    ON bc.government_id = sd.government_id
   AND bc.government_status = sd.government_status
ORDER BY
    sd.prime_minister,
    sd.government_status;
/*Senate Public Bill introductions have been substantially more frequent 
during minority-government periods under Harper and Trudeau, 
but this relationship is not universal.*/
