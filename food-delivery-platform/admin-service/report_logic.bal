import ballerina/lang.array;
import ballerina/time;
import ballerina/uuid;

// ============================================================
// report_logic.bal — Builds the four reports Admin publishes:
// order statistics, restaurant statistics, delivery performance
// and payment performance.
//
// Every number here is derived from the public REST APIs of the
// owning service, so the report can never drift from the data the
// service would show a customer of its own.
// ============================================================

function percentage(int part, int whole) returns float {
    return whole == 0 ? 0.0 : ((part * 100.0) / whole);
}

function isOpenNow(Restaurant restaurant) returns boolean {
    int? opens = minutesOfDay(restaurant.openingTime);
    int? closes = minutesOfDay(restaurant.closingTime);
    if opens is () || closes is () {
        return false;
    }
    int nowMinutes = (currentUtcSeconds() % SECONDS_PER_DAY) / 60;
    if opens == closes {
        return true;
    }
    if opens < closes {
        return nowMinutes >= opens && nowMinutes < closes;
    }
    // Opening hours that run past midnight, e.g. 18:00 to 02:00.
    return nowMinutes >= opens || nowMinutes < closes;
}

function buildOrdersReport(Order[] orders) returns OrdersReport {
    int total = orders.length();
    int delivered = 0;
    int cancelled = 0;
    float gross = 0.0;
    map<int> byStatus = {};
    // 24 buckets, one per UTC hour of the day.
    int[] byHour = [];
    foreach int i in 0 ..< 24 {
        byHour.push(0);
    }

    foreach Order o in orders {
        if o.status == "DELIVERED" {
            delivered += 1;
        }
        if o.status == "CANCELLED" {
            // Cancelled orders never became revenue.
            cancelled += 1;
        } else {
            gross += o.totalAmount;
        }
        byStatus[o.status] = (byStatus[o.status] ?: 0) + 1;
        int? hour = utcHourOfDay(o.createdAt);
        if hour is int && hour >= 0 && hour < 24 {
            byHour[hour] = byHour[hour] + 1;
        }
    }

    StatusCount[] statusBreakdown = [];
    foreach var [status, count] in byStatus.entries() {
        statusBreakdown.push({status: status, count: count});
    }

    // Always emit the full day so the histogram can be charted as-is.
    HourCount[] ordersByHour = [];
    foreach int hour in 0 ..< 24 {
        ordersByHour.push({hourOfDay: hour, orders: byHour[hour]});
    }

    return {
        totalOrders: total,
        grossRevenue: gross,
        averageOrderValue: total == 0 ? 0.0 : gross / <float>total,
        deliveredOrders: delivered,
        cancelledOrders: cancelled,
        cancellationRate: percentage(cancelled, total),
        statusBreakdown: statusBreakdown,
        ordersByHourOfDay: ordersByHour
    };
}

function buildRestaurantsReport(Restaurant[] restaurants, Order[] orders) returns RestaurantsReport {
    map<int> orderCount = {};
    map<float> revenue = {};
    foreach Order o in orders {
        if o.status != "CANCELLED" {
            orderCount[o.restaurantId] = (orderCount[o.restaurantId] ?: 0) + 1;
            revenue[o.restaurantId] = (revenue[o.restaurantId] ?: 0) + o.totalAmount;
        }
    }

    RestaurantStat[] stats = [];
    int openNow = 0;
    foreach Restaurant r in restaurants {
        int stockOnHand = 0;
        foreach MenuItem m in r.menu {
            stockOnHand += m.stock;
        }
        boolean open = isOpenNow(r);
        if open {
            openNow += 1;
        }
        stats.push({
            restaurantId: r.restaurantId,
            name: r.name,
            location: r.location,
            menuItemCount: r.menu.length(),
            totalStockOnHand: stockOnHand,
            ordersReceived: orderCount[r.restaurantId] ?: 0,
            revenue: revenue[r.restaurantId] ?: 0.0,
            openNow: open
        });
    }

    // Busiest restaurants first.
    RestaurantStat[] ranked = array:sort(stats, array:DESCENDING,
        isolated function(RestaurantStat s) returns float => s.revenue);

    return {
        totalRestaurants: stats.length(),
        restaurantsOpenNow: openNow,
        restaurants: ranked
    };
}

