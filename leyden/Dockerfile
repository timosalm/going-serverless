FROM ghcr.io/timosalm/going-serverless:leyden-base as builder

COPY ./build.gradle ./gradlew ./settings.gradle .
COPY ./gradle ./gradle
COPY ./src ./src
RUN ./gradlew assemble

COPY ./leyden/unpack-executable-jar.sh ./unpack-executable-jar.sh
RUN ./unpack-executable-jar.sh -d build-unpacked build/build/libs/hello-world-0.0.1-SNAPSHOT.jar
RUN rm -rf build unpack-executable-jar.sh
RUN java -Dspring.aot.enabled=true -Dspring.context.exit=onRefresh -XX:CacheDataStore=build-unpacked/application.cds -jar build-unpacked/run-app.jar

FROM ghcr.io/timosalm/going-serverless:leyden-base


ENV APP_JAR_FILE /opt/app/

RUN mkdir -p /opt/app
COPY --from=builder build-unpacked/ $APP_JAR_FILE

CMD ["java", "-Dspring.aot.enabled=true", "-XX:CacheDataStore=$APP_JAR_FILE/application.cds", "-jar", "$APP_JAR_FILE/run-app.jar"]