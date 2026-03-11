-- ==========================================================
-- File: scheduler_demo/register_jobs.sql
-- Purpose: Register demo jobs in the scheduler
-- Must be executed as SCHED_SYS
-- ==========================================================

PROMPT =====================================================
PROMPT Registering demo jobs in scheduler
PROMPT =====================================================

PROMPT NOTE:
PROMPT This script must be executed as user SCHED_SYS
PROMPT Demo schema must already be installed

-- Optional safety check
SHOW USER;

PROMPT Registering job: OVERDUE_TASKS_JOB

begin
   sched_sys.api_package.register_job(
      p_job_name         => 'overdue_tasks_job',
      p_procedure_name   => 'sched_demo.demo_handlers_package.overdue_tasks_handler',
      p_interval_seconds => 60,
      p_max_attempts     => 3
   );
end;
/

PROMPT Demo jobs registered successfully
