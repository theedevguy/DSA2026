import ballerinax/mongodb;

configurable string mongoConnectionUrl = "mongodb://localhost:27017";
configurable string kafkaBootstrapUrl = "localhost:9092";

// Chance (0.0 to 1.0) that a simulated payment fails, so the CANCELLED path is actually reachable
configurable float paymentFailureRate = 0.2;

mongodb:Client mongoClient = check new ({
    connection: mongoConnectionUrl
});

mongodb:Database paymentDb = check getPaymentDatabase();
mongodb:Collection paymentsCollection = check getPaymentsCollection(paymentDb);

function getPaymentDatabase() returns mongodb:Database|error {
    return mongoClient->getDatabase("payment_db");
}

function getPaymentsCollection(mongodb:Database db) returns mongodb:Collection|error {
    return db->getCollection("payments");
}