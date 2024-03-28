FROM azul/zulu-openjdk:17 as builder

COPY ./build.gradle ./gradlew ./settings.gradle .
COPY ./gradle ./gradle
COPY ./src ./src
RUN ./gradlew assemble

FROM azul/zulu-openjdk:17 as cds-archive

RUN mkdir -p /opt/app
COPY --from=builder build/libs/*.jar /opt/app/app.jar

RUN (cd /opt/app && java -Djarmode=tools -jar app.jar extract)

RUN java -Dspring.context.exit=onRefresh -XX:ArchiveClassesAtExit=/opt/app/app/app.jsa -jar /opt/app/app/app.jar

FROM azul/zulu-openjdk:17

COPY --from=cds-archive /opt/app/app /opt/app/app

ENTRYPOINT java $JAVA_OPTS -XX:SharedArchiveFile=/opt/app/app/app.jsa -jar /opt/app/app/app.jar