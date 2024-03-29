#!/bin/bash
set -x

CRAC_FILES_DIR=`eval echo ${CRAC_FILES_DIR}`
mkdir -p $CRAC_FILES_DIR

if [ -z "$(ls -A $CRAC_FILES_DIR)" ]; then
  ( echo 128 > /proc/sys/kernel/ns_last_pid ) 2>/dev/null || while [ $(cat /proc/sys/kernel/ns_last_pid) -lt 128 ]; do :; done
  java -XX:CRaCCheckpointTo=$CRAC_FILES_DIR -jar  $APP_JAR_FILE&
  sleep 30

  siege -c 1 -r 10 -b http://localhost:8080

  jcmd $APP_JAR_FILE JDK.checkpoint

  sleep 30

  if ([ -f $CRAC_FILES_DIR/dump4.log ]) && (grep -Fq "Dumping finished successfully" "$CRAC_FILES_DIR/dump4.log")
  then
    echo Checkpoint creation succeeded
    sleep infinity
  else
    echo Checkpoint creation failed
  fi
else
  java -XX:CRaCRestoreFrom=$CRAC_FILES_DIR -XX:+UnlockExperimentalVMOptions -XX:+IgnoreCPUFeatures
fi