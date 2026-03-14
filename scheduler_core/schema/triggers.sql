CREATE OR REPLACE TRIGGER trg_job_runs_state_guard
FOR INSERT OR UPDATE ON job_runs
COMPOUND TRIGGER

   g_job_id job_runs.job_id%type;
   g_scheduled_for job_runs.scheduled_for%type;
   g_run_id job_runs.run_id%type;
   g_status job_runs.status%type;

----------------------------------------------------------------
-- BEFORE EACH ROW
----------------------------------------------------------------
BEFORE EACH ROW IS
BEGIN

   -------------------------------------------------------------
   -- INSERT RULES
   -------------------------------------------------------------
   IF INSERTING THEN
      IF :NEW.status NOT IN ('RUNNING','ABORTED') THEN
         raise_application_error(
            -20030,
            'Only RUNNING or ABORTED allowed on INSERT.'
         );
      END IF;
   END IF;

   -------------------------------------------------------------
   -- UPDATE RULES
   -------------------------------------------------------------
   IF UPDATING THEN
      IF :OLD.status <> 'RUNNING' THEN
         raise_application_error(
            -20031,
            'Status can only be updated when current status is RUNNING.'
         );
      END IF;

      IF :NEW.status NOT IN ('SUCCESS','FAILED') THEN
         raise_application_error(
            -20032,
            'RUNNING can only transition to SUCCESS or FAILED.'
         );
      END IF;
   END IF;

   -------------------------------------------------------------
   -- Save execution for AFTER STATEMENT validation
   -------------------------------------------------------------
   g_job_id := :NEW.job_id;
   g_scheduled_for := :NEW.scheduled_for;
   g_run_id := :NEW.run_id;
   g_status := :NEW.status;

END BEFORE EACH ROW;

----------------------------------------------------------------
-- AFTER STATEMENT
----------------------------------------------------------------
AFTER STATEMENT IS
   v_dummy NUMBER;
BEGIN

   IF g_status IN ('RUNNING','SUCCESS','ABORTED') THEN
      BEGIN
         SELECT 1
         INTO v_dummy
         FROM job_runs
         WHERE job_id = g_job_id
         AND scheduled_for = g_scheduled_for
         AND status IN ('RUNNING','SUCCESS','ABORTED')
         AND run_id != g_run_id
         AND ROWNUM = 1;

         raise_application_error(
            -20033,
            'Only one RUNNING/SUCCESS/ABORTED allowed per execution.'
         );

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            NULL;
      END;
   END IF;

END AFTER STATEMENT;

END;
/
