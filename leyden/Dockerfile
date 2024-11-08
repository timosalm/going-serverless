FROM debian:latest

ENV JDK_URL=https://download.java.net/java/early_access/leyden/2/openjdk-24-leyden+2-8_linux-x64_bin.tar.gz
ENV JAVA_HOME=/opt/java/openjdk
ENV PATH="$JAVA_HOME/bin:$PATH"

RUN apt-get update && apt-get install -y wget tar && rm -rf /var/lib/apt/lists/*

RUN mkdir -p "$JAVA_HOME" && wget -qO- "$JDK_URL" | tar -xz --strip-components=1 -C "$JAVA_HOME"

RUN mkdir -p build
COPY build.gradle gradlew settings.gradle build/
COPY gradle build/gradle
COPY ./src build/src
RUN (cd build && gradlew assemble)

COPY ./leyden/unpack-executable-jar.sh ./unpack-executable-jar.sh
RUN ./unpack-executable-jar.sh -d build-unpacked build/build/libs/hello-world-0.0.1-SNAPSHOT.jar
RUN rm -rf build unpack-executable-jar.sh
RUN java -Dspring.aot.enabled=true -Dspring.context.exit=onRefresh -XX:CacheDataStore=build-unpacked/application.cds -jar build-unpacked/run-app.jar

CMD ["java", "-Dspring.aot.enabled=true", "-XX:CacheDataStore=build-unpacked/application.cds", "-jar", "build-unpacked/run-app.jar"]
