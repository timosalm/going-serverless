FROM azul/zulu-openjdk:17-jdk as builder

COPY ./build.gradle ./gradlew ./settings.gradle .
COPY ./gradle ./gradle
COPY ./src ./src
RUN ./gradlew assemble

FROM azul/zulu-openjdk:17-jdk as cds-archive

ENV APP_JAR_FILE /opt/app/app.jar

RUN apt-get install --no-install-recommends -y unzip

RUN mkdir -p /opt/app
COPY --from=builder build/libs/*.jar $APP_JAR_FILE
COPY ./cds/cds.sh /opt/app/cds.sh
COPY ./cds/unpack-executable-jar.sh /opt/app/unpack-executable-jar.sh

ENTRYPOINT /opt/app/cds.sh -b

FROM azul/zulu-openjdk:17-jdk

COPY --from=cds-archive /opt/app/unpacked /opt/app/unpacked
COPY --from=cds-archive /opt/app/cds.sh /opt/app/cds.sh

WORKDIR /data
ENTRYPOINT ./cds.sh -s