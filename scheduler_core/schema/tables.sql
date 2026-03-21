-- =================
-- File: tables.sql
-- =================

CREATE TABLE jobs (
   job_id NUMBER NOT NULL,
   job_name VARCHAR2(100) NOT NULL,
   procedure_name VARCHAR2(200) NOT NULL,
   enabled_flag CHAR(1) NOT NULL,
   interval_seconds NUMBER NOT NULL,
   next_run_date TIMESTAMP WITH TIME ZONE NOT NULL,
   max_attempts NUMBER,
   created_at TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP NOT NULL,
   created_by VARCHAR2(128)
);

CREATE TABLE job_runs (
   run_id NUMBER NOT NULL,
   job_id NUMBER NOT NULL,
   scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
   status VARCHAR2(20) NOT NULL,
   start_time TIMESTAMP WITH TIME ZONE NOT NULL,
   end_time TIMESTAMP WITH TIME ZONE,
   error_message CLOB,
   attempt_number NUMBER NOT NULL
);
