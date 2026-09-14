import ballerina/http;

listener http:Listener apiListener = new (8080);

map<Institution> institutions = {};
map<Asset> assets = {};
map<Component> components = {};
map<ScheduleEntry> schedules = {};
map<WorkOrder> workOrders = {};

int institutionCounter = 0;
int assetTagCounter = 0;
int componentCounter = 0;
int scheduleCounter = 0;
int workOrderCounter = 0;
int taskCounter = 0;

function nextInstitutionId() returns string {
    institutionCounter += 1;
    return string `INS${institutionCounter}`;
}

function nextAssetTag() returns string {
    assetTagCounter += 1;
    return string `AST${assetTagCounter}`;
}

function nextComponentId() returns string {
    componentCounter += 1;
    return string `CMP${componentCounter}`;
}

function nextScheduleId() returns string {
    scheduleCounter += 1;
    return string `SCH${scheduleCounter}`;
}

function nextWorkOrderId() returns string {
    workOrderCounter += 1;
    return string `WO${workOrderCounter}`;
}

function nextTaskId() returns string {
    taskCounter += 1;
    return string `TSK${taskCounter}`;
}

function init() {
    Institution inst1 = {id: nextInstitutionId(), name: "Windhoek Technical High School", location: "Windhoek, Khomas"};
    Institution inst2 = {id: nextInstitutionId(), name: "Ongwediva Trade College", location: "Ongwediva, Oshana"};
    institutions[inst1.id] = inst1;
    institutions[inst2.id] = inst2;

    Asset asset1 = {
        assetTag: nextAssetTag(),
        name: "HP LaserJet Pro Printer",
        description: "Shared office printer for the administration block.",
        category: "Printer",
        institutionId: inst1.id,
        site: "Admin Block, Room 12",
        status: "Available",
        maintenanceDueDate: "2026-08-01",
        dateAcquired: "2023-02-14"
    };
    Asset asset2 = {
        assetTag: nextAssetTag(),
        name: "Physics Lab A",
        description: "General-purpose physics laboratory used for practical classes.",
        category: "Lab",
        institutionId: inst2.id,
        site: "Science Building",
        status: "Available",
        maintenanceDueDate: "2027-01-15",
        dateAcquired: "2022-08-01"
    };
    assets[asset1.assetTag] = asset1;
    assets[asset2.assetTag] = asset2;
}
