-- ============================================================================
-- POSTGRESQL FOREIGN DATA WRAPPER (FDW) - REPORTING DATABASE SETUP SCRIPT
-- ============================================================================
-- Description: Sets up the reporting database infrastructure connecting 4
--              microservices (job, user, tracking, accounting) into reporting_db.
-- Source File: dev.sql
-- Formatted for idempotency and fail-safe execution (no "already exists" errors).
-- ============================================================================


-- ============================================================================
-- STEP 1: CONFIGURE MICROSERVICE DATABASES
-- Run as superuser in each respective database
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STEP 1A: In 'dev_getfieldy_job_db' (Open Query Tool on dev_getfieldy_job_db)
-- ----------------------------------------------------------------------------

-- Create report_reader role if it does not already exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'report_reader') THEN
        CREATE USER report_reader WITH PASSWORD 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp';
    ELSE
        ALTER USER report_reader WITH PASSWORD 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp';
    END IF;
END
$$;

GRANT CONNECT ON DATABASE dev_getfieldy_job_db TO report_reader;
GRANT USAGE ON SCHEMA public TO report_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO report_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO report_reader;


-- ----------------------------------------------------------------------------
-- STEP 1B: In 'dev_getfieldy_db' (Open Query Tool on dev_getfieldy_db)
-- ----------------------------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'report_reader') THEN
        CREATE USER report_reader WITH PASSWORD 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp';
    ELSE
        ALTER USER report_reader WITH PASSWORD 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp';
    END IF;
END
$$;

GRANT CONNECT ON DATABASE dev_getfieldy_db TO report_reader;
GRANT USAGE ON SCHEMA public TO report_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO report_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO report_reader;


-- ----------------------------------------------------------------------------
-- STEP 1C: In 'dev_getfieldy_tracking_db' (Open Query Tool on dev_getfieldy_tracking_db)
-- ----------------------------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'report_reader') THEN
        CREATE USER report_reader WITH PASSWORD 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp';
    ELSE
        ALTER USER report_reader WITH PASSWORD 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp';
    END IF;
END
$$;

GRANT CONNECT ON DATABASE dev_getfieldy_tracking_db TO report_reader;
GRANT USAGE ON SCHEMA public TO report_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO report_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO report_reader;


-- ----------------------------------------------------------------------------
-- STEP 1D: In 'dev_getfieldy_accounting_db' (Open Query Tool on dev_getfieldy_accounting_db)
-- ----------------------------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'report_reader') THEN
        CREATE USER report_reader WITH PASSWORD 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp';
    ELSE
        ALTER USER report_reader WITH PASSWORD 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp';
    END IF;
END
$$;

GRANT CONNECT ON DATABASE dev_getfieldy_accounting_db TO report_reader;
GRANT USAGE ON SCHEMA public TO report_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO report_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO report_reader;


-- ============================================================================
-- STEP 2: CREATE REPORTING USER AND DATABASE
-- Execute while connected to the 'postgres' database (as superuser)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STEP 2A: Create reporting_user role
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'reporting_user') THEN
        CREATE USER reporting_user WITH PASSWORD 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp';
    ELSE
        ALTER USER reporting_user WITH PASSWORD 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp';
    END IF;
END
$$;

COMMIT;

-- ----------------------------------------------------------------------------
-- STEP 2B: Create reporting_db database
-- IMPORTANT FOR pgAdmin:
-- PostgreSQL does NOT allow CREATE DATABASE inside a transaction block.
-- Highlight and execute ONLY the CREATE DATABASE statement below by itself,
-- OR create it via pgAdmin UI: Right-click 'Databases' -> 'Create' -> 'Database...'
-- ----------------------------------------------------------------------------
CREATE DATABASE reporting_db
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    CONNECTION LIMIT = -1;

-- ----------------------------------------------------------------------------
-- STEP 2C: Grant privileges
-- ----------------------------------------------------------------------------
GRANT ALL PRIVILEGES ON DATABASE reporting_db TO reporting_user;


-- ============================================================================
-- STEP 3: CONFIGURE REPORTING DATABASE (FDW & SCHEMAS)
-- Execute in 'reporting_db' (as superuser / postgres)
-- ============================================================================

-- Install Foreign Data Wrapper Extension
CREATE EXTENSION IF NOT EXISTS postgres_fdw;


-- ============================================================================
-- STEP 4: CREATE FOREIGN SERVERS
-- Execute in 'reporting_db' (as superuser / postgres)
-- ============================================================================

-- Note on 'host':
-- 1. If all databases are on the same server, 'localhost' or '127.0.0.1' connects locally.
-- 2. If using Cloud SQL / AWS RDS, replace 'localhost' with your database host/endpoint.
-- 3. If connecting via local Unix domain socket on Linux, omit the 'host' line or use '/var/run/postgresql'.

