#!/bin/sh

# Set archive log mode and enable GG replication
ORACLE_SID=ORCLCDB
export ORACLE_SID
sqlplus /nolog <<- EOF
	CONNECT sys/Oracle123 AS SYSDBA


	shutdown immediate
	startup mount
	alter database archivelog;
	alter database open;
        -- Should show "Database log mode: Archive Mode"
	archive log list
	exit;
EOF


sqlplus sys/Oracle123@//localhost:1521/ORCLCDB as sysdba <<- EOF
  	ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

    CREATE ROLE C##CDC_PRIVS;
    GRANT EXECUTE_CATALOG_ROLE TO C##CDC_PRIVS;
    GRANT ALTER SESSION TO C##CDC_PRIVS;
    GRANT SET CONTAINER TO C##CDC_PRIVS;
    GRANT SELECT ANY TRANSACTION TO C##CDC_PRIVS;
    GRANT SELECT ANY DICTIONARY TO C##CDC_PRIVS;
    GRANT SELECT ON SYSTEM.LOGMNR_COL$ TO C##CDC_PRIVS;
    GRANT SELECT ON SYSTEM.LOGMNR_OBJ$ TO C##CDC_PRIVS;
    GRANT SELECT ON SYSTEM.LOGMNR_USER$ TO C##CDC_PRIVS;
    GRANT SELECT ON SYSTEM.LOGMNR_UID$ TO C##CDC_PRIVS;
    GRANT CREATE SESSION TO C##CDC_PRIVS;
    GRANT EXECUTE ON SYS.DBMS_LOGMNR TO C##CDC_PRIVS;
    GRANT LOGMINING TO C##CDC_PRIVS;
    GRANT SELECT ON V_$LOGMNR_CONTENTS TO C##CDC_PRIVS;
    GRANT SELECT ON V_$DATABASE TO C##CDC_PRIVS;
    GRANT SELECT ON V_$THREAD TO C##CDC_PRIVS;
    GRANT SELECT ON V_$PARAMETER TO C##CDC_PRIVS;
    GRANT SELECT ON V_$NLS_PARAMETERS TO C##CDC_PRIVS;
    GRANT SELECT ON V_$TIMEZONE_NAMES TO C##CDC_PRIVS;
    GRANT SELECT ON ALL_INDEXES TO C##CDC_PRIVS;
    GRANT SELECT ON ALL_OBJECTS TO C##CDC_PRIVS;
    GRANT SELECT ON ALL_USERS TO C##CDC_PRIVS;
    GRANT SELECT ON ALL_CATALOG TO C##CDC_PRIVS;
    GRANT SELECT ON ALL_CONSTRAINTS TO C##CDC_PRIVS;
    GRANT SELECT ON ALL_CONS_COLUMNS TO C##CDC_PRIVS;
    GRANT SELECT ON ALL_TAB_COLS TO C##CDC_PRIVS;
    GRANT SELECT ON ALL_IND_COLUMNS TO C##CDC_PRIVS;
    GRANT SELECT ON ALL_ENCRYPTED_COLUMNS TO C##CDC_PRIVS;
    GRANT SELECT ON ALL_LOG_GROUPS TO C##CDC_PRIVS;
    GRANT SELECT ON ALL_TAB_PARTITIONS TO C##CDC_PRIVS;
    GRANT SELECT ON SYS.DBA_REGISTRY TO C##CDC_PRIVS;
    GRANT SELECT ON SYS.OBJ$ TO C##CDC_PRIVS;
    GRANT SELECT ON DBA_TABLESPACES TO C##CDC_PRIVS;
    GRANT SELECT ON DBA_OBJECTS TO C##CDC_PRIVS;
    GRANT SELECT ON SYS.ENC$ TO C##CDC_PRIVS;
    GRANT SELECT ON V_$ARCHIVED_LOG TO C##CDC_PRIVS;
    GRANT SELECT ON V_$LOG TO C##CDC_PRIVS;
    GRANT SELECT ON V_$LOGFILE TO C##CDC_PRIVS;
    GRANT SELECT ON V_$INSTANCE to C##CDC_PRIVS;
    GRANT SELECT ANY TABLE TO C##CDC_PRIVS;
    exit;
EOF


sqlplus sys/Oracle123@//localhost:1521/ORCLCDB as sysdba <<- EOF

    CREATE USER C##MYUSER IDENTIFIED BY password DEFAULT TABLESPACE USERS CONTAINER=ALL;
    ALTER USER C##MYUSER QUOTA UNLIMITED ON USERS;
    GRANT C##CDC_PRIVS to C##MYUSER CONTAINER=ALL;
    GRANT CONNECT TO C##MYUSER CONTAINER=ALL;
    GRANT CREATE TABLE TO C##MYUSER CONTAINER=ALL;
    GRANT CREATE SEQUENCE TO C##MYUSER CONTAINER=ALL;
    GRANT CREATE TRIGGER TO C##MYUSER CONTAINER=ALL;
    GRANT SELECT ON GV_$ARCHIVED_LOG TO C##MYUSER CONTAINER=ALL;
    GRANT SELECT ON GV_$DATABASE TO C##MYUSER CONTAINER=ALL;
    GRANT FLASHBACK ANY TABLE TO C##MYUSER;
    GRANT FLASHBACK ANY TABLE TO C##MYUSER container=all;
    exit;

EOF

sqlplus sys/Oracle123@//localhost:1521/ORCLCDB as sysdba <<- EOF

	CREATE TABLE C##MYUSER.BPM_DEPARTMENTS
	(
	    i INTEGER GENERATED BY DEFAULT AS IDENTITY,
	    DEPARTMENT VARCHAR2(100),
	    PRIMARY KEY (i)
	);

	GRANT SELECT ON C##MYUSER.BPM_DEPARTMENTS TO C##CDC_PRIVS;
	insert into C##MYUSER.BPM_DEPARTMENTS (DEPARTMENT) values ('Accounting');
	insert into C##MYUSER.BPM_DEPARTMENTS (DEPARTMENT) values ('Marketing');
	insert into C##MYUSER.BPM_DEPARTMENTS (DEPARTMENT) values ('Selling');
	insert into C##MYUSER.BPM_DEPARTMENTS (DEPARTMENT) values ('HR');
	COMMIT;

	CREATE TABLE C##MYUSER.BPM_EMPLOYEES
	(
	    ID NUMBER GENERATED BY DEFAULT AS IDENTITY,
	    name VARCHAR2(100),
	    CONSTRAINT PK_ID PRIMARY KEY (ID)
	);
	GRANT SELECT ON C##MYUSER.BPM_EMPLOYEES TO C##CDC_PRIVS;
	insert into C##MYUSER.BPM_EMPLOYEES (name) values ('Jessica');
	insert into C##MYUSER.BPM_EMPLOYEES (name) values ('John');
	insert into C##MYUSER.BPM_EMPLOYEES (name) values ('Alex');
	COMMIT;
	exit;

EOF