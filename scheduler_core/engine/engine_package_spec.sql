-- =============================
-- File: engine_package_spec.sql
-- Location: scheduler/scheduler_core/engine
-- Description: Package specification for the internal execution engine.
--               Defines the public contract implemented in engine_package_body.sql.
-- =============================

/**
 * Execution engine contract for Scheduler Core.
 *
 * This package defines the internal execution layer responsible for:
 * - Selecting due jobs
 * - Applying locking and concurrency control
 * - Managing execution lifecycle transitions
 * - Updating runtime metadata
 * - Recalculating scheduling timestamps
 *
 * Unlike the API package, this package is NOT intended
 * for external consumers. It represents the internal
 * orchestration logic of the scheduler runtime.
 *
 * Typically invoked by DBMS_SCHEDULER or a background worker.
 */
create or replace package engine_package as

   /**
    * Collection type used to return multiple job identifiers.
    *
    * Represents a list of job IDs selected for execution,
    * typically after applying locking and concurrency rules.
    */
   type t_job_id_table is table of jobs.job_id%type;

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

   /**
    * Marks a job execution instance as RUNNING.
    *
    * Creates or updates a corresponding row in job_runs
    * and records the execution start timestamp.
    *
    * p_job_id - Identifier of the job being executed.
    */
   procedure mark_job_as_running(
      p_job_id in jobs.job_id%type
   );


   /**
    * Finalizes a job execution instance.
    *
    * Updates job_runs with:
    * - final status (SUCCESS, FAILED, ABORTED)
    * - completion timestamp
    * - optional error message
    *
    * Also responsible for triggering scheduling recalculation.
    *
    * p_job_id        - Identifier of the executed job.
    * p_status        - Final execution status.
    * p_error_message - Optional error details in case of failure.
    */
   procedure mark_job_as_complete(
      p_job_id in jobs.job_id%type,
      p_status in job_runs.status%type,
      p_error_message in job_runs.error_message%type
   );

   /**
    * Recalculates and updates the next_run_date of a job.
    *
    * Typically invoked after a successful or failed execution,
    * based on the configured interval.
    *
    * p_job_id           - Identifier of the job.
    * p_interval_seconds - Execution frequency in seconds.
    */
   procedure calculate_next_run_date(
      p_job_id in jobs.job_id%type,
      p_interval_seconds in jobs.interval_seconds%type
   );

   /**
    * Selects and locks eligible jobs for a specific worker.
    *
    * Applies concurrency control to prevent multiple workers
    * from executing the same job simultaneously.
    *
    * p_worker_id - Logical identifier of the worker process.
    * p_max_jobs  - Maximum number of jobs to lock (default 1).
    * p_now       - Reference timestamp used for due calculation.
    *
    * Returns a collection of locked job IDs.
    */
   function get_locked_jobs(
      p_worker_id in varchar2,
      p_max_jobs in number default 1,
      p_now in timestamp default systimestamp
   ) return t_job_id_table;
end;
/
