
-- Calculate Trudeau's minority-government distribution
WITH trudeau_bills AS (
    SELECT
        government_status,
        days_to_royal_assent
    FROM public.bills_with_government
    WHERE prime_minister = 'Justin Trudeau'
      AND bill_type = 'House Government Bill'
      AND received_royal_assent = TRUE
      AND days_to_royal_assent IS NOT NULL
),

duration_buckets AS (
    SELECT
        government_status,
        CASE
            WHEN days_to_royal_assent <= 30 THEN '0–30 days'
            WHEN days_to_royal_assent <= 90 THEN '31–90 days'
            WHEN days_to_royal_assent <= 180 THEN '91–180 days'
            WHEN days_to_royal_assent <= 365 THEN '181–365 days'
            ELSE 'Over 365 days'
        END AS duration_bucket,
        CASE
            WHEN days_to_royal_assent <= 30 THEN 1
            WHEN days_to_royal_assent <= 90 THEN 2
            WHEN days_to_royal_assent <= 180 THEN 3
            WHEN days_to_royal_assent <= 365 THEN 4
            ELSE 5
        END AS bucket_order
    FROM trudeau_bills
)

SELECT
    government_status,
    duration_bucket,
    COUNT(*) AS bills,
    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (PARTITION BY government_status),
        1
    ) AS percentage
FROM duration_buckets
GROUP BY
    government_status,
    duration_bucket,
    bucket_order
ORDER BY
    government_status,
    bucket_order;
/*Justin Trudeau: majority vs. minority
Time to Royal Assent	Majority	Minority
0–30 days	            24.1%	    51.6%
31–90 days	1           6.9%	    14.3%
91–180 days	            6.0%	    7.7%
181–365 days	        12.0%	    12.1%
Over 365 days	        41.0%	    14.3%

Three things stand out:
- 51.6% of passed bills under Trudeau's minority government received Royal Assent within 30 days, compared with 24.1% under his majority government.
- 41% of majority-period bills took over a year, compared with just 14.3% during the minority period.
- The difference is concentrated at the extremes: minority-period bills were much more concentrated in the shortest duration category.

This is consistent with the previous median results:
- Majority: 209.6 days.
- Minority: 28.2 days.
That's a very large difference.

However, we're looking only at bills that passed. 
We cannot conclude that minority governments generally process legislation faster, 
because bills that remain unresolved are excluded.*/



-- Calculate distribution of every Prime Minister, split by majority/minority status.
WITH passed_bills AS (
    SELECT
        prime_minister,
        government_status,
        days_to_royal_assent,

        CASE
            WHEN days_to_royal_assent <= 30
                THEN '0–30 days'
            WHEN days_to_royal_assent <= 90
                THEN '31–90 days'
            WHEN days_to_royal_assent <= 180
                THEN '91–180 days'
            WHEN days_to_royal_assent <= 365
                THEN '181–365 days'
            ELSE 'Over 365 days'
        END AS duration_bucket,

        CASE
            WHEN days_to_royal_assent <= 30 THEN 1
            WHEN days_to_royal_assent <= 90 THEN 2
            WHEN days_to_royal_assent <= 180 THEN 3
            WHEN days_to_royal_assent <= 365 THEN 4
            ELSE 5
        END AS bucket_order

    FROM public.bills_with_government
    WHERE received_royal_assent = TRUE
      AND days_to_royal_assent IS NOT NULL
      AND government_status IS NOT NULL
      AND bill_type = 'House Government Bill'
),

bucket_counts AS (
    SELECT
        prime_minister,
        government_status,
        duration_bucket,
        bucket_order,
        COUNT(*) AS bills
    FROM passed_bills
    GROUP BY
        prime_minister,
        government_status,
        duration_bucket,
        bucket_order
)

SELECT
    prime_minister,
    government_status,
    duration_bucket,
    bills,
    ROUND(
        100.0 * bills /
        SUM(bills) OVER (
            PARTITION BY prime_minister, government_status
        ),
        1
    ) AS percentage
FROM bucket_counts
ORDER BY
    prime_minister,
    government_status,
    bucket_order;
/*Prime Minister	Status	    Within 90 days	Over 365 days
Chrétien	        Majority	45.9%	        6.8%
Martin	            Majority	85.7%	        0.0%
Martin	            Minority	30.4%	        4.3%
Harper	            Majority	52.3%	        19.0%
Harper	            Minority	50.9%	        4.0%
Trudeau	            Majority	41.0%	        41.0%
Trudeau         	Minority	65.9%	        14.3%
Carney	            Majority	100.0%	        0.0%
Carney	            Minority	40.9%	        0.0%

Carney's samples are particularly small: 4 majority and 22 minority bills.

The three most interesting findings
A. Trudeau's majority-to-minority transition

This is the most striking comparison:
- Within 90 days: 41.0% → 65.9%.
- Over one year: 41.0% → 14.3%.
- Median processing time: 209.6 → 28.2 days.
The difference is substantial. It deserves further investigation, particularly because the number of bills passed in each period is reasonably large (83 and 91).

B. Harper's minority government

Harper's minority government also had fewer bills taking over a year:
- Majority: 19.0%.
- Minority: 4.0%.
However, the proportion passed within 90 days barely changed: 52.3% versus 50.9%.

This suggests the difference was primarily in the long-duration tail rather than a general acceleration of all bills.

C. Martin's minority government

Martin experienced the opposite of Trudeau:
- Within 90 days: 85.7% under majority versus 30.4% under minority.
- Over one year: 0% versus 4.3%.
His majority sample was only 21 bills, so we should be cautious.*/
