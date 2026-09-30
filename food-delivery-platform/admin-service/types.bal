// ============================================================
// types.bal — Admin Service report types, plus read-only copies
// of the records the other services expose over REST.
//
// Admin is a reporting service: it owns no business data, it
// only reads each service through its public API and writes the
// generated report into its own database for later retrieval.
// ============================================================

// --- Read-only copies of the other services' public records ---

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
    string openingTime;
    string closingTime;
    MenuItem[] menu;
|};

public type Driver record {|
    string driverId;
    string name;
    string status;
|};

public type Delivery record {|
    string deliveryId;
    string orderId;
    string driverId;
    string status;
    string assignedAt;
    string completedAt;
    Order orderSnapshot;
|};

public type Payment record {|
    string paymentId;
    string orderId;
    float amount;
    string status;
    string createdAt;
|};

// --- Report shapes ---

public type StatusCount record {|
    string status;
    int count;
|};

public type HourCount record {|
    int hourOfDay;
    int orders;
|};

public type OrdersReport record {|
    int totalOrders;
    float grossRevenue;
    float averageOrderValue;
    int deliveredOrders;
    int cancelledOrders;
    float cancellationRate;
    StatusCount[] statusBreakdown;
    HourCount[] ordersByHourOfDay;
|};

public type RestaurantStat record {|
    string restaurantId;
    string name;
    string location;
    int menuItemCount;
    int totalStockOnHand;
    int ordersReceived;
    float revenue;
    boolean openNow;
|};

public type RestaurantsReport record {|
    int totalRestaurants;
    int restaurantsOpenNow;
    RestaurantStat[] restaurants;
|};

public type DeliveriesReport record {|
    int totalDeliveries;
    int pending;
    int assigned;
    int completed;
    float completionRate;
    int dispatchSamples;
    float averageDispatchSeconds;
    int deliverySamples;
    float averageDeliverySeconds;
    int driversTotal;
    int driversAvailable;
    int driversBusy;
    int driversOffline;
    float driverUtilisationRate;
|};

public type PaymentsReport record {|
    int totalPayments;
    int completed;
    int failed;
    float successRate;
    float capturedAmount;
    float averageCapturedAmount;
|};

// One stored report. data is typed per reportType.
public type ReportRun record {|
    string reportId;
    string reportType;
    string generatedAt;
    json data;
|};

public type ReportSummary record {|
    string reportId;
    string reportType;
    string generatedAt;
|};
