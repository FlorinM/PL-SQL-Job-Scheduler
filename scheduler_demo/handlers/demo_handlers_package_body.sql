-- ==========================
-- File: demo_handlers_package_body.sql
-- Location: scheduler/scheduler_demo/handlers
-- Description: Implementation of scheduler handlers used in the demo.
--              Each handler acts as a thin wrapper that delegates
--              execution to the corresponding business logic procedure.
-- ==========================

/**
 * Package body implementing scheduler handlers for the demo module.
 *
 * Handlers are invoked by the scheduler engine and are responsible
 * for delegating execution to the appropriate business logic layer.
 */
create or replace package body demo_handlers_package as

   -- Public procedure defined in demo_handlers_package_spec.sql
   procedure overdue_tasks_handler(p_job_id number) is
   begin
      -- Delegate business processing to the demo business logic package
      demo_package.mark_overdue_tasks;

   exception
      when others then
         -- Propagate the error to the scheduler engine
         raise;
   end;

end;
/
