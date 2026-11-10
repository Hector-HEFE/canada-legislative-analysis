
-- Create table to record agreements between political parties

CREATE TABLE public.government_support_arrangements (
    arrangement_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    government_id INTEGER NOT NULL
        REFERENCES public.governments(government_id),

    supporting_party TEXT NOT NULL,

    arrangement_type TEXT NOT NULL,

    start_date DATE NOT NULL,
    end_date DATE,

    arrangement_name TEXT,
    source_url TEXT,

    CONSTRAINT valid_arrangement_dates
        CHECK (end_date IS NULL OR end_date > start_date),

    CONSTRAINT valid_arrangement_type
        CHECK (
            arrangement_type IN (
                'Coalition',
                'Confidence and supply',
                'Informal agreement',
                'Other'
            )
        )
);



-- Insert the Liberal–NDP agreement

INSERT INTO public.government_support_arrangements (
    government_id,
    supporting_party,
    arrangement_type,
    start_date,
    end_date,
    arrangement_name,
    source_url
)
SELECT
    government_id,
    'New Democratic Party',
    'Confidence and supply',
    '2022-03-22',
    '2024-09-04',
    'Delivering for Canadians Now',
    'https://www.pm.gc.ca/en/news/news-releases/2022/03/22/delivering-canadians-now'
FROM public.governments
WHERE prime_minister = 'Justin Trudeau';



-- Validate data
SELECT
    g.prime_minister,
    g.governing_party,
    a.supporting_party,
    a.arrangement_type,
    a.start_date,
    a.end_date,
    a.arrangement_name
FROM public.government_support_arrangements a
JOIN public.governments g
    USING (government_id)
ORDER BY a.start_date;