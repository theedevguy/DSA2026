import ballerina/http;
import ballerina/time;

function findKitchenOrders(map<json> filter) returns Order[]|error {
    stream<Order, error?> result = check kitchenOrdersCollection->find(filter);
    return from Order o in result select o;
}

// Moves a kitchen order to a new status (only from an allowed current status)
// and publishes the matching event with the full order.
function setKitchenStatus(string restaurantId, string orderId, string newStatus, string[] allowedFrom) returns Order|http:NotFound|http:BadRequest|error {
    Order[] matches = check findKitchenOrders({orderId: orderId, restaurantId: restaurantId});
    if matches.length() == 0 {
        return http:NOT_FOUND;
    }
    Order existing = matches[0];
    if allowedFrom.indexOf(existing.status) is () {
        return <http:BadRequest>{body: string `Order is ${existing.status}; cannot move to ${newStatus}.`};
    }

    string nowStr = time:utcToString(time:utcNow());
    _ = check kitchenOrdersCollection->updateOne({orderId: orderId}, {set: {status: newStatus, updatedAt: nowStr}});
    existing.status = newStatus;
    existing.updatedAt = nowStr;

    string topic = newStatus == "PREPARING" ? "orders.preparing" : "orders.ready";
    check publishOrderEvent(topic, existing);
    return existing;
}

service /kitchen on restaurantListener {

    // GET /kitchen/{restaurantId}/orders?status= - this restaurant's kitchen queue
    resource function get [string restaurantId]/orders(string? status) returns Order[]|error {
        map<json> filter = {restaurantId: restaurantId};
        if status is string {
            filter["status"] = status;
        }
        return findKitchenOrders(filter);
    }

    // POST /kitchen/{restaurantId}/orders/{orderId}/prepare - start cooking
    resource function post [string restaurantId]/orders/[string orderId]/prepare() returns Order|http:NotFound|http:BadRequest|error {
        return setKitchenStatus(restaurantId, orderId, "PREPARING", ["CONFIRMED"]);
    }

    // POST /kitchen/{restaurantId}/orders/{orderId}/ready - food is ready for pickup
    resource function post [string restaurantId]/orders/[string orderId]/ready() returns Order|http:NotFound|http:BadRequest|error {
        return setKitchenStatus(restaurantId, orderId, "READY", ["PREPARING"]);
    }
}