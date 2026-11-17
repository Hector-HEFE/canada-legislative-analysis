
-- Create a table to track majority and minority status over time

CREATE TABLE public.government_seat_status (
    status_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    government_id INTEGER NOT NULL
        REFERENCES public.governments(government_id),

    status_start_date DATE NOT NULL,
    status_end_date DATE,

    seats_held INTEGER NOT NULL,
    total_seats INTEGER NOT NULL,

    government_status TEXT NOT NULL,

    source_url TEXT,

    CONSTRAINT valid_seat_counts
        CHECK (
            seats_held >= 0
            AND total_seats > 0
            AND seats_held <= total_seats
        ),

    CONSTRAINT valid_status_dates
        CHECK (
            status_end_date IS NULL
            OR status_end_date > status_start_date
        ),

    CONSTRAINT valid_government_status
        CHECK (
            government_status IN ('Majority', 'Minority')
        )
);



-- Validate empty table
SELECT *
FROM public.government_seat_status;



-- Populate majority/minority periods
INSERT INTO public.government_seat_status (
    government_id,
    status_start_date,
    status_end_date,
    seats_held,
    total_seats,
    government_status,
    source_url
)
SELECT
    g.government_id,
    raw.status_start_date::DATE,
    raw.status_end_date::DATE,
    raw.seats_held,
    raw.total_seats,
    raw.government_status,
    raw.source_url
FROM (
    VALUES
    -- Jean Chrétien
    ('Jean Chrétien', '1993-11-04', '1997-06-02', 177, 295, 'Majority',
     'https://www.ourcommons.ca/procedure/procedure-and-practice-4/app12-e.html'),
    ('Jean Chrétien', '1997-06-02', '2000-11-27', 155, 301, 'Majority',
     'https://www.ourcommons.ca/procedure/procedure-and-practice-4/app12-e.html'),
    ('Jean Chrétien', '2000-11-27', '2003-12-12', 172, 301, 'Majority',
     'https://www.ourcommons.ca/procedure/procedure-and-practice-4/app12-e.html'),

    -- Paul Martin
    ('Paul Martin', '2003-12-12', '2004-06-28', 172, 301, 'Majority',
     'https://www.ourcommons.ca/procedure/procedure-and-practice-4/app12-e.html'),
    ('Paul Martin', '2004-06-28', '2006-02-06', 135, 308, 'Minority',
     'https://www.ourcommons.ca/procedure/procedure-and-practice-4/app12-e.html'),

    -- Stephen Harper
    ('Stephen Harper', '2006-02-06', '2008-10-14', 124, 308, 'Minority',
     'https://www.ourcommons.ca/procedure/procedure-and-practice-4/app12-e.html'),
    ('Stephen Harper', '2008-10-14', '2011-05-02', 143, 308, 'Minority',
     'https://www.ourcommons.ca/procedure/procedure-and-practice-4/app12-e.html'),
    ('Stephen Harper', '2011-05-02', '2015-11-04', 166, 308, 'Majority',
     'https://www.ourcommons.ca/procedure/procedure-and-practice-4/app12-e.html'),

    -- Justin Trudeau
    ('Justin Trudeau', '2015-11-04', '2019-10-21', 184, 338, 'Majority',
     'https://www.ourcommons.ca/procedure/procedure-and-practice-4/app12-e.html'),
    ('Justin Trudeau', '2019-10-21', '2021-09-20', 157, 338, 'Minority',
     'https://www.ourcommons.ca/procedure/procedure-and-practice-4/app12-e.html'),
    ('Justin Trudeau', '2021-09-20', '2025-03-14', 160, 338, 'Minority',
     'https://www.ourcommons.ca/procedure/procedure-and-practice-4/app12-e.html'),

    -- Mark Carney
    ('Mark Carney', '2025-03-14', '2025-04-28', 153, 338, 'Minority',
     'https://elections.ca/content.aspx?dir=rep%2Foff%2Fsta_ge45&document=p2&lang=e&section=res'),
    ('Mark Carney', '2025-04-28', '2026-04-13', 169, 343, 'Minority',
     'https://elections.ca/content.aspx?dir=rep%2Foff%2Fsta_ge45&document=p2&lang=e&section=res'),
    ('Mark Carney', '2026-04-13', '2026-08-15', 174, 343, 'Majority',
     'https://politicalrecord.ca/'),
    ('Mark Carney', '2026-08-15', '2026-08-31', 171, 343, 'Minority',
     'https://politicalrecord.ca/'),
    ('Mark Carney', '2026-08-31', NULL, 173, 343, 'Majority',
     'https://politicalrecord.ca/')

) AS raw (
    prime_minister,
    status_start_date,
    status_end_date,
    seats_held,
    total_seats,
    government_status,
    source_url
)
JOIN public.governments g
    ON g.prime_minister = raw.prime_minister;



-- Validate data
SELECT
    g.prime_minister,
    g.governing_party,
    s.status_start_date,
    s.status_end_date,
    s.seats_held,
    s.total_seats,
    s.government_status
FROM public.government_seat_status s
JOIN public.governments g
    ON g.government_id = s.government_id
ORDER BY s.status_start_date;



-- Consistency check, expecting 0
SELECT
    prime_minister,
    status_start_date,
    seats_held,
    total_seats,
    government_status,
    CASE
        WHEN seats_held > total_seats / 2.0
            THEN 'Majority'
        ELSE 'Minority'
    END AS calculated_status
FROM public.governments g
JOIN public.government_seat_status s
    USING (government_id)
WHERE government_status <>
    CASE
        WHEN seats_held > total_seats / 2.0
            THEN 'Majority'
        ELSE 'Minority'
    END;