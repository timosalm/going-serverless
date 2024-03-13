#!/bin/bash
set -x

CRAC_FILES_DIR=`eval echo ${CRAC_FILES_DIR}`

mkdir -p $CRAC_FILES_DIR

if [ -z "$(ls -A $CRAC_FILES_DIR)" ]; then
  ( echo 128 > /proc/sys/kernel/ns_last_pid ) 2>/dev/null || while [ $(cat /proc/sys/kernel/ns_last_pid) -lt 128 ]; do :; done
  java -Dmanagement.endpoint.health.probes.add-additional-paths="true" -Dmanagement.health.probes.enabled="true" -XX:CRaCCheckpointTo=$CRAC_FILES_DIR -jar  /application/app.jar&
  sleep 60
  jcmd /application/app.jar JDK.checkpoint
  sleep 60
else
  java -Dmanagement.endpoint.health.probes.add-additional-paths="true" -Dmanagement.health.probes.enabled="true" -XX:CRaCRestoreFrom=$CRAC_FILES_DIR&
  PID=$!
  trap "kill $PID" SIGINT SIGTERM
  wait $PID
fi