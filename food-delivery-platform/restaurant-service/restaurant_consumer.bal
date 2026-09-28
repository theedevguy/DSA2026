import ballerinax/kafka;

function newStock(MenuItem m, OrderItem[] items) returns int {
    int stock = m.stock;
    foreach OrderItem i in items {
        if i.itemId == m.itemId {
            stock -= i.quantity;
        }
    }
    return stock < 0 ? 0 : stock;
}

function decrementStock(string restaurantId, OrderItem[] items) returns error? {
    Restaurant[] found = check findRestaurants({restaurantId: restaurantId});
    if found.length() == 0 {
        return;
    }
    MenuItem[] updatedMenu = from MenuItem m in found[0].menu
        select {
            itemId: m.itemId,
            name: m.name,
            price: m.price,
            stock: newStock(m, items)
        };
    _ = check restaurantsCollection->updateOne({restaurantId: restaurantId}, {set: {menu: updatedMenu}});
}

function handleOrderConfirmed(Order incoming) returns error? {
    // Idempotency guard: a redelivered event must not decrement stock twice
    Order[] existing = check findKitchenOrders({orderId: incoming.orderId});
    if existing.length() > 0 {
        return;
    }
    check kitchenOrdersCollection->insertOne(incoming);
    check decrementStock(incoming.restaurantId, incoming.items);
}

listener kafka:Listener ordersConfirmedListener = new (kafkaBootstrapUrl, {groupId: "restaurant-service-orders-confirmed", topics: ["orders.confirmed"]});

service on ordersConfirmedListener {
    remote function onConsumerRecord(@kafka:Payload Order[] orders) returns error? {
        foreach Order o in orders {
            check handleOrderConfirmed(o);
        }
    }
}