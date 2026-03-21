-- =======================================
-- File: config_package_body.sql
-- Location: scheduler/scheduler_core/api
-- Description: Implementation of CONFIG_PACKAGE
-- =======================================

/**
 *
 * Package Body: CONFIG_PACKAGE
 *
 * Design assumptions:
 *   - interval is a system constant (hardcoded)
 *   - budget is derived: budget = interval - 1
 *   - only timeout and worker-related configs are stored in DB
 *
 */
create or replace package body config_package as

   /**
    * System-level constant.
    * Must match the value used in DBMS_SCHEDULER repeat_interval.
    */
   c_interval constant number := 28;

   /**
    * Internal helper: fetch config value by name
    */
   function get_value(p_name in configs.name%type) return configs.value%type is
      v_value configs.value%type;
   begin
      select value
      into v_value
      from configs
      where name = p_name;

      return v_value;

   exception
      when no_data_found then
         raise_application_error(-20070, 'Config not found: ' || p_name);
   end;

   -- Public procedure defined in config_package_spec.sql
   function get_interval return number is
   begin
      return c_interval;
   end;

   -- Public procedure defined in config_package_spec.sql
   function get_budget return number is
   begin
      return c_interval - 1;
   end;

   /**
    * Validates timeout against system constraints
    */
   procedure validate_timeout(p_timeout in configs.value%type) is
      v_budget configs.value%type;
   begin
      if (p_timeout <= 0) then
         raise_application_error(-20071, 'timeout must be > 0');
      end if;

      v_budget := get_budget;

      if (p_timeout > v_budget / 3) then
         raise_application_error(
            -20072,
            'timeout must be <= budget / 3'
         );
      end if;
   end;

   -- Public procedure defined in config_package_spec.sql
   function get_timeout return configs.value%type is
      v_timeout configs.value%type;
   begin
      v_timeout := get_value('timeout');

      -- Validate DB value (protect against manual corruption)
      validate_timeout(v_timeout);

      return v_timeout;
   end;

   -- Public procedure defined in config_package_spec.sql
   procedure set_timeout(p_timeout in configs.value%type) is
   begin
      -- Validate input
      validate_timeout(p_timeout);

      update configs
      set value = p_timeout, updated_at = systimestamp
      where name = 'timeout';

      if (sql%rowcount = 0) then
         raise_application_error(
            -20073,
            'Config not found: timeout'
         );
      elsif (sql%rowcount > 1) then
         raise_application_error(
            -20074,
            'Data integrity error: multiple timeout rows'
         );
      end if;

   exception
      when others then
         raise_application_error(
            -20075,
            'Failed to update timeout to ' || p_timeout || ': ' || sqlerrm
         );
   end;

   -- Public procedure defined in config_package_spec.sql
   function get_jobs_per_worker return configs.value%type is
   begin
      return get_value('jobs_per_worker');
   end;

   -- Public procedure defined in config_package_spec.sql
   procedure set_jobs_per_worker(p_jobs_per_worker in configs.value%type) is
   begin
      update configs
      set value = p_jobs_per_worker, updated_at = systimestamp
      where name = 'jobs_per_worker';

      if (sql%rowcount = 0) then
         raise_application_error(
            -20076,
            'Config not found: jobs_per_worker'
         );
      elsif (sql%rowcount > 1) then
         raise_application_error(
            -20077,
            'Data integrity error: multiple jobs_per_worker rows'
         );
      end if;

   exception
      when others then
         raise_application_error(
            -20078,
            'Failed to update jobs_per_worker to ' || p_jobs_per_worker || ': ' || sqlerrm
         );
   end;

   -- Public procedure defined in config_package_spec.sql
   function get_max_workers return configs.value%type is
   begin
      return get_value('max_workers');
   end;

   -- Public procedure defined in config_package_spec.sql
   procedure set_max_workers(p_max_workers in configs.value%type) is
   begin
      update configs
      set value = p_max_workers, updated_at = systimestamp
      where name = 'max_workers';

      if (sql%rowcount = 0) then
         raise_application_error(-20079, 'Config not found: max_workers');
      elsif (sql%rowcount > 1) then
         raise_application_error(-20080, 'Data integrity error: multiple max_workers rows');
      end if;

   exception
      when others then
         raise_application_error(
            -20081,
            'Failed to update max_workers to ' || p_max_workers || ': ' || sqlerrm
         );
   end;

end;
/
