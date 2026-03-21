-- ========================================
-- File: config_package_spec.sql
-- Location: scheduler/scheduler_core/api
-- ========================================

/**
 *
 * Package: CONFIG_PACKAGE
 *
 * Public API for scheduler configuration access.
 *
 */
create or replace package config_package as

   /**
    * Returns the scheduler interval (fixed system value).
    *
    * @return number - interval in seconds
    */
   function get_interval return number;

   /**
    * Returns the execution budget derived from interval.
    *
    * Formula:
    *   budget = interval - 1
    *
    * @return number - budget in seconds
    */
   function get_budget return number;

   /**
    * Returns the configured timeout value.
    *
    * The value is validated at runtime to ensure it respects:
    *   timeout > 0
    *   timeout <= budget / 3
    *
    * @return configs.value%type - timeout in seconds
    */
   function get_timeout return configs.value%type;

   /**
    * Updates the timeout configuration value.
    *
    * The value is validated before being persisted.
    *
    * @param p_timeout configs.value%type - timeout in seconds
    */
   procedure set_timeout(p_timeout in configs.value%type);

   /**
    * Returns the number of jobs assigned to each worker.
    *
    * @return configs.value%type - jobs per worker
    */
   function get_jobs_per_worker return configs.value%type;

   /**
    * Updates the number of jobs processed per worker.
    *
    * @param p_jobs_per_worker configs.value%type - jobs per worker
    */
   procedure set_jobs_per_worker(p_jobs_per_worker in configs.value%type);

   /**
    * Returns the maximum number of workers allowed.
    *
    * @return configs.value%type - maximum workers
    */
   function get_max_workers return configs.value%type;

   /**
    * Updates the maximum number of workers allowed.
    *
    * @param p_max_workers configs.value%type - maximum workers
    */
   procedure set_max_workers(p_max_workers in configs.value%type);

end config_package;
/
