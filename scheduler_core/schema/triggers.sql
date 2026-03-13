CREATE OR REPLACE TRIGGER trg_job_runs_state_guard
BEFORE INSERT OR UPDATE ON job_runs
FOR EACH ROW
DECLARE
    v_dummy NUMBER;
BEGIN

    ----------------------------------------------------------------
    -- INSERT RULES
    ----------------------------------------------------------------
    IF INSERTING THEN
        IF :NEW.status NOT IN ('RUNNING','ABORTED') THEN
            RAISE_APPLICATION_ERROR(
                -20030,
                'Only RUNNING or ABORTED allowed on INSERT.'
            );
        END IF;
    END IF;

    ----------------------------------------------------------------
    -- UPDATE RULES
    ----------------------------------------------------------------
    IF UPDATING THEN
        -- updates allowed only from RUNNING
        IF :OLD.status <> 'RUNNING' THEN
            RAISE_APPLICATION_ERROR(
                -20031,
                'Status can only be updated when current status is RUNNING.'
            );
        END IF;

        -- allowed transitions
        IF :NEW.status NOT IN ('SUCCESS','FAILED') THEN
            RAISE_APPLICATION_ERROR(
                -20032,
                'RUNNING can only transition to SUCCESS or FAILED.'
            );
        END IF;
    END IF;

    ----------------------------------------------------------------
    -- MUTUAL EXCLUSIVITY
    ----------------------------------------------------------------
    IF :NEW.status IN ('RUNNING','SUCCESS','ABORTED') THEN
        BEGIN
            SELECT 1
            INTO v_dummy
            FROM job_runs
            WHERE job_id = :NEW.job_id
            AND scheduled_for = :NEW.scheduled_for
            AND status IN ('RUNNING','SUCCESS','ABORTED')
            AND run_id != :NEW.run_id
            AND ROWNUM = 1;

            RAISE_APPLICATION_ERROR(
                -20033,
                'Only one RUNNING/SUCCESS/ABORTED allowed per execution.'
            );

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
    END IF;

END;
/
