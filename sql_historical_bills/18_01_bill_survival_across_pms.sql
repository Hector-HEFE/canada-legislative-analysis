
-- Identify who passed each bill.

WITH bill_lifecycle AS (
    SELECT
        b.bill_id,
        b.bill_type,
        b.prime_minister AS introduced_under,
        b.governing_party AS introducing_party,
        b.introduction_date,
        b.royal_assent_date,
        b.received_royal_assent,
        b.bill_status,

        receiving_gov.prime_minister AS passed_under

    FROM public.bills_with_government b

    LEFT JOIN public.governments receiving_gov
        ON b.royal_assent_date::DATE >= receiving_gov.start_date
        AND (
            b.royal_assent_date::DATE < receiving_gov.end_date
            OR receiving_gov.end_date IS NULL
        )

    WHERE b.introduction_date IS NOT NULL
      AND b.government_id IS NOT NULL
),

classified_bills AS (
    SELECT
        *,
        CASE
            WHEN received_royal_assent = TRUE
                 AND passed_under IS NULL
                THEN 'Passed - government not attributed'

            WHEN received_royal_assent = TRUE
                 AND introduced_under = passed_under
                THEN 'Passed under same PM'

            WHEN received_royal_assent = TRUE
                THEN 'Passed under different PM'

            WHEN bill_status = 'Bill defeated'
                THEN 'Defeated'

            WHEN bill_status = 'Bill not proceeded with'
                THEN 'Not proceeded with'

            WHEN bill_status = 'Introduced as pro forma bill'
                THEN 'Pro forma'

            ELSE 'Unresolved'
        END AS outcome_category

    FROM bill_lifecycle
)

SELECT
    introduced_under,
    bill_type,
    outcome_category,
    passed_under,
    COUNT(*) AS bills,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (
            PARTITION BY introduced_under, bill_type
        ),
        1
    ) AS percentage

FROM classified_bills

GROUP BY
    introduced_under,
    bill_type,
    outcome_category,
    passed_under

ORDER BY
    introduced_under,
    bill_type,
    outcome_category,
    passed_under;
/* The dataset contains no recorded bills that received Royal Assent 
under a different Prime Minister from the one in power when they were introduced.

That exposes a limitation in our previous analysis.

We have been tracking individual bill records, 
not necessarily the underlying legislative initiatives.

Suppose:
1. A bill is introduced under Justin Trudeau.
2. Parliament is dissolved before it passes.
3. The same or substantially similar bill is introduced again under Mark Carney.
4. The second version receives Royal Assent.
Our current analysis would treat these as two separate records:
- First record: unresolved under Trudeau.
- Second record: passed under Carney.
It would not recognize that the second bill may be a continuation of the first.

That means our conclusion that no bills crossed Prime Minister transitions is 
only true at the individual-record level. 
It does not establish that legislative initiatives never continued across governments.*/



-- Do any records have previous bill id, number, or are marked as reinstated?
SELECT
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE NULLIF(
            BTRIM(reinstated_from_bill_document_id), ''
        ) IS NOT NULL
    ) AS records_with_previous_bill_id,

    COUNT(*) FILTER (
        WHERE NULLIF(
            BTRIM(reinstated_from_bill_number_code), ''
        ) IS NOT NULL
    ) AS records_with_previous_bill_number,

    COUNT(*) FILTER (
        WHERE did_reinstate_from_previous_session = 'true'
    ) AS records_marked_as_reinstated

FROM public.bills_historical_staging;



