import ballerinax/kafka;

kafka:ProducerConfiguration producerConfig = {
    clientId: "payment-service-producer",
    acks: "all",
    retryCount: 3
};

kafka:Producer paymentProducer = check new (kafkaBootstrapUrl, producerConfig);

function publishOrderEvent(string topic, Order orderData) returns error? {
    check paymentProducer->send({
        topic: topic,
        key: orderData.orderId.toBytes(),
        value: orderData.toJsonString().toBytes()
    });
}