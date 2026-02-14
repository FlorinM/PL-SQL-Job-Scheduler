-- =================
-- File: api_package_spec.sql
-- =================

create or replace package api_package_spec as

   type t_job_info is record (
      interval_seconds jobs.interval_seconds%type,
      next_run_date jobs.next_run_date%type,
      status job_runs.status%type
   );

   procedure register_job(
      p_job_name in jobs.job_name%type,
      p_procedure_name in jobs.procedure_name%type,
      p_interval_seconds in jobs.interval_seconds%type
   );

   procedure update_job_interval(
      p_job_name in jobs.job_name%type,
      p_new_interval_seconds in jobs.interval_seconds%type
   );

   procedure enable_job(
      p_job_name in jobs.job_name%type
   );

   procedure disable_job(
      p_job_name in jobs.job_name%type
   );

   function get_job_info(
      p_job_name in jobs.job_name%type
   ) return t_job_info;

   procedure run_job_now(
      p_job_name in jobs.job_name%type
   );
end;
/
