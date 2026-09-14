
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

public type ScheduleEntry record {|
    string id;
    string assetId;
    string scheduleType;
    string startDateTime;
    string endDateTime;
    string requestedBy;
    string purpose;
|};
