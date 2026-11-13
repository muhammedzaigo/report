-- ============================================================================
-- POSTGRESQL FOREIGN DATA WRAPPER (FDW) COMPLETE REVOKE/CLEANUP SCRIPT
-- Execute these commands to completely remove the FDW setup
-- ============================================================================

-- ============================================================================
-- STEP 1: DROP FOREIGN TABLES AND SCHEMAS IN REPORTING_DB
-- ============================================================================

-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ Execute in: reporting_db → Query Tool (as superuser/postgres)          │
-- └─────────────────────────────────────────────────────────────────────────┘

-- Drop all schemas with CASCADE (removes all foreign tables automatically)
DROP SCHEMA IF EXISTS job_schema CASCADE;
DROP SCHEMA IF EXISTS user_schema CASCADE;
DROP SCHEMA IF EXISTS tracking_schema CASCADE;
DROP SCHEMA IF EXISTS accounting_schema CASCADE;

-- Verify schemas dropped
SELECT schema_name 
FROM information_schema.schemata 
WHERE schema_name LIKE '%_schema';
-- Should return 0 rows


-- ============================================================================
-- STEP 2: DROP USER MAPPINGS
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- Execute in: reporting_db → Query Tool (as superuser/postgres)
-- ─────────────────────────────────────────────────────────────────────────

DROP USER MAPPING IF EXISTS FOR reporting_user SERVER job_server;
DROP USER MAPPING IF EXISTS FOR reporting_user SERVER user_server;
DROP USER MAPPING IF EXISTS FOR reporting_user SERVER tracking_server;
DROP USER MAPPING IF EXISTS FOR reporting_user SERVER accounting_server;

-- Verify user mappings dropped
SELECT 
    um.umuser::regrole AS local_user,
    fs.srvname AS foreign_server
FROM pg_user_mappings um
JOIN pg_foreign_server fs ON um.umserver = fs.oid
WHERE um.umuser::regrole::text = 'reporting_user';
-- Should return 0 rows


-- ============================================================================
-- STEP 3: DROP FOREIGN SERVERS
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- Execute in: reporting_db → Query Tool (as superuser/postgres)
-- ─────────────────────────────────────────────────────────────────────────

DROP SERVER IF EXISTS job_server CASCADE;
DROP SERVER IF EXISTS user_server CASCADE;
DROP SERVER IF EXISTS tracking_server CASCADE;
DROP SERVER IF EXISTS accounting_server CASCADE;

-- Verify foreign servers dropped
SELECT srvname FROM pg_foreign_server;
-- Should return 0 rows (or only servers not created by you)


-- ============================================================================
-- STEP 4: DROP POSTGRES_FDW EXTENSION
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- Execute in: reporting_db → Query Tool (as superuser/postgres)
-- ─────────────────────────────────────────────────────────────────────────

DROP EXTENSION IF EXISTS postgres_fdw CASCADE;

-- Verify extension dropped
SELECT * FROM pg_extension WHERE extname = 'postgres_fdw';
-- Should return 0 rows


-- ============================================================================
-- STEP 5: REVOKE PRIVILEGES FROM REPORTING_USER
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- Execute in: reporting_db → Query Tool (as superuser/postgres)
-- ─────────────────────────────────────────────────────────────────────────

-- Note: These may fail if schemas are already dropped, that's OK
REVOKE ALL PRIVILEGES ON SCHEMA job_schema FROM reporting_user;
REVOKE ALL PRIVILEGES ON SCHEMA user_schema FROM reporting_user;
REVOKE ALL PRIVILEGES ON SCHEMA tracking_schema FROM reporting_user;
REVOKE ALL PRIVILEGES ON SCHEMA accounting_schema FROM reporting_user;
REVOKE ALL PRIVILEGES ON SCHEMA public FROM reporting_user;

REVOKE ALL PRIVILEGES ON DATABASE reporting_db FROM reporting_user;


-- ============================================================================
-- STEP 6: DROP REPORTING_USER
-- ============================================================================

-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ Execute in: postgres database → Query Tool (as superuser)              │
-- │ OR disconnect from reporting_db first, then connect to postgres db     │
-- └─────────────────────────────────────────────────────────────────────────┘

-- Terminate any active connections by reporting_user
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE usename = 'reporting_user' AND pid <> pg_backend_pid();

-- Drop the user
DROP USER IF EXISTS reporting_user;

