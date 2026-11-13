-- ============================================================================
-- POSTGRESQL FOREIGN DATA WRAPPER (FDW) SETUP GUIDE
-- Complete Step-by-Step Implementation with pgAdmin Instructions
-- ============================================================================

-- ============================================================================
-- PREPARATION: UNDERSTAND YOUR ENVIRONMENT
-- ============================================================================
-- You have 5 databases:
-- 1. dev_getfieldy_job_db (port 5432)
-- 2. dev_getfieldy_db (user database, port 5432)
-- 3. dev_getfieldy_tracking_db (port 5432)
-- 4. dev_getfieldy_accounting_db (port 5432)
-- 5. reporting_db (NEW - will be created, port 5432)


-- ============================================================================
-- STEP 1: CREATE REPORT_READER USER IN EACH MICROSERVICE DATABASE
-- ============================================================================

-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ HOW TO EXECUTE IN pgAdmin:                                              │
-- │ 1. Open pgAdmin                                                         │
-- │ 2. Expand "Servers" → Your PostgreSQL Server                           │
-- │ 3. Expand "Databases" → Right-click "dev_getfieldy_job_db"            │
-- │ 4. Select "Query Tool" (or press Alt+Shift+Q)                         │
-- │ 5. Copy and paste the SQL below                                        │
-- │ 6. Click "Execute/Run" button (or press F5)                            │
-- └─────────────────────────────────────────────────────────────────────────┘

-- ─────────────────────────────────────────────────────────────────────────
-- STEP 1A: In dev_getfieldy_job_db → Query Tool
-- ─────────────────────────────────────────────────────────────────────────

-- Connect to reporting_db


CREATE USER report_reader WITH PASSWORD 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp';

GRANT CONNECT ON DATABASE dev_getfieldy_job_db TO report_reader;
GRANT USAGE ON SCHEMA public TO report_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO report_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO report_reader;

-- Verify (should return 1 row showing report_reader)
SELECT usename FROM pg_user WHERE usename = 'report_reader';


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 1B: In dev_getfieldy_db → Query Tool
-- ─────────────────────────────────────────────────────────────────────────
-- Close previous Query Tool, right-click "dev_getfieldy_db" → Query Tool
CREATE USER report_reader WITH PASSWORD 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp';
GRANT CONNECT ON DATABASE dev_getfieldy_db TO report_reader;
GRANT USAGE ON SCHEMA public TO report_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO report_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO report_reader;

-- Verify
SELECT usename FROM pg_user WHERE usename = 'report_reader';


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 1C: In dev_getfieldy_tracking_db → Query Tool
-- ─────────────────────────────────────────────────────────────────────────
-- Close previous Query Tool, right-click "dev_getfieldy_tracking_db" → Query Tool
CREATE USER report_reader WITH PASSWORD 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp';
GRANT CONNECT ON DATABASE dev_getfieldy_tracking_db TO report_reader;
GRANT USAGE ON SCHEMA public TO report_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO report_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO report_reader;

-- Verify
SELECT usename FROM pg_user WHERE usename = 'report_reader';


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 1D: In dev_getfieldy_accounting_db → Query Tool
-- ─────────────────────────────────────────────────────────────────────────
-- Close previous Query Tool, right-click "dev_getfieldy_accounting_db" → Query Tool
CREATE USER report_reader WITH PASSWORD 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp';
GRANT CONNECT ON DATABASE dev_getfieldy_accounting_db TO report_reader;
GRANT USAGE ON SCHEMA public TO report_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO report_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO report_reader;

-- Verify
SELECT usename FROM pg_user WHERE usename = 'report_reader';


-- ============================================================================
-- STEP 2: CREATE REPORTING DATABASE AND USER
-- ============================================================================

-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ HOW TO EXECUTE IN pgAdmin:                                              │
-- │ 1. Right-click on "Databases" (not a specific database)                │
-- │ 2. Select "Query Tool"                                                  │
-- │    OR right-click "postgres" database → Query Tool                     │
-- │ 3. You must be connected as superuser (postgres)                       │
-- └─────────────────────────────────────────────────────────────────────────┘

-- ─────────────────────────────────────────────────────────────────────────
-- STEP 2A: Create reporting_db database
-- Execute in: postgres database → Query Tool
-- ─────────────────────────────────────────────────────────────────────────
CREATE DATABASE reporting_db
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    CONNECTION LIMIT = -1;

