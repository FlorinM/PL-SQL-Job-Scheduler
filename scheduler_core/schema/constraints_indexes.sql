-- =============================
-- File: constraints_indexes.sql
-- =============================

CREATE UNIQUE INDEX uix_job_id ON jobs(job_id);
CREATE UNIQUE INDEX uix_run_id ON job_runs(run_id);
CREATE INDEX ix_job_id ON job_runs(job_id);

CREATE INDEX ix_jobs_ready ON jobs(enabled_flag, next_run_date);
CREATE INDEX ix_job_runs_running
   ON job_runs(job_id, scheduled_for, status, start_time);
CREATE UNIQUE INDEX uix_job_sched_attempt
   ON job_runs(job_id, scheduled_for, attempt_number);
CREATE INDEX ix_job_runs_status ON job_runs(status);


ALTER TABLE jobs ADD CONSTRAINT pk_jobs
   PRIMARY KEY (job_id) USING INDEX uix_job_id;
ALTER TABLE job_runs ADD CONSTRAINT pk_job_runs
   PRIMARY KEY (run_id) USING INDEX uix_run_id;
ALTER TABLE configs ADD CONSTRAINT pk_configs
   PRIMARY KEY (name);
ALTER TABLE job_runs ADD CONSTRAINT fk_job_runs_jobs
   FOREIGN KEY (job_id) REFERENCES jobs(job_id);

ALTER TABLE jobs ADD CONSTRAINT u_job_name
   UNIQUE (job_name);
ALTER TABLE jobs ADD CONSTRAINT ch_enabled_flag
   CHECK (enabled_flag IN ('Y', 'N'));
ALTER TABLE job_runs ADD CONSTRAINT ch_status
   CHECK (status IN ('RUNNING', 'SUCCESS', 'FAILED', 'ABORTED'));
ALTER TABLE jobs ADD CONSTRAINT u_procedure_name
   UNIQUE (procedure_name);
ALTER TABLE jobs ADD CONSTRAINT ch_interval_seconds
   CHECK (interval_seconds > 0);
ALTER TABLE jobs ADD CONSTRAINT ch_max_attempts
   CHECK (max_attempts >= 1);
ALTER TABLE job_runs ADD CONSTRAINT ch_attempt_number
   CHECK (attempt_number >= 1);
ALTER TABLE configs ADD CONSTRAINT ch_value
   CHECK (value > 0);
