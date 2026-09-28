public type OrderItem record {|
    string itemId;
    string name;
    float price;
    int quantity;
|};

public type Order record {|
    string orderId;
    string customerId;
    string restaurantId;
    OrderItem[] items;
    float totalAmount;
    string status;       // CREATED | CONFIRMED | PREPARING | READY | OUT_FOR_DELIVERY | DELIVERED | CANCELLED
    string driverId;      // empty string until Delivery Service assigns one
    string createdAt;
    string updatedAt;
|};

// Payload for POST /orders — server computes totalAmount, assigns orderId/status/timestamps
public type CreateOrderRequest record {|
    string customerId;
    string restaurantId;
    OrderItem[] items;
|};