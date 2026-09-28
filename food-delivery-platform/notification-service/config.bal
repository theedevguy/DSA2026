import ballerinax/mongodb;

configurable string mongoConnectionUrl = "mongodb://localhost:27017";
configurable string kafkaBootstrapUrl = "localhost:9092";

mongodb:Client mongoClient = check new ({
    connection: mongoConnectionUrl
});

mongodb:Database notificationDb = check getNotificationDatabase();
mongodb:Collection notificationsCollection = check getCollection(notificationDb, "notifications");

function getNotificationDatabase() returns mongodb:Database|error {
    return mongoClient->getDatabase("notification_db");
}

function getCollection(mongodb:Database db, string name) returns mongodb:Collection|error {
    return db->getCollection(name);
}