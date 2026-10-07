resource "kubectl_manifest" "streamprocessor" {
  depends_on = [
    "kubernetes_deployment.kafka_service",
    "kubernetes_deployment.cassandra"
  ]

  yaml_body = <<YAML
apiVersion: "sparkoperator.k8s.io/v1beta2"
kind: SparkApplication
metadata:
  name: streamprocessor
  namespace: ${var.namespace}
spec:
  type: Scala
  mode: cluster
  image: docker.io/library/finnhub-streaming-data-pipeline-spark-k8s:latest
  imagePullPolicy: Never
  mainClass: StreamProcessor
  mainApplicationFile: "local:///usr/spark/jars/streamprocessor-assembly-1.0.jar"
  sparkVersion: "3.0.0"

  restartPolicy:
    type: OnFailure
    onFailureRetries: 3
    onFailureRetryInterval: 10
    onSubmissionFailureRetries: 3
    onSubmissionFailureRetryInterval: 10

  volumes:
    - name: spark-volume
      hostPath:
        path: /host

  driver:
    cores: 2
    memory: "1g"
    serviceAccount: spark

    labels:
      k8s.network/pipeline-network: "true"

    volumeMounts:
      - name: spark-volume
        mountPath: /host

    javaOptions: "-Dconfig.resource=deployment.conf"

    envVars:
      KAFKA_SERVER: "kafka-service.pipeline.svc.cluster.local"
      KAFKA_PORT: "9092"
      KAFKA_TOPIC_NAME: "market"
      KAFKA_MIN_PARTITIONS: "1"
      SPARK_MASTER: "spark://spark-master:7077"
      SPARK_MAX_OFFSETS_PER_TRIGGER: "100"
      SPARK_SHUFFLE_PARTITIONS: "2"
      SPARK_DEPRECATED_OFFSETS: "False"

    envSecretKeyRefs:
      CASSANDRA_USER:
        name: pipeline-secrets
        key: CASSANDRA_USER
      CASSANDRA_PASSWORD:
        name: pipeline-secrets
        key: CASSANDRA_PASSWORD

  executor:
    cores: 2
    instances: 1
    memory: "2g"

    labels:
      k8s.network/pipeline-network: "true"

    volumeMounts:
      - name: spark-volume
        mountPath: /host

    javaOptions: "-Dconfig.resource=deployment.conf"

    envVars:
      KAFKA_SERVER: "kafka-service.pipeline.svc.cluster.local"
      KAFKA_PORT: "9092"
      KAFKA_TOPIC_NAME: "market"
      KAFKA_MIN_PARTITIONS: "1"
      SPARK_MASTER: "spark://spark-master:7077"
      SPARK_MAX_OFFSETS_PER_TRIGGER: "100"
      SPARK_SHUFFLE_PARTITIONS: "2"
      SPARK_DEPRECATED_OFFSETS: "False"

    envSecretKeyRefs:
      CASSANDRA_USER:
        name: pipeline-secrets
        key: CASSANDRA_USER
      CASSANDRA_PASSWORD:
        name: pipeline-secrets
        key: CASSANDRA_PASSWORD
YAML
}