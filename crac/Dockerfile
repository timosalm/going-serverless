FROM ubuntu:22.04 AS builder
WORKDIR application

USER root

# Add required libraries
RUN apt-get update && apt-get install -y \
        curl \
        jq \
        libnl-3-200 \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /azul-crac-jdk

RUN mkdir $JAVA_HOME \
  && curl https://cdn.azul.com/zulu/bin/zulu17.42.21-ca-crac-jdk17.0.7-linux_x64.tar.gz | tar -xz --strip-components 1 -C $JAVA_HOME

COPY ./mvnw ./mvnw.cmd ./pom.xml .
COPY ./.mvn ./.mvn
COPY ./src ./src
RUN ./mvnw package

FROM ubuntu:22.04

WORKDIR application
COPY --from=builder application/target/*.jar ./app.jar

COPY ./entrypoint.sh .

USER root

ENV JAVA_HOME /azul-crac-jdk
ENV PATH $PATH:$JAVA_HOME/bin

# Add required libraries
RUN apt-get update && apt-get install -y \
        libnl-3-200 \
    && rm -rf /var/lib/apt/lists/*

# Copy CRaC JDK from the checkpoint image (to save a download)
COPY --from=builder $JAVA_HOME $JAVA_HOME



# Copy layers
ENTRYPOINT ["/application/entrypoint.sh"]