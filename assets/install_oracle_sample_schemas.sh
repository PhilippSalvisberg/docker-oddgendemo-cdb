#!/bin/bash

cd ${ORACLE_HOME}/demo/schema
mkdir /tmp/log
echo "EXIT" | sqlplus -s -l system/${PASS}@${PDB_NAME} @mksample ${PASS} ${PASS} hr oe pm ix sh bi users temp /tmp/log/ ${PDB_NAME}
cd /
