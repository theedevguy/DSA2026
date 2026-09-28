import ballerinax/mongodb;

configurable string mongoConnectionUrl = "mongodb://localhost:27017";
configurable string kafkaBootstrapUrl = "localhost:9092";

mongodb:Client mongoClient = check new ({
    connection: mongoConnectionUrl
});

mongodb:Database deliveryDb = check getDeliveryDatabase();
mongodb:Collection driversCollection = check getCollection(deliveryDb, "drivers");
mongodb:Collection deliveriesCollection = check getCollection(deliveryDb, "deliveries");

function getDeliveryDatabase() returns mongodb:Database|error {
    return mongoClient->getDatabase("delivery_db");
}

function getCollection(mongodb:Database db, string name) returns mongodb:Collection|error {
    return db->getCollection(name);
}