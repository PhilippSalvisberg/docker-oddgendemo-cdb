#!/bin/bash

disable_http(){
	echo "Turning off DBMS_XDB HTTP port"
	echo "EXEC DBMS_XDB.SETHTTPPORT(0);" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${PDB_NAME} AS SYSDBA
}

enable_http(){
	echo "Turning on DBMS_XDB HTTP port"
	echo "EXEC DBMS_XDB.SETHTTPPORT(8084);" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${PDB_NAME} AS SYSDBA
}

apex_epg_config(){
	cd ${ORACLE_HOME}/apex
	echo "Setting up EPG for APEX by running: @apex_epg_config ${ORACLE_HOME}"
	echo "EXIT" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${PDB_NAME} AS SYSDBA @apex_epg_config ${ORACLE_HOME}
	echo "Unlock anonymous account on PDB"
	echo "ALTER USER ANONYMOUS ACCOUNT UNLOCK;" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${PDB_NAME} AS SYSDBA
	echo "Unlock anonymous account on CDB"
	echo "ALTER USER ANONYMOUS ACCOUNT UNLOCK;" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${ORACLE_SID} AS SYSDBA
}

apex_create_tablespace(){
	cd ${ORACLE_HOME}/apex
	echo "Creating APEX tablespace."
	${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${PDB_NAME} AS SYSDBA <<EOF
		CREATE TABLESPACE apex DATAFILE '${ORACLE_BASE}/oradata/${ORACLE_SID}/${PDB_NAME}/apex01.dbf' SIZE 100M AUTOEXTEND ON NEXT 10M;
EOF
}

apex_install(){	
	echo "Installing APEX..."
	echo "EXIT" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${PDB_NAME} AS SYSDBA @apexins APEX APEX TEMP /i/
	echo "Setting APEX ADMIN password."
    echo -e "\n\n${APEX_PASS}" | /opt/sqlcl/bin/sql -s -l sys/${PASS}@${PDB_NAME} as sysdba @apxchpwd.sql
}

disable_http
apex_create_tablespace
apex_install
apex_epg_config
enable_http
cd /
