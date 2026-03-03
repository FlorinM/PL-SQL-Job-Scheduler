# Scheduler Core – High-Level Architecture

## 1. Overview

This project implements a lightweight, database-native job scheduler built entirely in PL/SQL on top of Oracle Database.

The system is designed as an infrastructure component that:

- Runs in its own dedicated schema
- Is fully decoupled from business schemas
- Supports safe parallel execution
- Provides execution traceability
- Implements retry and failure handling
- Uses row-level locking and SELECT FOR UPDATE SKIP LOCKED

The scheduler contains no business logic.

---

## 2. Architectural Layers

The system is divided into two logical layers:

### 2.1 Infrastructure Layer (Scheduler Core)

- Owned by the SCHED_SYS schema.
- Responsibilities:
- Job registration
- Job metadata storage
- Execution tracking
- Concurrency control
- Failure logging
- Retry orchestration
- Worker dispatch via DBMS_SCHEDULER

Main components:

- sched_api_pkg
- sched_engine_pkg
- jobs table
- job_runs table
- Oracle DBMS_SCHEDULER job

### 2.2 Business Layer (External Consumers)

Business schemas:

- Define business procedures
- Register jobs via sched_api_pkg
- Remain independent from scheduler internals

Business procedures must follow a minimal contract:

`procedure job_name(p_job_id number);`

The scheduler does not access business tables directly.

## 3. High-Level Execution Flow

```      
Business Schema
      │
      │ register_job(...)
      ▼
sched_api_pkg
      │
      │ inserts job definition
      ▼
jobs table
      │
      │ DBMS_SCHEDULER triggers
      ▼
engine_package.execute_due_jobs()
      │
      ├─ Loop until worker budget_time expires:
      │      ├─ Claim next eligible job (FOR UPDATE SKIP LOCKED)
      │      ├─ Resolve any stale RUNNING attempt:
      │      │      └─ Mark stale RUNNING as FAILED
      │      ├─ Calculate attempt_number
      │      ├─ If attempt_number > max_attempts:
      │      │      ├─ Mark job as ABORTED
      │      │      └─ Recalculate next_run_date
      │      ├─ Else:
      │      │      ├─ Insert RUNNING row in job_runs
      │      │      └─ Commit claim phase (lock released)
      │      ├─ Execute business procedure (execute_business_logic)
      │      │      ├─ SUCCESS: mark RUNNING as SUCCESS + recalc next_run_date
      │      │      └─ FAILURE: mark RUNNING as FAILED (retry possible)
      │      └─ Commit final state for this job
      │
      └─ End loop when no eligible jobs or budget_time exceeded
```

## 4. Data Model

### 4.1 jobs (Job Definition)

Represents static configuration and scheduling metadata.

| Column           | Purpose                            |
| ---------------- | ---------------------------------- |
| job_id           | Primary key                        |
| job_name         | Logical job identifier (unique)    |
| procedure_name   | Business procedure to execute      |
| enabled_flag     | 'Y' or 'N'                         |
| interval_seconds | Execution frequency                |
| next_run_date    | Next scheduled execution timestamp |
| created_at       | Creation timestamp                 |
| created_by       | Creator                            |

This table contains no runtime state.

### 4.2 job_runs (Execution Journal)

Represents individual execution instances.

| Column         | Purpose                |
| -------------- | ---------------------- |
| run_id         | Primary key            |
| job_id         | FK → jobs              |
| status         | Execution state        |
| start_time     | Execution start        |
| end_time       | Execution end          |
| error_message  | Error details (if any) |
| attempt_number | Retry attempt counter  |
| created_at     | Insert timestamp       |

## 5. Execution Lifecycle (State Machine)

`status` models the lifecycle of a single execution instance.

Valid states:

- RUNNING
- SUCCESS
- FAILED
- ABORTED

Lifecycle Transitions:

```
CREATE RUN  ───────────────► RUNNING
RUNNING     ───────────────► SUCCESS
RUNNING     ───────────────► FAILED
RUNNING     ───────────────► ABORTED
```

Rules:

- A run is created with status = 'RUNNING'
- Only RUNNING may transition to another state
- Final states are immutable
- Retry creates a new run record (append-only model)

## 6. Concurrency Model

The scheduler supports safe parallel workers.

Claim Algorithm

Workers execute:

```
SELECT *
FROM jobs
WHERE enabled_flag = 'Y'
AND next_run_date <= SYSTIMESTAMP
FOR UPDATE SKIP LOCKED;
```

Properties:

- Row-level locking
- No double execution
- Safe horizontal scaling
- No blocking between workers

Claim Phase

- 1. Lock job row
- 2. Insert job_runs record with status = 'RUNNING'
- 3. Commit
- 4. Execute business procedure

The commit boundary ensures:

- Lock is released
- Execution is traceable even if worker crashes

## 7. Failure and Recovery Strategy

A run is considered stale if:

```
status = 'RUNNING'
AND end_time IS NULL
AND start_time < (current_time - timeout_threshold)
```

Recovery process:

- 1. Lock stale run
- 2. Mark as ABORTED
- 3. Create new run (retry)
- 4. Continue execution

No execution record is ever deleted or overwritten.

## 8. Design Principles

- Strict separation of concerns
- No business logic inside scheduler
- Explicit execution state
- Deterministic lifecycle transitions
- Safe parallelism
- Idempotent execution model
- Infrastructure-first design

## 9. Future Extensions

- Possible enhancements:
- Retry policies (fixed / exponential backoff)
- Max retry limits
- Dead-letter handling
- Metrics and monitoring views
- Execution statistics aggregation
- Job prioritization
- Pause/resume functionality

## 10. Summary

This scheduler is not a simple cron clone.

It is a database-native execution engine that:

- Uses transactional guarantees
- Supports concurrency safely
- Tracks execution history explicitly
- Is fully decoupled from business schemas
- Can scale horizontally using multiple workers

The architecture prioritizes clarity, determinism, and operational safety.
