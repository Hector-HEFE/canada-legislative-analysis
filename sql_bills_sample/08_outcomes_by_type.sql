
-- Outcomes by type
SELECT
    bill_type,
    bill_status,
    COUNT(*) AS total_bills
FROM public.bills_clean
GROUP BY
    bill_type,
    bill_status
ORDER BY
    bill_type,
    total_bills DESC;

/*
The main findings
House Government Bills
- 92 of 120 received Royal Assent (76.7%).
- 10 were at second reading.
- 6 were at report stage and second reading.
- 5 were in House committee.
- The remaining 7 were at later stages or classified as pro forma.
Government bills were generally much further through the legislative process, with most receiving Royal Assent.

Private Members' Bills
- 3 of 166 received Royal Assent (1.8%).
- 81 were outside the Order of Precedence.
- 43 were referred to committee before second reading.
- 16 were at second reading.
- 8 were not proceeded with.
- 7 were defeated.
- 7 in committee
- 1 at report stage
The striking point is that 124 of 166 Private Members' Bills (74.7%) were either outside the Order of Precedence or referred to committee before second reading. Only 18 were explicitly classified as defeated or not proceeded with.

Senate bills
- Senate Public Bills: 1 of 9 received Royal Assent; the other 8 were at second reading or in committee.
- Senate Private Bills: all 3 received Royal Assent.
- Senate Government Bills: both received Royal Assent.
The Senate categories are too small to support broad conclusions.
*/