-- Verify (should show reporting_db in list)
SELECT datname FROM pg_database WHERE datname = 'reporting_db';


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 2B: Create reporting_user
-- Still in postgres database → Query Tool
-- ─────────────────────────────────────────────────────────────────────────
CREATE USER reporting_user WITH PASSWORD 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp';
GRANT ALL PRIVILEGES ON DATABASE reporting_db TO reporting_user;

-- Verify
SELECT usename FROM pg_user WHERE usename = 'reporting_user';


-- ============================================================================
-- STEP 3: INSTALL POSTGRES_FDW EXTENSION
-- ============================================================================

-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ HOW TO EXECUTE IN pgAdmin:                                              │
-- │ 1. Right-click "reporting_db" → Query Tool                             │
-- │ 2. Make sure you're connected as superuser (postgres)                  │
-- │ 3. Run the commands below                                              │
-- └─────────────────────────────────────────────────────────────────────────┘

-- ─────────────────────────────────────────────────────────────────────────
-- Execute in: reporting_db → Query Tool (as superuser)
-- ─────────────────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Verify (should return 1 row)
SELECT * FROM pg_extension WHERE extname = 'postgres_fdw';


-- ============================================================================
-- STEP 4: CREATE FOREIGN SERVERS
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- Execute in: reporting_db → Query Tool (as superuser)
-- ─────────────────────────────────────────────────────────────────────────

-- Job Server
CREATE SERVER job_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host 'localhost',
    dbname 'dev_getfieldy_job_db',
    port '5432'
);

-- User Server
CREATE SERVER user_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host 'localhost',
    dbname 'dev_getfieldy_db',
    port '5432'
);

-- Tracking Server
CREATE SERVER tracking_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host 'localhost',
    dbname 'dev_getfieldy_tracking_db',
    port '5432'
);

-- Accounting Server
CREATE SERVER accounting_server
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host 'localhost',
    dbname 'dev_getfieldy_accounting_db',
    port '5432'
);

-- Verify (should return 4 rows)
SELECT srvname, srvoptions FROM pg_foreign_server;


-- ============================================================================
-- STEP 5: CREATE USER MAPPINGS
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- Execute in: reporting_db → Query Tool (as superuser)
-- ─────────────────────────────────────────────────────────────────────────

-- Job Server Mapping
CREATE USER MAPPING FOR reporting_user
SERVER job_server
OPTIONS (
    user 'report_reader',
    password 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp',
    password_required 'false'
);

-- User Server Mapping
CREATE USER MAPPING FOR reporting_user
SERVER user_server
OPTIONS (
    user 'report_reader',
    password 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp',
    password_required 'false'
);

-- Tracking Server Mapping
CREATE USER MAPPING FOR reporting_user
SERVER tracking_server
OPTIONS (
    user 'report_reader',
    password 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp',
    password_required 'false'
);

-- Accounting Server Mapping
CREATE USER MAPPING FOR reporting_user
SERVER accounting_server
OPTIONS (
    user 'report_reader',
    password 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp',
    password_required 'false'
);

-- Verify (should return 4 rows)
SELECT
    r.rolname AS local_user,
    s.srvname AS foreign_server,
    um.umoptions
FROM pg_user_mapping um
JOIN pg_roles r
    ON r.oid = um.umuser
JOIN pg_foreign_server s
    ON s.oid = um.umserver;

-- ============================================================================
-- STEP 6: CREATE SCHEMAS IN REPORTING_DB
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- Execute in: reporting_db → Query Tool (as superuser)
-- ─────────────────────────────────────────────────────────────────────────

CREATE SCHEMA IF NOT EXISTS job_schema;
CREATE SCHEMA IF NOT EXISTS user_schema;
CREATE SCHEMA IF NOT EXISTS tracking_schema;
CREATE SCHEMA IF NOT EXISTS accounting_schema;

-- Verify (should return 4 rows)
SELECT schema_name 
FROM information_schema.schemata 
WHERE schema_name LIKE '%_schema'
ORDER BY schema_name;


-- ============================================================================
-- STEP 7: GRANT PERMISSIONS TO REPORTING_USER
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- Execute in: reporting_db → Query Tool (as superuser)
-- ─────────────────────────────────────────────────────────────────────────

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

-- Grant CREATE privileges on schemas (needed for importing foreign tables)
GRANT CREATE ON SCHEMA job_schema TO reporting_user;
GRANT CREATE ON SCHEMA user_schema TO reporting_user;
GRANT CREATE ON SCHEMA tracking_schema TO reporting_user;
GRANT CREATE ON SCHEMA accounting_schema TO reporting_user;
GRANT CREATE ON SCHEMA public TO reporting_user;

