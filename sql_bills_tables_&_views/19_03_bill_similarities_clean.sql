
-- Create a clean view excluding self-references from our analytical queries
CREATE OR REPLACE VIEW public.bill_similarities_clean AS
SELECT
    bill_id,
    similar_bill_id
FROM public.bill_similarities
WHERE bill_id <> similar_bill_id;



-- Verify
SELECT
    COUNT(*) AS relationship_rows,
    COUNT(DISTINCT (bill_id, similar_bill_id))
        AS unique_directed_relationships,
    COUNT(DISTINCT (
        LEAST(bill_id, similar_bill_id),
        GREATEST(bill_id, similar_bill_id)
    )) AS unique_undirected_pairs
FROM public.bill_similarities_clean;