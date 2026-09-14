# Library/Asset Management System — CLI Client

An interactive command-line client that consumes the Library/Asset
Management backend API.

## Prerequisite

The backend must be running first, on `http://localhost:8080`.
See the backend's own README for how to start it.

## How to run

This starts an interactive menu in the terminal — it waits for keyboard
input, so keep this terminal in the foreground while using it.

## Menu options

1. **Global View** — lists every asset across all institutions
2. **Campus View** — lists institutions, then lets you filter assets by
   the one you choose
3. **Overdue Dashboard** — lists only assets past their maintenance due
   date
4. **Loan an Asset** — marks a chosen asset's status as "Loaned"
5. **Book a Room/Lab/Asset** — creates a booking schedule entry for a
   chosen asset, time slot, and purpose
6. **Schedule Manager** — sub-menu to view schedules for an asset, add a
   servicing schedule, or update an existing schedule entry
0. **Exit**

## Project structure

- `types.bal` — data shapes used for displaying results
- `api_client.bal` — functions wrapping every HTTP call to the backend
- `main.bal` — the interactive menu loop
