-- =====================================================
-- File: scheduler_demo/install.sql
-- Purpose: Installation entry point for Scheduler Demo
-- =====================================================

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

PROMPT Connecting as SCHED_DEMO
CONNECT SCHED_DEMO/sched_demo_password@localhost:1521/XEPDB1

PROMPT Running scheduler_demo/schema/demo.sql...
@@schema/demo.sql

PROMPT =====================================================
PROMPT Scheduler Demo installation completed
PROMPT =====================================================
