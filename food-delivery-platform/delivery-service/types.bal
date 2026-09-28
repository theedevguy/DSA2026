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

public type Driver record {|
    string driverId;
    string name;
    string status;      // AVAILABLE | BUSY | OFFLINE
|};

public type Delivery record {|
    string deliveryId;
    string orderId;
    string driverId;     // empty until assigned
    string status;       // PENDING | ASSIGNED | COMPLETED
    string assignedAt;
    string completedAt;
    Order orderSnapshot;
|};