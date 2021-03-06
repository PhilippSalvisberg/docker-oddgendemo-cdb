#!/bin/bash

# ignore secure linux
setenforce Permissive

# Prevent owner issues on mounted folders
chown -R oracle:dba /u01/app/oracle
rm -f /u01/app/oracle/product
ln -s /u01/app/oracle-product /u01/app/oracle/product

# Set environment variables
. ~/.bashrc

# Create tnsnames.ora
if [ -f "${ORACLE_HOME}/network/admin/tnsnames.ora" ]
then
	echo "tnsnames.ora found."
else
	echo "Creating tnsnames.ora" 
	printf "${ORACLE_SID} =\n\
	(DESCRIPTION =\n\
	 (ADDRESS = (PROTOCOL = TCP)(HOST = $(hostname))(PORT = 1522))\n\
	 (CONNECT_DATA = (SERVICE_NAME = ${GDBNAME})))\n" > ${ORACLE_HOME}/network/admin/tnsnames.ora
	printf "${PDB_NAME} =\n\
	(DESCRIPTION =\n\
	 (ADDRESS = (PROTOCOL = TCP)(HOST = $(hostname))(PORT = 1522))\n\
	 (CONNECT_DATA = (SERVICE_NAME = ${SERVICE_NAME})))\n" >> ${ORACLE_HOME}/network/admin/tnsnames.ora
fi

# Create listener.ora
if [ -f "${ORACLE_HOME}/network/admin/listener.ora" ]
then
	echo "listener.ora found."
else
	echo "Creating listener.ora.ora" 
	printf "LISTENER =\n\
    (DESCRIPTION_LIST =\n\
      (DESCRIPTION =\n\
        (ADDRESS = (PROTOCOL = TCP)(HOST = $(hostname))(PORT = 1522))\n\
        (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1522))\n\
      )\n\
    )\n\
USE_SID_AS_SERVICE_LISTENER=ON\n" > ${ORACLE_HOME}/network/admin/listener.ora
fi

# fix ownership and access rights
chown oracle:dba ${ORACLE_HOME}/network/admin/tnsnames.ora
chmod 664 ${ORACLE_HOME}/network/admin/tnsnames.ora
chown oracle:dba ${ORACLE_HOME}/network/admin/listener.ora
chmod 664 ${ORACLE_HOME}/network/admin/listener.ora
