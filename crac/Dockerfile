FROM azul/zulu-openjdk:21-jdk-crac as builder

COPY ./build.gradle ./gradlew ./settings.gradle .
COPY ./gradle ./gradle
COPY ./src ./src
RUN ./gradlew assemble

FROM azul/zulu-openjdk:21-jdk-crac

RUN apt-get update && apt-get install -y \
         siege

ENV CRAC_FILES_DIR /opt/crac-files
ENV APP_JAR_FILE /opt/app/app.jar

RUN mkdir -p /opt/app
COPY --from=builder build/libs/*.jar $APP_JAR_FILE
COPY ./crac/entrypoint.sh /opt/app/entrypoint.sh

ENTRYPOINT /opt/app/entrypoint.sh