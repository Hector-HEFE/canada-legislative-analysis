
-- Create the website-specific SQL view
CREATE OR REPLACE VIEW public.vw_bill_explorer AS

SELECT
    -- Identity
    b.bill_id,
    b.bill_number,

    -- Description
    b.bill_title,
    b.short_title,

    -- Parliament
    b.parliament_number,
    b.session_number,

    -- Classification
    b.bill_type,
    b.is_government_bill_derived AS is_government_bill,
    b.originating_chamber,

    -- Introduction date:
    -- First reading in the originating chamber
    CASE
        WHEN b.originating_chamber = 'House of Commons'
            THEN b.house_first_reading_date::DATE
        WHEN b.originating_chamber = 'Senate'
            THEN b.senate_first_reading_date::DATE
        ELSE NULL
    END AS introduction_date,

    -- Political context at introduction
    b.prime_minister,
    b.governing_party,

    -- Legislative progress
    b.bill_status,
    b.latest_completed_stage_name_with_chamber
        AS latest_completed_stage,

    -- Outcome classification
    CASE
        WHEN b.received_royal_assent = TRUE
            THEN 'Passed'
        WHEN b.bill_status = 'Bill defeated'
            THEN 'Defeated'
        WHEN b.bill_status = 'Bill not proceeded with'
            THEN 'Not proceeded with'
        WHEN b.bill_status = 'Introduced as pro forma bill'
            THEN 'Pro forma'
        WHEN b.bill_status IS NULL
            THEN 'Unknown'
        ELSE 'Unresolved'
    END AS outcome_category,

    -- House of Commons reading dates
    b.house_first_reading_date,
    b.house_second_reading_date,
    b.house_third_reading_date,

    -- Senate reading dates
    b.senate_first_reading_date,
    b.senate_second_reading_date,
    b.senate_third_reading_date,

    -- Completion and latest activity
    b.royal_assent_date,
    b.received_royal_assent,
    b.latest_bill_event_date,
    b.is_session_ongoing,

    -- Duration
    b.days_to_royal_assent

FROM public.bills_with_government b;




-- Verify the view
SELECT
    COUNT(*) AS total_bills,
    COUNT(DISTINCT bill_id) AS unique_bill_ids,
    COUNT(introduction_date) AS bills_with_introduction_date,
    COUNT(*) FILTER (
        WHERE introduction_date IS NULL
    ) AS bills_without_introduction_date,
    COUNT(*) FILTER (
        WHERE prime_minister IS NULL
    ) AS bills_without_prime_minister,
    COUNT(*) FILTER (
        WHERE outcome_category = 'Passed'
    ) AS bills_passed,
    COUNT(*) FILTER (
        WHERE outcome_category = 'Unresolved'
    ) AS bills_unresolved
FROM public.vw_bill_explorer;




-- Inspect a sample
    SELECT *
    FROM public.vw_bill_explorer
    ORDER BY introduction_date DESC NULLS LAST
    LIMIT 10;
