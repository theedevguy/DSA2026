import ballerinax/kafka;

kafka:ProducerConfiguration producerConfig = {
    clientId: "restaurant-service-producer",
    acks: "all",
    retryCount: 3
};

kafka:Producer restaurantProducer = check new (kafkaBootstrapUrl, producerConfig);

function publishOrderEvent(string topic, Order orderData) returns error? {
    check restaurantProducer->send({
        topic: topic,
        key: orderData.orderId.toBytes(),
        value: orderData.toJsonString().toBytes()
    });
}