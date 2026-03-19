-- ========================
-- File: config_install.sql
-- Purpose: Configuration variables for scheduler installation
-- Edit values before running install scripts
-- ========================

-- User configuration
DEFINE PDB_NAME = XEPDB1
DEFINE SCHED_USER = SCHED_SYS
DEFINE SCHED_PASSWORD = SCHED_SYS_PASSWORD
DEFINE DEFAULT_TABLESPACE = USERS
DEFINE TEMP_TABLESPACE = TEMP

-- Connection configuration
DEFINE DB_HOST = localhost
DEFINE DB_PORT = 1521
