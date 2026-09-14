import ballerina/http;

type WorkOrderInput record {|
    string assetId;
    string description;
|};

type WorkOrderUpdate record {|
    string description;
    string status; 
|};

type TaskInput record {|
    string description;
|};

type TaskUpdate record {|
    string description;
    string status; 
|};

service /workorders on apiListener {

    resource function get .(string? assetId, string? status) returns WorkOrder[] {
        WorkOrder[] result = workOrders.toArray();

        if assetId is string {
            string aid = assetId;
            result = result.filter(function(WorkOrder w) returns boolean {
                return w.assetId == aid;
            });
        }
        if status is string {
            string st = status;
            result = result.filter(function(WorkOrder w) returns boolean {
                return w.status == st;
            });
        }
        return result;
    }

    resource function get [string id]() returns WorkOrder|http:NotFound {
        WorkOrder? found = workOrders[id];
        if found is WorkOrder {
            return found;
        }
        return http:NOT_FOUND;
    }

    resource function post .(@http:Payload WorkOrderInput input) returns WorkOrder|http:BadRequest {
        if !assets.hasKey(input.assetId) {
            return <http:BadRequest>{body: string `No such asset: ${input.assetId}`};
        }
        string newId = nextWorkOrderId();
        WorkOrder newOrder = {
            id: newId,
            assetId: input.assetId,
            description: input.description,
            status: "Open",
            createdDate: todayDate(),
            tasks: []
        };
        workOrders[newId] = newOrder;
        return newOrder;
    }

    resource function put [string id](@http:Payload WorkOrderUpdate input) returns WorkOrder|http:NotFound {
        WorkOrder? existing = workOrders[id];
        if existing is () {
            return http:NOT_FOUND;
        }
        WorkOrder updated = {
            id: id,
            assetId: existing.assetId,
            description: input.description,
            status: input.status,
            createdDate: existing.createdDate,
            tasks: existing.tasks
        };
        workOrders[id] = updated;
        return updated;
    }

    resource function delete [string id]() returns http:Ok|http:NotFound {
        if !workOrders.hasKey(id) {
            return http:NOT_FOUND;
        }
        _ = workOrders.remove(id);
        return http:OK;
    }

    resource function post [string id]/tasks(@http:Payload TaskInput input) returns WorkOrder|http:NotFound {
        WorkOrder? existing = workOrders[id];
        if existing is () {
            return http:NOT_FOUND;
        }
        WorkOrderTask newTask = {
            id: nextTaskId(),
            description: input.description,
            status: "Pending"
        };
        WorkOrder updated = {
            id: existing.id,
            assetId: existing.assetId,
            description: existing.description,
            status: existing.status,
            createdDate: existing.createdDate,
            tasks: [...existing.tasks, newTask]
        };
        workOrders[id] = updated;
        return updated;
    }


    resource function put [string id]/tasks/[string taskId](@http:Payload TaskUpdate input) returns WorkOrder|http:NotFound {
        WorkOrder? existing = workOrders[id];
        if existing is () {
            return http:NOT_FOUND;
        }
        boolean taskExists = false;
        foreach WorkOrderTask t in existing.tasks {
            if t.id == taskId {
                taskExists = true;
            }
        }
        if !taskExists {
            return http:NOT_FOUND;
        }
        WorkOrderTask[] updatedTasks = existing.tasks.map(function(WorkOrderTask t) returns WorkOrderTask {
            if t.id == taskId {
                return {id: t.id, description: input.description, status: input.status};
            }
            return t;
        });
        WorkOrder updated = {
            id: existing.id,
            assetId: existing.assetId,
            description: existing.description,
            status: existing.status,
            createdDate: existing.createdDate,
            tasks: updatedTasks
        };
        workOrders[id] = updated;
        return updated;
    }

    resource function delete [string id]/tasks/[string taskId]() returns WorkOrder|http:NotFound {
        WorkOrder? existing = workOrders[id];
        if existing is () {
            return http:NOT_FOUND;
        }
        WorkOrderTask[] updatedTasks = existing.tasks.filter(function(WorkOrderTask t) returns boolean {
            return t.id != taskId;
        });
        WorkOrder updated = {
            id: existing.id,
            assetId: existing.assetId,
            description: existing.description,
            status: existing.status,
            createdDate: existing.createdDate,
            tasks: updatedTasks
        };
        workOrders[id] = updated;
        return updated;
    }
}
