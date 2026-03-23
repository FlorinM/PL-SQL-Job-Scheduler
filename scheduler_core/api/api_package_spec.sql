-- =============================
-- File: api_package_spec.sql
-- Location: scheduler/scheduler_core/api
-- Description: Package specification for the public Scheduler Core API.
--               Defines the contract for job management and interaction
--               by external business schemas.
-- =============================

/**
 * Public API contract for Scheduler Core.
 *
 * This package exposes the external interface used to manage
 * job lifecycle operations and runtime interaction.
 *
 * Responsibilities:
 * - Job registration and configuration
 * - Enabling / disabling jobs
 * - Interval management
 * - Runtime metadata retrieval
 * - Manual job triggering
 *
 * This package does NOT contain execution logic.
 * Actual execution and locking mechanics are handled by the engine package.
 *
 * All procedures and functions defined here represent
 * the supported integration surface of the scheduler.
 */
create or replace package api_package as

   /**
    * Record type returned by get_job_info.
    *
    * Represents the latest execution snapshot of a job, based on the most recent
    * (scheduled_for, attempt_number) combination.
    *
    * Provides both identification and runtime execution details for observability
    * and debugging purposes.
    *
    * job_name        - Logical job identifier.
    * run_id          - Unique identifier of the execution instance.
    * scheduled_for   - Timestamp representing the scheduled execution slot.
    * attempt_number  - Retry attempt number for the given scheduled execution.
    * start_time      - Timestamp when execution started.
    * end_time        - Timestamp when execution finished (NULL if still running).
    * status          - Execution status (RUNNING, SUCCESS, FAILED, ABORTED).
    * error_message   - Error message captured on failure (NULL if SUCCESS or RUNNING).
    */
   type t_job_info is record (
      job_name jobs.job_name%type,
      run_id job_runs.run_id%type,
      scheduled_for job_runs.scheduled_for%type,
      attempt_number job_runs.attempt_number%type,
      start_time job_runs.start_time%type,
      end_time job_runs.end_time%type,
      status job_runs.status%type,
      error_message job_runs.error_message%type
   );

   /**
    * Registers a new job definition in the scheduler.
    *
    * Creates a new row in the jobs table with:
    * - enabled_flag set to 'Y'
    * - next_run_date initialized based on interval
    *
    * p_job_name         - Logical unique name of the job.
    * p_procedure_name   - Fully qualified business procedure to execute.
    * p_interval_seconds - Execution frequency in seconds.
    *
    * Raises an exception if the job already exists or validation fails.
    */
   procedure register_job(
      p_job_name in jobs.job_name%type,
      p_procedure_name in jobs.procedure_name%type,
      p_interval_seconds in jobs.interval_seconds%type,
      p_max_attempts in jobs.max_attempts%type
   );

   /**
    * Updates the execution interval of an existing job.
    *
    * Recalculates scheduling metadata based on the new interval.
    *
    * p_job_name             - Logical job identifier.
    * p_new_interval_seconds - New execution frequency in seconds.
    */
   procedure update_job_interval(
      p_job_name in jobs.job_name%type,
      p_new_interval_seconds in jobs.interval_seconds%type
   );

   /**
    * Enables a previously disabled job.
    *
    * Sets enabled_flag to 'Y'.
    * The job becomes eligible for execution based on next_run_date.
    *
    * p_job_name - Logical job identifier.
    */
   procedure enable_job(
      p_job_name in jobs.job_name%type
   );


   /**
    * Disables a job.
    *
    * Sets enabled_flag to 'N'.
    * Disabled jobs are ignored by the execution engine.
    *
    * p_job_name - Logical job identifier.
    */
   procedure disable_job(
      p_job_name in jobs.job_name%type
   );

   /**
    * Retrieves job configuration and latest execution status.
    *
    * Returns a t_job_info record containing:
    * - configured interval
    * - next scheduled run
    * - status of the most recent execution
    *
    * p_job_name - Logical job identifier.
    */
   function get_job_info(
      p_job_name in jobs.job_name%type
   ) return t_job_info;

   /**
    * Forces immediate execution of a job.
    *
    * Overrides scheduling by making the job eligible for execution
    * on the next engine cycle (e.g., by updating next_run_date).
    *
    * Does not bypass concurrency control or execution safeguards.
    *
    * p_job_name - Logical job identifier.
    */
   procedure run_job_now(
      p_job_name in jobs.job_name%type
   );
end;
/
