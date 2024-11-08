FROM ubuntu:focal

COPY ./leyden/setup.sh /setup.sh
RUN ./setup.sh

FROM ubuntu:focal
RUN mkdir -p /opt/leyden/test/hotspot/jtreg/premain
COPY --from=0 /opt/jdk /opt/jdk

ENV JAVA_HOME /opt/jdk
ENV PATH $JAVA_HOME/bin:$PATH

RUN java --version