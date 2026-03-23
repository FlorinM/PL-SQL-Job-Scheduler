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

   /**
    * Default number of retry attempts assigned to a job
    * when the caller does not explicitly provide max_attempts
    * during registration.
    *
    * This value represents the scheduler’s standard retry policy
    * and ensures predictable behavior without requiring users
    * to configure retry logic explicitly.
    */
   c_default_max_attempts constant jobs.max_attempts%type := 5;

   /**
    * Upper safety limit for retry attempts allowed per job.
    *
    * This constant protects the scheduler infrastructure from
    * excessive retry configurations that could lead to retry storms,
    * resource exhaustion, or uncontrolled execution loops.
    *
    * Any user-provided max_attempts value greater than this limit
    * should be rejected at API validation level.
    */
   c_max_allowed_attempts constant jobs.max_attempts%type := 10;

   -- Public procedure defined in api_package_spec.sql
   procedure register_job(
      p_job_name in jobs.job_name%type,
      p_procedure_name in jobs.procedure_name%type,
      p_interval_seconds in jobs.interval_seconds%type,
      p_max_attempts in jobs.max_attempts%type
   ) is
      v_max_attempts jobs.max_attempts%type;
   begin

      if (p_max_attempts is null) then
         v_max_attempts := c_default_max_attempts;
      elsif p_max_attempts < 1 then
         raise_application_error(
            -20004, 'max_attempts must be >= 1');
      elsif (p_max_attempts > c_max_allowed_attempts) then
         raise_application_error(
            -20005,
            'max_attempts must be <= ' || c_max_allowed_attempts
         );
      else
         v_max_attempts := p_max_attempts;
      end if;

      insert into jobs (
         job_id,
         job_name,
         procedure_name,
         enabled_flag,
         interval_seconds,
         next_run_date,
         max_attempts,
         created_at,
         created_by
      ) values (
         jobs_seq.nextval,
         p_job_name,
         p_procedure_name,
         'Y',
         p_interval_seconds,
         systimestamp + numtodsinterval(p_interval_seconds, 'SECOND'),
         v_max_attempts,
         systimestamp,
         sys_context('USERENV', 'SESSION_USER')
      );

      commit;
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
      -- Validate input
      if (p_new_interval_seconds is null or p_new_interval_seconds <= 0) then
         raise_application_error(-20020, 'Interval must be greater than 0');
      end if;

      -- Update job
      update jobs
      set interval_seconds = p_new_interval_seconds,
         next_run_date = systimestamp + numtodsinterval(p_new_interval_seconds, 'SECOND')
      where job_name = p_job_name;

      -- Check if job exists
      if (sql%rowcount = 0) then
         raise_application_error(-20021, 'Job not found: ' || p_job_name);
      end if;

      -- Commit changes
      commit;

   exception
      when others then
         rollback;
         raise_application_error(
            -20022,
            'Failed to update interval_seconds where job_name = ' || p_job_name,
            true
        );
   end;

   -- Public procedure defined in api_package_spec.sql
   procedure enable_job(
      p_job_name in jobs.job_name%type
   ) is
   begin
      update jobs
      set enabled_flag = 'Y'
      where job_name = p_job_name;

      if (sql%rowcount = 0) then
         raise_application_error(
            -20023,
            'No job found with job_name = ' || p_job_name
         );
      end if;

      commit;

   exception
      when others then
         rollback;
         raise_application_error(
            -20024,
            'Failed to enable job for job_name = ' || p_job_name,
            true
         );
   end;

   -- Public procedure defined in api_package_spec.sql
   procedure disable_job(
      p_job_name in jobs.job_name%type
   ) is
   begin
      update jobs
      set enabled_flag = 'N'
      where job_name = p_job_name;

      if (sql%rowcount = 0) then
         raise_application_error(
            -20025,
            'No job found with job_name = ' || p_job_name
         );
      end if;

      commit;

   exception
      when others then
         rollback;
         raise_application_error(
            -20026,
            'Failed to disable job for job_name = ' || p_job_name,
            true
         );
   end;

   -- Public procedure defined in api_package_spec.sql
   function get_job_info(
      p_job_name in jobs.job_name%type
   ) return t_job_info is
      v_result t_job_info;
   begin
      select
         j.job_name,
         r.run_id,
         r.scheduled_for,
         r.attempt_number,
         r.start_time,
         r.end_time,
         r.status,
         r.error_message
      into
         v_result.job_name,
         v_result.run_id,
         v_result.scheduled_for,
         v_result.attempt_number,
         v_result.start_time,
         v_result.end_time,
         v_result.status,
         v_result.error_message
      from jobs j
      join job_runs r
      on j.job_id = r.job_id
      where j.job_name = p_job_name
      order by r.scheduled_for desc, r.attempt_number desc
      fetch first 1 rows only;

      return v_result;

   exception
      when no_data_found then
         raise_application_error(
            -20027,
            'No job execution found for job_name = ' || p_job_name
         );

      when others then
         raise_application_error(
            -20028,
            'Failed to retrieve job info for job_name = ' || p_job_name,
            true
         );
   end;

   -- Public procedure defined in api_package_spec.sql
   procedure run_job_now(
      p_job_name in jobs.job_name%type
   ) is
      v_enabled jobs.enabled_flag%type;
   begin
      -- Validate job existence + status
      select enabled_flag
      into v_enabled
      from jobs
      where job_name = p_job_name;

      if (v_enabled = 'N') then
         raise_application_error(
            -20029,
            'Job is disabled. Enable it before forcing execution: ' || p_job_name
         );
      end if;

      -- Force execution via scheduling metadata
      update jobs
      set next_run_date = systimestamp
      where job_name = p_job_name;

      commit;

   exception
      when no_data_found then
         raise_application_error(
            -20030,
            'No job found with job_name = ' || p_job_name
         );

      when others then
         rollback;
         raise_application_error(
            -20031,
            'Failed to force run for job_name = ' || p_job_name,
            true
         );
   end;
end;
/
