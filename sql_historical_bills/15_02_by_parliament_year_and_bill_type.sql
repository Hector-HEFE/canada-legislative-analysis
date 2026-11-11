
-- Legislative activity by year since election and bill type.
WITH election_boundaries AS (
    SELECT
        parliament_number,
        election_date,
        LEAD(election_date) OVER (
            ORDER BY election_date
        ) AS next_election_date
    FROM public.general_elections
    WHERE parliament_number > 35
),

date_bounds AS (
    SELECT
        MAX(introduction_date)::DATE + 1 AS last_observed_date
    FROM public.bills_with_government
    WHERE introduction_date IS NOT NULL
),

parliament_periods AS (
    SELECT
        e.parliament_number,
        e.election_date,
        e.next_election_date,
        LEAST(
            COALESCE(e.next_election_date, d.last_observed_date),
            d.last_observed_date
        ) AS parliament_end_date
    FROM election_boundaries e
    CROSS JOIN date_bounds d
),

year_periods AS (
    SELECT
        p.parliament_number,
        gs.parliament_year,
        (
            p.election_date
            + MAKE_INTERVAL(years => gs.parliament_year - 1)
        )::DATE AS year_start_date,

        LEAST(
            (
                p.election_date
                + MAKE_INTERVAL(years => gs.parliament_year)
            )::DATE,
            p.parliament_end_date
        ) AS year_end_date

    FROM parliament_periods p
    CROSS JOIN LATERAL GENERATE_SERIES(1, 10) AS gs(parliament_year)

    WHERE (
        p.election_date
        + MAKE_INTERVAL(years => gs.parliament_year - 1)
    )::DATE < p.parliament_end_date
),

observed_periods AS (
    SELECT
        *,
        year_end_date - year_start_date AS days_observed
    FROM year_periods
    WHERE year_end_date - year_start_date >= 90
)

SELECT
    p.parliament_number,
    p.parliament_year,
    p.year_start_date,
    p.year_end_date,
    p.days_observed,
    b.bill_type,
    COUNT(b.bill_id) AS bills_introduced,

    ROUND(
        COUNT(b.bill_id) * 30.4375 / p.days_observed,
        2
    ) AS annualized_monthly_introductions

FROM observed_periods p

LEFT JOIN public.bills_with_government b
    ON b.introduction_date >= p.year_start_date
    AND b.introduction_date < p.year_end_date

GROUP BY
    p.parliament_number,
    p.parliament_year,
    p.year_start_date,
    p.year_end_date,
    p.days_observed,
    b.bill_type

ORDER BY
    p.parliament_number,
    p.parliament_year,
    b.bill_type;
