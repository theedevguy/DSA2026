import ballerinax/kafka;

// ============================================================
// order_history_consumer.bal — Keeps a per-customer order history.
//
// Customer Service never reads the Order Service database. It
// instead projects the order lifecycle off the same Kafka topics
// every other service listens to, so a customer's history stays
// available even if Order Service is being restarted or scaled.
// ============================================================

function findOrderHistory(map<json> filter) returns Order[]|error {
    stream<Order, error?> result = check orderHistoryCollection->find(filter);
    return from Order o in result select o;
}

// Upsert semantics: the first event we see for an order inserts the
// snapshot, every later event only refreshes the mutable fields.
// That also makes the consumer safe if it joins the group late and
// never observes the original orders.created event.
function recordOrderEvent(Order incoming) returns error? {
    Order[] existing = check findOrderHistory({orderId: incoming.orderId});
    if existing.length() == 0 {
        check orderHistoryCollection->insertOne(incoming);
        return;
    }
    _ = check orderHistoryCollection->updateOne({orderId: incoming.orderId},
        {set: {status: incoming.status, driverId: incoming.driverId, updatedAt: incoming.updatedAt}});
}

listener kafka:Listener ordersCreatedListener = new (kafkaBootstrapUrl, {groupId: "customer-service-orders-created", topics: ["orders.created"]});
service on ordersCreatedListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check recordOrderEvent(o);
        }
    }
}

listener kafka:Listener ordersConfirmedListener = new (kafkaBootstrapUrl, {groupId: "customer-service-orders-confirmed", topics: ["orders.confirmed"]});
service on ordersConfirmedListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check recordOrderEvent(o);
        }
    }
}

listener kafka:Listener ordersPreparingListener = new (kafkaBootstrapUrl, {groupId: "customer-service-orders-preparing", topics: ["orders.preparing"]});
service on ordersPreparingListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check recordOrderEvent(o);
        }
    }
}

listener kafka:Listener ordersReadyListener = new (kafkaBootstrapUrl, {groupId: "customer-service-orders-ready", topics: ["orders.ready"]});
service on ordersReadyListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check recordOrderEvent(o);
        }
    }
}

listener kafka:Listener deliveryAssignedListener = new (kafkaBootstrapUrl, {groupId: "customer-service-delivery-assigned", topics: ["delivery.assigned"]});
service on deliveryAssignedListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check recordOrderEvent(o);
        }
    }
}

listener kafka:Listener deliveryCompletedListener = new (kafkaBootstrapUrl, {groupId: "customer-service-delivery-completed", topics: ["delivery.completed"]});
service on deliveryCompletedListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check recordOrderEvent(o);
        }
    }
}

listener kafka:Listener ordersDeliveredListener = new (kafkaBootstrapUrl, {groupId: "customer-service-orders-delivered", topics: ["orders.delivered"]});
service on ordersDeliveredListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check recordOrderEvent(o);
        }
    }
}

listener kafka:Listener ordersCancelledListener = new (kafkaBootstrapUrl, {groupId: "customer-service-orders-cancelled", topics: ["orders.cancelled"]});
service on ordersCancelledListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check recordOrderEvent(o);
        }
    }
}
