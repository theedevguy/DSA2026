import ballerina/random;
import ballerina/time;
import ballerina/uuid;
import ballerinax/kafka;

function processPayment(Order incoming) returns error? {
    // Idempotency guard: if this order was already processed (e.g. event redelivered), skip it
    Payment[] existing = check findPayments({orderId: incoming.orderId});
    if existing.length() > 0 {
        return;
    }

    boolean failed = random:createDecimal() < paymentFailureRate;

    Payment payment = {
        paymentId: uuid:createType4AsString(),
        orderId: incoming.orderId,
        amount: incoming.totalAmount,
        status: failed ? "FAILED" : "COMPLETED",
        createdAt: time:utcToString(time:utcNow())
    };
    check paymentsCollection->insertOne(payment);

    check publishOrderEvent(failed ? "payments.failed" : "payments.completed", incoming);
}

listener kafka:Listener ordersCreatedListener = new (kafkaBootstrapUrl, {groupId: "payment-service-orders-created", topics: ["orders.created"]});

service on ordersCreatedListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check processPayment(o);
        }
    }
}