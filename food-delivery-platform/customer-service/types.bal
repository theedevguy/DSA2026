// ============================================================
// types.bal — Customer Service domain types.
//
// Order is the same contract every other service publishes on
// Kafka; it is copied here so this service stays independently
// deployable (no shared module / no cross-service DB reads).
// ============================================================

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

public type Customer record {|
    string customerId;
    string name;
    string email;
    string phone;
    string createdAt;
|};

// One saved delivery destination. A customer may keep several and
// mark exactly one as the default.
public type Address record {|
    string addressId;
    string customerId;
    string label;          // "Home", "Work", ...
    string street;
    string city;
    string postalCode;
    boolean isDefault;
|};
