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

public type MenuItem record {|
    string itemId;
    string name;
    float price;
    int stock;
|};

public type Restaurant record {|
    string restaurantId;
    string name;
    string location;
    string openingTime;    // "HH:MM"
    string closingTime;    // "HH:MM"
    MenuItem[] menu;
|};