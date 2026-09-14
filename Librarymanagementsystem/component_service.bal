import ballerina/http;

type ComponentInput record {|
    string assetId;
    string name;
    string description;
    string status;
|};

type ScheduleInput record {|
    string assetId;
    string scheduleType; // "Booking" | "Servicing"
    string startDateTime;
    string endDateTime;
    string requestedBy;
    string purpose;
|};

service /components on apiListener {

    resource function get .(string? assetId) returns Component[] {
        Component[] result = components.toArray();
        if assetId is string {
            string aid = assetId;
            result = result.filter(function(Component c) returns boolean {
                return c.assetId == aid;
            });
        }
        return result;
    }

    resource function get [string id]() returns Component|http:NotFound {
        Component? found = components[id];
        if found is Component {
            return found;
        }
        return http:NOT_FOUND;
    }

    resource function post .(@http:Payload ComponentInput input) returns Component|http:BadRequest {
        if !assets.hasKey(input.assetId) {
            return <http:BadRequest>{body: string `No such asset: ${input.assetId}`};
        }
        string newId = nextComponentId();
        Component newComponent = {
            id: newId,
            assetId: input.assetId,
            name: input.name,
            description: input.description,
            status: input.status
        };
        components[newId] = newComponent;
        return newComponent;
    }

    resource function put [string id](@http:Payload ComponentInput input) returns Component|http:NotFound {
        if !components.hasKey(id) {
            return http:NOT_FOUND;
        }
        Component updated = {
            id: id,
            assetId: input.assetId,
            name: input.name,
            description: input.description,
            status: input.status
        };
        components[id] = updated;
        return updated;
    }

    resource function delete [string id]() returns http:Ok|http:NotFound {
        if !components.hasKey(id) {
            return http:NOT_FOUND;
        }
        _ = components.remove(id);
        return http:OK;
    }
}

service /schedules on apiListener {

    resource function get .(string? assetId) returns ScheduleEntry[] {
        ScheduleEntry[] result = schedules.toArray();
        if assetId is string {
            string aid = assetId;
            result = result.filter(function(ScheduleEntry s) returns boolean {
                return s.assetId == aid;
            });
        }
        return result;
    }

    resource function get [string id]() returns ScheduleEntry|http:NotFound {
        ScheduleEntry? found = schedules[id];
        if found is ScheduleEntry {
            return found;
        }
        return http:NOT_FOUND;
    }

    resource function post .(@http:Payload ScheduleInput input) returns ScheduleEntry|http:BadRequest {
        if !assets.hasKey(input.assetId) {
            return <http:BadRequest>{body: string `No such asset: ${input.assetId}`};
        }
        string newId = nextScheduleId();
        ScheduleEntry newEntry = {
            id: newId,
            assetId: input.assetId,
            scheduleType: input.scheduleType,
            startDateTime: input.startDateTime,
            endDateTime: input.endDateTime,
            requestedBy: input.requestedBy,
            purpose: input.purpose
        };
        schedules[newId] = newEntry;
        return newEntry;
    }

    resource function put [string id](@http:Payload ScheduleInput input) returns ScheduleEntry|http:NotFound {
        if !schedules.hasKey(id) {
            return http:NOT_FOUND;
        }
        ScheduleEntry updated = {
            id: id,
            assetId: input.assetId,
            scheduleType: input.scheduleType,
            startDateTime: input.startDateTime,
            endDateTime: input.endDateTime,
            requestedBy: input.requestedBy,
            purpose: input.purpose
        };
        schedules[id] = updated;
        return updated;
    }

    resource function delete [string id]() returns http:Ok|http:NotFound {
        if !schedules.hasKey(id) {
            return http:NOT_FOUND;
        }
        _ = schedules.remove(id);
        return http:OK;
    }
}
