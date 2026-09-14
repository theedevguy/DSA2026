# Rental Accommodation System — gRPC Server

A gRPC service built in Ballerina for the Ministry of Tourism's short-term
accommodation rental platform. Manages property listings and bookings for
two user roles: Host and Guest.

## How to run

Starts the gRPC service on `localhost:9090`. Data is held in-memory and is
seeded with two sample properties on startup — it resets each time you
restart the server.

## Contract

Defined in `resources/rental.proto`, service `RentalAccommodationService`.

| RPC | Type | Purpose |
|---|---|---|
| `add_property` | Unary | Host registers a new listing, receives a generated `property_id` |
| `create_users` | Client-streaming | Registers multiple Host/Guest profiles in one call, single confirmation returned at the end |
| `update_property` | Unary | Host updates a listing's details, keyed by `property_id` |
| `remove_property` | Unary | Host deletes a listing; server returns the fresh list of available properties in that same location |
| `list_available_properties` | Server-streaming | Guest browses available properties, streamed one by one, optionally filtered by location and/or price range |
| `search_property` | Unary | Guest looks up one property by ID; returns full details or a "Not Available" status |
| `book_property` | Unary | Guest requests a booking for specific dates; basic date validation only, held in a temporary per-Guest "cart" |
| `confirm_booking` | Unary | Finalizes the Guest's pending booking — checks for date overlaps against existing confirmed bookings, calculates total cost, clears the cart |

## Data model

- **Property** — `property_id`, `name`, `location`, `property_type`, `price_per_night`, `status`
- **UserProfile** — `user_id`, `name`, `role` (Host/Guest)
- Internally, the server also tracks confirmed bookings (property, guest, dates) to check for date-overlap conflicts — this isn't part of the `.proto` contract, just server-side bookkeeping.

## Notes

- All storage is in-memory (Ballerina maps) — no external database.
- Each Guest has exactly one pending booking-cart entry at a time.
- `remove_property`'s "region" requirement is implemented using the property's
  `location` field.