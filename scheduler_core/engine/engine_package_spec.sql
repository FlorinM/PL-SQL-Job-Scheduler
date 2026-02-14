-- =============================
-- File: engine_package_spec.sql
-- =============================

create or replace package engine_package_spec as
   type t_job_id_table is table of jobs.job_id%type;

   procedure execute_due_jobs;

   procedure mark_job_as_running(
      p_job_id in jobs.job_id%type
   );

   procedure mark_job_as_complete(
      p_job_id in jobs.job_id%type,
      p_status in job_runs.status%type,
      p_error_message in job_runs.error_message%type
   );

   procedure calculate_next_run_date(
      p_job_id in jobs.job_id%type,
      p_interval_seconds in jobs.interval_seconds%type
   );

   function get_locked_jobs(
      p_worker_id in varchar2,
      p_max_jobs in number default 1,
      p_now in timestamp default systimestamp
   ) return t_job_id_table;
end;
/
