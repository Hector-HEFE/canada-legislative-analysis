
-- Verify observable days for each election
WITH date_bounds AS (
    SELECT
        MIN(introduction_date)::DATE AS first_bill_date,
        MAX(introduction_date)::DATE AS last_bill_date
    FROM public.bills_with_government
    WHERE introduction_date IS NOT NULL
)
SELECT
    e.parliament_number,
    e.election_date,
    d.first_bill_date,
    d.last_bill_date,

    GREATEST(e.election_date - 180, d.first_bill_date)
        AS pre_election_start,

    LEAST(e.election_date, d.last_bill_date + 1)
        AS pre_election_end,

    GREATEST(
        0,
        LEAST(e.election_date, d.last_bill_date + 1)
        - GREATEST(e.election_date - 180, d.first_bill_date)
    ) AS observable_pre_election_days,

    GREATEST(e.election_date, d.first_bill_date)
        AS post_election_start,

    LEAST(e.election_date + 180, d.last_bill_date + 1)
        AS post_election_end,

    GREATEST(
        0,
        LEAST(e.election_date + 180, d.last_bill_date + 1)
        - GREATEST(e.election_date, d.first_bill_date)
    ) AS observable_post_election_days

FROM public.general_elections e
CROSS JOIN date_bounds d
ORDER BY e.election_date;
-- Will exclude the 1993 election, as there is only partial data available for this analysis.



-- Calculate aggregate legislative activity changes around elections.
WITH date_bounds AS (
    SELECT
        MIN(introduction_date)::DATE AS first_date,
        MAX(introduction_date)::DATE AS last_date
    FROM public.bills_with_government
    WHERE introduction_date IS NOT NULL
),

calendar AS (
    SELECT
        generate_series(
            first_date,
            last_date,
            INTERVAL '1 day'
        )::DATE AS calendar_date
    FROM date_bounds
),

daily_bills AS (
    SELECT
        introduction_date::DATE AS bill_date,
        COUNT(*) AS bills_introduced
    FROM public.bills_with_government
    WHERE introduction_date IS NOT NULL
    GROUP BY introduction_date::DATE
),

classified_days AS (
    SELECT
        c.calendar_date,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM public.general_elections e
                WHERE e.parliament_number > 35
                  AND c.calendar_date >= e.election_date - 180
                  AND c.calendar_date < e.election_date
            ) THEN 'Pre-election'

            WHEN EXISTS (
                SELECT 1
                FROM public.general_elections e
                WHERE e.parliament_number > 35
                  AND c.calendar_date >= e.election_date
                  AND c.calendar_date < e.election_date + 180
            ) THEN 'Post-election'

            ELSE 'Outside election windows'
        END AS election_period,

        COALESCE(d.bills_introduced, 0) AS bills_introduced

    FROM calendar c
    LEFT JOIN daily_bills d
        ON c.calendar_date = d.bill_date
)

SELECT
    election_period,
    COUNT(*) AS days_observed,
    SUM(bills_introduced) AS bills_introduced,
    ROUND(
        SUM(bills_introduced) * 30.4375 / COUNT(*),
        2
    ) AS average_monthly_introductions

FROM classified_days
GROUP BY election_period
ORDER BY
    CASE election_period
        WHEN 'Pre-election' THEN 1
        WHEN 'Post-election' THEN 2
        ELSE 3
    END;



-- Analyze legislative activity around each election.
SELECT
    e.parliament_number,
    e.election_date,

    COUNT(*) FILTER (
        WHERE b.introduction_date >= e.election_date - 180
          AND b.introduction_date < e.election_date
    ) AS pre_election_bills,

    ROUND(
        COUNT(*) FILTER (
            WHERE b.introduction_date >= e.election_date - 180
              AND b.introduction_date < e.election_date
        ) * 30.4375 / 180,
        2
    ) AS pre_election_monthly_rate,

    COUNT(*) FILTER (
        WHERE b.introduction_date >= e.election_date
          AND b.introduction_date < e.election_date + 180
    ) AS post_election_bills,

    ROUND(
        COUNT(*) FILTER (
            WHERE b.introduction_date >= e.election_date
              AND b.introduction_date < e.election_date + 180
        ) * 30.4375 / 180,
        2
    ) AS post_election_monthly_rate

FROM public.general_elections e
CROSS JOIN public.bills_with_government b

WHERE e.parliament_number > 35
  AND b.introduction_date IS NOT NULL

GROUP BY
    e.parliament_number,
    e.election_date

ORDER BY e.election_date;



-- Analyze bill type increase around elections.
WITH classified_bills AS (
    SELECT
        b.*,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM public.general_elections e
                WHERE e.parliament_number > 35
                  AND b.introduction_date >= e.election_date - 180
                  AND b.introduction_date < e.election_date
            ) THEN 'Pre-election'

            WHEN EXISTS (
                SELECT 1
                FROM public.general_elections e
                WHERE e.parliament_number > 35
                  AND b.introduction_date >= e.election_date
                  AND b.introduction_date < e.election_date + 180
            ) THEN 'Post-election'

            ELSE 'Outside election windows'
        END AS election_period
    FROM public.bills_with_government b
    WHERE b.introduction_date IS NOT NULL
)

SELECT
    election_period,
    bill_type,
    COUNT(*) AS bills_introduced,
    ROUND(
        COUNT(*) * 30.4375 /
        CASE
            WHEN election_period IN ('Pre-election', 'Post-election')
                THEN 1800
            ELSE 8379
        END,
        2
    ) AS average_monthly_introductions
FROM classified_bills
GROUP BY election_period, bill_type
ORDER BY
    CASE election_period
        WHEN 'Pre-election' THEN 1
        WHEN 'Post-election' THEN 2
        ELSE 3
    END,
    bill_type;
