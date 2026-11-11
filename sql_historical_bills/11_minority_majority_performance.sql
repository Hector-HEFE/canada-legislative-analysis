
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



-- 