// ============================================================
// order_event_handlers.bal — What happens when each upstream
// event arrives. Each handler re-fetches the order by orderId
// from our own database rather than trusting the incoming
// snapshot wholesale (see design note in chat).
// ============================================================

function handlePaymentCompleted(Order incoming) returns error? {
    Order[] matches = check findOrders({orderId: incoming.orderId});
    if matches.length() == 0 {
        return;
    }
    string nowStr = nowTimestamp();
    _ = check ordersCollection->updateOne({orderId: incoming.orderId}, {set: {status: "CONFIRMED", updatedAt: nowStr}});

    Order updated = matches[0];
    updated.status = "CONFIRMED";
    updated.updatedAt = nowStr;
    check publishOrderEvent("orders.confirmed", updated);
}

function handlePaymentFailed(Order incoming) returns error? {
    Order[] matches = check findOrders({orderId: incoming.orderId});
    if matches.length() == 0 {
        return;
    }
    string nowStr = nowTimestamp();
    _ = check ordersCollection->updateOne({orderId: incoming.orderId}, {set: {status: "CANCELLED", updatedAt: nowStr}});

    Order updated = matches[0];
    updated.status = "CANCELLED";
    updated.updatedAt = nowStr;
    check publishOrderEvent("orders.cancelled", updated);
}

function handleOrderPreparing(Order incoming) returns error? {
    Order[] matches = check findOrders({orderId: incoming.orderId});
    if matches.length() == 0 {
        return;
    }
    string nowStr = nowTimestamp();
    _ = check ordersCollection->updateOne({orderId: incoming.orderId}, {set: {status: "PREPARING", updatedAt: nowStr}});
}

function handleOrderReady(Order incoming) returns error? {
    Order[] matches = check findOrders({orderId: incoming.orderId});
    if matches.length() == 0 {
        return;
    }
    string nowStr = nowTimestamp();
    _ = check ordersCollection->updateOne({orderId: incoming.orderId}, {set: {status: "READY", updatedAt: nowStr}});
}

function handleDeliveryAssigned(Order incoming) returns error? {
    Order[] matches = check findOrders({orderId: incoming.orderId});
    if matches.length() == 0 {
        return;
    }
    string nowStr = nowTimestamp();
    _ = check ordersCollection->updateOne({orderId: incoming.orderId}, {set: {status: "OUT_FOR_DELIVERY", driverId: incoming.driverId, updatedAt: nowStr}});
}

function handleDeliveryCompleted(Order incoming) returns error? {
    Order[] matches = check findOrders({orderId: incoming.orderId});
    if matches.length() == 0 {
        return;
    }
    string nowStr = nowTimestamp();
    _ = check ordersCollection->updateOne({orderId: incoming.orderId}, {set: {status: "DELIVERED", updatedAt: nowStr}});

    Order updated = matches[0];
    updated.status = "DELIVERED";
    updated.updatedAt = nowStr;
    check publishOrderEvent("orders.delivered", updated);
}