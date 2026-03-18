-- ===========================================================
-- File: create_user.sql
-- Porpose: Create dedicated schema for scheduler core
-- Must be executed as SYS or user with CREATE USER privilege
-- Target container: &&PDB_NAME
-- ===========================================================

@@../config/config_install.sql

PROMPT Creating scheduler schema &&SCHED_USER ...

-- Validate container (optional but recommended)
declare
   v_con_name VARCHAR2(30);
begin
   SELECT sys_context('USERENV', 'CON_NAME')
   INTO v_con_name
   FROM dual;

   if (length(trim('&&PDB_NAME')) > 0 and v_con_name != '&&PDB_NAME') then
      raise_application_error(
         -20050,
         'Wrong container. Expected: &&PDB_NAME, but got: ' || v_con_name
      );
   end if;

   if (v_con_name = 'CDB$ROOT') then
      raise_application_error(
         -20051,
         'Do not run this script in CDB$ROOT'
      );
   end if;
end;
/

-- Drop user if exists (optional for development)
-- Comment this block in production environments
begin
   execute immediate 'DROP USER "' || '&&SCHED_USER' || '" CASCADE';
exception
   when others then
      if (sqlcode != -01918) then
         raise;
      end if;
end;
/

-- Create user
CREATE USER &&SCHED_USER
   IDENTIFIED BY "&&SCHED_PASSWORD"
   DEFAULT TABLESPACE &&DEFAULT_TABLESPACE
   TEMPORARY TABLESPACE &&TEMP_TABLESPACE
   QUOTA UNLIMITED ON &&DEFAULT_TABLESPACE;

-- Core privileges
GRANT CREATE SESSION TO &&SCHED_USER;
GRANT CREATE TABLE TO &&SCHED_USER;
GRANT CREATE SEQUENCE TO &&SCHED_USER;
GRANT CREATE TRIGGER TO &&SCHED_USER;
GRANT CREATE PROCEDURE TO &&SCHED_USER;
GRANT CREATE JOB TO &&SCHED_USER;

-- Allow dynamic SQL execution safety
GRANT EXECUTE ON DBMS_SCHEDULER TO &&SCHED_USER;

PROMPT User &&SCHED_USER created successfully
