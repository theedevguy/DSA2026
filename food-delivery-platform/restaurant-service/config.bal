import ballerinax/mongodb;

configurable string mongoConnectionUrl = "mongodb://localhost:27017";
configurable string kafkaBootstrapUrl = "localhost:9092";

mongodb:Client mongoClient = check new ({
    connection: mongoConnectionUrl
});

mongodb:Database restaurantDb = check getRestaurantDatabase();
mongodb:Collection restaurantsCollection = check getCollection(restaurantDb, "restaurants");
mongodb:Collection kitchenOrdersCollection = check getCollection(restaurantDb, "kitchen_orders");

function getRestaurantDatabase() returns mongodb:Database|error {
    return mongoClient->getDatabase("restaurant_db");
}

function getCollection(mongodb:Database db, string name) returns mongodb:Collection|error {
    return db->getCollection(name);
}