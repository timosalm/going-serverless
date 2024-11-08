FROM ubuntu:focal

COPY ./leyden/setup.sh /setup.sh
RUN ./setup.sh

FROM ubuntu:focal
RUN mkdir -p /opt/leyden/test/hotspot/jtreg/premain
COPY --from=0 /opt/jdk /opt/jdk

ENV JAVA_HOME /opt/jdk
ENV PATH $JAVA_HOME/bin:$PATH

RUN mkdir -p build
COPY build.gradle gradlew settings.gradle build/
COPY gradle build/gradle
COPY ./src build/src
RUN (cd build && ./gradlew assemble)

COPY ./leyden/unpack-executable-jar.sh ./unpack-executable-jar.sh
RUN ./unpack-executable-jar.sh -d build-unpacked build/build/libs/hello-world-0.0.1-SNAPSHOT.jar
RUN rm -rf build unpack-executable-jar.sh
RUN java -Dspring.aot.enabled=true -Dspring.context.exit=onRefresh -XX:CacheDataStore=build-unpacked/application.cds -jar build-unpacked/run-app.jar

CMD ["java", "-Dspring.aot.enabled=true", "-XX:CacheDataStore=build-unpacked/application.cds", "-jar", "build-unpacked/run-app.jar"]