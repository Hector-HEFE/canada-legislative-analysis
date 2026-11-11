
-- Create table of election results per party.
CREATE TABLE public.election_party_results (
    result_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    election_id INTEGER NOT NULL
        REFERENCES public.general_elections(election_id),
    political_party TEXT NOT NULL,
    seats_won INTEGER NOT NULL,

    UNIQUE (election_id, political_party),

    CHECK (seats_won >= 0)
); 



-- Populate table
INSERT INTO public.election_party_results (
    election_id,
    political_party,
    seats_won
)
SELECT
    e.election_id,
    r.political_party,
    r.seats_won
FROM (
    VALUES
        -- 35th Parliament: 1993
        ('1993-10-25'::DATE, 'Liberal', 177),
        ('1993-10-25'::DATE, 'Bloc Québécois', 54),
        ('1993-10-25'::DATE, 'Reform Party', 52),
        ('1993-10-25'::DATE, 'New Democratic Party', 9),
        ('1993-10-25'::DATE, 'Progressive Conservative', 2),
        ('1993-10-25'::DATE, 'Independent', 1),

        -- 36th Parliament: 1997
        ('1997-06-02'::DATE, 'Liberal', 155),
        ('1997-06-02'::DATE, 'Reform Party', 60),
        ('1997-06-02'::DATE, 'Bloc Québécois', 44),
        ('1997-06-02'::DATE, 'New Democratic Party', 21),
        ('1997-06-02'::DATE, 'Progressive Conservative', 20),
        ('1997-06-02'::DATE, 'Independent', 1),

        -- 37th Parliament: 2000
        ('2000-11-27'::DATE, 'Liberal', 172),
        ('2000-11-27'::DATE, 'Canadian Reform Conservative Alliance', 66),
        ('2000-11-27'::DATE, 'Bloc Québécois', 38),
        ('2000-11-27'::DATE, 'New Democratic Party', 13),
        ('2000-11-27'::DATE, 'Progressive Conservative', 12),

        -- 38th Parliament: 2004
        ('2004-06-28'::DATE, 'Liberal', 135),
        ('2004-06-28'::DATE, 'Conservative', 99),
        ('2004-06-28'::DATE, 'Bloc Québécois', 54),
        ('2004-06-28'::DATE, 'New Democratic Party', 19),
        ('2004-06-28'::DATE, 'Independent', 1),

        -- 39th Parliament: 2006
        ('2006-01-23'::DATE, 'Conservative', 124),
        ('2006-01-23'::DATE, 'Liberal', 103),
        ('2006-01-23'::DATE, 'Bloc Québécois', 51),
        ('2006-01-23'::DATE, 'New Democratic Party', 29),
        ('2006-01-23'::DATE, 'Independent', 1),

        -- 40th Parliament: 2008
        ('2008-10-14'::DATE, 'Conservative', 143),
        ('2008-10-14'::DATE, 'Liberal', 77),
        ('2008-10-14'::DATE, 'Bloc Québécois', 49),
        ('2008-10-14'::DATE, 'New Democratic Party', 37),
        ('2008-10-14'::DATE, 'Independent', 2),

        -- 41st Parliament: 2011
        ('2011-05-02'::DATE, 'Conservative', 166),
        ('2011-05-02'::DATE, 'New Democratic Party', 103),
        ('2011-05-02'::DATE, 'Liberal', 34),
        ('2011-05-02'::DATE, 'Bloc Québécois', 4),
        ('2011-05-02'::DATE, 'Green Party', 1),

        -- 42nd Parliament: 2015
        ('2015-10-19'::DATE, 'Liberal', 184),
        ('2015-10-19'::DATE, 'Conservative', 99),
        ('2015-10-19'::DATE, 'New Democratic Party', 44),
        ('2015-10-19'::DATE, 'Bloc Québécois', 10),
        ('2015-10-19'::DATE, 'Green Party', 1),

        -- 43rd Parliament: 2019
        ('2019-10-21'::DATE, 'Liberal', 157),
        ('2019-10-21'::DATE, 'Conservative', 121),
        ('2019-10-21'::DATE, 'Bloc Québécois', 32),
        ('2019-10-21'::DATE, 'New Democratic Party', 24),
        ('2019-10-21'::DATE, 'Green Party', 3),
        ('2019-10-21'::DATE, 'Independent', 1),

        -- 44th Parliament: 2021
        ('2021-09-20'::DATE, 'Liberal', 160),
        ('2021-09-20'::DATE, 'Conservative', 119),
        ('2021-09-20'::DATE, 'Bloc Québécois', 32),
        ('2021-09-20'::DATE, 'New Democratic Party', 25),
        ('2021-09-20'::DATE, 'Green Party', 2),

        -- 45th Parliament: 2025
        ('2025-04-28'::DATE, 'Liberal', 169),
        ('2025-04-28'::DATE, 'Conservative', 144),
        ('2025-04-28'::DATE, 'Bloc Québécois', 22),
        ('2025-04-28'::DATE, 'New Democratic Party', 7),
        ('2025-04-28'::DATE, 'Green Party', 1)

) AS r(election_date, political_party, seats_won)

JOIN public.general_elections e
    ON e.election_date = r.election_date

ON CONFLICT (election_id, political_party)
DO UPDATE SET
    seats_won = EXCLUDED.seats_won;



-- Verify general_elections table and election_party_results_table 
SELECT
    e.parliament_number,
    e.election_date,
    SUM(r.seats_won) AS seats_accounted_for,
    COUNT(r.result_id) AS number_of_party_entries
FROM public.general_elections e
LEFT JOIN public.election_party_results r
    ON e.election_id = r.election_id
GROUP BY
    e.parliament_number,
    e.election_date
ORDER BY
    e.parliament_number;