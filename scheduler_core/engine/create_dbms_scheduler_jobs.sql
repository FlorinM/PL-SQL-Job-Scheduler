-- =====================================================
-- File: create_dbms_scheduler_jobs.sql
-- Location: scheduler/scheduler_core/engine
-- Purpose: Creates the Oracle DBMS_SCHEDULER jobs that
--          periodically executes the scheduler engine.
-- =====================================================

PROMPT Creating scaler procedure...

create or replace procedure scale_engine_workers is
   v_backlog number;
   v_workers number;

   c_jobs_per_worker constant number := config_package.get_jobs_per_worker;
   c_max_workers constant number := config_package.get_max_workers;
begin

   -- Validate config
   if (c_jobs_per_worker < 1) then
      raise_application_error(-20090, 'jobs_per_worker must be >= 1');
   end if;

   if (c_max_workers < 1) then
      raise_application_error(-20091, 'max_workers must be >= 1');
   end if;

   -- backlog
   select count(*)
   into v_backlog
   from jobs j
   where j.enabled_flag = 'Y'
   and j.next_run_date <= systimestamp;

   -- no work => no workers
   if (v_backlog = 0) then
      return;
   end if;

   -- workers
   v_workers := ceil(v_backlog / c_jobs_per_worker);

   -- enforce minimum 1 worker
   v_workers := greatest(v_workers, 1);

   -- cap at max_workers
   v_workers := least(v_workers, c_max_workers);

   -- launch workers
   for i in 1 .. v_workers loop
      dbms_scheduler.run_job('SCHED_ENGINE_JOB', FALSE);
   end loop;

end;
/

PROMPT Creating DBMS_SCHEDULER jobs...

begin
   -- Drop worker job if it already exists (idempotent install)
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

   -- Drop scaler job
   begin
      dbms_scheduler.drop_job('SCHED_ENGINE_SCALER_JOB', force => TRUE);
   exception
      when others then
         if SQLCODE != -27475 then
            raise;
         end if;
   end;

   ----------------------------------------------------------------
   -- WORKER JOB
   ----------------------------------------------------------------
   dbms_scheduler.create_job(
      job_name        => 'SCHED_ENGINE_JOB',
      job_type        => 'STORED_PROCEDURE',
      job_action      => 'ENGINE_PACKAGE.EXECUTE_DUE_JOBS',
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

   ----------------------------------------------------------------
   -- SCALER JOB
   ----------------------------------------------------------------
   dbms_scheduler.create_job(
      job_name        => 'SCHED_ENGINE_SCALER_JOB',
      job_type        => 'STORED_PROCEDURE',
      job_action      => 'SCALE_ENGINE_WORKERS',
      start_date      => systimestamp + INTERVAL '1' SECOND,
      repeat_interval => 'FREQ=SECONDLY;INTERVAL=28',
      enabled         => TRUE,
      auto_drop       => FALSE,
      comments        => 'Controls number of scheduler workers'
   );
end;
/

PROMPT DBMS_SCHEDULER job created successfully.
