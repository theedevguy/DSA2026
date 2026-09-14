import ballerina/http;
import ballerina/time;

type AssetInput record {|
    string name;
    string description;
    string category;
    string institutionId;
    string site;
    string status;
    string maintenanceDueDate;
    string dateAcquired;
|};

function todayDate() returns string {
    time:Utc now = time:utcNow();
    string nowStr = time:utcToString(now);
    return nowStr.substring(0, 10);
}

// --- View types for the nested "full" representation only ---

type ComponentView record {|
    string compId;
    string name;
    string description;
|};

type ScheduleView record {|
    string scheduleId;
    string 'type;
    string dueDate;
    string description;
|};

type WorkOrderTaskView record {|
    string taskId;
    string description;
|};

type WorkOrderView record {|
    string orderId;
    string status;
    string description;
    WorkOrderTaskView[] tasks;
|};

type AssetFullView record {|
    string assetTag;
    string name;
    string description;
    string institution;
    string site;
    string status;
    string dateAcquired;
    ComponentView[] components;
    ScheduleView[] schedules;
    WorkOrderView[] workOrders;
|};

service /assets on apiListener {

    resource function get .(string? institutionId, string? category, boolean? overdue) returns Asset[] {
        Asset[] result = assets.toArray();

        if institutionId is string {
            string instId = institutionId;
            result = result.filter(function(Asset a) returns boolean {
                return a.institutionId == instId;
            });
        }
        if category is string {
            string cat = category;
            result = result.filter(function(Asset a) returns boolean {
                return a.category == cat;
            });
        }
        if overdue is boolean && overdue {
            string today = todayDate();
            result = result.filter(function(Asset a) returns boolean {
                return a.maintenanceDueDate < today;
            });
        }
        return result;
    }

    resource function get [string assetTag]() returns Asset|http:NotFound {
        Asset? found = assets[assetTag];
        if found is Asset {
            return found;
        }
        return http:NOT_FOUND;
    }

    // GET /assets/{assetTag}/full — nested view matching the marking grid's example
    resource function get [string assetTag]/full() returns AssetFullView|http:NotFound {
        Asset? found = assets[assetTag];
        if found is () {
            return http:NOT_FOUND;
        }
        Asset asset = found;

        string institutionName = "Unknown institution";
        Institution? inst = institutions[asset.institutionId];
        if inst is Institution {
            institutionName = inst.name;
        }

        ComponentView[] compViews = components.toArray()
            .filter(function(Component c) returns boolean {
            return c.assetId == assetTag;
        })
            .map(function(Component c) returns ComponentView {
            return {compId: c.id, name: c.name, description: c.description};
        });

        ScheduleView[] schedViews = schedules.toArray()
            .filter(function(ScheduleEntry s) returns boolean {
            return s.assetId == assetTag;
        })
            .map(function(ScheduleEntry s) returns ScheduleView {
            string viewType = s.scheduleType == "Servicing" ? "MAINTENANCE" : "BOOKING";
            string dueDateValue = s.startDateTime.length() >= 10 ? s.startDateTime.substring(0, 10) : s.startDateTime;
            return {
                scheduleId: s.id,
                'type: viewType,
                dueDate: dueDateValue,
                description: s.purpose
            };
        });

        WorkOrderView[] woViews = workOrders.toArray()
            .filter(function(WorkOrder w) returns boolean {
            return w.assetId == assetTag;
        })
            .map(function(WorkOrder w) returns WorkOrderView {
            WorkOrderTaskView[] taskViews = w.tasks.map(function(WorkOrderTask t) returns WorkOrderTaskView {
                return {taskId: t.id, description: t.description};
            });
            return {
                orderId: w.id,
                status: w.status.toUpperAscii(),
                description: w.description,
                tasks: taskViews
            };
        });

        AssetFullView view = {
            assetTag: asset.assetTag,
            name: asset.name,
            description: asset.description,
            institution: institutionName,
            site: asset.site,
            status: asset.status.toUpperAscii(),
            dateAcquired: asset.dateAcquired,
            components: compViews,
            schedules: schedViews,
            workOrders: woViews
        };
        return view;
    }

    resource function post .(@http:Payload AssetInput input) returns Asset {
        string newTag = nextAssetTag();
        Asset newAsset = {
            assetTag: newTag,
            name: input.name,
            description: input.description,
            category: input.category,
            institutionId: input.institutionId,
            site: input.site,
            status: input.status,
            maintenanceDueDate: input.maintenanceDueDate,
            dateAcquired: input.dateAcquired
        };
        assets[newTag] = newAsset;
        return newAsset;
    }

    resource function put [string assetTag](@http:Payload AssetInput input) returns Asset|http:NotFound {
        if !assets.hasKey(assetTag) {
            return http:NOT_FOUND;
        }
        Asset updated = {
            assetTag: assetTag,
            name: input.name,
            description: input.description,
            category: input.category,
            institutionId: input.institutionId,
            site: input.site,
            status: input.status,
            maintenanceDueDate: input.maintenanceDueDate,
            dateAcquired: input.dateAcquired
        };
        assets[assetTag] = updated;
        return updated;
    }

    resource function delete [string assetTag]() returns http:Ok|http:NotFound {
        if !assets.hasKey(assetTag) {
            return http:NOT_FOUND;
        }
        _ = assets.remove(assetTag);
        return http:OK;
    }
}