function buildDeliveriesReport(Delivery[] deliveries, Driver[] drivers) returns DeliveriesReport {
    int pending = 0;
    int assigned = 0;
    int completed = 0;
    int dispatchTotal = 0;
    int dispatchSamples = 0;
    int journeyTotal = 0;
    int journeySamples = 0;

    foreach Delivery d in deliveries {
        match d.status {
            "PENDING" => { pending += 1; }
            "ASSIGNED" => { assigned += 1; }
            _ => { completed += 1; }
        }

        // -1 marks a stamp that could not be parsed, so it is skipped.
        int ordered = parseUtcSeconds(d.orderSnapshot.createdAt) ?: -1;
        int dispatched = parseUtcSeconds(d.assignedAt) ?: -1;
        int dropped = parseUtcSeconds(d.completedAt) ?: -1;

        if ordered >= 0 && dispatched >= 0 {
            // Time from the customer clicking order to a driver taking it.
            int dispatchSeconds = dispatched - ordered;
            if dispatchSeconds >= 0 {
                dispatchTotal += dispatchSeconds;
                dispatchSamples += 1;
            }
        }
        if dispatched >= 0 && dropped >= 0 {
            // Time from pickup to drop-off.
            int journeySeconds = dropped - dispatched;
            if journeySeconds >= 0 {
                journeyTotal += journeySeconds;
                journeySamples += 1;
            }
        }
    }

    int available = 0;
    int busy = 0;
    int offline = 0;
    foreach Driver d in drivers {
        match d.status {
            "AVAILABLE" => { available += 1; }
            "BUSY" => { busy += 1; }
            _ => { offline += 1; }
        }
    }

    return {
        totalDeliveries: deliveries.length(),
        pending: pending,
        assigned: assigned,
        completed: completed,
        completionRate: percentage(completed, deliveries.length()),
        dispatchSamples: dispatchSamples,
        averageDispatchSeconds: dispatchSamples == 0 ? 0.0 : <float>dispatchTotal / <float>dispatchSamples,
        deliverySamples: journeySamples,
        averageDeliverySeconds: journeySamples == 0 ? 0.0 : <float>journeyTotal / <float>journeySamples,
        driversTotal: drivers.length(),
        driversAvailable: available,
        driversBusy: busy,
        driversOffline: offline,
        driverUtilisationRate: percentage(busy, drivers.length())
    };
}

function buildPaymentsReport(Payment[] payments) returns PaymentsReport {
    int completed = 0;
    int failed = 0;
    float captured = 0.0;
    foreach Payment p in payments {
        if p.status == "COMPLETED" {
            completed += 1;
            captured += p.amount;
        } else {
            failed += 1;
        }
    }

    return {
        totalPayments: payments.length(),
        completed: completed,
        failed: failed,
        successRate: percentage(completed, payments.length()),
        capturedAmount: captured,
        averageCapturedAmount: completed == 0 ? 0.0 : captured / <float>completed
    };
}

function findReports(map<json> filter) returns ReportRun[]|error {
    stream<ReportRun, error?> result = check reportsCollection->find(filter);
    return from ReportRun r in result select r;
}

// Persists a generated report so it can be retrieved again later.
function storeReport(string reportType, anydata report) returns ReportRun|error {
    ReportRun run = {
        reportId: uuid:createType4AsString(),
        reportType: reportType,
        generatedAt: time:utcToString(time:utcNow()),
        data: report.toJson()
    };
    check reportsCollection->insertOne(run);
    return run;
}
