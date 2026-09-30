import ballerinax/mongodb;

// ============================================================
// config.bal — Configurable connection settings + MongoDB setup.
// ============================================================

configurable string mongoConnectionUrl = "mongodb://localhost:27017";
configurable string kafkaBootstrapUrl = "localhost:9092";

mongodb:Client mongoClient = check new ({
    connection: mongoConnectionUrl
});

mongodb:Database customerDb = check getCustomerDatabase();
mongodb:Collection customersCollection = check getCollection(customerDb, "customers");
mongodb:Collection addressesCollection = check getCollection(customerDb, "addresses");

// Projection of the order lifecycle, maintained from Kafka rather
// than by reading the Order Service database.
mongodb:Collection orderHistoryCollection = check getCollection(customerDb, "order_history");

function getCustomerDatabase() returns mongodb:Database|error {
    return mongoClient->getDatabase("customer_db");
}

function getCollection(mongodb:Database db, string name) returns mongodb:Collection|error {
    return db->getCollection(name);
}
