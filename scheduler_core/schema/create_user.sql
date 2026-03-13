-- ===========================================================
-- File: create_user.sql
-- Porpose: Create dedicated schema for scheduler core
-- Must be executed as SYS ur user with CREATE USER privilege
-- Target container: XEPDB1
-- ===========================================================

PROMPT Creating scheduler schema SCHED_SYS ...

-- Optional safety check
SHOW CON_NAME;

-- Drop user if exists (optional for development)
-- Comment this block in production environments
begin
   execute immediate 'DROP USER SCHED_SYS CASCADE';
exception
   when others then
      if (sqlcode != -01918) then
         raise;
      end if;
end;
/

-- Create user
CREATE USER SCHED_SYS
   IDENTIFIED BY sched_sys_password
   DEFAULT TABLESPACE USERS
   TEMPORARY TABLESPACE TEMP
   QUOTA UNLIMITED ON USERS;

-- Core privileges
GRANT CREATE SESSION TO SCHED_SYS;
GRANT CREATE TABLE TO SCHED_SYS;
GRANT CREATE SEQUENCE TO SCHED_SYS;
GRANT CREATE TRIGGER TO SCHED_SYS;
GRANT CREATE PROCEDURE TO SCHED_SYS;
GRANT CREATE JOB TO SCHED_SYS;

-- Allow dynamic SQL execution safety
GRANT EXECUTE ON DBMS_SCHEDULER TO SCHED_SYS;

PROMPT User SCHED_SYS created successfully
