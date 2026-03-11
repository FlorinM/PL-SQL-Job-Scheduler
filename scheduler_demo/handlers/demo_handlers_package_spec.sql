-- ==========================
-- File: demo_handlers_package_spec.sql
-- Location: scheduler/scheduler_demo/handlers
-- Description: Scheduler handler definitions for the demo module.
--              Handlers act as entry points invoked by the scheduler
--              and delegate the actual work to business logic packages.
-- ==========================

/**
 * Package exposing scheduler handlers used in the demo environment.
 *
 * These procedures are invoked by the scheduler engine when a job
 * is executed. Each handler acts as a thin wrapper that calls the
 * corresponding business logic implementation.
 */
create or replace package demo_handlers_package as

   /**
    * Scheduler handler responsible for processing overdue tasks.
    *
    * Invoked by the scheduler engine when the associated job runs.
    * Delegates the actual work to demo_package.mark_overdue_tasks.
    *
    * @param p_job_id Identifier of the scheduler job being executed.
    */
   procedure overdue_tasks_handler (p_job_id number);

end;
/
