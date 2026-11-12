
-- Bill introductions by majority/minority and bill type.
WITH date_bounds AS (
    SELECT
        MIN(introduction_date) AS first_date,
        MAX(introduction_date) AS last_date
    FROM public.bills_with_government
    WHERE introduction_date IS NOT NULL
),
-- Clip each majority/minority period to the dates covered by our bill data
status_periods AS (
    SELECT
        s.government_status,
        GREATEST(s.status_start_date, d.first_date) AS period_start,
        LEAST(
            COALESCE(s.status_end_date, d.last_date + 1),
            d.last_date + 1
        ) AS period_end
    FROM public.government_seat_status s
    CROSS JOIN date_bounds d
    WHERE s.status_start_date < d.last_date + 1
      AND COALESCE(s.status_end_date, d.last_date + 1) > d.first_date
),
-- Calculate the total observed days under each type of government
status_days AS (
    SELECT
        government_status,
        SUM(period_end - period_start) AS observed_days
    FROM status_periods
    WHERE period_start < period_end
    GROUP BY government_status
),
-- Count introductions by government status and bill type
bill_counts AS (
    SELECT
        government_status,
        bill_type,
        COUNT(*) AS bills_introduced
    FROM public.bills_with_government
    WHERE introduction_date IS NOT NULL
      AND government_status IS NOT NULL
    GROUP BY government_status, bill_type
),
bill_types AS (
    SELECT DISTINCT bill_type
    FROM public.bills_with_government
    WHERE bill_type IS NOT NULL
)
SELECT
    sd.government_status,
    bt.bill_type,
    sd.observed_days,
    COALESCE(bc.bills_introduced, 0) AS bills_introduced,
    ROUND(
        COALESCE(bc.bills_introduced, 0) * 30.4375
        / sd.observed_days,
        2
    ) AS average_monthly_introductions
FROM status_days sd
CROSS JOIN bill_types bt
LEFT JOIN bill_counts bc
    ON bc.government_status = sd.government_status
   AND bc.bill_type = bt.bill_type
ORDER BY
    bt.bill_type,
    sd.government_status;



-- Validate the time coverage (days)
WITH date_bounds AS (
    SELECT
        MIN(introduction_date) AS first_date,
        MAX(introduction_date) AS last_date
    FROM public.bills_with_government
    WHERE introduction_date IS NOT NULL
),
status_periods AS (
    SELECT
        GREATEST(s.status_start_date, d.first_date) AS period_start,
        LEAST(
            COALESCE(s.status_end_date, d.last_date + 1),
            d.last_date + 1
        ) AS period_end
    FROM public.government_seat_status s
    CROSS JOIN date_bounds d
    WHERE s.status_start_date < d.last_date + 1
      AND COALESCE(s.status_end_date, d.last_date + 1) > d.first_date
)
SELECT
    (d.last_date - d.first_date + 1) AS calendar_days,
    SUM(p.period_end - p.period_start) AS classified_status_days,
    (d.last_date - d.first_date + 1)
        - SUM(p.period_end - p.period_start) AS unclassified_days
FROM date_bounds d
CROSS JOIN status_periods p
GROUP BY d.first_date, d.last_date;
