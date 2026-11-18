
-- What percentage of government bills introduced under each prime minister received Royal Assent?

-- Calculate Royal Assent rates
SELECT
    prime_minister,
    governing_party,
    government_status,

    COUNT(*) AS government_bills,

    COUNT(*) FILTER (
        WHERE received_royal_assent IS TRUE
    ) AS bills_received_royal_assent,

    COUNT(*) FILTER (
        WHERE received_royal_assent IS FALSE
    ) AS bills_without_royal_assent,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE received_royal_assent IS TRUE
        ) / NULLIF(COUNT(*), 0),
        1
    ) AS royal_assent_percentage

FROM public.bills_with_government

WHERE
    prime_minister IS NOT NULL
    AND bill_type IN (
        'House Government Bill',
        'Senate Government Bill'
    )

GROUP BY
    prime_minister,
    governing_party,
    government_status

ORDER BY
    MIN(introduction_date);



-- Check how many government bills were excluded
SELECT
    bill_type,
    COUNT(*) AS government_bills_without_introduction_date
FROM public.bills_with_government
WHERE
    introduction_date IS NULL
    AND bill_type IN (
        'House Government Bill',
        'Senate Government Bill'
    )
GROUP BY bill_type
ORDER BY bill_type;



-- Bill statuses for government bills, grouped by prime minister and majority/minority status.
SELECT
    prime_minister,
    government_status,
    bill_status,
    COUNT(*) AS total_bills

FROM public.bills_with_government

WHERE
    prime_minister IS NOT NULL
    AND bill_type IN (
        'House Government Bill',
        'Senate Government Bill'
    )

GROUP BY
    prime_minister,
    government_status,
    bill_status

ORDER BY
    prime_minister,
    government_status,
    total_bills DESC;



-- Build a consistent outcome classification
WITH classified_bills AS (
    SELECT
        prime_minister,
        governing_party,
        government_status,
        bill_id,
        bill_status,
        CASE
            WHEN bill_status = 'Royal assent received'
                THEN 'Passed'
            WHEN bill_status = 'Bill defeated'
                THEN 'Defeated'
            WHEN bill_status = 'Bill not proceeded with'
                THEN 'Not proceeded with'
            WHEN bill_status = 'Introduced as pro forma bill'
                THEN 'Pro forma'
            ELSE 'In legislative process / unresolved'
        END AS outcome_category
    FROM public.bills_with_government
    WHERE
        prime_minister IS NOT NULL
        AND bill_type IN (
            'House Government Bill',
            'Senate Government Bill'
        )
)
SELECT
    prime_minister,
    government_status,
    COUNT(*) AS total_bills,
    COUNT(*) FILTER (
        WHERE outcome_category = 'Passed'
    ) AS passed,
    COUNT(*) FILTER (
        WHERE outcome_category = 'Defeated'
    ) AS defeated,
    COUNT(*) FILTER (
        WHERE outcome_category = 'Not proceeded with'
    ) AS not_proceeded_with,
    COUNT(*) FILTER (
        WHERE outcome_category = 'Pro forma'
    ) AS pro_forma,
    COUNT(*) FILTER (
        WHERE outcome_category = 'In legislative process / unresolved'
    ) AS unresolved,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE outcome_category = 'Passed'
        )
        /
        NULLIF(
            COUNT(*) FILTER (
                WHERE outcome_category IN (
                    'Passed',
                    'Defeated',
                    'Not proceeded with'
                )
            ),
            0
        ),
        1
    ) AS success_rate_resolved_bills
FROM classified_bills
GROUP BY
    prime_minister,
    government_status
ORDER BY
    MIN(prime_minister);
