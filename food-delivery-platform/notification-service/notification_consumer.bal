import ballerinax/kafka;

listener kafka:Listener ordersCreatedListener = new (kafkaBootstrapUrl, {groupId: "notification-service-orders-created", topics: ["orders.created"]});
service on ordersCreatedListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check handleNotificationEvent("orders.created", o);
        }
    }
}

listener kafka:Listener ordersConfirmedListener = new (kafkaBootstrapUrl, {groupId: "notification-service-orders-confirmed", topics: ["orders.confirmed"]});
service on ordersConfirmedListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check handleNotificationEvent("orders.confirmed", o);
        }
    }
}

listener kafka:Listener ordersCancelledListener = new (kafkaBootstrapUrl, {groupId: "notification-service-orders-cancelled", topics: ["orders.cancelled"]});
service on ordersCancelledListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check handleNotificationEvent("orders.cancelled", o);
        }
    }
}

listener kafka:Listener ordersPreparingListener = new (kafkaBootstrapUrl, {groupId: "notification-service-orders-preparing", topics: ["orders.preparing"]});
service on ordersPreparingListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check handleNotificationEvent("orders.preparing", o);
        }
    }
}

listener kafka:Listener ordersReadyListener = new (kafkaBootstrapUrl, {groupId: "notification-service-orders-ready", topics: ["orders.ready"]});
service on ordersReadyListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check handleNotificationEvent("orders.ready", o);
        }
    }
}

listener kafka:Listener deliveryAssignedListener = new (kafkaBootstrapUrl, {groupId: "notification-service-delivery-assigned", topics: ["delivery.assigned"]});
service on deliveryAssignedListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check handleNotificationEvent("delivery.assigned", o);
        }
    }
}

listener kafka:Listener deliveryCompletedListener = new (kafkaBootstrapUrl, {groupId: "notification-service-delivery-completed", topics: ["delivery.completed"]});
service on deliveryCompletedListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check handleNotificationEvent("delivery.completed", o);
        }
    }
}

listener kafka:Listener ordersDeliveredListener = new (kafkaBootstrapUrl, {groupId: "notification-service-orders-delivered", topics: ["orders.delivered"]});
service on ordersDeliveredListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check handleNotificationEvent("orders.delivered", o);
        }
    }
}