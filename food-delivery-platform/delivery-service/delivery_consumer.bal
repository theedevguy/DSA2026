import ballerinax/kafka;

listener kafka:Listener ordersReadyListener = new (kafkaBootstrapUrl, {groupId: "delivery-service-orders-ready", topics: ["orders.ready"]});

service on ordersReadyListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check handleOrderReady(o);
        }
    }
}