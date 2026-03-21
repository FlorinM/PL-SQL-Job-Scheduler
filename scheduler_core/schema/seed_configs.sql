-- =====================================================
-- File: seed_configs.sql
-- Purpose: Initialize default configuration values
-- Must be run after creating CONFIGS table
-- =====================================================

PROMPT =====================================================
PROMPT Seeding default configuration values
PROMPT =====================================================

-- Helper: merge (insert if not exists, otherwise update)
DECLARE
   PROCEDURE upsert_config(p_name IN configs.name%TYPE, p_value IN configs.value%TYPE) IS
   BEGIN
      UPDATE configs
      SET value = p_value, updated_at = SYSTIMESTAMP
      WHERE name = p_name;

      IF (SQL%ROWCOUNT = 0) THEN
         INSERT INTO configs (
            name,
            value,
            created_at,
            updated_at
         ) VALUES (
            p_name,
            p_value,
            systimestamp,
            systimestamp
         );
      END IF;
   END;
BEGIN

   ----------------------------------------------------------------
   -- TIME MODEL (corelated values)
   ----------------------------------------------------------------
   -- timeout → budget → interval (derived relationship)

   upsert_config('timeout', 3);  -- example: 3 sec

   ----------------------------------------------------------------
   -- SCALING MODEL (independent)
   ----------------------------------------------------------------
   upsert_config('jobs_per_worker', 10);
   upsert_config('max_workers', 20);

END;
/

PROMPT Default configuration seeded successfully.
