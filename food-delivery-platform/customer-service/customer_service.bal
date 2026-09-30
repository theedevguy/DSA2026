import ballerina/http;
import ballerina/time;
import ballerina/uuid;

// ============================================================
// customer_service.bal — REST API for customer accounts,
// their saved delivery addresses, and their order history.
// ============================================================

listener http:Listener customerListener = new (8086);

type CustomerInput record {|
    string name;
    string email;
    string phone;
|};

type AddressInput record {|
    string label;
    string street;
    string city;
    string postalCode;
    boolean isDefault = false;
|};

// Per-customer roll-up of the projected order history.
type CustomerSummary record {|
    string customerId;
    int totalOrders;
    int activeOrders;
    int deliveredOrders;
    int cancelledOrders;
    float lifetimeSpend;
    string defaultAddress;
|};

function nowTimestamp() returns string {
    return time:utcToString(time:utcNow());
}

function findCustomers(map<json> filter) returns Customer[]|error {
    stream<Customer, error?> result = check customersCollection->find(filter);
    return from Customer c in result select c;
}

function findAddresses(map<json> filter) returns Address[]|error {
    stream<Address, error?> result = check addressesCollection->find(filter);
    return from Address a in result select a;
}

function customerExists(string customerId) returns boolean|error {
    Customer[] matches = check findCustomers({customerId: customerId});
    return matches.length() > 0;
}

function validContactDetails(CustomerInput input) returns boolean {
    return input.name.trim().length() > 0 && input.email.includes("@");
}

// Only one address per customer may carry the default flag.
function clearOtherDefaults(string customerId, string keepAddressId) returns error? {
    Address[] addresses = check findAddresses({customerId: customerId});
    foreach Address a in addresses {
        if a.addressId != keepAddressId && a.isDefault {
            _ = check addressesCollection->updateOne({addressId: a.addressId}, {set: {isDefault: false}});
        }
    }
}

