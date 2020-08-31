INSERT INTO firms (name)
  VALUES ('TM');

INSERT INTO departments (name)
  VALUES ('Actuarial');

INSERT INTO processes (name)
  VALUES
    ('Planning'),
    ('Governance'),
    ('Resourcing'),
    ('Systems/processes'),
    ('Data'),
    ('Work'),
    ('Communication');

INSERT INTO risks (uuid, risk_ID, name, loss, firm_ID, department_ID, process_ID)
  VALUES
    ('edbac89f-a536-456b-b942-04fba0b88b87', 'A1','Inadequate compensation', 0, 1, 1, 3),
    ('b5ce0c8e-d17a-48e9-85e5-5f4a556aced5', 'A2','Staff leave', 1, 1, 1, 3);

INSERT INTO risklinks (riskfrom_ID, riskto_ID)
  VALUES ('edbac89f-a536-456b-b942-04fba0b88b87','b5ce0c8e-d17a-48e9-85e5-5f4a556aced5');
