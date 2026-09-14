import ballerina/grpc;

listener grpc:Listener ep = new (9090);

@grpc:Descriptor {value: RENTAL_DESC}
service "RentalAccommodationService" on ep {

    remote function add_property(AddPropertyRequest value) returns AddPropertyResponse|error {
        string newId = nextPropertyId();
        Property newProperty = {
            property_id: newId,
            name: value.name,
            location: value.location,
            property_type: value.property_type,
            price_per_night: value.price_per_night,
            status: value.status
        };
        properties[newId] = newProperty;
        return {property_id: newId};
    }

    remote function update_property(UpdatePropertyRequest value) returns UpdatePropertyResponse|error {
        if !properties.hasKey(value.property_id) {
            return error(string `Property not found: ${value.property_id}`);
        }
        Property updated = {
            property_id: value.property_id,
            name: value.name,
            location: value.location,
            property_type: value.property_type,
            price_per_night: value.price_per_night,
            status: value.status
        };
        properties[value.property_id] = updated;
        return {property: updated};
    }

    remote function remove_property(RemovePropertyRequest value) returns RemovePropertyResponse|error {
        Property? removed = properties[value.property_id];
        if removed is () {
            return error(string `Property not found: ${value.property_id}`);
        }
        _ = properties.remove(value.property_id);

        string sameLocation = removed.location;
        Property[] remaining = properties.toArray().filter(function(Property p) returns boolean {
            return p.location == sameLocation && p.status == "Available";
        });
        return {available_properties: remaining};
    }

    remote function search_property(SearchPropertyRequest value) returns SearchPropertyResponse|error {
        Property? found = properties[value.property_id];
        if found is Property && found.status == "Available" {
            return {available: true, status_message: "OK", property: found};
        }
        return {available: false, status_message: "Not Available", property: {}};
    }

    remote function book_property(BookPropertyRequest value) returns BookPropertyResponse|error {
        if value.check_out_date <= value.check_in_date {
            return {success: false, message: "Check-out date must be after check-in date."};
        }
        bookingCarts[value.guest_id] = value;
        return {success: true, message: "Booking request added to cart. Call confirm_booking to finalize."};
    }

    remote function confirm_booking(ConfirmBookingRequest value) returns ConfirmBookingResponse|error {
        BookPropertyRequest? cartEntry = bookingCarts[value.guest_id];
        if cartEntry is () {
            return {
                success: false,
                message: "No pending booking found for this guest.",
                property_id: "",
                check_in_date: "",
                check_out_date: "",
                number_of_nights: 0,
                total_cost: 0.0
            };
        }

        Property? prop = properties[cartEntry.property_id];
        if prop is () {
            return {
                success: false,
                message: "Property no longer exists.",
                property_id: cartEntry.property_id,
                check_in_date: "",
                check_out_date: "",
                number_of_nights: 0,
                total_cost: 0.0
            };
        }

        boolean hasOverlap = false;
        foreach ConfirmedBooking b in confirmedBookings {
            if b.propertyId == cartEntry.property_id {
                boolean noOverlap = cartEntry.check_out_date <= b.checkInDate || cartEntry.check_in_date >= b.checkOutDate;
                if !noOverlap {
                    hasOverlap = true;
                }
            }
        }

        if hasOverlap {
            return {
                success: false,
                message: "Property is not available for the requested dates.",
                property_id: cartEntry.property_id,
                check_in_date: cartEntry.check_in_date,
                check_out_date: cartEntry.check_out_date,
                number_of_nights: 0,
                total_cost: 0.0
            };
        }

        int nights = check daysBetween(cartEntry.check_in_date, cartEntry.check_out_date);
        float totalCost = <float>nights * prop.price_per_night;

        string newBookingId = nextBookingId();
        ConfirmedBooking newBooking = {
            bookingId: newBookingId,
            propertyId: cartEntry.property_id,
            guestId: value.guest_id,
            checkInDate: cartEntry.check_in_date,
            checkOutDate: cartEntry.check_out_date
        };
        confirmedBookings[newBookingId] = newBooking;
        _ = bookingCarts.remove(value.guest_id);

        return {
            success: true,
            message: "Booking confirmed.",
            property_id: cartEntry.property_id,
            check_in_date: cartEntry.check_in_date,
            check_out_date: cartEntry.check_out_date,
            number_of_nights: nights,
            total_cost: totalCost
        };
    }

    remote function create_users(stream<UserProfile, grpc:Error?> clientStream) returns CreateUsersResponse|error {
        int count = 0;
        error? streamError = clientStream.forEach(function(UserProfile profile) {
            users[profile.user_id] = profile;
            count += 1;
        });
        if streamError is error {
            return streamError;
        }
        return {users_created: count, message: string `${count} user(s) registered successfully.`};
    }

    remote function list_available_properties(ListAvailablePropertiesRequest value) returns stream<Property, error?>|error {
        Property[] result = properties.toArray().filter(function(Property p) returns boolean {
            return p.status == "Available";
        });

        if value.location != "" {
            string loc = value.location;
            result = result.filter(function(Property p) returns boolean {
                return p.location == loc;
            });
        }
        if value.min_price > 0.0 {
            float minP = value.min_price;
            result = result.filter(function(Property p) returns boolean {
                return p.price_per_night >= minP;
            });
        }
        if value.max_price > 0.0 {
            float maxP = value.max_price;
            result = result.filter(function(Property p) returns boolean {
                return p.price_per_night <= maxP;
            });
        }

        return result.toStream();
    }
}