DROP SERVER IF EXISTS job_server CASCADE;
CREATE SERVER job_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host '172.17.0.1',
    dbname 'dev_getfieldy_job_db',
    port '5432'
);

DROP SERVER IF EXISTS user_server CASCADE;
CREATE SERVER user_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host '172.17.0.1',
    dbname 'dev_getfieldy_db',
    port '5432'
);

DROP SERVER IF EXISTS tracking_server CASCADE;
CREATE SERVER tracking_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host '172.17.0.1',
    dbname 'dev_getfieldy_tracking_db',
    port '5432'
);

DROP SERVER IF EXISTS accounting_server CASCADE;
CREATE SERVER accounting_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host '172.17.0.1',
    dbname 'dev_getfieldy_accounting_db',
    port '5432'
);

-- Verify foreign servers were created (should return 4 rows)
SELECT srvname, srvoptions FROM pg_foreign_server;


-- ============================================================================
-- STEP 5: CREATE USER MAPPINGS
-- Create mappings for BOTH reporting_user and postgres (superuser)
-- so either user can import schemas and query foreign tables without errors.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 5A: User Mappings for 'reporting_user'
-- ----------------------------------------------------------------------------
DROP USER MAPPING IF EXISTS FOR reporting_user SERVER job_server;
CREATE USER MAPPING FOR reporting_user
SERVER job_server
OPTIONS (
    user 'report_reader',
    password 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp'
);

DROP USER MAPPING IF EXISTS FOR reporting_user SERVER user_server;
CREATE USER MAPPING FOR reporting_user
SERVER user_server
OPTIONS (
    user 'report_reader',
    password 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp'
);

DROP USER MAPPING IF EXISTS FOR reporting_user SERVER tracking_server;
CREATE USER MAPPING FOR reporting_user
SERVER tracking_server
OPTIONS (
    user 'report_reader',
    password 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp'
);

DROP USER MAPPING IF EXISTS FOR reporting_user SERVER accounting_server;
CREATE USER MAPPING FOR reporting_user
SERVER accounting_server
OPTIONS (
    user 'report_reader',
    password 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp'
);

-- ----------------------------------------------------------------------------
-- 5B: User Mappings for 'postgres' (superuser)
-- ----------------------------------------------------------------------------
DROP USER MAPPING IF EXISTS FOR postgres SERVER job_server;
CREATE USER MAPPING FOR postgres
SERVER job_server
OPTIONS (
    user 'report_reader',
    password 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp'
);

DROP USER MAPPING IF EXISTS FOR postgres SERVER user_server;
CREATE USER MAPPING FOR postgres
SERVER user_server
OPTIONS (
    user 'report_reader',
    password 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp'
);

DROP USER MAPPING IF EXISTS FOR postgres SERVER tracking_server;
CREATE USER MAPPING FOR postgres
SERVER tracking_server
OPTIONS (
    user 'report_reader',
    password 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp'
);

DROP USER MAPPING IF EXISTS FOR postgres SERVER accounting_server;
CREATE USER MAPPING FOR postgres
SERVER accounting_server
OPTIONS (
    user 'report_reader',
    password 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp'
);


-- ============================================================================
-- STEP 6: CREATE SCHEMAS IN REPORTING_DB
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS job_schema;
CREATE SCHEMA IF NOT EXISTS user_schema;
CREATE SCHEMA IF NOT EXISTS tracking_schema;
CREATE SCHEMA IF NOT EXISTS accounting_schema;


-- ============================================================================
-- STEP 7: GRANT PERMISSIONS TO REPORTING_USER
-- ============================================================================

-- Grant schema privileges
GRANT ALL PRIVILEGES ON SCHEMA job_schema TO reporting_user;
GRANT ALL PRIVILEGES ON SCHEMA user_schema TO reporting_user;
GRANT ALL PRIVILEGES ON SCHEMA tracking_schema TO reporting_user;
GRANT ALL PRIVILEGES ON SCHEMA accounting_schema TO reporting_user;
GRANT ALL PRIVILEGES ON SCHEMA public TO reporting_user;

-- Grant foreign server usage
GRANT USAGE ON FOREIGN SERVER job_server TO reporting_user;
GRANT USAGE ON FOREIGN SERVER user_server TO reporting_user;
GRANT USAGE ON FOREIGN SERVER tracking_server TO reporting_user;
GRANT USAGE ON FOREIGN SERVER accounting_server TO reporting_user;