-- Verify user dropped
SELECT usename FROM pg_user WHERE usename = 'reporting_user';
-- Should return 0 rows


-- ============================================================================
-- STEP 7: DROP REPORTING_DB DATABASE
-- ============================================================================

-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ IMPORTANT: You CANNOT drop a database while connected to it!           │
-- │ Execute in: postgres database → Query Tool (as superuser)              │
-- └─────────────────────────────────────────────────────────────────────────┘

-- Terminate all connections to reporting_db
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'reporting_db' AND pid <> pg_backend_pid();

-- Drop the database
DROP DATABASE IF EXISTS reporting_db;

-- Verify database dropped
SELECT datname FROM pg_database WHERE datname = 'reporting_db';
-- Should return 0 rows


-- ============================================================================
-- STEP 8: REVOKE PRIVILEGES FROM REPORT_READER IN MICROSERVICE DATABASES
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- STEP 8A: In dev_getfieldy_job_db → Query Tool (as superuser)
-- ─────────────────────────────────────────────────────────────────────────

REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM report_reader;
REVOKE USAGE ON SCHEMA public FROM report_reader;
REVOKE CONNECT ON DATABASE dev_getfieldy_job_db FROM report_reader;

-- Reset default privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE SELECT ON TABLES FROM report_reader;

-- Verify
SELECT 
    schemaname, 
    tablename, 
    array_agg(privilege_type) as privileges
FROM information_schema.table_privileges
WHERE grantee = 'report_reader'
GROUP BY schemaname, tablename;
-- Should return 0 rows


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 8B: In dev_getfieldy_db → Query Tool (as superuser)
-- ─────────────────────────────────────────────────────────────────────────

REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM report_reader;
REVOKE USAGE ON SCHEMA public FROM report_reader;
REVOKE CONNECT ON DATABASE dev_getfieldy_db FROM report_reader;

ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE SELECT ON TABLES FROM report_reader;

-- Verify
SELECT 
    schemaname, 
    tablename, 
    array_agg(privilege_type) as privileges
FROM information_schema.table_privileges
WHERE grantee = 'report_reader'
GROUP BY schemaname, tablename;
-- Should return 0 rows


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 8C: In dev_getfieldy_tracking_db → Query Tool (as superuser)
-- ─────────────────────────────────────────────────────────────────────────

REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM report_reader;
REVOKE USAGE ON SCHEMA public FROM report_reader;
REVOKE CONNECT ON DATABASE dev_getfieldy_tracking_db FROM report_reader;

ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE SELECT ON TABLES FROM report_reader;

-- Verify
SELECT 
    schemaname, 
    tablename, 
    array_agg(privilege_type) as privileges
FROM information_schema.table_privileges
WHERE grantee = 'report_reader'
GROUP BY schemaname, tablename;
-- Should return 0 rows


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 8D: In dev_getfieldy_accounting_db → Query Tool (as superuser)
-- ─────────────────────────────────────────────────────────────────────────

REVOKE SELECT ON ALL TABLES IN SCHEMA public FROM report_reader;
REVOKE USAGE ON SCHEMA public FROM report_reader;
REVOKE CONNECT ON DATABASE dev_getfieldy_accounting_db FROM report_reader;

ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE SELECT ON TABLES FROM report_reader;

-- Verify
SELECT 
    schemaname, 
    tablename, 
    array_agg(privilege_type) as privileges
FROM information_schema.table_privileges
WHERE grantee = 'report_reader'
GROUP BY schemaname, tablename;
-- Should return 0 rows


-- ============================================================================
-- STEP 9: DROP REPORT_READER USER FROM EACH MICROSERVICE DATABASE
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- STEP 9A: In dev_getfieldy_job_db → Query Tool (as superuser)
-- ─────────────────────────────────────────────────────────────────────────

-- Terminate any active connections
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE usename = 'report_reader' AND pid <> pg_backend_pid();

DROP USER IF EXISTS report_reader;

-- Verify
SELECT usename FROM pg_user WHERE usename = 'report_reader';
-- Should return 0 rows


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 9B: In dev_getfieldy_db → Query Tool (as superuser)
-- ─────────────────────────────────────────────────────────────────────────

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE usename = 'report_reader' AND pid <> pg_backend_pid();

DROP USER IF EXISTS report_reader;

-- Verify
SELECT usename FROM pg_user WHERE usename = 'report_reader';
-- Should return 0 rows


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 9C: In dev_getfieldy_tracking_db → Query Tool (as superuser)
-- ─────────────────────────────────────────────────────────────────────────

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE usename = 'report_reader' AND pid <> pg_backend_pid();

