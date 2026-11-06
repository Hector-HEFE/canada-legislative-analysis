
-- Classify outcomes
/*
Rather than treating every bill without Royal Assent as a failure, let's classify outcomes into five groups:
Classification	                Meaning
Passed	                        Received Royal Assent
Explicitly unsuccessful	        Defeated or not proceeded with
Outside Order of Precedence	    Not advanced through the normal process
In legislative process	        At a reading, committee, report stage, or referred to committee
Other	                        Special or unclassified status
*/

SELECT
    bill_type,
    bill_status,
    CASE
        WHEN received_royal_assent = TRUE
            THEN 'Passed'

        WHEN bill_status IN (
            'Bill defeated',
            'Bill not proceeded with'
        )
            THEN 'Explicitly unsuccessful'

        WHEN bill_status = 'Outside the Order of Precedence'
            THEN 'Outside Order of Precedence'

        WHEN bill_status LIKE 'At %'
          OR bill_status LIKE 'Referred to %'
            THEN 'In legislative process'

        ELSE 'Other'
    END AS outcome_category,

    COUNT(*) AS total_bills

FROM public.bills_clean

GROUP BY
    bill_type,
    bill_status,
    outcome_category

ORDER BY
    bill_type,
    total_bills DESC;




-- Outcome summary
SELECT
    bill_type,

    CASE
        WHEN received_royal_assent = TRUE
            THEN 'Passed'
        WHEN bill_status IN (
            'Bill defeated',
            'Bill not proceeded with'
        )
            THEN 'Explicitly unsuccessful'
        WHEN bill_status = 'Outside the Order of Precedence'
            THEN 'Outside Order of Precedence'
        WHEN bill_status LIKE 'At %'
          OR bill_status LIKE 'Referred to %'
            THEN 'In legislative process'
        ELSE 'Other'
    END AS outcome_category,

    COUNT(*) AS total_bills,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (PARTITION BY bill_type),
        1
    ) AS percentage_of_bill_type

FROM public.bills_clean

GROUP BY bill_type, outcome_category

ORDER BY bill_type, total_bills DESC;