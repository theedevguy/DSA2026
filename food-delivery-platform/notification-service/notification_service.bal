import ballerina/http;

listener http:Listener notificationListener = new (8085);

function findNotifications(map<json> filter) returns Notification[]|error {
    stream<Notification, error?> result = check notificationsCollection->find(filter);
    return from Notification n in result select n;
}

service /notifications on notificationListener {

    // GET /notifications?userId= - a user's notification history
    resource function get .(string? userId) returns Notification[]|error {
        map<json> filter = {};
        if userId is string {
            filter["userId"] = userId;
        }
        return findNotifications(filter);
    }
}