-- ===========================================================
-- File: scheduler_demo/schema/create_user.sql
-- Purpose: Create demo schema for the scheduler demonstration
-- Must be executed as SYS or a user with CREATE USER privilege
-- Target container: &&PDB_NAME
-- ===========================================================

@@../config/config_install.sql

PROMPT Creating demo schema &&DEMO_USER

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

-- Drop user if exists (development convenience)
-- Ignore ORA-01918 (user does not exist)
-- Comment this block in production environments
begin
   execute immediate 'DROP USER "' || '&&DEMO_USER' || '" CASCADE';
exception
   when others then
      if (sqlcode != -01918) then
         raise;
      end if;
end;
/

-- Create user
CREATE USER &&DEMO_USER
   IDENTIFIED BY "&&DEMO_PASSWORD"
   DEFAULT TABLESPACE &&DEFAULT_TABLESPACE
   TEMPORARY TABLESPACE &&TEMP_TABLESPACE
   QUOTA UNLIMITED ON &&DEFAULT_TABLESPACE;

-- Core privileges
GRANT CREATE SESSION TO &&DEMO_USER;
GRANT CREATE TABLE TO &&DEMO_USER;
GRANT CREATE SEQUENCE TO &&DEMO_USER;
GRANT CREATE PROCEDURE TO &&DEMO_USER;

PROMPT User &&DEMO_USER created successfully
