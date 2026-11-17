
-- 7. Test connected-component logic:
-- First Nations veterans' compensation
WITH RECURSIVE connections AS (
    -- Treat every relationship as bidirectional
    SELECT
        bill_id AS start_id,
        similar_bill_id AS connected_id
    FROM public.bill_similarities_clean
    UNION
    SELECT
        similar_bill_id AS start_id,
        bill_id AS connected_id
    FROM public.bill_similarities_clean
),
target_bills AS (
    SELECT unnest(ARRAY[
        9978, 539391, 1181615, 1394915,
        2153041, 3073041, 3648551, 4327884
    ]::BIGINT[]) AS bill_id
),
reachability AS (
    SELECT
        bill_id AS start_id,
        bill_id AS connected_id
    FROM target_bills
    UNION
    SELECT
        r.start_id,
        c.connected_id
    FROM reachability r
    JOIN connections c
        ON r.connected_id = c.start_id
    JOIN target_bills t
        ON c.connected_id = t.bill_id
)
SELECT DISTINCT
    start_id,
    connected_id
FROM reachability
ORDER BY start_id, connected_id;




/* Validate that the above query gave indirect indirect relationships, 
by querying direct relationships below*/
WITH target_bills AS (
    SELECT unnest(ARRAY[
        9978, 539391, 1181615, 1394915,
        2153041, 3073041, 3648551, 4327884
    ]::BIGINT[]) AS bill_id
),

direct_connections AS (
    SELECT
        s.bill_id,
        s.similar_bill_id
    FROM public.bill_similarities_clean s
    JOIN target_bills a
        ON s.bill_id = a.bill_id
    JOIN target_bills b
        ON s.similar_bill_id = b.bill_id
)

SELECT
    bill_id,
    COUNT(DISTINCT similar_bill_id) AS directly_referenced_bills
FROM direct_connections
GROUP BY bill_id
ORDER BY bill_id;
/*So the recursive query was doing something meaningful: 
it was discovering connections 
that aren't explicitly recorded as direct relationships.*/




-- 8. Identify connected components across the full network
/* Create bill_similarity_edges_work
This table represents the connections between bills.

Original bill_similarities_clean looks like this:
bill_id	similar_bill_id
100	    200
200	    100
200	    300
300	    200

The edges table simplifies that to:
node_a	node_b
100	    200
200	    300

Why? Because for identifying connected groups, A → B and B → A represent the same connection.
*/
DROP TABLE IF EXISTS public.bill_similarity_edges_work;
CREATE TABLE public.bill_similarity_edges_work AS
SELECT
    LEAST(bill_id, similar_bill_id) AS node_a,
    GREATEST(bill_id, similar_bill_id) AS node_b
FROM public.bill_similarities_clean
GROUP BY
    LEAST(bill_id, similar_bill_id),
    GREATEST(bill_id, similar_bill_id);

/*Creat bill_similarity_labels_work
This table assigns each bill a group identifier.

Initially:
node_id	component_id
100	    100
200	    200
300	    300

The iterative SQL process then propagates the smallest component ID across connected bills.

Eventually:
node_id	component_id
100	    100
200	    100
300	    100

Now we know all three bills belong to the same connected component.
*/
DROP TABLE IF EXISTS public.bill_similarity_labels_work;
CREATE TABLE public.bill_similarity_labels_work AS
SELECT
    bill_id AS node_id,
    bill_id AS component_id
FROM (
    SELECT bill_id FROM public.bill_similarities_clean
    UNION
    SELECT similar_bill_id FROM public.bill_similarities_clean
) AS network_nodes;

-- Verify both working tables
SELECT
    'Labels' AS table_name,
    COUNT(*) AS rows
FROM public.bill_similarity_labels_work

UNION ALL

SELECT
    'Edges',
    COUNT(*)
FROM public.bill_similarity_edges_work;

--Propagate group labels
DO $$
DECLARE
    changed_rows INTEGER;
    iteration_count INTEGER := 0;
BEGIN
    LOOP
        WITH candidate_labels AS (
            SELECT
                node_id,
                component_id
            FROM public.bill_similarity_labels_work

            UNION ALL

            SELECT
                e.node_a,
                b.component_id
            FROM public.bill_similarity_edges_work e
            JOIN public.bill_similarity_labels_work b
                ON b.node_id = e.node_b

            UNION ALL

            SELECT
                e.node_b,
                a.component_id
            FROM public.bill_similarity_edges_work e
            JOIN public.bill_similarity_labels_work a
                ON a.node_id = e.node_a
        ),

        new_labels AS (
            SELECT
                node_id,
                MIN(component_id) AS component_id
            FROM candidate_labels
            GROUP BY node_id
        )

        UPDATE public.bill_similarity_labels_work current
        SET component_id = new_labels.component_id
        FROM new_labels
        WHERE current.node_id = new_labels.node_id
          AND current.component_id <> new_labels.component_id;

        GET DIAGNOSTICS changed_rows = ROW_COUNT;

        iteration_count := iteration_count + 1;

        EXIT WHEN changed_rows = 0;
    END LOOP;

    RAISE NOTICE 'Completed after % iterations.', iteration_count;
