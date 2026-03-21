# Oracle PL/SQL Custom Job Scheduler

## Overview

This project implements a lightweight, database-native job scheduler built entirely in PL/SQL on top of Oracle Database.

The purpose of this project is to demonstrate advanced database engineering concepts, including:

- Transaction control
- Row-level locking
- Concurrency handling
- `SELECT FOR UPDATE SKIP LOCKED`
- At-least-once job execution semantics
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

## Execution Guarantees

The scheduler provides **at-least-once execution semantics**.

Under normal operating conditions:

- A job instance is executed once
- Concurrency is controlled via row-level locking and `SKIP LOCKED`
- Only one worker can claim and execute a job at a given moment

In edge cases:

- If a worker exceeds the configured timeout, another worker may reclaim and execute the same job instance
- This can lead to **duplicate execution of business logic**

The scheduler guarantees consistency at the execution tracking level (job logs), but does not enforce idempotency of business side effects.

---

## Concurrency and Reliability

The scheduler ensures:

- Safe parallel execution
- Controlled concurrency via locking
- Crash recovery capability
- Retry after failure
- Execution traceability

If a worker crashes during execution:

- The execution record remains in a recoverable state
- The job can be retried based on retry policy

If a worker exceeds the configured timeout:

- The job may be reclaimed and executed again
- Duplicate execution is possible but limited to such edge cases

---

## Idempotency Considerations

The scheduler does not enforce idempotency of business logic.

However:

- Each execution is associated with a unique context (`p_job_id`)
- Business procedures may optionally use this identifier as an idempotency key

This allows consumers to implement protection against duplicate side effects where required (e.g., external calls, inserts, integrations).

---

## Limitations

- The scheduler is optimized for **short-running jobs**
- Long-running jobs may exceed the configured timeout and lead to duplicate execution
- The scheduler does not control or enforce side effects produced by business logic
- Exactly-once execution is not guaranteed without cooperation from the business layer

---

## Installation

1. Edit `scheduler_core/config/config_install.sql` (PDB, USER, PASSWORD, etc.)
2. Connect to the target PDB as `SYSDBA`
3. Run:

```sql```
@install.sql

The installation script will:

- Create the scheduler schema
- Grant necessary privileges
- Create required tables and indexes
- Create sequences
- Create API, engine, and config packages
- Create dispatcher workers via `DBMS_SCHEDULER`

### (Optional) Install Demo
1. Edit `scheduler_demo/config/config_install.sql`
2. Connect to the target PDB as `SYSDBA`
3. Run:

```sql```
@scheduler_demo/install.sql

4. Disconnect and connect as the scheduler user (not the demo user)
5. Run:

```sql```
@scheduler_demo/register_jobs.sql

6. Query the `jobs` and `job_runs` tables to observe execution results

---

## Public API Contract

Business schemas interact with the scheduler exclusively through the public API package.

- To register a job:
```sql```
   api_package.register_job(...);

### Handler Contract

Business procedures (handlers) are the execution entry point and may perform any required logic:

`procedure job_name(p_job_id number);`

- The p_job_id acts as an execution context identifier.
- The handler is responsible for:
- Retrieving parameters from its own tables or payload structures
- Invoking other procedures or services
- Implementing the full business logic

The scheduler does not impose any constraints on internal handler implementation.

### Exception Handling Contract

Execution outcome is determined jointly by the handler and the scheduler:

- The handler defines what constitutes a successful execution
- The scheduler interprets execution outcome based on exceptions:

#### Rules
- If the handler completes without raising an exception → the job is considered SUCCESS
- If an exception is raised and propagates to the scheduler → the job is considered FAILED
- The handler may explicitly raise exceptions to force a FAILED outcome
- Exceptions that are caught and fully handled within the handler (i.e. not propagated) result in SUCCESS

### Responsibility Split

#### Handler responsibility:
- Define business semantics of success and failure
- Execute all business logic
- Optionally signal failure via exceptions

#### Scheduler responsibility:
- Execute handlers
- Capture exceptions
- Map execution outcome to SUCCESS or FAILED
- Maintain execution state and tracking

### Important Note

The scheduler treats:
- Any propagated error as FAILED
- Any clean completion (no propagated errors) as SUCCESS

This contract ensures clear separation of concerns while allowing the handler full control over business semantics and execution outcome.

---

## Security and Permissions

The scheduler executes business handlers dynamically from within its own schema.

As a result, the **scheduler user must be granted execute privileges on the business handler packages or procedures**.

### Required Privileges

- The scheduler user must have `EXECUTE` privileges on all handler packages or procedures that are invoked by the scheduler.

Example:

```sql```
GRANT EXECUTE ON business_schema.job_handlers_pkg TO scheduler_user;

---

## Development Environment

Tested on:
- Oracle Database Express Edition (XE)
- Docker-based Oracle XE container
- Pluggable database (e.g., XEPDB1)

---

## Status

- Project under development.
