
/* Establishing the introduction date
Our clean table doesn't have a dedicated introduction_date column. 
However, we have the first-reading dates for both chambers.

For this analysis, we'll use:
- House of Commons bill → house_first_reading_date
- Senate bill → senate_first_reading_date

First reading is a reasonable proxy for the date a bill was introduced into its originating chamber. */


-- How many bills were introduced and how many received Royal Assent each year, from 1994 to 2026?
WITH bill_dates AS (
    SELECT
        bill_id,
        originating_chamber,
        received_royal_assent,

        CASE
            WHEN originating_chamber = 'House of Commons'
                THEN house_first_reading_date
            WHEN originating_chamber = 'Senate'
                THEN senate_first_reading_date
        END AS introduction_date,

        royal_assent_date

    FROM public.bills_historical_clean
),

annual_introductions AS (
    SELECT
        EXTRACT(YEAR FROM introduction_date)::INTEGER AS year,
        COUNT(*) AS bills_introduced
    FROM bill_dates
    WHERE introduction_date IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM introduction_date)
),

annual_assent AS (
    SELECT
        EXTRACT(YEAR FROM royal_assent_date)::INTEGER AS year,
        COUNT(*) AS bills_passed
    FROM bill_dates
    WHERE received_royal_assent IS TRUE
      AND royal_assent_date IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM royal_assent_date)
)

SELECT
    COALESCE(i.year, a.year) AS year,
    COALESCE(i.bills_introduced, 0) AS bills_introduced,
    COALESCE(a.bills_passed, 0) AS bills_passed

FROM annual_introductions i
FULL OUTER JOIN annual_assent a
    ON i.year = a.year

ORDER BY year;



-- Does legislative activity differ by originating chamber accross the years?
WITH bill_dates AS (
    SELECT
        originating_chamber,

        CASE
            WHEN originating_chamber = 'House of Commons'
                THEN house_first_reading_date
            WHEN originating_chamber = 'Senate'
                THEN senate_first_reading_date
        END AS introduction_date

    FROM public.bills_historical_clean
)

SELECT
    EXTRACT(YEAR FROM introduction_date)::INTEGER AS year,
    originating_chamber,
    COUNT(*) AS bills_introduced

FROM bill_dates

WHERE introduction_date IS NOT NULL

GROUP BY
    EXTRACT(YEAR FROM introduction_date),
    originating_chamber

ORDER BY
    year,
    originating_chamber;



/* Data-quality issue: clean table has 7,155 bills, but the introduction query counts only 6,055. 
That means 1,100 records have no usable first-reading date in their originating chamber.
Let's investigate whether the missing dates are concentrated in particular sessions or bill types. */
SELECT
    parliament_number,
    session_number,
    bill_type,
    originating_chamber,
    COUNT(*) AS total_bills,

    COUNT(*) FILTER (
        WHERE
            CASE
                WHEN originating_chamber = 'House of Commons'
                    THEN house_first_reading_date
                WHEN originating_chamber = 'Senate'
                    THEN senate_first_reading_date
            END IS NULL
    ) AS missing_introduction_dates

FROM public.bills_historical_clean

GROUP BY
    parliament_number,
    session_number,
    bill_type,
    originating_chamber

ORDER BY
    parliament_number,
    session_number,
    bill_type,
    originating_chamber;
/*This is a very useful result. We've found that the missing introduction dates are not randomly distributed. 
They are concentrated in Private Members' Bills in particular parliamentary sessions.
For example:
- 37th Parliament, Session 3: 202 of 264 Private Members' Bills have no originating-chamber first-reading date.
- 39th Parliament, Session 2: 217 of 356.
- 40th Parliament, Session 3: 277 of 432.
- 41st Parliament, Session 2: 293 of 458.
- 43rd Parliament, Session 2: 43 of 122.
That pattern suggests a systematic issue with the way some historical Private Members' Bills are represented in the source data, 
rather than isolated missing values. */



/*Let's find out whether these bills:
- Never reached first reading.
- Were introduced but have incomplete date metadata.
- Were reinstated from a previous session.
- Have another recorded milestone that could help us establish their legislative history. */
SELECT
    parliament_number,
    session_number,
    bill_status,
    latest_completed_stage_name,
    did_reinstate_from_previous_session,
    passed_first_chamber_first_reading,
    passed_first_chamber_second_reading,
    passed_first_chamber_third_reading,
    COUNT(*) AS total_bills

FROM public.bills_historical_clean

WHERE
    CASE
        WHEN originating_chamber = 'House of Commons'
            THEN house_first_reading_date
        WHEN originating_chamber = 'Senate'
            THEN senate_first_reading_date
    END IS NULL

GROUP BY
    parliament_number,
    session_number,
    bill_status,
    latest_completed_stage_name,
    did_reinstate_from_previous_session,
    passed_first_chamber_first_reading,
    passed_first_chamber_second_reading,
    passed_first_chamber_third_reading

ORDER BY
    parliament_number,
    session_number,
    total_bills DESC;



/* Can we recover the original introduction dates?
The original staging table contains two fields deliberately left out of the clean table:
- reinstated_from_bill_document_id
- reinstated_from_bill_number_code
The first may let us connect a reinstated bill to its earlier record and recover its original first-reading date.
Let's test that before changing the clean table.*/
SELECT
    COUNT(*) AS missing_introduction_dates,

    COUNT(*) FILTER (
        WHERE s.did_reinstate_from_previous_session = '1'
    ) AS confirmed_reinstatements,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(s.did_reinstate_from_previous_session), '') IS NULL
    ) AS unknown_reinstatement_status,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(s.reinstated_from_bill_document_id), '') IS NOT NULL
    ) AS records_with_previous_bill_id,

    COUNT(*) FILTER (
        WHERE previous.id IS NOT NULL
    ) AS records_with_matching_previous_bill,

    COUNT(*) FILTER (
        WHERE previous.id IS NOT NULL
          AND (
              NULLIF(TRIM(previous.passed_house_first_reading_date_time), '') IS NOT NULL
              OR NULLIF(TRIM(previous.passed_senate_first_reading_date_time), '') IS NOT NULL
          )
    ) AS previous_bills_with_reading_dates

FROM public.bills_historical_clean c

JOIN public.bills_historical_staging s
    ON s.id = c.bill_id

LEFT JOIN public.bills_historical_staging previous
    ON previous.id = s.reinstated_from_bill_document_id

WHERE
    CASE
        WHEN c.originating_chamber = 'House of Commons'
            THEN c.house_first_reading_date
        WHEN c.originating_chamber = 'Senate'
            THEN c.senate_first_reading_date
    END IS NULL;
--Unfortunately, the data is not available to answer this. 