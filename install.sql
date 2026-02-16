-- =====================================================
-- File: install.sql
-- Purpose: Installation entry point for Scheduler Core
-- Currently runs only user creation script
-- =====================================================

PROMPT =====================================================
PROMPT Starting Scheduler Core installation
PROMPT =====================================================

-- Optional: check current container/session
SHOW CON_NAME;

PROMPT Running create_user.sql...
@@scheduler_core/schema/create_user.sql

PROMPT Connecting as SCHED_SYS
CONNECT SCHED_SYS/sched_sys_password@localhost:1521/XEPDB1

PROMPT Running tables.sql...
@@scheduler_core/schema/tables.sql

PROMPT Running sequences.sql...
@@scheduler_core/schema/sequences.sql

PROMPT Running constraints_indexes.sql...
@@scheduler_core/schema/constraints_indexes.sql

PROMPT Running api_package_spec.sql...
@@scheduler_core/api/api_package_spec.sql

PROMPT Running engine_package_spec.sql...
@@scheduler_core/engine/engine_package_spec.sql

PROMPT Running api_package_body.sql...
@@scheduler_core/api/api_package_body.sql

PROMPT =====================================================
PROMPT Scheduler Core installation completed (current stage)
PROMPT =====================================================
