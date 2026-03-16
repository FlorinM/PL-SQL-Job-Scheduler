-- =====================================================
-- File: create_dbms_scheduler_jobs.sql
-- Location: scheduler/scheduler_core/engine
-- Purpose: Creates the Oracle DBMS_SCHEDULER job that
--          periodically executes the scheduler engine.
-- =====================================================

PROMPT Creating DBMS_SCHEDULER job SCHED_ENGINE_JOB...

begin
   -- Drop job if it already exists (idempotent install)
   begin
      dbms_scheduler.drop_job(
         job_name => 'SCHED_ENGINE_JOB',
         force    => TRUE
      );
   exception
      when OTHERS then
         -- Ignore error if job does not exist
         if SQLCODE != -27475 then  -- ORA-27475: job does not exist
            raise;
         end if;
   end;

   -- Create scheduler job
   dbms_scheduler.create_job(
      job_name        => 'SCHED_ENGINE_JOB',
      job_type        => 'STORED_PROCEDURE',
      job_action      => 'SCHED_SYS.ENGINE_PACKAGE.EXECUTE_DUE_JOBS',
      start_date      => SYSTIMESTAMP + INTERVAL '1' SECOND,
      repeat_interval => 'FREQ=SECONDLY;INTERVAL=10',
      enabled         => FALSE,
      auto_drop       => FALSE,
      comments        => 'Scheduler Core Engine Worker'
   );

   -- Configure logging level
   dbms_scheduler.set_attribute(
      name      => 'SCHED_ENGINE_JOB',
      attribute => 'logging_level',
      value     => dbms_scheduler.LOGGING_RUNS
   );

   -- Enable job
   dbms_scheduler.enable(
      name => 'SCHED_ENGINE_JOB'
   );

   -- Wake-up dbms_scheduler
   begin
      dbms_scheduler.run_job('SCHED_ENGINE_JOB', FALSE);
   exception
      when others then
         raise_application_error(
            -20040,
            'Failed to run the job SCHED_ENGINE_JOB'
         );
   end;
end;
/

PROMPT DBMS_SCHEDULER job created successfully.
