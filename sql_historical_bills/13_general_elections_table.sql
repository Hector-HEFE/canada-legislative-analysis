
-- Create table for federal general elections.
CREATE TABLE public.general_elections (
    election_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    election_date DATE NOT NULL UNIQUE,
    parliament_number INTEGER NOT NULL UNIQUE,
    source_url TEXT,

    CHECK (parliament_number > 0)
);



-- Populate table
INSERT INTO public.general_elections (
    election_date,
    parliament_number,
    source_url
)
VALUES
    ('1993-10-25', 35, 'https://www.ourcommons.ca/procedure-and-practice-4/app12-e.html'),
    ('1997-06-02', 36, 'https://www.ourcommons.ca/procedure-and-practice-4/app12-e.html'),
    ('2000-11-27', 37, 'https://www.ourcommons.ca/procedure-and-practice-4/app12-e.html'),
    ('2004-06-28', 38, 'https://www.ourcommons.ca/procedure-and-practice-4/app12-e.html'),
    ('2006-01-23', 39, 'https://www.ourcommons.ca/procedure-and-practice-4/app12-e.html'),
    ('2008-10-14', 40, 'https://www.ourcommons.ca/procedure-and-practice-4/app12-e.html'),
    ('2011-05-02', 41, 'https://www.ourcommons.ca/procedure-and-practice-4/app12-e.html'),
    ('2015-10-19', 42, 'https://www.ourcommons.ca/procedure-and-practice-4/app12-e.html'),
    ('2019-10-21', 43, 'https://www.ourcommons.ca/procedure-and-practice-4/app12-e.html'),
    ('2021-09-20', 44, 'https://www.ourcommons.ca/procedure-and-practice-4/app12-e.html'),
    ('2025-04-28', 45, 'https://www.ourcommons.ca/procedure-and-practice-4/app12-e.html')
ON CONFLICT (election_date)
DO UPDATE SET
    parliament_number = EXCLUDED.parliament_number,
    source_url = EXCLUDED.source_url;