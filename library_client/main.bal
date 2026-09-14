import ballerina/io;

public function main() {
    boolean running = true;
    while running {
        printMainMenu();
        string choice = io:readln("Select an option: ");
        match choice {
            "1" => {
                showGlobalView();
            }
            "2" => {
                showCampusView();
            }
            "3" => {
                showOverdueDashboard();
            }
            "4" => {
                loanAssetFlow();
            }
            "5" => {
                bookAssetFlow();
            }
            "6" => {
                scheduleManagerMenu();
            }
            "0" => {
                running = false;
                io:println("Goodbye!");
            }
            _ => {
                io:println("Invalid option, try again.");
            }
        }
    }
}

function printMainMenu() {
    io:println("\n=== Library Asset Management - Client ===");
    io:println("1. Global View (all assets)");
    io:println("2. Campus View (filter by institution)");
    io:println("3. Overdue Dashboard");
    io:println("4. Loan an Asset");
    io:println("5. Book a Room/Lab/Asset");
    io:println("6. Schedule Manager (servicing)");
    io:println("0. Exit");
}

function printAsset(Asset a) {
    io:println(string `  [${a.assetTag}] ${a.name} (${a.category}) - ${a.status} - Institution: ${a.institutionId} - Due: ${a.maintenanceDueDate}`);
}

// --- 1. Global View ---
function showGlobalView() {
    Asset[]|error result = getAllAssets();
    if result is error {
        io:println("Error fetching assets: ", result.message());
        return;
    }
    io:println("\n-- Global Asset View --");
    foreach Asset a in result {
        printAsset(a);
    }
}

// --- 2. Campus View ---
function showCampusView() {
    Institution[]|error insts = getInstitutions();
    if insts is error {
        io:println("Error fetching institutions: ", insts.message());
        return;
    }
    io:println("\n-- Institutions --");
    foreach Institution i in insts {
        io:println(string `  [${i.id}] ${i.name} - ${i.location}`);
    }
    string institutionId = io:readln("Enter institution ID to view its assets: ");
    Asset[]|error result = getAssetsByInstitution(institutionId);
    if result is error {
        io:println("Error fetching assets: ", result.message());
        return;
    }
    io:println();
    io:println(string `-- Assets at ${institutionId} --`);
    foreach Asset a in result {
        printAsset(a);
    }
}

// --- 3. Overdue Dashboard ---
function showOverdueDashboard() {
    Asset[]|error result = getOverdueAssets();
    if result is error {
        io:println("Error fetching overdue assets: ", result.message());
        return;
    }
    io:println("\n-- OVERDUE Assets --");
    if result.length() == 0 {
        io:println("  Nothing overdue.");
    }
    foreach Asset a in result {
        printAsset(a);
    }
}

// --- 4. Loaning ---
function loanAssetFlow() {
    string assetId = io:readln("Enter asset ID to loan: ");
    Asset|error result = loanAsset(assetId);
    if result is error {
        io:println("Error: ", result.message());
        return;
    }
    io:println(string `Loaned: ${result.name} is now marked "${result.status}".`);
}

// --- 5. Booking ---
function bookAssetFlow() {
    string assetId = io:readln("Enter asset ID (room/lab) to book: ");
    string startDT = io:readln("Start date/time (e.g. 2026-09-20T09:00:00): ");
    string endDT = io:readln("End date/time (e.g. 2026-09-20T11:00:00): ");
    string requestedBy = io:readln("Your name: ");
    string purpose = io:readln("Purpose: ");
    ScheduleEntry|error result = bookAsset(assetId, startDT, endDT, requestedBy, purpose);
    if result is error {
        io:println("Error: ", result.message());
        return;
    }
    io:println(string `Booked. Reference: ${result.id}`);
}

function scheduleManagerMenu() {
    io:println("\n-- Schedule Manager --");
    io:println("1. View schedules for an asset");
    io:println("2. Add a servicing schedule");
    io:println("3. Update an existing schedule");
    string choice = io:readln("Select an option: ");
    match choice {
        "1" => {
            viewSchedulesFlow();
        }
        "2" => {
            addServicingFlow();
        }
        "3" => {
            updateScheduleFlow();
        }
        _ => {
            io:println("Invalid option.");
        }
    }
}

function viewSchedulesFlow() {
    string assetId = io:readln("Asset ID: ");
    ScheduleEntry[]|error result = getSchedulesForAsset(assetId);
    if result is error {
        io:println("Error: ", result.message());
        return;
    }
    foreach ScheduleEntry s in result {
        io:println(string `  [${s.id}] ${s.scheduleType}: ${s.startDateTime} - ${s.endDateTime} (${s.requestedBy}: ${s.purpose})`);
    }
}

function addServicingFlow() {
    string assetId = io:readln("Asset ID: ");
    string startDT = io:readln("Start date/time: ");
    string endDT = io:readln("End date/time: ");
    string requestedBy = io:readln("Requested by: ");
    string purpose = io:readln("Purpose (e.g. routine servicing): ");
    ScheduleEntry|error result = addServicingSchedule(assetId, startDT, endDT, requestedBy, purpose);
    if result is error {
        io:println("Error: ", result.message());
        return;
    }
    io:println(string `Servicing scheduled. Reference: ${result.id}`);
}

function updateScheduleFlow() {
    string scheduleId = io:readln("Schedule ID to update: ");
    string assetId = io:readln("Asset ID: ");
    string scheduleType = io:readln("Type (Booking/Servicing): ");
    string startDT = io:readln("Start date/time: ");
    string endDT = io:readln("End date/time: ");
    string requestedBy = io:readln("Requested by: ");
    string purpose = io:readln("Purpose: ");
    ScheduleEntry|error result = updateSchedule(scheduleId, assetId, scheduleType, startDT, endDT, requestedBy, purpose);
    if result is error {
        io:println("Error: ", result.message());
        return;
    }
    io:println(string `Updated schedule ${result.id}.`);
}
