import ballerina/http;


final http:Client backend = check new ("http://localhost:8080");

public function getAllAssets() returns Asset[]|error {
    return backend->get("/assets");
}

public function getAssetsByInstitution(string institutionId) returns Asset[]|error {
    return backend->get("/assets?institutionId=" + institutionId);
}

public function getOverdueAssets() returns Asset[]|error {
    return backend->get("/assets?overdue=true");
}

public function getInstitutions() returns Institution[]|error {
    return backend->get("/institutions");
}

type AssetUpdatePayload record {|
    string name;
    string description;
    string category;
    string institutionId;
    string site;
    string status;
    string maintenanceDueDate;
    string dateAcquired;
|};

public function loanAsset(string assetId) returns Asset|error {
    Asset current = check backend->get("/assets/" + assetId);
    AssetUpdatePayload payload = {
        name: current.name,
        description: current.description,
        category: current.category,
        institutionId: current.institutionId,
        site: current.site,
        status: "Loaned",
        maintenanceDueDate: current.maintenanceDueDate,
        dateAcquired: current.dateAcquired
    };
    return backend->put("/assets/" + assetId, payload);
}

type ScheduleInputPayload record {|
    string assetId;
    string scheduleType;
    string startDateTime;
    string endDateTime;
    string requestedBy;
    string purpose;
|};

public function bookAsset(string assetId, string startDateTime, string endDateTime, string requestedBy, string purpose) returns ScheduleEntry|error {
    ScheduleInputPayload payload = {
        assetId: assetId,
        scheduleType: "Booking",
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        requestedBy: requestedBy,
        purpose: purpose
    };
    return backend->post("/schedules", payload);
}

public function addServicingSchedule(string assetId, string startDateTime, string endDateTime, string requestedBy, string purpose) returns ScheduleEntry|error {
    ScheduleInputPayload payload = {
        assetId: assetId,
        scheduleType: "Servicing",
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        requestedBy: requestedBy,
        purpose: purpose
    };
    return backend->post("/schedules", payload);
}

public function getSchedulesForAsset(string assetId) returns ScheduleEntry[]|error {
    return backend->get("/schedules?assetId=" + assetId);
}

public function updateSchedule(string scheduleId, string assetId, string scheduleType, string startDateTime, string endDateTime, string requestedBy, string purpose) returns ScheduleEntry|error {
    ScheduleInputPayload payload = {
        assetId: assetId,
        scheduleType: scheduleType,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        requestedBy: requestedBy,
        purpose: purpose
    };
    return backend->put("/schedules/" + scheduleId, payload);
}
