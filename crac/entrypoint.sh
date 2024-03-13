#!/bin/bash
set -x

if [ -z "$(ls -A $CRAC_FILES_DIR)" ]; then
  ( echo 128 > /proc/sys/kernel/ns_last_pid ) 2>/dev/null || while [ $(cat /proc/sys/kernel/ns_last_pid) -lt 128 ]; do :; done
  java -XX:CRaCCheckpointTo=$CRAC_FILES_DIR -jar  $APP_JAR_FILE&
  sleep 30

  siege -c 1 -r 10 -b http://localhost:8080/api/v1/emojis

  jcmd $APP_JAR_FILE JDK.checkpoint

  sleep 30

  if ([ -f $CRAC_FILES_DIR/dump4.log ]) && (grep -Fq "Dumping finished successfully" "$CRAC_FILES_DIR/dump4.log")
  then
    echo Checkpoint creation succeeded
  else
    echo Checkpoint creation failed
  fi
else
  java -XX:CRaCRestoreFrom=$CRAC_FILES_DIR
fi