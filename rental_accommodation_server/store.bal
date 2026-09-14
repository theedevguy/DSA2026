import ballerina/time;



map<Property> properties = {};
map<UserProfile> users = {};
map<BookPropertyRequest> bookingCarts = {}; // keyed by guest_id — one pending request per Guest
map<ConfirmedBooking> confirmedBookings = {}; // keyed by a generated booking id

type ConfirmedBooking record {|
    string bookingId;
    string propertyId;
    string guestId;
    string checkInDate;
    string checkOutDate;
|};

int propertyCounter = 0;
int bookingCounter = 0;

function nextPropertyId() returns string {
    propertyCounter += 1;
    return string `PROP${propertyCounter}`;
}

function nextBookingId() returns string {
    bookingCounter += 1;
    return string `BKG${bookingCounter}`;
}

// Number of nights between two "YYYY-MM-DD" dates.
function daysBetween(string startDate, string endDate) returns int|error {
    time:Utc startUtc = check time:utcFromString(startDate + "T00:00:00.000Z");
    time:Utc endUtc = check time:utcFromString(endDate + "T00:00:00.000Z");
    time:Seconds diffSeconds = time:utcDiffSeconds(endUtc, startUtc);
    return <int>(diffSeconds / 86400);
}

function init() {
    Property p1 = {
        property_id: nextPropertyId(),
        name: "Seaside Cottage",
        location: "Swakopmund",
        property_type: "Cottage",
        price_per_night: 850.0,
        status: "Available"
    };
    Property p2 = {
        property_id: nextPropertyId(),
        name: "City Apartment",
        location: "Windhoek",
        property_type: "Apartment",
        price_per_night: 650.0,
        status: "Available"
    };
    properties[p1.property_id] = p1;
    properties[p2.property_id] = p2;
}
