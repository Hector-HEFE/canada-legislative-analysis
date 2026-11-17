
-- 1. Similar bill relationships
CREATE TABLE IF NOT EXISTS public.bill_similarities (
    bill_id BIGINT NOT NULL,
    similar_bill_id BIGINT NOT NULL,
    PRIMARY KEY (bill_id, similar_bill_id)
);

-- 2. Extraction tracking
CREATE TABLE IF NOT EXISTS public.bill_similarity_extraction (
    bill_id BIGINT PRIMARY KEY,
    parliament_number INTEGER,
    session_number INTEGER,
    number_code TEXT,
    extraction_status TEXT NOT NULL
);

-- Index for reverse relationship searches
CREATE INDEX IF NOT EXISTS
    idx_bill_similarities_similar_bill_id
ON public.bill_similarities (similar_bill_id);

-- verify results
SELECT
    (SELECT COUNT(*) FROM public.bill_similarities)
        AS total_relationships,

    (SELECT COUNT(*) FROM public.bill_similarity_extraction)
        AS total_bills,

    (SELECT COUNT(*)
     FROM public.bill_similarity_extraction
     WHERE extraction_status = 'Success')
        AS bills_with_similar_bills,

    (SELECT COUNT(*)
     FROM public.bill_similarity_extraction
     WHERE extraction_status = 'No similar bills')
        AS bills_without_similar_bills;