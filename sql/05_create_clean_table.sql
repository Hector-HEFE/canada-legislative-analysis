
-- Recreate the analytical table from the untouched staging table
DROP TABLE IF EXISTS public.bills_clean;

CREATE TABLE public.bills_clean AS

SELECT
    -- Identification
    id AS bill_id,
    number_code AS bill_number,

    -- Description
    long_title_en AS bill_title,
    short_title_en AS short_title,

    -- Parliamentary context
    parliament_number::INTEGER AS parliament_number,
    session_number::INTEGER AS session_number,

    -- Classification
    bill_document_type_name_en AS bill_type,

    CASE
        WHEN bill_document_type_name_en LIKE '%Government Bill%'
            THEN TRUE
        ELSE FALSE
    END AS is_government_bill_derived,

    originating_chamber_organization_id AS originating_chamber_id,

    CASE
        WHEN is_house_bill = 'TRUE' THEN 'House of Commons'
        WHEN is_senate_bill = 'TRUE' THEN 'Senate'
        ELSE 'Unknown'
    END AS originating_chamber,

    -- Legislative status
    status_name_en AS bill_status,

    -- Important dates
    NULLIF(received_royal_assent_date_time, '')::TIMESTAMPTZ
        AS royal_assent_date,

    NULLIF(passed_house_first_reading_date_time, '')::TIMESTAMPTZ
        AS house_first_reading_date,

    NULLIF(passed_house_second_reading_date_time, '')::TIMESTAMPTZ
        AS house_second_reading_date,

    NULLIF(passed_house_third_reading_date_time, '')::TIMESTAMPTZ
        AS house_third_reading_date,

    NULLIF(passed_senate_first_reading_date_time, '')::TIMESTAMPTZ
        AS senate_first_reading_date,

    NULLIF(passed_senate_second_reading_date_time, '')::TIMESTAMPTZ
        AS senate_second_reading_date,

    NULLIF(passed_senate_third_reading_date_time, '')::TIMESTAMPTZ
        AS senate_third_reading_date,

    -- Outcome
    received_royal_assent = 'TRUE' AS received_royal_assent

FROM public.bills_staging;
