FROM ghcr.io/timosalm/going-serverless:leyden-base as builder

COPY ./leyden/mvnw ./leyden/pom.xml ./
COPY ./leyden/.mvn ./.mvn
COPY ./src ./src
RUN ./mvnw package

RUN java -Djarmode=tools -jar target/hello-world-0.0.1-SNAPSHOT.jar extract --destination build-unpacked
RUN java -Dspring.aot.enabled=true -Dspring.context.exit=onRefresh -XX:CacheDataStore=build-unpacked/application.cds -jar build-unpacked/run-app.jar

FROM ghcr.io/timosalm/going-serverless:leyden-base

ENV APP_JAR_FILE /opt/app/

RUN mkdir -p /opt/app
COPY --from=builder build-unpacked/ $APP_JAR_FILE

CMD ["java", "-Dspring.aot.enabled=true", "-XX:CacheDataStore=$APP_JAR_FILE/application.cds", "-jar", "$APP_JAR_FILE/run-app.jar"]