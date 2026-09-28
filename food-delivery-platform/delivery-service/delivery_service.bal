import ballerina/http;
import ballerina/uuid;

listener http:Listener deliveryListener = new (8084);

type DriverInput record {|
    string name;
|};

type DriverStatusUpdate record {|
    string status;
|};

function completeDelivery(string orderId) returns Delivery|http:NotFound|http:BadRequest|error {
    Delivery[] matches = check findDeliveries({orderId: orderId});
    if matches.length() == 0 {
        return http:NOT_FOUND;
    }
    Delivery delivery = matches[0];
    if delivery.status != "ASSIGNED" {
        return <http:BadRequest>{body: string `Delivery is ${delivery.status}; only an ASSIGNED delivery can be completed.`};
    }

    string nowStr = nowTimestamp();
    Order snapshot = delivery.orderSnapshot;
    snapshot.status = "DELIVERED";
    snapshot.updatedAt = nowStr;

    _ = check deliveriesCollection->updateOne({deliveryId: delivery.deliveryId}, {set: {status: "COMPLETED", completedAt: nowStr, orderSnapshot: snapshot}});
    _ = check driversCollection->updateOne({driverId: delivery.driverId}, {set: {status: "AVAILABLE"}});
    delivery.status = "COMPLETED";
    delivery.completedAt = nowStr;

    check publishOrderEvent("delivery.completed", snapshot);
    check tryAssignPending();
    return delivery;
}

service /drivers on deliveryListener {

    // POST /drivers - register a driver (starts AVAILABLE)
    resource function post .(@http:Payload DriverInput input) returns Driver|error {
        Driver driver = {driverId: uuid:createType4AsString(), name: input.name, status: "AVAILABLE"};
        check driversCollection->insertOne(driver);
        check tryAssignPending();
        Driver[] fresh = check findDrivers({driverId: driver.driverId});
        return fresh[0];
    }

    // GET /drivers?status=
    resource function get .(string? status) returns Driver[]|error {
        map<json> filter = {};
        if status is string {
            filter["status"] = status;
        }
        return findDrivers(filter);
    }

    // PUT /drivers/{id}/status - go AVAILABLE or OFFLINE
    resource function put [string id]/status(@http:Payload DriverStatusUpdate input) returns Driver|http:NotFound|http:BadRequest|error {
        if input.status != "AVAILABLE" && input.status != "OFFLINE" {
            return <http:BadRequest>{body: "Status must be AVAILABLE or OFFLINE."};
        }
        Driver[] matches = check findDrivers({driverId: id});
        if matches.length() == 0 {
            return http:NOT_FOUND;
        }
        if matches[0].status == "BUSY" {
            return <http:BadRequest>{body: "Driver is on a delivery; complete it first."};
        }
        _ = check driversCollection->updateOne({driverId: id}, {set: {status: input.status}});
        check tryAssignPending();
        Driver[] fresh = check findDrivers({driverId: id});
        return fresh[0];
    }
}

service /deliveries on deliveryListener {

    // GET /deliveries?status=
    resource function get .(string? status) returns Delivery[]|error {
        map<json> filter = {};
        if status is string {
            filter["status"] = status;
        }
        return findDeliveries(filter);
    }

    // GET /deliveries/{orderId}
    resource function get [string orderId]() returns Delivery|http:NotFound|error {
        Delivery[] matches = check findDeliveries({orderId: orderId});
        if matches.length() == 0 {
            return http:NOT_FOUND;
        }
        return matches[0];
    }

    // POST /deliveries/{orderId}/complete - driver marks the drop-off done
    resource function post [string orderId]/complete() returns Delivery|http:NotFound|http:BadRequest|error {
        return completeDelivery(orderId);
    }
}