-- ==========================
-- File: engine_package_body.sql
-- Location: scheduler/scheduler_core/engine
-- Description: Implementation of ENGINE_PACKAGE;
--              contains core procedures to execute, track, and manage scheduled jobs
-- ==========================

/**
 * Package body for ENGINE_PACKAGE.
 *
 * Implements all procedures and functions declared in the ENGINE_PACKAGE specification.
 * Responsible for executing due jobs, marking jobs as running or complete,
 * calculating next run dates, and providing worker concurrency control.
 *
 * This is the engine core that is invoked by the DBMS_SCHEDULER job.
 */
create or replace package body engine_package as

   /**
    * Maximum lifetime (in seconds) allocated to a single worker
    * invocation of execute_due_jobs.
    *
    * The worker processes one job at a time in a loop and continues
    * claiming and executing eligible jobs until this time budget
    * is exhausted.
    *
    * This value is intentionally set slightly below the DBMS_SCHEDULER
    * repeat interval to prevent overlapping worker executions and
    * to ensure controlled, time-bounded processing.
    *
    * Acts as a safety mechanism to avoid long-running or runaway
    * worker sessions.
    */
   c_budget_time_sec constant pls_integer := 9;

   /**
    * Maximum allowed execution time (in seconds) for a worker to complete a single job.
    *
    * If a job remains in RUNNING state longer than this, it is considered stale
    * and can be reclaimed by another worker.
    */
   c_timeout_sec constant pls_integer := 3;

   /**
    * Claims the next eligible job for execution.
    *
    * A job is eligible if it is enabled, due (next_run_date <= current time),
    * and has no active RUNNING attempt within the configured timeout.
    * Jobs are ordered by next_run_date ascending to avoid starvation.
    *
    * @return jobs%rowtype of the claimed job, or NULL if none found.
    */
   function claim_next_job return jobs%rowtype is
      v_job jobs%rowtype;
      v_job_id jobs.job_id%type;
   begin
      -- Select eligible job
      select j.* into v_job
      from jobs j
      where j.enabled_flag = 'Y'
      and j.next_run_date <= systimestamp
      and not exists (
         select 1
         from job_runs r
         where r.job_id = j.job_id
         and r.scheduled_for = j.next_run_date
         and (
            r.status in ('SUCCESS', 'ABORTED')
            or (
               r.status = 'RUNNING'
               and r.start_time + numtodsinterval(c_timeout_sec, 'SECOND') > systimestamp
            )
         )
      )
      order by j.next_run_date asc
      fetch first 1 rows only;

      -- Lock the job
      select job_id into v_job_id from jobs
      where job_id = v_job.job_id
      for update skip locked;

      return v_job;

   exception
      when no_data_found then
         return null;
   end;

   /**
    * Checks whether a scheduled execution has a stale RUNNING attempt.
    *
    * A RUNNING attempt is considered stale if start_time + c_timeout_sec
    * is less than or equal to the current timestamp.
    *
    * @param p_job_id         Identifier of the job.
    * @param p_scheduled_for  Scheduled execution timestamp.
    *
    * @return RUN_ID of the stale RUNNING attempt, or NULL if none exists.
    *
    * Invariant: At most one RUNNING attempt per (job_id, scheduled_for)
    * is enforced at database level.
    */
   function exists_stale_running_attempt(
      p_job_id in jobs.job_id%type,
      p_scheduled_for in job_runs.scheduled_for%type
   ) return job_runs.run_id%type is
      v_run_id job_runs.run_id%type;
   begin
      --
      select run_id into v_run_id
      from job_runs
      where job_id = p_job_id
      and scheduled_for = p_scheduled_for
      and status = 'RUNNING'
      and start_time + numtodsinterval(c_timeout_sec, 'SECOND') <= systimestamp;

      return v_run_id;

   exception
      when no_data_found then
         return null;
   end;

   /**
    * Marks a previously detected stale RUNNING attempt as FAILED.
    *
    * The attempt identified by p_run_id is transitioned from RUNNING to FAILED,
    * its end_time is set to the current timestamp, and an error message is
    * recorded indicating that the worker exceeded the configured timeout.
    *
    * Expected behavior:
    *   - Exactly one row must be updated.
    *   - If no row or more than one row is affected, a fatal application error
    *     is raised, as this indicates a data integrity violation or a logic bug
    *     in the engine.
    *
    * Preconditions:
    *    @p_run_id must identify an existing RUNNING attempt previously validated
    *    as stale.
    */
   procedure solve_stale_running_attempt(p_run_id in job_runs.run_id%type) is
   begin
      update job_runs
      set
         status = 'FAILED',
         end_time = systimestamp,
         error_message = 'Worker timeout exceeded; marking attempt as FAILED'
      where run_id = p_run_id;

      if (sql%rowcount <> 1) then
         raise_application_error(
            -20006,
            'Engine invariant violation: expected exactly one row when failing stale RUNNING attempt (run_id='
         || p_run_id || ')'
         );
      end if;
   end;

   /**
    * Determines the attempt_number for the current scheduled execution of a job.
    *
    * Looks at existing JOB_RUNS for the given (job_id, scheduled_for) and
    * returns the attempt_number to use for this execution
    * (1 if none exist, otherwise max(previous) + 1).
    *
    * Does not validate the value against max_attempts.
    *
    * @param p_job_id         Identifier of the job.
    * @param p_scheduled_for  Scheduled execution timestamp.
    *
    * @return Attempt number for the current execution.
    */
   function calculate_current_attempt_number(
      p_job_id in jobs.job_id%type,
      p_scheduled_for in job_runs.scheduled_for%type
   ) return job_runs.attempt_number%type is
      v_max_attempt_number job_runs.attempt_number%type;
   begin

      select nvl(max(attempt_number), 0)
      into v_max_attempt_number
      from job_runs
      where job_id = p_job_id
      and scheduled_for = p_scheduled_for;

      return v_max_attempt_number + 1;
   end;

   /**
    * Marks a job execution attempt as ABORTED.
    *
    * This procedure inserts a single row into the `job_runs` table
    * for the given job, scheduled execution, and attempt number.
    * The row indicates that the attempt was aborted because it
    * exceeded the maximum allowed attempts.
    *
    * @param p_job_id         : Identifier of the job being executed.
    * @param p_scheduled_for  : Timestamp of the scheduled execution.
    * @param p_attempt_number : Attempt number that exceeded max_attempts.
    *
    */
   procedure mark_job_as_aborted(
      p_job_id in jobs.job_id%type,
      p_scheduled_for in job_runs.scheduled_for%type,
      p_attempt_number in job_runs.attempt_number%type
   ) is
   begin
      insert into job_runs (
         run_id,
         job_id,
         scheduled_for,
         status,
         start_time,
         end_time,
         error_message,
         attempt_number,
         created_at
      ) values (
         job_runs_seq.nextval,
         p_job_id,
         p_scheduled_for,
         'ABORTED',
         systimestamp,
         systimestamp,
         'Attempt number exceeded max_attempts',
         p_attempt_number,
         systimestamp
      );

   exception
      when others then
         raise_application_error(
            -20007,
            'Failed to mark job_id=' || p_job_id || ' as ABORTED: ' || SQLERRM
         );
   end;

   /**
    * Marks the start of a job execution attempt.
    *
    * Inserts a RUNNING row in JOB_RUNS for the given job, scheduled time, and attempt number,
    * and returns the generated RUN_ID.
    *
    * @param p_job_id         : Identifier of the job being executed.
    * @param p_scheduled_for  : Scheduled execution timestamp.
    * @param p_attempt_number : Attempt number for the current execution.
    *
    * @return RUN_ID of the newly created RUNNING row.
    *
    * Raises an application error if the insert fails.
    */
   function mark_job_as_running(
      p_job_id in jobs.job_id%type,
      p_scheduled_for in job_runs.scheduled_for%type,
      p_attempt_number in job_runs.attempt_number%type
   ) return job_runs.run_id%type is
      v_run_id job_runs.run_id%type;
   begin
      insert into job_runs (
         run_id,
         job_id,
         scheduled_for,
         status,
         start_time,
         end_time,
         error_message,
         attempt_number,
         created_at
      ) values (
         job_runs_seq.nextval,
         p_job_id,
         p_scheduled_for,
         'RUNNING',
         systimestamp,
         null,
         null,
         p_attempt_number,
         systimestamp
      ) returning run_id into v_run_id;

      return v_run_id;

   exception
      when others then
         raise_application_error(
            -20008,
            'Failed to mark job_id=' || p_job_id || ' as RUNNING: ' || SQLERRM
         );
   end;

   /**
    * Recalculates and updates the next_run_date of a job.
    *
    * Typically invoked after a successful or aborted execution,
    * based on the configured interval.
    *
    * @param p_job_id           - Identifier of the job.
    */
   procedure schedule_next_execution(
      p_job_id in jobs.job_id%type
   ) is
      v_interval_seconds jobs.interval_seconds%type;
   begin
      select interval_seconds into v_interval_seconds
      from jobs
      where job_id = p_job_id;

      update jobs set next_run_date = systimestamp + numtodsinterval(v_interval_seconds, 'SECOND')
      where job_id = p_job_id;

      if (sql%rowcount <> 1) then
         raise_application_error(
            -20010,
            'Invariant violation: expected 1 row when updating next_run_date for job_id=' || p_job_id
         );
      end if;

      exception
         when no_data_found then
            raise_application_error(
            -20009,
            'Job not found when calculating next_run_date. job_id=' || p_job_id
         );
   end;

   procedure execute_business_logic is
   begin
      null;
   end;

   /**
    * Checks whether the specified run_id is still in RUNNING state.
    *
    * This function is used by a worker returning from business logic execution to determine
    * if its assigned run is still active. If the run has been marked as FAILED or SUCCESS
    * (e.g., due to timeout and retry by another worker), the function returns FALSE.
    *
    * @param p_run_id : The identifier of the job run to check.
    *
    * @return BOOLEAN : TRUE if the run exists and is currently RUNNING, FALSE otherwise.
    *
    * Raises an application error if the query fails due to unexpected reasons
    * (e.g., database error). An exception will also be raised if the run_id does not exist,
    * signaling an invariant violation.
    */
   function is_current_run_still_running(p_run_id job_runs.run_id%type) return boolean is
      v_status job_runs.status%type;
   begin
      select status into v_status from job_runs where run_id = p_run_id;

      if (v_status = 'RUNNING') then
         return true;
      end if;
      return false;

   exception
      when others then
         raise_application_error(
            -20015,
            'Failed to select status for run_id = ' || p_run_id || ' in is_current_run_still_running'
         );
   end;

   /**
    * Marks a job execution as SUCCESS.
    *
    * Updates the status of the job_run identified by p_run_id to 'SUCCESS'.
    * Ensures exactly one row is updated; otherwise, raises an application error.
    *
    * @param p_run_id - Identifier of the job_run to mark as SUCCESS
    */
   procedure mark_job_as_success(p_run_id in job_runs.run_id%type) is
   begin
      -- Attempt to mark the run as SUCCESS
      update job_runs set status = 'SUCCESS', end_time = systimestamp
      where run_id = p_run_id;

      -- Validate that exactly one row is updated
      if (sql%rowcount <> 1) then
         raise_application_error(
            -20011,
            'Invariant violation: expected 1 row when marking job as SUCCESS for run_id = ' || p_run_id
         );
      end if;

   exception
      when others then
         -- Any unexpected error during the update is reported
         raise_application_error(
            -20012,
            'Failed to mark job run as SUCCESS for run_id = ' || p_run_id || ': ' || sqlerrm
         );
   end;

   /**
    * Marks a job execution run as FAILED.
    *
    * Constructs a detailed CLOB error message including timestamp, the given error text,
    * and the PL/SQL backtrace, then updates the job_runs row with status, end_time, and error_message.
    *
    * @param p_run_id  - Identifier of the job run to mark as FAILED.
    * @param p_error   - Error text to include in the error message.
    *
    * Raises an application error if:
    *   - No row or more than one row is affected.
    *   - Any unexpected error occurs during the update.
    */
   procedure mark_job_as_failed(
      p_run_id in job_runs.run_id%type,
      p_error in job_runs.error_message%type

   ) is
      v_clob_error clob;
   begin
      -- Take the full error
      v_clob_error := 'Timestamp: ' || to_char(systimestamp, 'YYYY-MM-DD HH24:MI:SS.FF') || chr(10)
                  || 'Error: ' || p_error || chr(10)
                  || 'Backtrace:' || chr(10)
                  || replace(dbms_utility.format_error_backtrace, chr(10), chr(10) || '  ');

      -- Attempt to mark the run as FAILED
      update job_runs set
            status = 'FAILED',
            end_time = systimestamp,
            error_message = v_clob_error
      where run_id = p_run_id;

      -- Validate that exactly one row is updated
      if (sql%rowcount <> 1) then
         raise_application_error(
            -20013,
            'Invariant violation: expected 1 row when marking job as FAILED for run_id = ' || p_run_id
         );
      end if;

   exception
      when others then
         -- Any unexpected error during the update is reported
         raise_application_error(
            -20014,
            'Failed to mark job run as FAILED for run_id = ' || p_run_id || ': ' || sqlerrm
         );
   end;

   /**
    * Executes the business logic for a given job.
    *
    * This procedure acts as a thin dispatcher: it looks up the registered handler
    * for the provided job_id and executes it. Only exceptions raised by the
    * handler itself are propagated to the scheduler; any internal lookup or
    * execution errors are swallowed to avoid false FAILED statuses.
    *
    * @param p_job_id  The identifier of the job to execute.
    */
   procedure execute_business_logic(p_job_id in jobs.job_id%type) is
      -- Variable to hold the handler (procedure) name for the job
      v_handler_name jobs.procedure_name%type;
   begin
      -- Fetch the handler name for the given job_id from the jobs table
      begin
         select procedure_name
         into v_handler_name
         from jobs
         where job_id = p_job_id;

      exception
         when no_data_found then
            -- Job does not exist or was deleted. This is an internal scheduler issue,
            -- not a business failure. Log and return without raising an error.
            dbms_output.put_line('Scheduler internal warning: job_id ' || p_job_id || ' not found');
            return;
      end;


      -- Execute the handler dynamically
      -- The handler itself follows the contract: procedure handler_name(p_job_id number);
      -- Any exception raised here will propagate to execute_due_jobs and mark the job as FAILED.
      execute immediate 'begin ' || v_handler_name || '(:1); end;' using p_job_id;

      -- Note:
      -- No explicit exception handling here: any handler exception will bubble up.
      -- Scheduler internal errors are caught above, so the scheduler is not misled.
   end;

   -- Public procedure defined in engine_package_spec.sql
   procedure execute_due_jobs is
      v_start_time timestamp with time zone;
      v_deadline timestamp with time zone;
      v_job jobs%rowtype;
      v_scheduled_for job_runs.scheduled_for%type;
      v_stale_run_id job_runs.run_id%type;
      v_current_attempt_number job_runs.attempt_number%type;
      v_run_id job_runs.run_id%type;
   begin
      v_start_time := systimestamp;
      v_deadline := v_start_time + numtodsinterval(c_budget_time_sec, 'SECOND');

      loop
         -- Exit loop when budget time exhausted
         exit when systimestamp >= v_deadline;

         -- Select next eligible job or exit if none
         v_job := claim_next_job;

         if (v_job.job_id is null) then
            exit;
         end if;

         -- Programmed execution for current job
         v_scheduled_for := v_job.next_run_date;

         -- Resolve any stale RUNNING attempt
         v_stale_run_id := exists_stale_running_attempt(v_job.job_id, v_scheduled_for);

         if (v_stale_run_id is not null) then
            solve_stale_running_attempt(v_stale_run_id);
         end if;

         -- Calculate attempt number, abort if exceeding max and schedule next execution
         v_current_attempt_number := calculate_current_attempt_number(v_job.job_id, v_scheduled_for);

         if (v_current_attempt_number > v_job.max_attempts) then
            mark_job_as_aborted(
               v_job.job_id,
               v_scheduled_for,
               v_current_attempt_number
            );

            schedule_next_execution(v_job.job_id);

            commit;
            continue;
         end if;

         -- Mark job as RUNNING and commit
         v_run_id := mark_job_as_running(
            v_job.job_id,
            v_scheduled_for,
            v_current_attempt_number
         );
         commit;

         -- Execute business logic (placeholder)
         begin
            execute_business_logic(v_job.job_id);

            -- SUCCESS branch
            -- Cooperative cancellation pattern:
            -- Check if the current run is still RUNNING before marking SUCCESS.
            -- If another worker already marked it as FAILED or SUCCESS, skip updates.
            if (is_current_run_still_running(v_run_id)) then
               mark_job_as_success(v_run_id);
               schedule_next_execution(v_job.job_id);
               commit;
            end if;
         exception
            -- FAILED branch
            -- Cooperative cancellation pattern:
            -- Only mark as FAILED if the current run is still RUNNING.
            when others then
               if(is_current_run_still_running(v_run_id)) then
                  mark_job_as_failed(v_run_id, sqlerrm);
                  commit;
               end if;
         end;
      end loop;
   end;

end;
/