service /customers on customerListener {

    // POST /customers - register a customer account
    resource function post .(@http:Payload CustomerInput input) returns Customer|http:BadRequest|http:Conflict|error {
        if !validContactDetails(input) {
            return <http:BadRequest>{body: "A non-empty name and a valid email address are required."};
        }
        Customer[] existing = check findCustomers({email: input.email});
        if existing.length() > 0 {
            return <http:Conflict>{body: string `A customer with email ${input.email} already exists.`};
        }

        Customer newCustomer = {
            customerId: uuid:createType4AsString(),
            name: input.name,
            email: input.email,
            phone: input.phone,
            createdAt: nowTimestamp()
        };
        check customersCollection->insertOne(newCustomer);
        return newCustomer;
    }

    // GET /customers - list all customers
    resource function get .() returns Customer[]|error {
        return findCustomers({});
    }

    // GET /customers/{customerId}
    resource function get [string customerId]() returns Customer|http:NotFound|error {
        Customer[] matches = check findCustomers({customerId: customerId});
        if matches.length() == 0 {
            return http:NOT_FOUND;
        }
        return matches[0];
    }

    // PUT /customers/{customerId} - update contact details
    resource function put [string customerId](@http:Payload CustomerInput input) returns Customer|http:NotFound|http:BadRequest|error {
        Customer[] matches = check findCustomers({customerId: customerId});
        if matches.length() == 0 {
            return http:NOT_FOUND;
        }
        if !validContactDetails(input) {
            return <http:BadRequest>{body: "A non-empty name and a valid email address are required."};
        }
        _ = check customersCollection->updateOne({customerId: customerId},
            {set: {name: input.name, email: input.email, phone: input.phone}});
        Customer[] fresh = check findCustomers({customerId: customerId});
        return fresh[0];
    }

    // DELETE /customers/{customerId} - remove the account and everything filed under it
    resource function delete [string customerId]() returns http:Ok|http:NotFound|error {
        Customer[] matches = check findCustomers({customerId: customerId});
        if matches.length() == 0 {
            return http:NOT_FOUND;
        }
        _ = check customersCollection->deleteOne({customerId: customerId});
        _ = check addressesCollection->deleteMany({customerId: customerId});
        _ = check orderHistoryCollection->deleteMany({customerId: customerId});
        return http:OK;
    }

    // GET /customers/{customerId}/summary - order counts, lifetime spend, default address
    resource function get [string customerId]/summary() returns CustomerSummary|http:NotFound|error {
        if !(check customerExists(customerId)) {
            return http:NOT_FOUND;
        }
        Order[] history = check findOrderHistory({customerId: customerId});

        int active = 0;
        int delivered = 0;
        int cancelled = 0;
        float spend = 0.0;
        foreach Order o in history {
            match o.status {
                "DELIVERED" => {
                    delivered += 1;
                    spend += o.totalAmount;
                }
                "CANCELLED" => { cancelled += 1; }
                _ => { active += 1; }
            }
        }

        Address[] defaults = check findAddresses({customerId: customerId, isDefault: true});
        return {
            customerId: customerId,
            totalOrders: history.length(),
            activeOrders: active,
            deliveredOrders: delivered,
            cancelledOrders: cancelled,
            lifetimeSpend: spend,
            defaultAddress: defaults.length() > 0 ? defaults[0].label : ""
        };
    }

    // GET /customers/{customerId}/addresses
    resource function get [string customerId]/addresses() returns Address[]|http:NotFound|error {
        if !(check customerExists(customerId)) {
            return http:NOT_FOUND;
        }
        return findAddresses({customerId: customerId});
    }

    // POST /customers/{customerId}/addresses - save a delivery destination
    resource function post [string customerId]/addresses(@http:Payload AddressInput input) returns Address|http:NotFound|http:BadRequest|error {
        if !(check customerExists(customerId)) {
            return http:NOT_FOUND;
        }
        if input.street.trim().length() == 0 || input.city.trim().length() == 0 {
            return <http:BadRequest>{body: "Street and city must not be empty."};
        }

        // The first address a customer saves becomes their default.
        Address[] existing = check findAddresses({customerId: customerId});
        boolean makeDefault = input.isDefault || existing.length() == 0;

        Address newAddress = {
            addressId: uuid:createType4AsString(),
            customerId: customerId,
            label: input.label,
            street: input.street,
            city: input.city,
            postalCode: input.postalCode,
            isDefault: makeDefault
        };
        check addressesCollection->insertOne(newAddress);
        check clearOtherDefaults(customerId, newAddress.addressId);
        return newAddress;
    }

    // PUT /customers/{customerId}/addresses/{addressId}
    resource function put [string customerId]/addresses/[string addressId](@http:Payload AddressInput input) returns Address|http:NotFound|http:BadRequest|error {
        Address[] matches = check findAddresses({customerId: customerId, addressId: addressId});
        if matches.length() == 0 {
            return http:NOT_FOUND;
        }
        if input.street.trim().length() == 0 || input.city.trim().length() == 0 {
            return <http:BadRequest>{body: "Street and city must not be empty."};
        }

        // An address that is already the default stays the default.
        boolean makeDefault = input.isDefault || matches[0].isDefault;
        _ = check addressesCollection->updateOne({addressId: addressId}, {set: {
            label: input.label,
            street: input.street,
            city: input.city,
            postalCode: input.postalCode,
            isDefault: makeDefault
        }});
        check clearOtherDefaults(customerId, addressId);
        Address[] fresh = check findAddresses({addressId: addressId});
        return fresh[0];
    }

    // DELETE /customers/{customerId}/addresses/{addressId}
    resource function delete [string customerId]/addresses/[string addressId]() returns http:Ok|http:NotFound|error {
        Address[] matches = check findAddresses({customerId: customerId, addressId: addressId});
        if matches.length() == 0 {
            return http:NOT_FOUND;
        }
        _ = check addressesCollection->deleteOne({addressId: addressId});

        // Never leave a customer without a usable default destination.
        if matches[0].isDefault {
            Address[] remaining = check findAddresses({customerId: customerId});
            if remaining.length() > 0 {
                _ = check addressesCollection->updateOne({addressId: remaining[0].addressId}, {set: {isDefault: true}});
            }
        }
        return http:OK;
    }

    // GET /customers/{customerId}/orders?status= - historical order data
    resource function get [string customerId]/orders(string? status) returns Order[]|http:NotFound|error {
        if !(check customerExists(customerId)) {
            return http:NOT_FOUND;
        }
        map<json> filter = {customerId: customerId};
        if status is string {
            filter["status"] = status;
        }
        return findOrderHistory(filter);
    }
}
