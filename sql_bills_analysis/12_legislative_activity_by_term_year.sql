
-- Calculate the year of the government's mandate
SELECT
    prime_minister,
    government_status,

    EXTRACT(
        YEAR FROM AGE(
            introduction_date,
            government_start_date
        )
    )::INTEGER + 1 AS government_term_year,

    COUNT(*) AS bills_introduced,

    COUNT(*) FILTER (
        WHERE received_royal_assent = TRUE
    ) AS bills_passed

FROM public.bills_with_government

WHERE
    prime_minister IS NOT NULL
    AND introduction_date IS NOT NULL

GROUP BY
    prime_minister,
    government_status,
    government_term_year

ORDER BY
    MIN(introduction_date);



-- Normalizing legislative acitivity by parliament year.
WITH election_periods AS (
    SELECT
        parliament_number,
        election_date,
        LEAD(election_date) OVER (
            ORDER BY election_date
        ) AS next_election_date
    FROM public.general_elections
),

term_bounds AS (
    SELECT
        parliament_number,
        election_date,
        COALESCE(
            next_election_date,
            CURRENT_DATE + 1
        ) AS term_end_date
    FROM election_periods
),

term_durations AS (
    SELECT
        *,
        EXTRACT(
            YEAR FROM AGE(term_end_date, election_date)
        )::INTEGER
        +
        CASE
            WHEN term_end_date >
                (
                    election_date
                    + MAKE_INTERVAL(
                        years => EXTRACT(
                            YEAR FROM AGE(term_end_date, election_date)
                        )::INTEGER
                    )
                )::DATE
            THEN 1
            ELSE 0
        END AS number_of_years
    FROM term_bounds
),

term_years AS (
    SELECT
        t.parliament_number,
        gs.parliament_year,

        (
            t.election_date
            + MAKE_INTERVAL(
                years => gs.parliament_year - 1
            )
        )::DATE AS year_start_date,

        LEAST(
            (
                t.election_date
                + MAKE_INTERVAL(
                    years => gs.parliament_year
                )
            )::DATE,
            t.term_end_date
        ) AS year_end_date

    FROM term_durations t

    CROSS JOIN LATERAL GENERATE_SERIES(
        1,
        t.number_of_years
    ) AS gs(parliament_year)
)

SELECT
    ty.parliament_number,
    ty.parliament_year,
    ty.year_start_date,
    ty.year_end_date,

    ty.year_end_date - ty.year_start_date
        AS days_observed,

    COUNT(b.bill_id) AS bills_introduced,

    ROUND(
        COUNT(b.bill_id) * 365.25
        / NULLIF(
            ty.year_end_date - ty.year_start_date,
            0
        ),
        1
    ) AS annualized_introductions

FROM term_years ty

LEFT JOIN public.bills_with_government b
    ON b.parliament_number = ty.parliament_number
    AND b.introduction_date >= ty.year_start_date
    AND b.introduction_date < ty.year_end_date

GROUP BY
    ty.parliament_number,
    ty.parliament_year,
    ty.year_start_date,
    ty.year_end_date

ORDER BY
    ty.parliament_number,
    ty.parliament_year;
