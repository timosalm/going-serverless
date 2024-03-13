#!/usr/bin/env bash
set -e

# Source: https://github.com/sdeleuze/spring-cds-demo

# Build the application, generate the AppCDS cache, and start it with AppCDS optimization
# Use -b to only perform the build steps
# Use -s to only start the application

# Change JAVA_OPTS to "" to not use Spring AOT optimizations
# JAVA_OPTS="-Dspring.aot.enabled=true"

APP_DIR=$(echo "${APP_JAR_FILE%/*}")
UNPACKED_DIR=$APP_DIR/unpacked

if [[ $1 != "-s" ]]; then

  # Unpack the Spring Boot executable JAR in a way suitable for optimal performances with AppCDS
  eval ".$APP_DIR/unpack-executable-jar.sh -d $UNPACKED_DIR $APP_JAR_FILE"

  # AppCDS training run
  java -Dspring.context.exit=onRefresh -XX:ArchiveClassesAtExit=$UNPACKED_DIR/application.jsa -jar $UNPACKED_DIR/run-app.jar
fi

if [[ $1 != "-b" ]]; then
  # CDS optimized run
  java $JAVA_OPTS -XX:SharedArchiveFile=$UNPACKED_DIR/application.jsa -jar $UNPACKED_DIR/run-app.jar
fi