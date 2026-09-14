
public type Institution record {|
    string id;
    string name;
    string location;
|};

public type Asset record {|
    string assetTag;
    string name;
    string description;
    string category;
    string institutionId;
    string site;
    string status;
    string maintenanceDueDate;
    string dateAcquired;
|};

public type Component record {|
    string id;
    string assetId;
    string name;
    string description;
    string status;
|};

public type ScheduleEntry record {|
    string id;
    string assetId;
    string scheduleType;
    string startDateTime;
    string endDateTime;
    string requestedBy;
    string purpose;
|};

public type WorkOrderTask record {|
    string id;
    string description;
    string status;
|};

public type WorkOrder record {|
    string id;
    string assetId;
    string description;
    string status;
    string createdDate;
    WorkOrderTask[] tasks;
|};
