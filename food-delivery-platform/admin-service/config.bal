import ballerina/http;
import ballerinax/mongodb;

// ============================================================
// config.bal — Admin Service wiring.
//
// Unlike the transactional services, Admin does not subscribe to
// Kafka. It reads each service's public REST API so that no
// service has to expose its database to a reporting tool, and it
// stores the reports it produces in its own database.
// ============================================================

configurable string mongoConnectionUrl = "mongodb://localhost:27017";

// Peer service base URLs. Inside Docker Compose these resolve to
// the service names; running locally they use the dev ports.
configurable string orderServiceUrl = "http://localhost:8080";
configurable string paymentServiceUrl = "http://localhost:8082";
configurable string restaurantServiceUrl = "http://localhost:8083";
configurable string deliveryServiceUrl = "http://localhost:8084";

mongodb:Client mongoClient = check new ({
    connection: mongoConnectionUrl
});

mongodb:Database adminDb = check getAdminDatabase();
mongodb:Collection reportsCollection = check getCollection(adminDb, "reports");

function getAdminDatabase() returns mongodb:Database|error {
    return mongoClient->getDatabase("admin_db");
}

function getCollection(mongodb:Database db, string name) returns mongodb:Collection|error {
    return db->getCollection(name);
}

final http:Client orderClient = check new (orderServiceUrl);
final http:Client paymentClient = check new (paymentServiceUrl);
final http:Client restaurantClient = check new (restaurantServiceUrl);
final http:Client deliveryClient = check new (deliveryServiceUrl);

function fetchOrders() returns Order[]|error {
    return check orderClient->get("/orders");
}

function fetchRestaurants() returns Restaurant[]|error {
    return check restaurantClient->get("/restaurants");
}

function fetchDrivers() returns Driver[]|error {
    return check deliveryClient->get("/drivers");
}

function fetchDeliveries() returns Delivery[]|error {
    return check deliveryClient->get("/deliveries");
}

function fetchPayments() returns Payment[]|error {
    return check paymentClient->get("/payments");
}
