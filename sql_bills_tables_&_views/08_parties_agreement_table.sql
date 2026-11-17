
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



-- Insert agreements
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
    g.government_id,
    v.supporting_party,
    v.arrangement_type,
    v.start_date::DATE,
    v.end_date::DATE,
    v.arrangement_name,
    v.source_url
FROM (
    VALUES
    (
        'Paul Martin',
        'New Democratic Party',
        'Informal agreement',
        '2005-04-26',
        '2005-05-19',
        '2005 federal budget accommodation',
        'https://www.ourcommons.ca/DocumentViewer/en/1806727'
    ),
    (
        'Justin Trudeau',
        'New Democratic Party',
        'Confidence and supply',
        '2022-03-22',
        '2024-09-04',
        'Delivering for Canadians Now',
        'https://www.pm.gc.ca/en/news/news-releases/2022/03/22/delivering-canadians-now'
    )
) AS v (
    prime_minister,
    supporting_party,
    arrangement_type,
    start_date,
    end_date,
    arrangement_name,
    source_url
)
JOIN public.governments g
    ON g.prime_minister = v.prime_minister;




-- Validate data
SELECT
    g.prime_minister,
    a.supporting_party,
    a.arrangement_type,
    a.start_date,
    a.end_date,
    a.arrangement_name
FROM public.government_support_arrangements a
JOIN public.governments g USING (government_id)
ORDER BY a.start_date;

