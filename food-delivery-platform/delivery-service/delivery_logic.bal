import ballerina/time;
import ballerina/uuid;

function nowTimestamp() returns string {
    return time:utcToString(time:utcNow());
}

function findDrivers(map<json> filter) returns Driver[]|error {
    stream<Driver, error?> result = check driversCollection->find(filter);
    return from Driver d in result select d;
}

function findDeliveries(map<json> filter) returns Delivery[]|error {
    stream<Delivery, error?> result = check deliveriesCollection->find(filter);
    return from Delivery d in result select d;
}

// Gives a waiting delivery to a free driver and announces it.
function assignDriver(Delivery delivery, Driver driver) returns error? {
    string nowStr = nowTimestamp();
    _ = check driversCollection->updateOne({driverId: driver.driverId}, {set: {status: "BUSY"}});

    Order snapshot = delivery.orderSnapshot;
    snapshot.driverId = driver.driverId;
    snapshot.status = "OUT_FOR_DELIVERY";
    snapshot.updatedAt = nowStr;

    _ = check deliveriesCollection->updateOne({deliveryId: delivery.deliveryId}, {set: {driverId: driver.driverId, status: "ASSIGNED", assignedAt: nowStr, orderSnapshot: snapshot}});
    check publishOrderEvent("delivery.assigned", snapshot);
}

// Matches waiting deliveries with free drivers, in stored order.
function tryAssignPending() returns error? {
    Delivery[] pending = check findDeliveries({status: "PENDING"});
    Driver[] free = check findDrivers({status: "AVAILABLE"});
    int n = pending.length() < free.length() ? pending.length() : free.length();
    foreach int i in 0 ..< n {
        check assignDriver(pending[i], free[i]);
    }
}

function handleOrderReady(Order incoming) returns error? {
    // Idempotency guard: a redelivered event must not create a second delivery
    Delivery[] existing = check findDeliveries({orderId: incoming.orderId});
    if existing.length() > 0 {
        return;
    }
    Delivery delivery = {
        deliveryId: uuid:createType4AsString(),
        orderId: incoming.orderId,
        driverId: "",
        status: "PENDING",
        assignedAt: "",
        completedAt: "",
        orderSnapshot: incoming
    };
    check deliveriesCollection->insertOne(delivery);
    check tryAssignPending();
}
