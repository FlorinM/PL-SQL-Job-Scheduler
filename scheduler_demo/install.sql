-- =====================================================
-- File: scheduler_demo/install.sql
-- Purpose: Installation entry point for Scheduler Demo
-- =====================================================

@@config/config_install.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT =====================================================
PROMPT Starting Scheduler Demo installation
PROMPT =====================================================

PROMPT NOTE:
PROMPT The Scheduler core must be installed before installing the demo
PROMPT If you have not installed the core yet, run the following script
PROMPT from the project root directory:
PROMPT
PROMPT   @install.sql
PROMPT
PROMPT Then return and run this demo installer

-- Optional: check current container/session
SHOW CON_NAME;

PROMPT Running scheduler_demo/schema/create_user.sql...
@@schema/create_user.sql

PROMPT Connecting as &&DEMO_USER
CONNECT &&DEMO_USER/&&DEMO_PASSWORD@&&DB_HOST:&&DB_PORT/&&PDB_NAME

PROMPT Running scheduler_demo/schema/demo.sql...
@@schema/demo.sql

PROMPT Running demo_package_spec.sql...
@@business_logic/demo_package_spec.sql

PROMPT Running demo_package_body.sql...
@@business_logic/demo_package_body.sql

PROMPT Running demo_handlers_package_spec.sql...
@@handlers/demo_handlers_package_spec.sql

PROMPT Running demo_handlers_package_body.sql...
@@handlers/demo_handlers_package_body.sql

PROMPT Granting scheduler access to handlers...
GRANT EXECUTE ON &&DEMO_USER..demo_handlers_package TO &&SCHED_USER;

PROMPT =====================================================
PROMPT Scheduler Demo installation completed
PROMPT =====================================================
