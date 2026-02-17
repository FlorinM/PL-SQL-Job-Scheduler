-- =============================
-- File: engine_package_spec.sql
-- Location: scheduler/scheduler_core/engine
-- Description: Package specification for the internal execution engine.
--               Defines the public contract implemented in engine_package_body.sql.
-- =============================

/**
 * Execution engine contract for Scheduler Core.
 *
 * Provides the entry point `execute_due_jobs` to run all due jobs.
 * Handles scheduling, concurrency control, and lifecycle transitions internally.
 *
 * Intended to be invoked by DBMS_SCHEDULER; not for general external use.
 */
create or replace package engine_package as

   /**
    * Main engine entry point.
    *
    * Scans for eligible jobs (enabled and due),
    * acquires necessary locks,
    * and dispatches execution.
    *
    * This procedure is typically invoked by DBMS_SCHEDULER
    * or an external worker process.
    */
   procedure execute_due_jobs;
end;
/
