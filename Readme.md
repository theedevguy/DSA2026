# DSA612S Assignment 1

## Distributed Systems and Applications

This repository contains our implementation for DSA612S Assignment 1.

The assignment consists of two distributed systems:

* **Question 1:** RESTful API Library and Resource Management System
* **Question 2:** gRPC Rental Accommodation System

### Group Work

**Question 1**

* Hans Haitembu

**Question 2**

* Jason Kashimbode

---

# Question 1: Library and Resource Management System

Question 1 is a distributed library and resource management system for institutions of higher learning. It manages resources such as books, electronic equipment, laboratories and meeting rooms across different institutions and campuses.

The system consists of a Ballerina REST API backend and a Ballerina command-line client. Communication between the client and server takes place through HTTP/REST. Assets are stored using a Ballerina Map/Table, with `assetTag` as the unique identifier.

### Ballerina Version Note

Question 1 was developed and tested using **Ballerina 2201.12.9 (Swan Lake Update 12)**. This is a different Ballerina version from the one used for Question 2. The Question 1 implementation is fully functional and tested on its specified version, so the version difference does not affect the functionality of the system. The required Ballerina version should be used when building or running Question 1 to ensure compatibility.


### Main Features

**Asset Management**

* Create, view, update and delete assets
* View all assets
* Filter assets by institution and site

**Institution Management**

* Add and remove institutions
* Manage sites/campuses
* Assign assets to institutions and sites

**Schedules**

* Add, view and remove maintenance, booking and servicing schedules
* Detect overdue maintenance

**Components**

* Add and remove components belonging to complex assets

**Work Orders**

* Create, update and close work orders
* Add and remove tasks belonging to work orders

**Loaning and Booking**

* Loan and return assets
* Create, view and cancel bookings
* Prevent conflicting bookings

### Client

The Ballerina client provides:

```text
1. Global Asset View
2. Campus / Institution View
3. Loan / Return
4. Booking
5. Overdue Dashboard
6. Schedule Manager
7. Exit
```

These correspond to the client functionality required by Question 1.

---

# Question 2: Rental Accommodation System

Question 2 is a distributed rental accommodation system using **Ballerina gRPC**.

The system manages properties, hosts, guests and bookings.

The implementation uses a `.proto` contract to define the gRPC service and messages.

### Main Operations

* Add property
* Create users using client-side streaming
* Update property
* Remove property
* List available properties using server-side streaming
* Search for a property
* Book a property
* Confirm a booking

The server maintains property and booking state using Ballerina maps or tables and performs validation such as date-overlap checking and booking cost calculation.

---

# Technologies

| Component                | Technology                  |
| ------------------------ | --------------------------- |
| Language                 | Ballerina                   |
| Question 1 Communication | HTTP/REST                   |
| Question 1 Database      | Ballerina Map/Table         |
| Question 1 Client        | Ballerina CLI               |
| Question 2 Communication | gRPC                        |
| Question 2 Contract      | Protocol Buffers (`.proto`) |
| Question 2 Database      | Ballerina Map/Table         |

---

# Naming Conventions

Keep identifiers consistent throughout the project.

### Asset Tags

Use:

```text
INSTITUTION-TYPE-NUMBER
```

Examples:

```text
NUST-LIB-3DP-001
NUST-LAP-001
UNAM-LAB-001
```

Asset tags must be unique.

### Components

```text
C001
C002
C003
```

### Schedules

```text
SCH-001
SCH-002
SCH-003
```

### Work Orders

```text
WO-001
WO-002
WO-003
```

### Tasks

```text
T1
T2
T3
```

### Dates

Always use:

```text
YYYY-MM-DD
```

Example:

```text
2026-09-01
```

### Asset Status

Use the existing values:

```text
AVAILABLE
LOANED_OUT
OCCUPIED
UNDER_MAINTENANCE
DISPOSED
```

### Schedule Types

```text
MAINTENANCE
BOOKING
SERVICING
```

### Work Order Status

```text
OPEN
IN_PROGRESS
CLOSED
```

Do not create alternative names for existing values.

---

# Development Rules

Keep new features consistent with the existing project.

1. Check whether functionality already exists before adding a new endpoint or function.
2. Follow the existing naming and API structure.
3. Keep backend and client field names consistent.
4. Validate invalid, duplicate and conflicting requests.
5. Test new features before committing.
6. Avoid unnecessary technologies or changes outside the assignment requirements.
7. Keep commits focused on a specific feature.

Example commit:

```text
implement schedule manager client
```

Before pushing:

```bash
git status
git pull --rebase origin main
git push origin main
```

---

# Project Scope

Question 1 focuses on the **RESTful library and resource management system**.

Question 2 focuses on the **gRPC rental accommodation system**.

Both questions use Ballerina, but they demonstrate different distributed communication approaches required by the assignment.
The goal is to keep the implementation simple, consistent and easy for every group member to understand and defend.
