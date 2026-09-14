# Rental Accommodation System — gRPC Client

An interactive command-line client for the Rental Accommodation System,
built in Ballerina. Demonstrates every operation defined in the
`RentalAccommodationService` contract, including both streaming RPCs.

## Prerequisite

The server must be running first, on `localhost:9090`. See the server's
own README for how to start it.

## How to run

Starts an interactive menu in the terminal.

## Menu structure

This maps directly to the two user roles: Hosts manage property listings
(Host Menu), Guests browse, search, and book accommodations (Guest Menu).

## Project structure

- `resources/rental.proto` — the shared contract (identical to the server's copy)
- `rental_pb.bal` — generated message types
- `rentalaccommodationservice_client.bal` — generated client stub + the
  interactive menu logic