-- Verify permissions
SELECT 
    'Schema Permissions' AS permission_type,
    nspname AS object_name,
    array_agg(DISTINCT privilege_type) AS privileges
FROM information_schema.role_usage_grants
JOIN pg_namespace ON object_schema = nspname
WHERE grantee = 'reporting_user'
  AND nspname LIKE '%_schema'
GROUP BY nspname

UNION ALL

SELECT 
    'Foreign Server Permissions' AS permission_type,
    um.srvname AS object_name,
    ARRAY['USAGE'] AS privileges
FROM pg_user_mappings um
WHERE um.usename = 'reporting_user'

ORDER BY permission_type, object_name;

-- ============================================================================
-- STEP 8: IMPORT FOREIGN SCHEMAS
-- ============================================================================

-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ HOW TO SWITCH TO reporting_user IN pgAdmin:                            │
-- │                                                                         │
-- │ METHOD 1: Create New Connection                                        │
-- │ 1. In pgAdmin, right-click "Servers"                                   │
-- │ 2. Create → Server                                                     │
-- │ 3. General Tab: Name = "PostgreSQL (reporting_user)"                  │
-- │ 4. Connection Tab:                                                     │
-- │    - Host: localhost                                                   │
-- │    - Port: 5432                                                        │
-- │    - Maintenance database: reporting_db                               │
-- │    - Username: reporting_user                                         │
-- │    - Password: OsR1tH2A20q78sumZO2fR1lc7MTl8LZp                      │
-- │ 5. Save → Expand server → Right-click "reporting_db" → Query Tool    │
-- │                                                                         │
-- │ METHOD 2: Use SET ROLE (if connected as superuser)                    │
-- │ 1. In reporting_db Query Tool                                         │
-- │ 2. Run: SET ROLE reporting_user;                                      │
-- │ 3. Then execute IMPORT commands below                                 │
-- └─────────────────────────────────────────────────────────────────────────┘

-- ─────────────────────────────────────────────────────────────────────────
-- Execute in: reporting_db → Query Tool (as reporting_user)
-- ─────────────────────────────────────────────────────────────────────────

-- Verify you're reporting_user
SELECT current_user, current_database();
-- Should show: current_user = reporting_user, current_database = reporting_db


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 8A: Import Job Schema Tables
-- ─────────────────────────────────────────────────────────────────────────
SET ROLE reporting_user;

IMPORT FOREIGN SCHEMA public
LIMIT TO (
    task_customfield_option,
    task_customfield_value,
    task_customfield,
    jobs,
    assign_checklists,
    checklist_settings,
    leads,
    lead_defaultfield_option,
    lead_settings_status,
    lead_tags,
    lead_customfield_option,
    lead_customfield_value,
    lead_customfield,
    job_add_on_customfield_option,
    job_add_on_customfield_value,
    job_add_on_customfield,
    assets,
    job_amc_or_assets,
    job_add_costs,
    job_cost_tracking_settings,
    job_customfield_option,
    job_customfield_value,
    job_customfield,
    job_assigned_teams,
    job_assigned_technicians,
    job_time_tracking_settings,
    job_add_times,
    job_defaultfield_option,
    amcs,
    job_tags,
    asset_defaultfield_option,
    asset_customfield_option,
    asset_customfield_value,
    asset_customfield,
    amc_customfield_option,
    amc_customfield_value,
    amc_customfield,
    task_defaultfield_option
)
FROM SERVER job_server
INTO job_schema;

-- Verify job tables imported
SELECT COUNT(*) as job_table_count 
FROM information_schema.tables 
WHERE table_schema = 'job_schema';


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 8B: Import User Schema Tables
-- ─────────────────────────────────────────────────────────────────────────

SET ROLE reporting_user;

CREATE TYPE public.accounttypestatusenum AS ENUM (
    'DELETED',
    'ACTIVE'
);

CREATE TYPE public.teamstatusenum AS ENUM (
    'DELETED',
    'ACTIVE'
);

CREATE TYPE public.locationstatusenum AS ENUM (
    'DELETED',
    'ACTIVE'
);

CREATE TYPE public.workspacestatusenum AS ENUM (
    'DELETED',
    'ACTIVE'
);
CREATE TYPE public.tenantstatusenum AS ENUM (
    'DELETED',
    'ACTIVE',
	'INACTIVE',
	'NOT_VERIFIED'
);


SET ROLE reporting_user;

