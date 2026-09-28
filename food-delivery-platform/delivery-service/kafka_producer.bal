import ballerinax/kafka;

kafka:ProducerConfiguration producerConfig = {
    clientId: "delivery-service-producer",
    acks: "all",
    retryCount: 3
};

kafka:Producer deliveryProducer = check new (kafkaBootstrapUrl, producerConfig);

function publishOrderEvent(string topic, Order orderData) returns error? {
    check deliveryProducer->send({
        topic: topic,
        key: orderData.orderId.toBytes(),
        value: orderData.toJsonString().toBytes()
    });
}