END $$;



--Summarize the results
WITH component_sizes AS (
    SELECT
        component_id,
        COUNT(*) AS bill_count
    FROM bill_similarity_labels_work
    GROUP BY component_id
)
SELECT
    COUNT(*) AS total_components,
    SUM(bill_count) AS bills_in_network,
    MAX(bill_count) AS largest_component_size,
    ROUND(AVG(bill_count), 2) AS average_component_size,
    COUNT(*) FILTER (WHERE bill_count = 1) AS single_bill_components,
    COUNT(*) FILTER (WHERE bill_count > 1) AS multi_bill_components
FROM component_sizes;




/* Verifying 4,239 network nodes identified in the original table vs. 
4,236 identified in the clean view */  
SELECT
    'Original table' AS source,
    COUNT(*) AS relationship_rows,
    COUNT(DISTINCT bill_id) AS distinct_source_bills,
    COUNT(DISTINCT similar_bill_id) AS distinct_referenced_bills
FROM public.bill_similarities
UNION ALL
SELECT
    'Clean view',
    COUNT(*),
    COUNT(DISTINCT bill_id),
    COUNT(DISTINCT similar_bill_id)
FROM public.bill_similarities_clean;
/*The three-bill difference in network membership means three bills 
appear in the original network only through self-references */





-- Largest components
SELECT
    component_id,
    COUNT(*) AS bills_in_component
FROM public.bill_similarity_labels_work
GROUP BY component_id
ORDER BY bills_in_component DESC, component_id
LIMIT 20;

-- Inspect the largest component
SELECT
    l.component_id,
    b.bill_id,
    b.bill_number,
    b.parliament_number,
    b.session_number,
    b.bill_title,
    b.prime_minister,
    b.governing_party,
    b.introduction_date,
    b.received_royal_assent,
    b.bill_status
FROM public.bill_similarity_labels_work l
JOIN public.bills_with_government b
    ON l.node_id = b.bill_id::BIGINT
WHERE l.component_id = 9104
ORDER BY
    b.parliament_number,
    b.session_number,
    b.bill_number;




-- Inspect direct relationships within component 9104

SELECT
    e.node_a AS bill_id_a,
    a.bill_number AS bill_number_a,
    a.parliament_number AS parliament_a,
    a.session_number AS session_a,
    a.bill_title AS title_a,

    e.node_b AS bill_id_b,
    b.bill_number AS bill_number_b,
    b.parliament_number AS parliament_b,
    b.session_number AS session_b,
    b.bill_title AS title_b

FROM public.bill_similarity_edges_work e

JOIN public.bill_similarity_labels_work la
    ON e.node_a = la.node_id

JOIN public.bill_similarity_labels_work lb
    ON e.node_b = lb.node_id

JOIN public.bills_with_government a
    ON e.node_a = a.bill_id::BIGINT

JOIN public.bills_with_government b
    ON e.node_b = b.bill_id::BIGINT

WHERE la.component_id = 9104
  AND lb.component_id = 9104

ORDER BY
    a.parliament_number,
    a.session_number,
    a.bill_number,
    b.parliament_number,
    b.session_number;



-- checking the original bill_similarities records for the four unexplained connections, alongside their extraction records
WITH target_pairs AS (
    SELECT *
    FROM (VALUES
        (197333::BIGINT, 6253542::BIGINT),
        (1188121::BIGINT, 6253551::BIGINT),
        (5081261::BIGINT, 6253542::BIGINT),
        (5081557::BIGINT, 6253542::BIGINT)
    ) AS t(bill_a, bill_b)
)
SELECT
    e.node_a AS bill_id_1,
    b1.bill_number AS bill_number_1,
    b1.parliament_number AS parliament_1,
    b1.bill_title AS title_1,
    e.node_b AS bill_id_2,
    b2.bill_number AS bill_number_2,
    b2.parliament_number AS parliament_2,
    b2.bill_title AS title_2
FROM public.bill_similarity_edges_work e
JOIN target_pairs t
    ON e.node_a = LEAST(t.bill_a, t.bill_b)
    AND e.node_b = GREATEST(t.bill_a, t.bill_b)
LEFT JOIN public.bills_historical_clean b1
    ON e.node_a = b1.bill_id::BIGINT
LEFT JOIN public.bills_historical_clean b2
    ON e.node_b = b2.bill_id::BIGINT
ORDER BY e.node_a;