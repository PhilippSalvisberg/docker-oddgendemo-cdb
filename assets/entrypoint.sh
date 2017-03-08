#!/bin/bash

# set environment 
. /assets/setenv.sh

# Exit script on non-zero command exit status
set -e

case "$1" in
	'')
		# default behaviour when no parameters are passed to the container

		# Startup database if oradata directory is found otherwise create a database
		if [ -d ${ORACLE_BASE}/oradata ]; then
			echo "Reuse existing database."
			echo "ocdb:$ORACLE_HOME:N" >> /etc/oratab
			chown oracle:dba /etc/oratab
			chmod 664 /etc/oratab
			rm -rf /u01/app/oracle-product/12.2.0.1/dbhome/dbs
			ln -s /u01/app/oracle/dbs /u01/app/oracle-product/12.2.0.1/dbhome/dbs
			gosu oracle bash -c "${ORACLE_HOME}/bin/lsnrctl start"
			gosu oracle bash -c 'echo startup\; | ${ORACLE_HOME}/bin/sqlplus -s -l / as sysdba'
		else
			echo "Creating database."
			mv /u01/app/oracle-product/12.2.0.1/dbhome/dbs /u01/app/oracle/dbs
			ln -s /u01/app/oracle/dbs /u01/app/oracle-product/12.2.0.1/dbhome/dbs
			gosu oracle bash -c "${ORACLE_HOME}/bin/lsnrctl start"
			gosu oracle bash -c "${ORACLE_HOME}/bin/dbca -silent -createDatabase -templateName General_Purpose.dbc \
			   -gdbname ${GDBNAME} -sid ${ORACLE_SID} -createAsContainerDatabase true -numberOfPDBs 1 -pdbName ${PDB_NAME} \
			   -responseFile NO_VALUE -characterSet AL32UTF8 -totalMemory ${DBCA_TOTAL_MEMORY} -emConfiguration DBEXPRESS \
			   -sysPassword ${PASS} -systemPassword ${PASS} -pdbAdminUserName pdbadmin -pdbAdminPassword ${PASS}"
			echo "Change listener port."
			gosu oracle bash -c 'echo -e "ALTER SYSTEM SET LOCAL_LISTENER='"'"'(ADDRESS = (PROTOCOL = TCP)(HOST = $(hostname))(PORT = 1522))'"'"' SCOPE=BOTH;\n ALTER SYSTEM REGISTER;\n EXIT" | ${ORACLE_HOME}/bin/sqlplus -s -l / as sysdba'
			echo "Save open state of PDB."
			gosu oracle bash -c 'echo -e "ALTER PLUGGABLE DATABASE opdb1 OPEN;\n ALTER PLUGGABLE DATABASE opdb1 SAVE STATE;\n EXIT" | ${ORACLE_HOME}/bin/sqlplus -s -l / as sysdba'
			echo "Remove APEX from CDB"
			gosu oracle bash -c 'cd ${ORACLE_HOME}/apex.old; echo EXIT | /opt/sqlcl/bin/sql -s -l / as sysdba @apxremov_con.sql'
			if [ $WEB_CONSOLE == "true" ]; then
				gosu oracle bash -c 'echo EXEC DBMS_XDB_CONFIG.setglobalportenabled\(true\)\; | ${ORACLE_HOME}/bin/sqlplus -s -l / as sysdba'
				gosu oracle bash -c 'echo EXEC DBMS_XDB.sethttpport\(8083\)\; | ${ORACLE_HOME}/bin/sqlplus -s -l / as sysdba'
				. /assets/install_apex.sh
			else
				gosu oracle bash -c 'echo EXEC DBMS_XDB.sethttpport\(0\)\; | ${ORACLE_HOME}/bin/sqlplus -s -l / as sysdba'
				gosu oracle bash -c 'echo EXEC DBMS_XDB.sethttpport\(0\)\; | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@${PDB_NAME} as sysdba'
			fi
			echo "Installing schema SCOTT."
			export TWO_TASK=opdb1
			${ORACLE_HOME}/bin/sqlplus sys/${PASS}@opdb1 as sysdba @${ORACLE_HOME}/rdbms/admin/utlsampl.sql
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
		
		# Successful installation/startup
		echo ""
		echo "Database ready to use. Enjoy! ;-)"

		# Infinite wait loop, trap interrupt/terminate signal for graceful termination
		trap "gosu oracle bash -c 'echo shutdown immediate\; | ${ORACLE_HOME}/bin/sqlplus -S / as sysdba'" INT TERM
		while true; do sleep 1; done
		;;

	*)
		# use parameters passed to the container
		
		echo ""
		echo "Overridden default behaviour. Run /assets/entrypoint.sh when ready."	
		$@
		;;
esac
