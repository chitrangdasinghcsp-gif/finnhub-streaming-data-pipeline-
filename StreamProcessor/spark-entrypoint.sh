#!/bin/bash
set -e

SPARK_HOME=/usr/spark
SPARK_CLASSPATH="$SPARK_CLASSPATH:${SPARK_HOME}/jars/*"

env | grep SPARK_JAVA_OPT_ | sort -t_ -k4 -n | sed 's/[^=]*=\(.*\)/\1/g' > /tmp/java_opts.txt
readarray -t SPARK_EXECUTOR_JAVA_OPTS < /tmp/java_opts.txt

if [ -n "$SPARK_EXTRA_CLASSPATH" ]; then
    SPARK_CLASSPATH="$SPARK_CLASSPATH:$SPARK_EXTRA_CLASSPATH"
fi

case "$1" in

    driver)
        shift 1
        CMD=(
            "$SPARK_HOME/bin/spark-submit"
            --conf "spark.driver.bindAddress=$SPARK_DRIVER_BIND_ADDRESS"
            --deploy-mode client
            "$@"
        )
        ;;

    executor)
        shift 1
        CMD=(
            java
            "${SPARK_EXECUTOR_JAVA_OPTS[@]}"
            -Xms$SPARK_EXECUTOR_MEMORY
            -Xmx$SPARK_EXECUTOR_MEMORY
            -cp "$SPARK_CLASSPATH"
            org.apache.spark.executor.CoarseGrainedExecutorBackend
            --driver-url "$SPARK_DRIVER_URL"
            --executor-id "$SPARK_EXECUTOR_ID"
            --cores "$SPARK_EXECUTOR_CORES"
            --app-id "$SPARK_APPLICATION_ID"
            --hostname "$SPARK_EXECUTOR_POD_IP"
        )
        ;;

    *)
        CMD=("$@")
        ;;

esac

exec "${CMD[@]}"