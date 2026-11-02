-- Create schemas

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS clean;
CREATE SCHEMA IF NOT EXISTS analysis;

-- Confirm that schemas were created

SELECT schema_name FROM information_schema.schemata
WHERE schema_name IN ('raw', 'clean', 'analysis')
ORDER BY schema_name;