DROP USER IF EXISTS report_reader;

-- Verify
SELECT usename FROM pg_user WHERE usename = 'report_reader';
-- Should return 0 rows


-- ─────────────────────────────────────────────────────────────────────────
-- STEP 9D: In dev_getfieldy_accounting_db → Query Tool (as superuser)
-- ─────────────────────────────────────────────────────────────────────────

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE usename = 'report_reader' AND pid <> pg_backend_pid();

DROP USER IF EXISTS report_reader;

-- Verify
SELECT usename FROM pg_user WHERE usename = 'report_reader';
-- Should return 0 rows


-- ============================================================================
-- FINAL VERIFICATION - RUN IN POSTGRES DATABASE
-- ============================================================================

-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │ Execute in: postgres database → Query Tool (as superuser)              │
-- └─────────────────────────────────────────────────────────────────────────┘

-- Check that reporting_db is gone
SELECT datname FROM pg_database WHERE datname = 'reporting_db';
-- Should return 0 rows

-- Check that reporting_user is gone
SELECT usename FROM pg_user WHERE usename IN ('reporting_user', 'report_reader');
-- Should return 0 rows

-- Check for any remaining foreign servers across all databases
SELECT datname, srvname 
FROM pg_database, pg_foreign_server 
WHERE datname IN ('dev_getfieldy_job_db', 'dev_getfieldy_db', 
                  'dev_getfieldy_tracking_db', 'dev_getfieldy_accounting_db');
-- Should return 0 rows


-- ============================================================================
-- CLEANUP CHECKLIST
-- ============================================================================
/*
EXECUTION ORDER (CRITICAL - Follow this order):

□ STEP 1: Drop schemas in reporting_db (as superuser)
  ✓ Removes all foreign tables automatically

□ STEP 2: Drop user mappings in reporting_db (as superuser)
  ✓ Disconnects reporting_user from foreign servers

□ STEP 3: Drop foreign servers in reporting_db (as superuser)
  ✓ Removes connection definitions

□ STEP 4: Drop postgres_fdw extension in reporting_db (as superuser)
  ✓ Removes FDW functionality

□ STEP 5: Revoke privileges in reporting_db (as superuser)
  ✓ Removes permissions

□ STEP 6: Drop reporting_user (in postgres db as superuser)
  ✓ Removes the reporting database user

□ STEP 7: Drop reporting_db database (in postgres db as superuser)
  ✓ Completely removes reporting database

□ STEP 8: Revoke privileges in each microservice database (as superuser)
  □ dev_getfieldy_job_db
  □ dev_getfieldy_db
  □ dev_getfieldy_tracking_db
  □ dev_getfieldy_accounting_db

□ STEP 9: Drop report_reader from each microservice database (as superuser)
  □ dev_getfieldy_job_db
  □ dev_getfieldy_db
  □ dev_getfieldy_tracking_db
  □ dev_getfieldy_accounting_db

□ STEP 10: Final verification in postgres database

CLEANUP COMPLETE WHEN:
✓ reporting_db database does not exist
✓ reporting_user does not exist
✓ report_reader does not exist in any database
✓ No foreign servers remain
✓ No foreign tables remain
✓ No user mappings remain
*/


-- ============================================================================
-- TROUBLESHOOTING
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────
-- If you get "database is being accessed by other users"
-- ─────────────────────────────────────────────────────────────────────────
-- Run in postgres database:
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'reporting_db' AND pid <> pg_backend_pid();

-- Then try dropping again
DROP DATABASE reporting_db;


-- ─────────────────────────────────────────────────────────────────────────
-- If you get "role cannot be dropped because some objects depend on it"
-- ─────────────────────────────────────────────────────────────────────────
-- Find what depends on the role:
SELECT 
    n.nspname as schema,
    c.relname as object_name,
    c.relkind as object_type,
    pg_get_userbyid(c.relowner) as owner
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE pg_get_userbyid(c.relowner) IN ('reporting_user', 'report_reader');

-- Drop those objects first, then drop the user


-- ─────────────────────────────────────────────────────────────────────────
-- Force cleanup if normal steps fail
-- ─────────────────────────────────────────────────────────────────────────
-- In reporting_db (if it still exists):
DROP OWNED BY reporting_user CASCADE;

-- In each microservice database:
DROP OWNED BY report_reader CASCADE;