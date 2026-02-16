-- ==========================
-- File: api_package_body.sql
-- Location: scheduler/scheduler_core/api
-- Description: Package body implementing the public Scheduler Core API.
--              Contains the executable logic for procedures and functions
--              declared in api_package_spec.sql. Private helpers may also
--              reside here with inline comments as needed.
-- ==========================

/**
 * Implementation of the Scheduler Core public API.
 *
 * Contains the actual logic for procedures and functions
 * defined in api_package_spec.sql.
 *
 * Public procedures correspond to the API contract and
 * are documented in the package specification.
 *
 * Private helper procedures and internal logic may also
 * exist here, and should be documented inline as needed.
 */
create or replace package body api_package as

   -- Public procedure defined in api_package_spec.sql
   procedure register_job(
      p_job_name in jobs.job_name%type,
      p_procedure_name in jobs.procedure_name%type,
      p_interval_seconds in jobs.interval_seconds%type
   ) is
   begin
      insert into jobs (
         job_id,
         job_name,
         procedure_name,
         enabled_flag,
         interval_seconds,
         next_run_date,
         created_at,
         created_by
      ) values (
         jobs_seq.nextval,
         p_job_name,
         p_procedure_name,
         'Y',
         p_interval_seconds,
         systimestamp + numtodsinterval(p_interval_seconds, 'SECOND'),
         systimestamp,
         sys_context('USERENV', 'SESSION_USER')
      );
   exception
      when DUP_VAL_ON_INDEX then
         if (SQLERRM like '%u_job_name%') then
            raise_application_error(
               -20001,
               'Job name already exists'
            );
         elsif (SQLERRM like '%u_procedure_name%') then
            raise_application_error(
               -20002,
               'Procedure or function already registered'
            );
         else
            raise;
         end if;

      when OTHERS then
         if (SQLCODE = -2290 and SQLERRM like '%ch_interval_seconds%') then
            raise_application_error(
               -20003,
               'Interval must be greater than zero'
            );
         elsif (SQLCODE = -1400) then
            raise_application_error(
               -20000,
               'Mandatory field cannot be null'
            );
         else
            raise;
         end if;
   end;

   -- Public procedure defined in api_package_spec.sql
   procedure update_job_interval(
      p_job_name in jobs.job_name%type,
      p_new_interval_seconds in jobs.interval_seconds%type
   ) is
   begin
      null;
   end;

   -- Public procedure defined in api_package_spec.sql
   procedure enable_job(
      p_job_name in jobs.job_name%type
   ) is
   begin
      null;
   end;

   -- Public procedure defined in api_package_spec.sql
   procedure disable_job(
      p_job_name in jobs.job_name%type
   ) is
   begin
      null;
   end;

   -- Public procedure defined in api_package_spec.sql
   function get_job_info(
      p_job_name in jobs.job_name%type
   ) return t_job_info is
   begin
      return t_job_info(1, systimestamp + numtodsinterval(10, 'SECOND'));
   end;

   -- Public procedure defined in api_package_spec.sql
   procedure run_job_now(
      p_job_name in jobs.job_name%type
   ) is
   begin
      null;
   end;
end;
/
