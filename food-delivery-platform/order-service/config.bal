import ballerinax/mongodb;

// ============================================================
// config.bal — Configurable connection settings + MongoDB setup.
// ============================================================

configurable string mongoConnectionUrl = "mongodb://localhost:27017";
configurable string kafkaBootstrapUrl = "localhost:9092";

mongodb:Client mongoClient = check new ({
    connection: mongoConnectionUrl
});

mongodb:Database orderDb = check getOrderDatabase();
mongodb:Collection ordersCollection = check getOrdersCollection(orderDb);

function getOrderDatabase() returns mongodb:Database|error {
    return mongoClient->getDatabase("order_db");
}

function getOrdersCollection(mongodb:Database db) returns mongodb:Collection|error {
    return db->getCollection("orders");
}