-- Grant CREATE privileges on schemas
GRANT CREATE ON SCHEMA job_schema TO reporting_user;
GRANT CREATE ON SCHEMA user_schema TO reporting_user;
GRANT CREATE ON SCHEMA tracking_schema TO reporting_user;
GRANT CREATE ON SCHEMA accounting_schema TO reporting_user;
GRANT CREATE ON SCHEMA public TO reporting_user;


-- ============================================================================
-- STEP 8: CREATE ENUM TYPES & IMPORT FOREIGN SCHEMAS
-- ============================================================================

-- Create ENUM types required by foreign tables in user_schema
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'accounttypestatusenum') THEN
        CREATE TYPE public.accounttypestatusenum AS ENUM (
            'DELETED',
            'ACTIVE'
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'teamstatusenum') THEN
        CREATE TYPE public.teamstatusenum AS ENUM (
            'DELETED',
            'ACTIVE'
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'locationstatusenum') THEN
        CREATE TYPE public.locationstatusenum AS ENUM (
            'DELETED',
            'ACTIVE'
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'workspacestatusenum') THEN
        CREATE TYPE public.workspacestatusenum AS ENUM (
            'DELETED',
            'ACTIVE'
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tenantstatusenum') THEN
        CREATE TYPE public.tenantstatusenum AS ENUM (
            'DELETED',
            'ACTIVE',
            'INACTIVE',
            'NOT_VERIFIED'
        );
    END IF;
END
$$;

-- Safely remove existing foreign tables prior to import to prevent duplicate relation errors on re-runs
DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN 
        SELECT foreign_table_schema, foreign_table_name 
        FROM information_schema.foreign_tables 
        WHERE foreign_table_schema IN ('job_schema', 'user_schema', 'accounting_schema', 'tracking_schema')
    LOOP
        EXECUTE format('DROP FOREIGN TABLE IF EXISTS %I.%I CASCADE;', rec.foreign_table_schema, rec.foreign_table_name);
    END LOOP;
END
$$;

-- ----------------------------------------------------------------------------
-- STEP 8A: Import Job Schema Foreign Tables (All tables)
-- ----------------------------------------------------------------------------
IMPORT FOREIGN SCHEMA public
FROM SERVER job_server
INTO job_schema;

-- ----------------------------------------------------------------------------
-- STEP 8B: Import User Schema Foreign Tables (All tables)
-- ----------------------------------------------------------------------------
IMPORT FOREIGN SCHEMA public
FROM SERVER user_server
INTO user_schema;

-- ----------------------------------------------------------------------------
-- STEP 8C: Import Accounting Schema Foreign Tables (All tables)
-- ----------------------------------------------------------------------------
IMPORT FOREIGN SCHEMA public
FROM SERVER accounting_server
INTO accounting_schema;

-- ----------------------------------------------------------------------------
-- STEP 8D: Import Tracking Schema Foreign Tables (All tables)
-- ----------------------------------------------------------------------------
IMPORT FOREIGN SCHEMA public
FROM SERVER tracking_server
INTO tracking_schema;


-- ============================================================================
-- STEP 9: VERIFICATION QUERIES
-- ============================================================================

-- Check current connection details
SELECT current_user, current_database();

-- Verify foreign servers
SELECT srvname, srvoptions FROM pg_foreign_server;

-- Verify user mappings
SELECT 
    r.rolname AS local_user,
    s.srvname AS foreign_server,
    um.umoptions
FROM pg_user_mapping um
JOIN pg_roles r ON r.oid = um.umuser
JOIN pg_foreign_server s ON s.oid = um.umserver;

-- Count imported foreign tables by schema
SELECT 
    foreign_table_schema AS schema_name,
    COUNT(*) AS foreign_table_count
FROM information_schema.foreign_tables
WHERE foreign_table_schema IN ('job_schema', 'user_schema', 'tracking_schema', 'accounting_schema')
GROUP BY foreign_table_schema
ORDER BY foreign_table_schema;

-- Test data access from foreign tables
SELECT COUNT(*) AS job_count FROM job_schema.jobs;
SELECT COUNT(*) AS lead_count FROM job_schema.leads;
SELECT COUNT(*) AS user_count FROM user_schema.users;
SELECT COUNT(*) AS company_count FROM user_schema.companies;
SELECT COUNT(*) AS invoice_count FROM accounting_schema.invoices;
SELECT COUNT(*) AS estimate_count FROM accounting_schema.estimates;



GRANT SELECT ON TABLE public.mv_users TO reporting_user;
GRANT USAGE ON SCHEMA public TO reporting_user;
DO $$
DECLARE
    mv RECORD;
BEGIN
    FOR mv IN
        SELECT schemaname, matviewname
        FROM pg_matviews
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format(
            'GRANT SELECT ON TABLE %I.%I TO reporting_user',
            mv.schemaname,
            mv.matviewname
        );
    END LOOP;
END $$;