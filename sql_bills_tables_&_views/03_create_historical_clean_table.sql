-- Create clean historical table
CREATE TABLE public.bills_historical_clean AS

WITH source_cleaned AS (
    SELECT
        -- Bill identification
        id AS bill_id,
        number_code AS bill_number,
        long_title AS bill_title,
        short_title,

        -- Current legislative status
        status_name AS bill_status,
        latest_completed_major_stage_id AS latest_completed_stage_id,
        latest_completed_major_stage_name AS latest_completed_stage_name,
        latest_completed_major_stage_name_with_chamber_suffix
            AS latest_completed_stage_name_with_chamber,
        latest_completed_major_stage_chamber_organization_id
            AS latest_completed_stage_chamber_id,

        -- Parliamentary session
        NULLIF(TRIM(parliament_number), '')::INTEGER
            AS parliament_number,
        NULLIF(TRIM(session_number), '')::INTEGER
            AS session_number,

        -- Bill classification
        bill_document_type_name AS bill_type,

        CASE
            WHEN bill_document_type_name IN (
                'House Government Bill',
                'Senate Government Bill'
            ) THEN TRUE
            ELSE FALSE
        END AS is_government_bill_derived,

        -- Originating chamber
        originating_chamber_organization_id AS originating_chamber_id,

        CASE
            WHEN NULLIF(TRIM(is_house_bill), '')::BOOLEAN IS TRUE
                THEN 'House of Commons'
            WHEN NULLIF(TRIM(is_senate_bill), '')::BOOLEAN IS TRUE
                THEN 'Senate'
            ELSE 'Unknown'
        END AS originating_chamber,

        NULLIF(TRIM(is_house_bill), '')::BOOLEAN AS is_house_bill,
        NULLIF(TRIM(is_senate_bill), '')::BOOLEAN AS is_senate_bill,

        -- House reading dates
        NULLIF(TRIM(passed_house_first_reading_date_time), '')
            ::TIMESTAMPTZ AS house_first_reading_date,

        NULLIF(TRIM(passed_house_second_reading_date_time), '')
            ::TIMESTAMPTZ AS house_second_reading_date,

        NULLIF(TRIM(passed_house_third_reading_date_time), '')
            ::TIMESTAMPTZ AS house_third_reading_date,

        -- Senate reading dates
        NULLIF(TRIM(passed_senate_first_reading_date_time), '')
            ::TIMESTAMPTZ AS senate_first_reading_date,

        NULLIF(TRIM(passed_senate_second_reading_date_time), '')
            ::TIMESTAMPTZ AS senate_second_reading_date,

        NULLIF(TRIM(passed_senate_third_reading_date_time), '')
            ::TIMESTAMPTZ AS senate_third_reading_date,

        -- Royal Assent
        NULLIF(TRIM(received_royal_assent_date_time), '')
            ::TIMESTAMPTZ AS royal_assent_date,

        NULLIF(TRIM(received_royal_assent), '')::BOOLEAN
            AS received_royal_assent,

        -- Reinstatement
        NULLIF(TRIM(did_reinstate_from_previous_session), '')
            ::BOOLEAN AS did_reinstate_from_previous_session,

        -- Legislative milestones
        NULLIF(TRIM(passed_first_chamber_first_reading), '')
            ::BOOLEAN AS passed_first_chamber_first_reading,

        NULLIF(TRIM(passed_first_chamber_second_reading), '')
            ::BOOLEAN AS passed_first_chamber_second_reading,

        NULLIF(TRIM(passed_first_chamber_third_reading), '')
            ::BOOLEAN AS passed_first_chamber_third_reading,

        NULLIF(TRIM(passed_second_chamber_first_reading), '')
            ::BOOLEAN AS passed_second_chamber_first_reading,

        NULLIF(TRIM(passed_second_chamber_second_reading), '')
            ::BOOLEAN AS passed_second_chamber_second_reading,

        NULLIF(TRIM(passed_second_chamber_third_reading), '')
            ::BOOLEAN AS passed_second_chamber_third_reading,

        -- Session status
        NULLIF(TRIM(is_session_ongoing), '')::BOOLEAN
            AS is_session_ongoing,

        -- Latest bill event
        CASE
            WHEN NULLIF(TRIM(latest_bill_event_date_time), '') IS NULL
                THEN NULL
            WHEN LEFT(TRIM(latest_bill_event_date_time), 4) = '0001'
                THEN NULL
            ELSE TRIM(latest_bill_event_date_time)::TIMESTAMPTZ
        END AS latest_bill_event_date

    FROM public.bills_historical_staging
)

SELECT
    source_cleaned.*,

    -- Elapsed calendar days from first reading to Royal Assent
    CASE
        WHEN received_royal_assent IS TRUE
             AND royal_assent_date IS NOT NULL
        THEN
            CASE
                WHEN originating_chamber = 'House of Commons'
                     AND house_first_reading_date IS NOT NULL
                THEN ROUND(
                    (
                        EXTRACT(EPOCH FROM (
                            royal_assent_date - house_first_reading_date
                        )) / 86400
                    )::NUMERIC,
                    1
                )

                WHEN originating_chamber = 'Senate'
                     AND senate_first_reading_date IS NOT NULL
                THEN ROUND(
                    (
                        EXTRACT(EPOCH FROM (
                            royal_assent_date - senate_first_reading_date
                        )) / 86400
                    )::NUMERIC,
                    1
                )

                ELSE NULL
            END
        ELSE NULL
    END AS days_to_royal_assent

FROM source_cleaned;