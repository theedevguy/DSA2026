import ballerina/io;
import ballerina/lang.'float;

RentalAccommodationServiceClient ep = check new ("http://localhost:9090");

public function main() {
    boolean running = true;
    while running {
        printMainMenu();
        string choice = io:readln("Select an option: ");
        match choice {
            "1" => {
                hostMenu();
            }
            "2" => {
                guestMenu();
            }
            "3" => {
                registerUsersFlow();
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
    io:println("\n=== Rental Accommodation System - Client ===");
    io:println("1. Host Menu (manage property listings)");
    io:println("2. Guest Menu (browse, search, book)");
    io:println("3. Register New Users");
    io:println("0. Exit");
}

function printProperty(Property p) {
    io:println(string `  [${p.property_id}] ${p.name} - ${p.location} (${p.property_type}) - Price: ${p.price_per_night}/night - ${p.status}`);
}

// ================= HOST MENU =================

function hostMenu() {
    boolean inHostMenu = true;
    while inHostMenu {
        io:println("\n--- Host Menu ---");
        io:println("1. Add Property");
        io:println("2. Update Property");
        io:println("3. Remove Property");
        io:println("0. Back to Main Menu");
        string choice = io:readln("Select an option: ");
        match choice {
            "1" => {
                addPropertyFlow();
            }
            "2" => {
                updatePropertyFlow();
            }
            "3" => {
                removePropertyFlow();
            }
            "0" => {
                inHostMenu = false;
            }
            _ => {
                io:println("Invalid option.");
            }
        }
    }
}

function addPropertyFlow() {
    string name = io:readln("Property name: ");
    string location = io:readln("Location: ");
    string propertyType = io:readln("Property type (e.g. Cottage, Apartment): ");
    string priceStr = io:readln("Price per night: ");
    float|error price = 'float:fromString(priceStr);
    if price is error {
        io:println("Invalid price entered.");
        return;
    }
    string status = io:readln("Status (e.g. Available): ");

    AddPropertyRequest request = {
        name: name,
        location: location,
        property_type: propertyType,
        price_per_night: price,
        status: status
    };
    AddPropertyResponse|error response = ep->add_property(request);
    if response is error {
        io:println("Error: ", response.message());
        return;
    }
    io:println(string `Property added. ID: ${response.property_id}`);
}

function updatePropertyFlow() {
    string propertyId = io:readln("Property ID to update: ");
    string name = io:readln("Name: ");
    string location = io:readln("Location: ");
    string propertyType = io:readln("Property type: ");
    string priceStr = io:readln("Price per night: ");
    float|error price = 'float:fromString(priceStr);
    if price is error {
        io:println("Invalid price entered.");
        return;
    }
    string status = io:readln("Status: ");

    UpdatePropertyRequest request = {
        property_id: propertyId,
        name: name,
        location: location,
        property_type: propertyType,
        price_per_night: price,
        status: status
    };
    UpdatePropertyResponse|error response = ep->update_property(request);
    if response is error {
        io:println("Error: ", response.message());
        return;
    }
    io:println("Updated:");
    printProperty(response.property);
}

function removePropertyFlow() {
    string propertyId = io:readln("Property ID to remove: ");
    RemovePropertyRequest request = {property_id: propertyId};
    RemovePropertyResponse|error response = ep->remove_property(request);
    if response is error {
        io:println("Error: ", response.message());
        return;
    }
    io:println("Property removed. Remaining available properties in that location:");
    foreach Property p in response.available_properties {
        printProperty(p);
    }
}



function guestMenu() {
    boolean inGuestMenu = true;
    while inGuestMenu {
        io:println("\n--- Guest Menu ---");
        io:println("1. Browse All Available Properties");
        io:println("2. Browse Properties (filtered by location/price)");
        io:println("3. Search Property by ID");
        io:println("4. Book a Property");
        io:println("5. Confirm Booking");
        io:println("0. Back to Main Menu");
        string choice = io:readln("Select an option: ");
        match choice {
            "1" => {
                browseAllFlow();
            }
            "2" => {
                browseFilteredFlow();
            }
            "3" => {
                searchPropertyFlow();
            }
            "4" => {
                bookPropertyFlow();
            }
            "5" => {
                confirmBookingFlow();
            }
            "0" => {
                inGuestMenu = false;
            }
            _ => {
                io:println("Invalid option.");
            }
        }
    }
}

function browseAllFlow() {
    ListAvailablePropertiesRequest request = {location: "", min_price: 0.0, max_price: 0.0};
    stream<Property, error?>|error responseStream = ep->list_available_properties(request);
    if responseStream is error {
        io:println("Error: ", responseStream.message());
        return;
    }
    io:println("\n-- Available Properties --");
    error? streamErr = responseStream.forEach(function(Property p) {
        printProperty(p);
    });
    if streamErr is error {
        io:println("Error while streaming: ", streamErr.message());
    }
}

function browseFilteredFlow() {
    string location = io:readln("Filter by location (leave blank for any): ");
    string minPriceStr = io:readln("Min price (0 for no minimum): ");
    string maxPriceStr = io:readln("Max price (0 for no maximum): ");
    float|error minPrice = 'float:fromString(minPriceStr);
    float|error maxPrice = 'float:fromString(maxPriceStr);
    if minPrice is error || maxPrice is error {
        io:println("Invalid price entered.");
        return;
    }

    ListAvailablePropertiesRequest request = {location: location, min_price: minPrice, max_price: maxPrice};
    stream<Property, error?>|error responseStream = ep->list_available_properties(request);
    if responseStream is error {
        io:println("Error: ", responseStream.message());
        return;
    }
    io:println("\n-- Matching Properties --");
    error? streamErr = responseStream.forEach(function(Property p) {
        printProperty(p);
    });
    if streamErr is error {
        io:println("Error while streaming: ", streamErr.message());
    }
}

function searchPropertyFlow() {
    string propertyId = io:readln("Property ID to search: ");
    SearchPropertyRequest request = {property_id: propertyId};
    SearchPropertyResponse|error response = ep->search_property(request);
    if response is error {
        io:println("Error: ", response.message());
        return;
    }
    if response.available {
        io:println("Found:");
        printProperty(response.property);
    } else {
        io:println(response.status_message);
    }
}

function bookPropertyFlow() {
    string guestId = io:readln("Your Guest ID: ");
    string propertyId = io:readln("Property ID to book: ");
    string checkIn = io:readln("Check-in date (YYYY-MM-DD): ");
    string checkOut = io:readln("Check-out date (YYYY-MM-DD): ");

    BookPropertyRequest request = {
        guest_id: guestId,
        property_id: propertyId,
        check_in_date: checkIn,
        check_out_date: checkOut
    };
    BookPropertyResponse|error response = ep->book_property(request);
    if response is error {
        io:println("Error: ", response.message());
        return;
    }
    io:println(response.message);
}

function confirmBookingFlow() {
    string guestId = io:readln("Your Guest ID: ");
    ConfirmBookingRequest request = {guest_id: guestId};
    ConfirmBookingResponse|error response = ep->confirm_booking(request);
    if response is error {
        io:println("Error: ", response.message());
        return;
    }
    io:println(response);
}



function registerUsersFlow() {
    Create_usersStreamingClient|error streamClient = ep->create_users();
    if streamClient is error {
        io:println("Error: ", streamClient.message());
        return;
    }

    int count = 0;
    boolean addingUsers = true;
    while addingUsers {
        string more = io:readln("Add a new user? (y/n): ");
        if more.toLowerAscii() != "y" {
            addingUsers = false;
        } else {
            string userId = io:readln("User ID: ");
            string name = io:readln("Name: ");
            string role = io:readln("Role (Host/Guest): ");
            UserProfile profile = {user_id: userId, name: name, role: role};
            error? sendErr = streamClient->sendUserProfile(profile);
            if sendErr is error {
                io:println("Error sending user: ", sendErr.message());
            } else {
                count += 1;
            }
        }
    }

    error? completeErr = streamClient->complete();
    if completeErr is error {
        io:println("Error completing stream: ", completeErr.message());
        return;
    }

    CreateUsersResponse|error? response = streamClient->receiveCreateUsersResponse();
    if response is error {
        io:println("Error receiving confirmation: ", response.message());
        return;
    }
    io:println(response);
}
