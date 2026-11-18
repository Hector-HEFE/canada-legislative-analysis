
-- Create the export SQL file
\pset format unaligned
\pset tuples_only on
\pset footer off

-- Standardize exported timestamps to UTC
SET TIME ZONE 'UTC';
SELECT jsonb_build_object(
    'schema_version', '1.0',

    'generated_at',
        to_char(
            CURRENT_TIMESTAMP AT TIME ZONE 'UTC',
            'YYYY-MM-DD"T"HH24:MI:SS"Z"'
        ),

    'total_bills', COUNT(*),

    'bills',
        COALESCE(
            jsonb_agg(
                to_jsonb(b)
                ORDER BY
                    b.introduction_date DESC NULLS LAST,
                    b.bill_id
            ),
            '[]'::jsonb
        )
)
FROM public.vw_bill_explorer b;




-- Run the export from the VS Code terminal

& "C:\Program Files\PostgreSQL\18\bin\psql.exe" `
    -h localhost `
    -p 5432 `
    -U postgres `
    -d canadian_bills `
    -W `
    -X `
    -q `
    -v ON_ERROR_STOP=1 `
    -f "export_queries/20_02_export_bill_explorer.sql" `
    -o "export_queries/export_bill_explorer_view.json"