IMPORT FOREIGN SCHEMA public
LIMIT TO (
    workspaces,
    tenants,
    users,
    companies,
    company_phone_no,
    company_tags,
    company_locations,
    contacts,
    contact_phone_no,
    contact_tags,
    contact_locations,
    company_customfield,
    company_customfield_value,
    company_customfield_option,

    contact_customfield,
    contact_customfield_value,
    contact_customfield_option,

    company_contact_customfield,
    company_contact_customfield_value,
    company_contact_customfield_option,

    user_workspace_association,
    user_location_association,
    user_team_association,
    locations,
    teams,
    account_types,
    user_customfield,
    user_customfield_value,
    user_customfield_option,
    user_tags,

    company_associate_users,
    contact_associate_users
)
FROM SERVER user_server
INTO user_schema;

-- Verify user tables imported
SELECT COUNT(*) as user_table_count 
FROM information_schema.tables 
WHERE table_schema = 'user_schema';


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 8C: Import Accounting Schema Tables
-- ─────────────────────────────────────────────────────────────────────────
SET ROLE reporting_user;

IMPORT FOREIGN SCHEMA public
LIMIT TO (
    invoice_payments,
    invoice_defaultfield_option,
    payment_methods,
    invoices,
    invoice_secondary_customfield_option, 
    invoice_secondary_customfield_value, 
    invoice_secondary_customfield,
    invoice_terms_and_condition_settings,
    invoice_customfield_option,
    invoice_customfield,
    invoice_customfield_value,
    invoice_summary_customfield_option,
    invoice_summary_customfield_value,
    invoice_summary_customfield,
    estimates,
    estimate_defaultfield_option,
    estimate_terms_and_condition_settings,
    estimate_customfield_option,
    estimate_customfield,
    estimate_customfield_value,
    estimate_summary_customfield_option,
    estimate_summary_customfield,
    estimate_summary_customfield_value,
    estimate_secondary_customfield_option,
    estimate_secondary_customfield,
    estimate_secondary_customfield_value,
    inventory_items
)
FROM SERVER accounting_server
INTO accounting_schema;

-- Verify accounting tables imported
SELECT COUNT(*) as accounting_table_count 
FROM information_schema.tables 
WHERE table_schema = 'accounting_schema';


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 8D: Import Tracking Schema Tables (ALL tables)
-- ─────────────────────────────────────────────────────────────────────────
IMPORT FOREIGN SCHEMA public
FROM SERVER tracking_server
INTO tracking_schema;

-- Verify tracking tables imported
SELECT COUNT(*) as tracking_table_count 
FROM information_schema.tables 
WHERE table_schema = 'tracking_schema';


-- ============================================================================
-- STEP 9: VERIFY COMPLETE SETUP
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- Execute in: reporting_db → Query Tool (as reporting_user)
-- ─────────────────────────────────────────────────────────────────────────

-- Check current user and database
SELECT current_user, current_database();

-- Count all imported tables by schema
SELECT 
    schemaname,
    COUNT(*) as table_count
FROM pg_tables
WHERE schemaname IN ('job_schema', 'user_schema', 'tracking_schema', 'accounting_schema')
GROUP BY schemaname
ORDER BY schemaname;

-- List all foreign tables
SELECT 
    foreign_table_schema,
    foreign_table_name,
    foreign_server_name
FROM information_schema.foreign_tables
ORDER BY foreign_table_schema, foreign_table_name;

-- Test data access from each schema
SELECT COUNT(*) as job_count FROM job_schema.jobs;
SELECT COUNT(*) as lead_count FROM job_schema.leads;
SELECT COUNT(*) as user_count FROM user_schema.users;
SELECT COUNT(*) as company_count FROM user_schema.companies;
SELECT COUNT(*) as invoice_count FROM accounting_schema.invoices;
SELECT COUNT(*) as estimate_count FROM accounting_schema.estimates;

-- Sample data from jobs
SELECT * FROM job_schema.jobs LIMIT 5;

-- Sample data from users
SELECT * FROM user_schema.users LIMIT 5;

-- Sample data from invoices
SELECT * FROM accounting_schema.invoices LIMIT 5;


-- ============================================================================
-- TROUBLESHOOTING
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- If you get "permission denied" errors
-- ─────────────────────────────────────────────────────────────────────────
-- Run in reporting_db as SUPERUSER:
GRANT ALL PRIVILEGES ON SCHEMA job_schema TO reporting_user;
GRANT ALL PRIVILEGES ON SCHEMA user_schema TO reporting_user;
GRANT ALL PRIVILEGES ON SCHEMA tracking_schema TO reporting_user;
GRANT ALL PRIVILEGES ON SCHEMA accounting_schema TO reporting_user;


