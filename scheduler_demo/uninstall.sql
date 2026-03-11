-- =====================================================
-- File: scheduler_demo/uninstall.sql
-- Purpose: Remove Scheduler Demo schema
-- Must be executed as SYS or user with DROP USER privilege
-- =====================================================

PROMPT ===============================================
PROMPT Removing Scheduler Demo schema
PROMPT ===============================================

SHOW CON_NAME;

DROP USER SCHED_DEMO CASCADE;

PROMPT Scheduler Demo schema removed successfully
