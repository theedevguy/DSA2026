import ballerina/time;
import ballerina/uuid;

function notificationMessage(string eventType, Order o) returns string {
    match eventType {
        "orders.created" => { return string `Order ${o.orderId} placed, total ${o.totalAmount}.`; }
        "orders.confirmed" => { return string `Order ${o.orderId} confirmed - payment received.`; }
        "orders.cancelled" => { return string `Order ${o.orderId} was cancelled.`; }
        "orders.preparing" => { return string `Restaurant is preparing order ${o.orderId}.`; }
        "orders.ready" => { return string `Order ${o.orderId} is ready for pickup.`; }
        "delivery.assigned" => { return string `A driver has been assigned to order ${o.orderId}.`; }
        "delivery.completed" => { return string `Order ${o.orderId} has been delivered.`; }
        "orders.delivered" => { return string `Order ${o.orderId} delivery confirmed.`; }
        _ => { return string `Update for order ${o.orderId}.`; }
    }
}

function notificationChannel(string eventType) returns string {
    match eventType {
        "orders.created"|"orders.confirmed"|"orders.cancelled" => { return "EMAIL"; }
        "delivery.assigned"|"delivery.completed"|"orders.delivered" => { return "SMS"; }
        _ => { return "PUSH"; }
    }
}

function insertNotification(string userId, string eventType, string message, string channel, string nowStr) returns error? {
    Notification notif = {
        notificationId: uuid:createType4AsString(),
        userId: userId,
        eventType: eventType,
        message: message,
        channel: channel,
        createdAt: nowStr
    };
    check notificationsCollection->insertOne(notif);
}

function handleNotificationEvent(string eventType, Order incoming) returns error? {
    string message = notificationMessage(eventType, incoming);
    string channel = notificationChannel(eventType);
    string nowStr = time:utcToString(time:utcNow());

    check insertNotification(incoming.customerId, eventType, message, channel, nowStr);

    if eventType == "orders.created" || eventType == "orders.confirmed" || eventType == "orders.cancelled" {
        check insertNotification(incoming.restaurantId, eventType, message, channel, nowStr);
    }
    if eventType == "delivery.assigned" && incoming.driverId != "" {
        check insertNotification(incoming.driverId, eventType, message, channel, nowStr);
    }
}