FROM maven:alpine AS maven_builder

WORKDIR /maven
COPY pom.xml .
RUN mvn dependency:copy-dependencies


FROM sbtscala/scala-sbt:eclipse-temurin-17.0.4_1.7.1_3.2.0 AS sbt_builder

COPY build.sbt /sbt/build.sbt
ADD src /sbt/src/
ADD project /sbt/project/

WORKDIR /sbt
RUN sbt assembly


FROM godatadriven/spark:3.0.0

WORKDIR /usr/spark/jars

COPY --from=maven_builder maven/target/dependency/ .
COPY --from=sbt_builder sbt/target/scala-2.12/streamprocessor-assembly-1.0.jar .

USER root

COPY spark-entrypoint.sh /usr/local/bin/spark-entrypoint.sh

RUN sed -i 's/\r$//' /usr/local/bin/spark-entrypoint.sh \
    && chmod +x /usr/local/bin/spark-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/spark-entrypoint.sh"]