-- ─────────────────────────────────────────────────────────────────────────
-- If you get "password required" error
-- ─────────────────────────────────────────────────────────────────────────
-- Run in reporting_db as SUPERUSER:
DROP USER MAPPING IF EXISTS FOR reporting_user SERVER job_server;
DROP USER MAPPING IF EXISTS FOR reporting_user SERVER user_server;
DROP USER MAPPING IF EXISTS FOR reporting_user SERVER tracking_server;
DROP USER MAPPING IF EXISTS FOR reporting_user SERVER accounting_server;

CREATE USER MAPPING FOR reporting_user SERVER job_server 
OPTIONS (user 'report_reader', password 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp', password_required 'false');

CREATE USER MAPPING FOR reporting_user SERVER user_server 
OPTIONS (user 'report_reader', password 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp', password_required 'false');

CREATE USER MAPPING FOR reporting_user SERVER tracking_server 
OPTIONS (user 'report_reader', password 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp', password_required 'false');

CREATE USER MAPPING FOR reporting_user SERVER accounting_server 
OPTIONS (user 'report_reader', password 'OsR1tH2A20q78sumZO2fR1lc7MTl8LZp', password_required 'false');


-- ─────────────────────────────────────────────────────────────────────────
-- Check if report_reader exists in all databases
-- ─────────────────────────────────────────────────────────────────────────
-- Run this in EACH microservice database:
SELECT usename, usecreatedb, usesuper 
FROM pg_user 
WHERE usename = 'report_reader';


-- ─────────────────────────────────────────────────────────────────────────
-- View connection details
-- ─────────────────────────────────────────────────────────────────────────
-- Run in reporting_db:
SELECT 
    um.umuser::regrole AS local_user,
    fs.srvname AS foreign_server,
    fs.srvoptions AS server_options,
    um.umoptions AS mapping_options
FROM pg_user_mappings um
JOIN pg_foreign_server fs ON um.umserver = fs.oid
ORDER BY fs.srvname;


-- ============================================================================
-- EXECUTION CHECKLIST
-- ============================================================================
/*
□ STEP 1: Create report_reader in 4 microservice databases
  □ dev_getfieldy_job_db
  □ dev_getfieldy_db
  □ dev_getfieldy_tracking_db
  □ dev_getfieldy_accounting_db

□ STEP 2: Create reporting_db and reporting_user (in postgres db)

□ STEP 3: Install postgres_fdw extension (in reporting_db as superuser)

□ STEP 4: Create 4 foreign servers (in reporting_db as superuser)

□ STEP 5: Create 4 user mappings (in reporting_db as superuser)

□ STEP 6: Create 4 schemas (in reporting_db as superuser)

□ STEP 7: Grant permissions (in reporting_db as superuser)

□ STEP 8: Import foreign schemas (in reporting_db as reporting_user)
  □ job_schema (37 tables)
  □ user_schema (24 tables)
  □ accounting_schema (26 tables)
  □ tracking_schema (all tables)

□ STEP 9: Verify setup and test queries

SUCCESS CRITERIA:
✓ All 4 schemas created
✓ Foreign tables visible in each schema
✓ Can SELECT from foreign tables
✓ No permission errors
*/


-- ─────────────────────────────────────────────────────────────────────────
-- In dev_getfieldy_job_db → Query Tool (as superuser)
-- ─────────────────────────────────────────────────────────────────────────
GRANT SELECT ON ALL TABLES IN SCHEMA public TO report_reader;

-- ─────────────────────────────────────────────────────────────────────────
-- In dev_getfieldy_db → Query Tool (as superuser)
-- ─────────────────────────────────────────────────────────────────────────
GRANT SELECT ON ALL TABLES IN SCHEMA public TO report_reader;

-- ─────────────────────────────────────────────────────────────────────────
-- In dev_getfieldy_tracking_db → Query Tool (as superuser)
-- ─────────────────────────────────────────────────────────────────────────
GRANT SELECT ON ALL TABLES IN SCHEMA public TO report_reader;

-- ─────────────────────────────────────────────────────────────────────────
-- In dev_getfieldy_accounting_db → Query Tool (as superuser)
-- ─────────────────────────────────────────────────────────────────────────
GRANT SELECT ON ALL TABLES IN SCHEMA public TO report_reader;