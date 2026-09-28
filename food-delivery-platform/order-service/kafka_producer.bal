import ballerinax/kafka;

// ============================================================
// kafka_producer.bal — Publishes Order events to Kafka.
// Every event carries the FULL current Order object as its
// value (JSON-encoded), keyed by orderId so all events for the
// same order land on the same partition and process in order.
// ============================================================

kafka:ProducerConfiguration producerConfig = {
    clientId: "order-service-producer",
    acks: "all",
    retryCount: 3
};

kafka:Producer orderProducer = check new (kafkaBootstrapUrl, producerConfig);

function publishOrderEvent(string topic, Order orderData) returns error? {
    check orderProducer->send({
        topic: topic,
        key: orderData.orderId.toBytes(),
        value: orderData.toJsonString().toBytes()
    });
}