#!/bin/bash

cd /opt/ftldb*
/bin/bash dba_install.sh ${PDB_NAME} sys ${PASS} ftldb ftldb
/bin/bash dba_switch_java_permissions.sh ${PDB_NAME} sys ${PASS} grant public
/bin/bash dba_switch_plsql_privileges.sh ${PDB_NAME} sys ${PASS} ftldb grant public
