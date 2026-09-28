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

public type Notification record {|
    string notificationId;
    string userId;
    string eventType;
    string message;
    string channel;      // EMAIL | SMS | PUSH
    string createdAt;
|};