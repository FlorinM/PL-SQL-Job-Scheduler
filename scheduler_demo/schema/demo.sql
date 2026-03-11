-- ===========================================================
-- File: scheduler_demo/schema/demo.sql
-- Purpose: Create demo schema for the scheduler demonstration
-- ===========================================================

-- =========================
-- DEMO TABLE
-- =========================

CREATE TABLE tasks (
   task_id NUMBER NOT NULL,
   title VARCHAR2(100) NOT NULL,
   description VARCHAR2(200) NOT NULL,
   due_date DATE NOT NULL,
   status VARCHAR2(10) NOT NULL,
   created_at DATE DEFAULT SYSDATE NOT NULL,
   closed_at DATE
);

-- =========================
-- DEMO INDEXES
-- =========================

CREATE UNIQUE INDEX uix_task_id ON tasks(task_id);
CREATE INDEX ix_status_due ON tasks(status, due_date);

-- =========================
-- DEMO CONSTRAINTS
-- =========================

ALTER TABLE tasks ADD CONSTRAINT pk_tasks
   PRIMARY KEY (task_id) USING INDEX uix_task_id;
ALTER TABLE tasks ADD CONSTRAINT ch_status
   CHECK (status IN ('OPEN', 'DONE', 'OVERDUE'));
ALTER TABLE tasks ADD CONSTRAINT ch_closed_after_created
   CHECK (closed_at IS NULL OR closed_at > created_at);
ALTER TABLE tasks ADD CONSTRAINT ch_status_closed
CHECK (
    (status = 'OPEN' AND closed_at IS NULL)
 OR (status IN ('DONE','OVERDUE'))
);

-- =========================
-- DEMO SEQUENCES
-- =========================

CREATE SEQUENCE tasks_seq
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

-- =========================
-- DEMO DATA
-- =========================

-- OPEN
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Prepare monthly sales report','Compile regional sales data and submit report',SYSDATE+4,'OPEN',SYSDATE-10,NULL);
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Update customer contract templates','Legal team review of updated clauses',SYSDATE+2,'OPEN',SYSDATE-6,NULL);
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Deploy security patches','Apply latest OS and middleware security updates',SYSDATE+2,'OPEN',SYSDATE-3,NULL);
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Database performance review','Analyze slow queries and optimize indexes',SYSDATE+3,'OPEN',SYSDATE-5,NULL);
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Quarterly financial reconciliation','Validate ledger balances with accounting records',SYSDATE+5,'OPEN',SYSDATE-2,NULL);
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Audit user access permissions','Verify role assignments for internal systems',SYSDATE+1,'OPEN',SYSDATE-4,NULL);
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Update onboarding documentation','Revise internal wiki for new employees',SYSDATE+4,'OPEN',SYSDATE-3,NULL);
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Review vendor invoices','Validate billing details before payment',SYSDATE+6,'OPEN',SYSDATE-11,NULL);
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Prepare board meeting materials','Collect KPIs and prepare presentation slides',SYSDATE+1,'OPEN',SYSDATE-4,NULL);
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Inventory warehouse audit','Verify stock levels and discrepancies',SYSDATE+3,'OPEN',SYSDATE-8,NULL);

-- DONE
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Migrate reporting database','Move reporting workload to new cluster',SYSDATE-8,'DONE',SYSDATE-14,SYSDATE-9);
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Close monthly payroll','Finalize salary calculations and approvals',SYSDATE-5,'DONE',SYSDATE-12,SYSDATE-6);
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Upgrade CRM system','Deploy new CRM version and verify integrations',SYSDATE-3,'DONE',SYSDATE-10,SYSDATE-4);
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Conduct internal compliance review','Evaluate adherence to company policies',SYSDATE-3,'DONE',SYSDATE-7,SYSDATE-5);
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Resolve critical production incident','Investigate outage and restore services',SYSDATE-4,'DONE',SYSDATE-9,SYSDATE-5);

-- SEMANTIC OVERDUE (status still OPEN)
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Prepare hiring plan','Define recruitment needs for next quarter',SYSDATE-1,'OPEN',SYSDATE-7,NULL);
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Evaluate cloud infrastructure costs','Review monthly cloud billing and usage',SYSDATE-2,'OPEN',SYSDATE-6,NULL);
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Test disaster recovery procedure','Execute failover simulation in staging',SYSDATE-3,'OPEN',SYSDATE-11,NULL);
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Review data retention policies','Ensure compliance with regulatory requirements',SYSDATE-1,'OPEN',SYSDATE-2,NULL);
INSERT INTO tasks VALUES (tasks_seq.NEXTVAL,'Document API integration changes','Update technical docs after recent release',SYSDATE-5,'OPEN',SYSDATE-9,NULL);

COMMIT;
