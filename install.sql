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

PROMPT Running tables.sql...
@@scheduler_core/schema/tables.sql

PROMPT Running sequences.sql...
@@scheduler_core/schema/sequences.sql

PROMPT =====================================================
PROMPT Scheduler Core installation completed (current stage)
PROMPT =====================================================
