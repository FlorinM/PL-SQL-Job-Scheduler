-- ========================
-- File: scheduler_demo/config_install.sql
-- Purpose: Configuration variables for demo installation
-- Edit values before running install scripts
-- ========================

-- Import config shared
@@../../scheduler_core/config/config_install.sql

-- Config demo specific
DEFINE DEMO_USER = SCHED_DEMO
DEFINE DEMO_PASSWORD = SCHED_DEMO_PASSWORD

