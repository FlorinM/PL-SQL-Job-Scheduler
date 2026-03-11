-- ===========================================================
-- File: scheduler_demo/schema/create_user.sql
-- Purpose: Create demo schema for the scheduler demonstration
-- Must be executed as SYS or a user with CREATE USER privilege
-- Target container: XEPDB1
-- ===========================================================

PROMPT Creating demo schema SCHED_DEMO

-- Optional safety check
SHOW CON_NAME;

-- Drop user if exists (development convenience)
-- Ignore ORA-01918 (user does not exist)
-- Comment this block in production environments
begin
   execute immediate 'DROP USER SCHED_DEMO CASCADE';
exception
   when others then
      if (sqlcode != -01918) then
         raise;
      end if;
end;
/

-- Create user
CREATE USER SCHED_DEMO
   IDENTIFIED BY "sched_demo_password"
   DEFAULT TABLESPACE USERS
   TEMPORARY TABLESPACE TEMP
   QUOTA UNLIMITED ON USERS;

-- Core privileges
GRANT CREATE SESSION TO SCHED_DEMO;
GRANT CREATE TABLE TO SCHED_DEMO;
GRANT CREATE SEQUENCE TO SCHED_DEMO;
GRANT CREATE PROCEDURE TO SCHED_DEMO;

PROMPT User SCHED_DEMO created successfully
