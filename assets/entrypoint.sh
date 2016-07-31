#!/bin/bash

# set environment 
. /assets/setenv.sh

# Exit script on non-zero command exit status
set -e

case "$1" in
	'')
		# default behaviour when no parameters are passed

		#Check for mounted database files
		if [ "$(ls -A ${ORACLE_BASE}/oradata)" ]; then
			echo "Found data files in ${ORACLE_BASE}/oradata, initial database does not need to be created."
			echo "odb:$ORACLE_HOME:N" >> /etc/oratab
			chown oracle:dba /etc/oratab
			chown 664 /etc/oratab
			rm -rf /u01/app/oracle-product/12.1.0.2/dbhome/dbs
			ln -s /u01/app/oracle/dbs /u01/app/oracle-product/12.1.0.2/dbhome/dbs
			#Startup Database
			gosu oracle bash -c "${ORACLE_HOME}/bin/lsnrctl start"
			gosu oracle bash -c 'echo startup\; | ${ORACLE_HOME}/bin/sqlplus -s -l / as sysdba'
		else
			echo "No data files found in ${ORACLE_BASE}/oradata, initializing database."
			mv /u01/app/oracle-product/12.1.0.2/dbhome/dbs /u01/app/oracle/dbs
			ln -s /u01/app/oracle/dbs /u01/app/oracle-product/12.1.0.2/dbhome/dbs
			gosu oracle bash -c "${ORACLE_HOME}/bin/dbca -silent -createDatabase -templateName General_Purpose.dbc \
			   -gdbname ${GDBNAME} -sid ${ORACLE_SID} -createAsContainerDatabase true -numberOfPDBs 1 -pdbName ${PDB_NAME} \
			   -responseFile NO_VALUE -characterSet AL32UTF8 -totalMemory ${DBCA_TOTAL_MEMORY} -emConfiguration DBEXPRESS \
			   -sysPassword ${PASS} -systemPassword ${PASS} -pdbAdminUserName pdbadmin -pdbAdminPassword ${PASS}"
			echo "Starting TNS Listener."
			gosu oracle bash -c 'echo -e "ALTER SYSTEM SET LOCAL_LISTENER='"'"'(ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1522))'"'"' SCOPE=BOTH;\n ALTER SYSTEM REGISTER;\n EXIT" | ${ORACLE_HOME}/bin/sqlplus -s -l / as sysdba'
			gosu oracle bash -c "${ORACLE_HOME}/bin/lsnrctl start"
			echo "Save open state of PDB."
			gosu oracle bash -c 'echo -e "ALTER PLUGGABLE DATABASE opdb1 OPEN;\n ALTER PLUGGABLE DATABASE opdb1 SAVE STATE;\n EXIT" | ${ORACLE_HOME}/bin/sqlplus -s -l / as sysdba'
			echo "removing APEX from CDB"
			gosu oracle bash -c 'cd ${ORACLE_HOME}/apex.old; echo EXIT | /opt/sqlcl/bin/sql -s -l / as sysdba @apxremov_con.sql'
			if [ $WEB_CONSOLE == "true" ]; then
				. /assets/install_apex.sh
			fi			
			echo "Database initialized."
			echo "Installing schema SCOTT."
			export TWO_TASK=opdb1
			${ORACLE_HOME}/bin/sqlplus sys/oracle@opdb1 as sysdba @${ORACLE_HOME}/rdbms/admin/utlsampl.sql
			unset TWO_TASK
			echo "Installing Oracle sample schemas."
			. /assets/install_oracle_sample_schemas.sh
			echo "Installing FTLDB."
			. /assets/install_ftldb.sh
			echo "Installing tePLSQL."
			. /assets/install_teplsql.sh
			echo "Installing oddgen examples/tutorials"
			. /assets/install_oddgen.sh
		fi
		
		if [ $WEB_CONSOLE == "true" ]; then
			gosu oracle bash -c 'echo EXEC DBMS_XDB.sethttpport\(8083\)\; | ${ORACLE_HOME}/bin/sqlplus -s -l / as sysdba'
			gosu oracle bash -c 'echo EXEC DBMS_XDB.sethttpport\(8084\)\; | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${PDB_NAME} as sysdba'
			echo "APEX and EM Database Express 12c initialized. Please visit"
			echo "   - http://localhost:8083/em (${ORACLE_SID})"
			echo "   - http://localhost:8084/em (${PDB_NAME})"
			echo "   - http://localhost:8084/apex"
		else
			echo 'Disabling APEX and EM Database Express 12c'
			gosu oracle bash -c 'echo EXEC DBMS_XDB.sethttpport\(0\)\; | ${ORACLE_HOME}/bin/sqlplus -s -l / as sysdba'
			gosu oracle bash -c 'echo EXEC DBMS_XDB.sethttpport\(0\)\; | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${PDB_NAME} as sysdba'
		fi

		# Successful installation/startup
		echo ""
		echo "Database ready to use. Enjoy! ;-)"

		# Infinite wait loop, trap interrupt/terminate signal for graceful termination
		trap "gosu oracle bash -c 'echo shutdown immediate\; | ${ORACLE_HOME}/bin/sqlplus -S / as sysdba'" INT TERM
		while true; do sleep 1; done
		;;

	*)
		# use parameters 
		
		echo ""
		echo "Overridden default behaviour. Run /assets/entrypoint.sh when ready."	
		$@
		;;
esac
