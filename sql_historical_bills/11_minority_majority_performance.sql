
-- Compare majority and minority governments overall
WITH classified_bills AS (
    SELECT
        government_status,
        bill_id,
        CASE
            WHEN bill_status = 'Royal assent received'
                THEN 'Passed'
            WHEN bill_status = 'Bill defeated'
                THEN 'Defeated'
            WHEN bill_status = 'Bill not proceeded with'
                THEN 'Not proceeded with'
            WHEN bill_status = 'Introduced as pro forma bill'
                THEN 'Pro forma'
            ELSE 'Unresolved'
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
        WHERE outcome_category = 'Unresolved'
    ) AS unresolved,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE outcome_category = 'Passed'
        ) / NULLIF(
            COUNT(*) FILTER (
                WHERE outcome_category <> 'Pro forma'
            ), 0
        ), 1
    ) AS observed_passage_share,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE outcome_category = 'Unresolved'
        ) / NULLIF(
            COUNT(*) FILTER (
                WHERE outcome_category <> 'Pro forma'
            ), 0
        ), 1
    ) AS unresolved_share,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE outcome_category = 'Passed'
        ) / NULLIF(
            COUNT(*) FILTER (
                WHERE outcome_category IN (
                    'Passed',
                    'Defeated',
                    'Not proceeded with'
                )
            ), 0
        ), 1
    ) AS resolved_success_rate
FROM classified_bills
GROUP BY government_status
ORDER BY government_status;



-- Compare majority and minority governments days to royal assent
SELECT
    government_status,

    COUNT(*) AS bills_passed,

    ROUND(AVG(days_to_royal_assent), 1)
        AS average_days_to_royal_assent,

    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY days_to_royal_assent
    ) AS median_days_to_royal_assent,

    MIN(days_to_royal_assent)
        AS minimum_days,

    MAX(days_to_royal_assent)
        AS maximum_days

FROM public.bills_with_government

WHERE
    prime_minister IS NOT NULL
    AND bill_type IN (
        'House Government Bill',
        'Senate Government Bill'
    )
    AND received_royal_assent = TRUE
    AND days_to_royal_assent IS NOT NULL

GROUP BY government_status
ORDER BY government_status;



-- Compare majority and minority governments days to royal assent, by originating chamber.
SELECT
    government_status,
    originating_chamber,

    COUNT(*) AS bills_passed,

    ROUND(
        AVG(days_to_royal_assent), 1
    ) AS average_days,

    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY days_to_royal_assent
    ) AS median_days,

    PERCENTILE_CONT(0.75) WITHIN GROUP (
        ORDER BY days_to_royal_assent
    ) AS percentile_75_days,

    PERCENTILE_CONT(0.90) WITHIN GROUP (
        ORDER BY days_to_royal_assent
    ) AS percentile_90_days

FROM public.bills_with_government

WHERE
    prime_minister IS NOT NULL
    AND bill_type IN (
        'House Government Bill',
        'Senate Government Bill'
    )
    AND received_royal_assent = TRUE
    AND days_to_royal_assent IS NOT NULL

GROUP BY
    government_status,
    originating_chamber

ORDER BY
    originating_chamber,
    government_status;



-- Compare majority and minority government bills introduced by legislative type and originating chamber.
SELECT
    government_status,
    bill_type,
    originating_chamber,

    COUNT(*) AS total_bills,

    COUNT(*) FILTER (
        WHERE bill_status = 'Royal assent received'
    ) AS passed,

    COUNT(*) FILTER (
        WHERE bill_status = 'Bill defeated'
    ) AS defeated,

    COUNT(*) FILTER (
        WHERE bill_status = 'Bill not proceeded with'
    ) AS not_proceeded_with,

    COUNT(*) FILTER (
        WHERE bill_status = 'Introduced as pro forma bill'
    ) AS pro_forma,

    COUNT(*) FILTER (
        WHERE bill_status IS NULL
    ) AS missing_status,

    COUNT(*) FILTER (
        WHERE bill_status IS NOT NULL
          AND bill_status NOT IN (
              'Royal assent received',
              'Bill defeated',
              'Bill not proceeded with',
              'Introduced as pro forma bill'
          )
    ) AS other_in_process_statuses

FROM public.bills_with_government

WHERE
    prime_minister IS NOT NULL
    AND bill_type IN (
        'House Government Bill',
        'Senate Government Bill'
    )

GROUP BY
    government_status,
    bill_type,
    originating_chamber

ORDER BY
    bill_type,
    government_status;