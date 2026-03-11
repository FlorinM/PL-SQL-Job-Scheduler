-- ==========================
-- File: demo_package_body.sql
-- Location: scheduler/scheduler_demo/business_logic
-- Description: Implementation of demo_package for handling overdue tasks
-- ==========================

/**
 * Package body for demo_package
 *
 * Contains the business logic for demo tasks (e.g., mark_overdue_tasks)
 */
create or replace package body demo_package as

   -- Public procedure defined in demo_package_spec.sql
   procedure mark_overdue_tasks is
   begin
      -- Update all open tasks whose due_date has passed
      update tasks
      set status = 'OVERDUE'
      where status = 'OPEN'
      and due_date < sysdate;

      -- Commit changes if successful
      commit;
   exception
      when others then
         -- Rollback in case of any error to maintain atomicity
         rollback;

         -- Propagate error with descriptive message
         raise_application_error(
            -20001,
            'Failed to mark due tasks as OVERDUE: ' || sqlerrm
         );
   end;
end;
/
