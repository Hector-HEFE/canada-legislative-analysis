-- Verify government bill classification
SELECT
    bill_document_type_name_en,
    is_government_bill,
    COUNT(*) AS bill_count
FROM public.bills_staging
GROUP BY
    bill_document_type_name_en,
    is_government_bill
ORDER BY bill_document_type_name_en;


-- Inspect chamber information
SELECT
    originating_chamber_organization_id,
    originating_chamber_name_en,
    is_house_bill,
    is_senate_bill,
    COUNT(*) AS bill_count
FROM public.bills_staging
GROUP BY
    originating_chamber_organization_id,
    originating_chamber_name_en,
    is_house_bill,
    is_senate_bill
ORDER BY bill_count DESC;


-- Inspect actual values in the raw records
SELECT
    number_code,
    bill_document_type_name_en,
    is_government_bill,
    originating_chamber_organization_id,
    originating_chamber_name_en,
    is_house_bill,
    is_senate_bill,
    status_name_en,
    bill_stages
FROM public.bills_staging
LIMIT 15;


-- Verify the bill stages structure
SELECT
    number_code,
    LEFT(bill_stages, 1000) AS bill_stages_sample,
    LENGTH(bill_stages) AS stages_length
FROM public.bills_staging
WHERE bill_stages IS NOT NULL
ORDER BY LENGTH(bill_stages) DESC
LIMIT 5;



-- Check the distribution of important Boolean fields
SELECT
    'is_government_bill' AS field,
    is_government_bill AS value,
    COUNT(*) AS records
FROM public.bills_staging
GROUP BY is_government_bill

UNION ALL

SELECT
    'is_house_bill',
    is_house_bill,
    COUNT(*)
FROM public.bills_staging
GROUP BY is_house_bill

UNION ALL

SELECT
    'is_senate_bill',
    is_senate_bill,
    COUNT(*)
FROM public.bills_staging
GROUP BY is_senate_bill

UNION ALL

SELECT
    'received_royal_assent',
    received_royal_assent,
    COUNT(*)
FROM public.bills_staging
GROUP BY received_royal_assent

ORDER BY field, value;
