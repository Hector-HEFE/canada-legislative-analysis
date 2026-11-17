
-- Create the governments table (based on Prime Minister)

CREATE TABLE public.governments (
    government_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    prime_minister TEXT NOT NULL,
    governing_party TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    source_url TEXT,

    CONSTRAINT valid_government_dates
        CHECK (end_date IS NULL OR end_date > start_date)
);


INSERT INTO public.governments (
    prime_minister,
    governing_party,
    start_date,
    end_date,
    source_url
)
VALUES
(
    'Jean Chrétien',
    'Liberal',
    '1993-11-04',
    '2003-12-12',
    'https://www.ourcommons.ca/Procedure/procedure-and-practice-4/app06-e.html'
),
(
    'Paul Martin',
    'Liberal',
    '2003-12-12',
    '2006-02-06',
    'https://www.ourcommons.ca/Procedure/procedure-and-practice-4/app06-e.html'
),
(
    'Stephen Harper',
    'Conservative',
    '2006-02-06',
    '2015-11-04',
    'https://www.ourcommons.ca/Procedure/procedure-and-practice-4/app06-e.html'
),
(
    'Justin Trudeau',
    'Liberal',
    '2015-11-04',
    '2025-03-14',
    'https://www.ourcommons.ca/Procedure/procedure-and-practice-4/app06-e.html'
),
(
    'Mark Carney',
    'Liberal',
    '2025-03-14',
    NULL,
    'https://www.ourcommons.ca/Procedure/procedure-and-practice-4/app06-e.html'
);

-- Validate table
SELECT *
FROM public.governments
ORDER BY start_date;