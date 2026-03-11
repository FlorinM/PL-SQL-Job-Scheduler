-- ==========================
-- File: demo_package_spec.sql
-- Location: scheduler/scheduler_demo/business_logic
-- Description: Package specification for demo business logic used by the
--              scheduler demonstration.
--
--              It represents a typical background maintenance job that
--              would normally be executed periodically by a scheduler.
-- ==========================

create or replace package demo_package as

   /**
    * Scans the TASKS table for tasks whose due_date has passed
    * and whose status is still OPEN.
    *
    * Such tasks are marked as OVERDUE.
    *
    * Intended to be invoked periodically by the scheduler
    * as part of the demo business workflow.
    */
   procedure mark_overdue_tasks;
end;
/
