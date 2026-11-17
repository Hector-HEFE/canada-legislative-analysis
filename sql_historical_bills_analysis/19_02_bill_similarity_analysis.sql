
-- 1. Overall table counts and relationship coverage
SELECT
    (SELECT COUNT(*)
     FROM public.bill_similarity_extraction) AS extracted_bill_records,

    (SELECT COUNT(*)
     FROM public.bill_similarities) AS similarity_relationships,

    (SELECT COUNT(DISTINCT bill_id)
     FROM public.bill_similarities) AS original_bills_with_relationships,

    (SELECT COUNT(DISTINCT similar_bill_id)
     FROM public.bill_similarities) AS distinct_similar_bill_ids,

    (SELECT COUNT(*)
     FROM public.bill_similarities s
     LEFT JOIN public.bills_historical_clean b
        ON s.bill_id = b.bill_id::BIGINT
     WHERE b.bill_id IS NULL) AS missing_original_bill_records,

    (SELECT COUNT(*)
     FROM public.bill_similarities s
     LEFT JOIN public.bills_historical_clean b
        ON s.similar_bill_id = b.bill_id::BIGINT
     WHERE b.bill_id IS NULL) AS similar_bills_outside_dataset;



-- 2. Extraction status breakdown
SELECT
    extraction_status,
    COUNT(*) AS bill_records
FROM public.bill_similarity_extraction
GROUP BY extraction_status
ORDER BY bill_records DESC;



-- 3. Similarity relationships involving the nine known bill records
WITH target_bills AS (
    SELECT unnest(ARRAY[
        9727, 9978, 539391, 1181615, 1394915,
        2153041, 3073041, 3648551, 4327884
    ]::BIGINT[]) AS bill_id
)
SELECT DISTINCT
    s.bill_id AS source_bill_id,
    src.bill_number AS source_bill_number,
    src.parliament_number AS source_parliament,
    src.session_number AS source_session,
    src.prime_minister AS source_prime_minister,
    s.similar_bill_id,
    sim.bill_number AS similar_bill_number,
    sim.parliament_number AS similar_parliament,
    sim.session_number AS similar_session,
    sim.prime_minister AS similar_prime_minister,
    src.bill_title AS source_title,
    sim.bill_title AS similar_title
FROM public.bill_similarities s
LEFT JOIN public.bills_with_government src
    ON s.bill_id = src.bill_id::BIGINT
LEFT JOIN public.bills_with_government sim
    ON s.similar_bill_id = sim.bill_id::BIGINT
WHERE s.bill_id IN (SELECT bill_id FROM target_bills)
   OR s.similar_bill_id IN (SELECT bill_id FROM target_bills)
ORDER BY
    source_parliament,
    source_session,
    source_bill_id;



-- 4. Structure of the similarity network
WITH directed_pairs AS (
    SELECT
        bill_id,
        similar_bill_id,
        LEAST(bill_id, similar_bill_id) AS lower_bill_id,
        GREATEST(bill_id, similar_bill_id) AS higher_bill_id
    FROM public.bill_similarities
),
unique_undirected_pairs AS (
    SELECT
        lower_bill_id,
        higher_bill_id,
        COUNT(DISTINCT (bill_id, similar_bill_id)) AS directions
    FROM directed_pairs
    GROUP BY lower_bill_id, higher_bill_id
),
network_nodes AS (
    SELECT bill_id AS node_id
    FROM public.bill_similarities
    UNION
    SELECT similar_bill_id AS node_id
    FROM public.bill_similarities
)
SELECT
    (SELECT COUNT(*) FROM directed_pairs)
        AS total_relationship_rows,
    (SELECT COUNT(DISTINCT (bill_id, similar_bill_id))
     FROM directed_pairs)
        AS unique_directed_relationships,
    (SELECT COUNT(*) FROM unique_undirected_pairs)
        AS unique_undirected_relationships,
    (SELECT COUNT(*) FROM unique_undirected_pairs
     WHERE directions = 2)
        AS mutually_referenced_pairs,
    (SELECT COUNT(*) FROM directed_pairs
     WHERE bill_id = similar_bill_id)
        AS self_references,
    (SELECT COUNT(*) FROM network_nodes)
        AS distinct_bills_in_network;



-- 5. Bills with the highest number of similarity connections
WITH all_connections AS (
    SELECT bill_id AS connected_bill_id, similar_bill_id AS other_bill_id
    FROM public.bill_similarities
    UNION
    SELECT similar_bill_id AS connected_bill_id, bill_id AS other_bill_id
    FROM public.bill_similarities
)
SELECT
    c.connected_bill_id,
    b.bill_number,
    b.parliament_number,
    b.session_number,
    b.bill_title,
    COUNT(DISTINCT c.other_bill_id) AS similar_bill_count
FROM all_connections c
LEFT JOIN public.bills_historical_clean b
    ON c.connected_bill_id = b.bill_id::BIGINT
GROUP BY
    c.connected_bill_id,
    b.bill_number,
    b.parliament_number,
    b.session_number,
    b.bill_title
ORDER BY similar_bill_count DESC
LIMIT 20;



-- 6. Inspect self-references
SELECT
    s.bill_id,
    b.bill_number,
    b.parliament_number,
    b.session_number,
    b.bill_title
FROM public.bill_similarities s
LEFT JOIN public.bills_historical_clean b
    ON s.bill_id = b.bill_id::BIGINT
WHERE s.bill_id = s.similar_bill_id
ORDER BY b.parliament_number, b.session_number;