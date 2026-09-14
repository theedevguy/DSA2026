# Library/Asset Management System — Ballerina

A RESTful API backend (Ballerina) and a command-line client (Ballerina) for
managing institutional assets, bookings, servicing schedules, and work orders.

## Project structure

- `Librarymanagementsystem/` — the backend API (port 8080)
- `library_client/` — the interactive CLI client

## How to run

Two terminals are required, started **in this order**:

1. Backend:
   Wait until it shows it's running before starting the client.

2. Client (in a separate terminal):

Starts the API on `http://localhost:8080`. Data is held in-memory and is
seeded with sample institutions/assets on startup — it resets each time you
restart the server.

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | /assets | List all assets |
| GET | /assets?institutionId={id} | Filter assets by institution |
| GET | /assets?overdue=true | List assets past their maintenance due date |
| GET | /assets/{id} | Get one asset |
| POST | /assets | Create an asset |
| PUT | /assets/{id} | Update an asset |
| DELETE | /assets/{id} | Delete an asset |
| GET | /components?assetId={id} | List components on an asset |
| POST | /components | Add a component |
| PUT | /components/{id} | Update a component |
| DELETE | /components/{id} | Remove a component |
| GET | /schedules?assetId={id} | List bookings/servicing for an asset |
| POST | /schedules | Add a booking or servicing entry |
| PUT | /schedules/{id} | Modify a schedule entry |
| DELETE | /schedules/{id} | Cancel a schedule entry |
| GET | /workorders?assetId={id}\|?status={status} | List/filter work orders |
| POST | /workorders | Open a work order against a faulty asset |
| PUT | /workorders/{id} | Update or close a work order |
| DELETE | /workorders/{id} | Remove a work order |
| POST | /workorders/{id}/tasks | Add a sub-task |
| PUT | /workorders/{id}/tasks/{taskId} | Update a sub-task |
| DELETE | /workorders/{id}/tasks/{taskId} | Remove a sub-task |
| GET | /institutions | List all institutions |

## Data model

- **Institution** — id, name, location
- **Asset** — id, name, category, institutionId, location, status, maintenanceDueDate
- **Component** — id, assetId, name, description, status
- **ScheduleEntry** — id, assetId, scheduleType (Booking/Servicing), startDateTime, endDateTime, requestedBy, purpose
- **WorkOrder** — id, assetId, description, status, createdDate, tasks[]
- **WorkOrderTask** — id, description, status

## Notes

- Storage is in-memory (Ballerina maps) — no external database required.
- `POST /components` and `POST /schedules` and `POST /workorders` validate
  that the referenced `assetId` exists before creating a record.