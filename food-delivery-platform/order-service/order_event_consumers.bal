import ballerinax/kafka;

// ============================================================
// order_event_consumers.bal — One Kafka listener per topic
// Order Service reacts to.
// ============================================================

listener kafka:Listener paymentsCompletedListener = new (kafkaBootstrapUrl, {groupId: "order-service-payments-completed", topics: ["payments.completed"]});
service on paymentsCompletedListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check handlePaymentCompleted(o);
        }
    }
}

listener kafka:Listener paymentsFailedListener = new (kafkaBootstrapUrl, {groupId: "order-service-payments-failed", topics: ["payments.failed"]});
service on paymentsFailedListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check handlePaymentFailed(o);
        }
    }
}

listener kafka:Listener ordersPreparingListener = new (kafkaBootstrapUrl, {groupId: "order-service-orders-preparing", topics: ["orders.preparing"]});
service on ordersPreparingListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check handleOrderPreparing(o);
        }
    }
}

listener kafka:Listener ordersReadyListener = new (kafkaBootstrapUrl, {groupId: "order-service-orders-ready", topics: ["orders.ready"]});
service on ordersReadyListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check handleOrderReady(o);
        }
    }
}

listener kafka:Listener deliveryAssignedListener = new (kafkaBootstrapUrl, {groupId: "order-service-delivery-assigned", topics: ["delivery.assigned"]});
service on deliveryAssignedListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check handleDeliveryAssigned(o);
        }
    }
}

listener kafka:Listener deliveryCompletedListener = new (kafkaBootstrapUrl, {groupId: "order-service-delivery-completed", topics: ["delivery.completed"]});
service on deliveryCompletedListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check handleDeliveryCompleted(o);
        }
    }
}