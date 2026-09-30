import ballerina/http;

// ============================================================
// admin_service.bal — REST API for platform reporting.
//
// Every report is generated on request from the owning service's
// public API and then stored, so a report can be shared or
// re-inspected later without regenerating it.
// ============================================================

listener http:Listener adminListener = new (8087);

type OrdersReportEnvelope record {|
    string reportId;
    string reportType;
    string generatedAt;
    OrdersReport report;
|};

type RestaurantsReportEnvelope record {|
    string reportId;
    string reportType;
    string generatedAt;
    RestaurantsReport report;
|};

type DeliveriesReportEnvelope record {|
    string reportId;
    string reportType;
    string generatedAt;
    DeliveriesReport report;
|};

type PaymentsReportEnvelope record {|
    string reportId;
    string reportType;
    string generatedAt;
    PaymentsReport report;
|};

service /admin on adminListener {

    // GET /admin/reports - previously generated reports, newest last
    resource function get reports(string? reportType) returns ReportSummary[]|error {
        map<json> filter = {};
        if reportType is string {
            filter["reportType"] = reportType;
        }
        ReportRun[] runs = check findReports(filter);
        return from ReportRun r in runs
            select {reportId: r.reportId, reportType: r.reportType, generatedAt: r.generatedAt};
    }

    // GET /admin/reports/{reportId} - a stored report
    resource function get reports/[string reportId]() returns ReportRun|http:NotFound|error {
        ReportRun[] matches = check findReports({reportId: reportId});
        if matches.length() == 0 {
            return http:NOT_FOUND;
        }
        return matches[0];
    }

    // GET /admin/reports/orders - order volume, revenue and peak hours
    resource function get reports/orders() returns OrdersReportEnvelope|error {
        OrdersReport report = buildOrdersReport(check fetchOrders());
        ReportRun run = check storeReport("orders", report);
        return {
            reportId: run.reportId,
            reportType: run.reportType,
            generatedAt: run.generatedAt,
            report: report
        };
    }

    // GET /admin/reports/restaurants - per-restaurant statistics, busiest first
    resource function get reports/restaurants() returns RestaurantsReportEnvelope|error {
        RestaurantsReport report = buildRestaurantsReport(check fetchRestaurants(), check fetchOrders());
        ReportRun run = check storeReport("restaurants", report);
        return {
            reportId: run.reportId,
            reportType: run.reportType,
            generatedAt: run.generatedAt,
            report: report
        };
    }

    // GET /admin/reports/deliveries - dispatch times, delivery times, driver usage
    resource function get reports/deliveries() returns DeliveriesReportEnvelope|error {
        DeliveriesReport report = buildDeliveriesReport(check fetchDeliveries(), check fetchDrivers());
        ReportRun run = check storeReport("deliveries", report);
        return {
            reportId: run.reportId,
            reportType: run.reportType,
            generatedAt: run.generatedAt,
            report: report
        };
    }

    // GET /admin/reports/payments - payment success rate and captured value
    resource function get reports/payments() returns PaymentsReportEnvelope|error {
        PaymentsReport report = buildPaymentsReport(check fetchPayments());
        ReportRun run = check storeReport("payments", report);
        return {
            reportId: run.reportId,
            reportType: run.reportType,
            generatedAt: run.generatedAt,
            report: report
        };
    }
}
