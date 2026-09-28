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
    string status;
    string driverId;
    string createdAt;
    string updatedAt;
|};

public type Payment record {|
    string paymentId;
    string orderId;
    float amount;
    string status;       // COMPLETED | FAILED
    string createdAt;
|};