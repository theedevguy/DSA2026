import ballerina/http;

listener http:Listener paymentListener = new (8082);

function findPayments(map<json> filter) returns Payment[]|error {
    stream<Payment, error?> result = check paymentsCollection->find(filter);
    return from Payment p in result select p;
}

service /payments on paymentListener {

    // GET /payments?status= - list payments, optionally filtered by status
    resource function get .(string? status) returns Payment[]|error {
        map<json> filter = {};
        if status is string {
            filter["status"] = status;
        }
        return findPayments(filter);
    }

    // GET /payments/{orderId} - payment status for an order
    resource function get [string orderId]() returns Payment|http:NotFound|error {
        Payment[] matches = check findPayments({orderId: orderId});
        if matches.length() == 0 {
            return http:NOT_FOUND;
        }
        return matches[0];
    }
}