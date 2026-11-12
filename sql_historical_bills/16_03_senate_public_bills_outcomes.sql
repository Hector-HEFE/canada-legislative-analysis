
-- Compare outcomes for Senate Public Bills under majority and minority governments, broken down by Prime Minister.
SELECT
    prime_minister,
    government_status,
    COUNT(*) AS total_bills,

    COUNT(*) FILTER (
        WHERE received_royal_assent = TRUE
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
        WHERE received_royal_assent = FALSE
          AND bill_status NOT IN (
              'Bill defeated',
              'Bill not proceeded with',
              'Introduced as pro forma bill'
          )
    ) AS unresolved,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE received_royal_assent = TRUE
        ) / NULLIF(COUNT(*), 0),
        1
    ) AS observed_passage_percentage

FROM public.bills_with_government

WHERE bill_type = 'Senate Public Bill'
  AND introduction_date IS NOT NULL
  AND government_status IS NOT NULL

GROUP BY
    prime_minister,
    government_status

ORDER BY
    prime_minister,
    government_status;
