import ballerina/http;
import ballerina/time;
import ballerina/uuid;

// ============================================================
// order_service.bal — REST API for the central order state
// machine. Publishes a Kafka event on every transition.
// ============================================================

listener http:Listener orderListener = new (8080);

function findOrders(map<json> filter) returns Order[]|error {
    stream<Order, error?> result = check ordersCollection->find(filter);
    return from Order o in result select o;
}

function nowTimestamp() returns string {
    return time:utcToString(time:utcNow());
}

service /orders on orderListener {

    // POST /orders — customer places an order
    resource function post .(@http:Payload CreateOrderRequest input) returns Order|http:BadRequest|error {
        if input.items.length() == 0 {
            return <http:BadRequest>{body: "Order must contain at least one item."};
        }

        float total = 0.0;
        foreach OrderItem item in input.items {
            total += item.price * <float>item.quantity;
        }

        string nowStr = nowTimestamp();
        Order newOrder = {
            orderId: uuid:createType4AsString(),
            customerId: input.customerId,
            restaurantId: input.restaurantId,
            items: input.items,
            totalAmount: total,
            status: "CREATED",
            driverId: "",
            createdAt: nowStr,
            updatedAt: nowStr
        };

        check ordersCollection->insertOne(newOrder);
        check publishOrderEvent("orders.created", newOrder);

        return newOrder;
    }

    // GET /orders/{id} — fetch one order
    resource function get [string id]() returns Order|http:NotFound|error {
        Order[] matches = check findOrders({orderId: id});
        if matches.length() == 0 {
            return http:NOT_FOUND;
        }
        return matches[0];
    }

    // GET /orders?customerId=&restaurantId= — filtered list
    resource function get .(string? customerId, string? restaurantId) returns Order[]|error {
        map<json> filter = {};
        if customerId is string {
            filter["customerId"] = customerId;
        }
        if restaurantId is string {
            filter["restaurantId"] = restaurantId;
        }
        return findOrders(filter);
    }

    // PUT /orders/{id}/cancel — cancel, if not already too far along
    resource function put [string id]/cancel() returns Order|http:NotFound|http:BadRequest|error {
        Order[] matches = check findOrders({orderId: id});
        if matches.length() == 0 {
            return http:NOT_FOUND;
        }
        Order existing = matches[0];

        if existing.status == "OUT_FOR_DELIVERY" || existing.status == "DELIVERED" || existing.status == "CANCELLED" {
            return <http:BadRequest>{body: string `Cannot cancel an order with status ${existing.status}.`};
        }

        string nowStr = nowTimestamp();
        _ = check ordersCollection->updateOne({orderId: id}, {set: {status: "CANCELLED", updatedAt: nowStr}});

        Order cancelledOrder = {
            orderId: existing.orderId,
            customerId: existing.customerId,
            restaurantId: existing.restaurantId,
            items: existing.items,
            totalAmount: existing.totalAmount,
            status: "CANCELLED",
            driverId: existing.driverId,
            createdAt: existing.createdAt,
            updatedAt: nowStr
        };
        check publishOrderEvent("orders.cancelled", cancelledOrder);

        return cancelledOrder;
    }
}