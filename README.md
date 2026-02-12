# Oracle PL/SQL Custom Job Scheduler

## Overview

This project implements a lightweight, database-native job scheduler built entirely in PL/SQL on top of Oracle Database.

The purpose of this project is to demonstrate advanced database engineering concepts, including:

- Transaction control
- Row-level locking
- Concurrency handling
- `SELECT FOR UPDATE SKIP LOCKED`
- Idempotent job execution
- Failure recovery
- Retry mechanisms
- Operational traceability
- Schema decoupling
- Infrastructure vs. business separation

The scheduler is designed as a reusable infrastructure component that can be installed in any Oracle database and consumed by independent business schemas.

---

## Architecture Philosophy

The system is divided into two logical layers.

### 1. Scheduler Core (Infrastructure Layer)

The scheduler runs in its own dedicated schema and owns all of its objects.

Responsibilities include:

- Job registration
- Job state management
- Concurrency control
- Execution tracking
- Retry handling
- Failure logging
- Worker orchestration

The scheduler contains **no business logic**.  
It operates strictly as infrastructure.

---

### 2. Business Layer (External Consumer)

Business schemas remain independent from the scheduler.

They:

- Define business procedures
- Register jobs through the scheduler API
- Provide minimal adapter procedures if needed

The scheduler does not know anything about business tables or business rules.

This guarantees strict separation of concerns and loose coupling.

---

## Execution Model

The system leverages Oracle `DBMS_SCHEDULER` to periodically invoke internal dispatcher workers.

Each worker performs the following steps:

1. Select eligible jobs.
2. Lock them using `SELECT FOR UPDATE SKIP LOCKED`.
3. Insert a record into the job execution log.
4. Commit the claim phase.
5. Dynamically execute the business procedure.
6. Update execution status.
7. Calculate and schedule the next execution.

Multiple workers can run concurrently.

Concurrency safety is ensured through:

- Row-level locking
- `SKIP LOCKED`
- Explicit transaction boundaries
- Deterministic job state transitions

---

## Concurrency and Reliability

The scheduler ensures:

- No double execution of the same job instance
- Safe parallelism
- Crash recovery capability
- Retry after failure
- Execution traceability

If a worker crashes during execution:

- The execution record remains in a recoverable state
- The job can be retried based on retry policy
- No other worker can execute the same locked job concurrently

---

## Installation

1. Connect to the target PDB (e.g., `XEPDB1`).
2. Run:

```sql```
@install.sql

The installation script will:

- Create the scheduler schema
- Create required tables and indexes
- Create sequences
- Create API and engine packages
- Create dispatcher workers via `DBMS_SCHEDULER`
- Grant necessary privileges

---

## Public API Contract

Business schemas interact with the scheduler exclusively through the public API package.

- To register a job:
```sql```
   sched_api_pkg.register_job(...);

- Business procedures must follow a minimal contract:
   procedure job_name(p_job_id number);

- The p_job_id acts as an execution context identifier.
- The business layer may use it to retrieve parameters from its own tables or payload structures.
- Internal scheduler tables are not exposed to consumer schemas.

---

## Development Environment

Tested on:
- Oracle Database Express Edition (XE)
- Docker-based Oracle XE container
- Pluggable database (e.g., XEPDB1)

---

## Status

- Project under development.
