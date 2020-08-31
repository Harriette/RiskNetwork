DROP DATABASE IF EXISTS risknetwork;
CREATE DATABASE risknetwork;
USE risknetwork;

CREATE TABLE IF NOT EXISTS firms (
  firm_ID         INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  name            VARCHAR(50)   NOT NULL DEFAULT '',
  PRIMARY KEY     (firm_ID)
);

CREATE TABLE IF NOT EXISTS departments (
  department_ID   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  name            VARCHAR(25)   NOT NULL DEFAULT '',
  PRIMARY KEY     (department_ID)
);

CREATE TABLE IF NOT EXISTS processes (
  process_ID      INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  name            VARCHAR(25)   NOT NULL DEFAULT '',
  PRIMARY KEY     (process_ID)
);

CREATE TABLE IF NOT EXISTS risks (
  uuid            VARCHAR(50),
  risk_ID         VARCHAR(10)   NOT NULL DEFAULT '',
  name            VARCHAR(50)   NOT NULL DEFAULT '',
  loss            BOOLEAN       DEFAULT 0,
  firm_ID         INT UNSIGNED  NOT NULL,
  department_ID   INT UNSIGNED  NOT NULL,
  process_ID      INT UNSIGNED  NOT NULL,
  description     VARCHAR(500),
  prob_rating     TINYINT,
  severity_rating TINYINT,
  rag_rating      VARCHAR(10),
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_by      VARCHAR(50),
  modified_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modified_by     VARCHAR(50),
  is_deleted      BOOLEAN DEFAULT 0,
  PRIMARY KEY     (uuid),
  FOREIGN KEY     (firm_ID)       REFERENCES firms (firm_ID),
  FOREIGN KEY     (department_ID) REFERENCES departments (department_ID),
  FOREIGN KEY     (process_ID)    REFERENCES processes (process_ID)
);

CREATE TABLE IF NOT EXISTS risklinks (
  risklink_ID     INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  riskfrom_ID     VARCHAR(50)    NOT NULL,
  riskto_ID       VARCHAR(50)    NOT NULL,
  PRIMARY KEY     (risklink_ID),
  FOREIGN KEY     (riskfrom_ID)  REFERENCES risks (uuid),
  FOREIGN KEY     (riskto_ID)    REFERENCES risks (uuid)
);
