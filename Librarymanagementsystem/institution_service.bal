import ballerina/http;


type InstitutionInput record {|
    string name;
    string location;
|};

service /institutions on apiListener {


    resource function get .() returns Institution[] {
        return institutions.toArray();
    }

    resource function get [string id]() returns Institution|http:NotFound {
        Institution? found = institutions[id];
        if found is Institution {
            return found;
        }
        return http:NOT_FOUND;
    }

    resource function post .(@http:Payload InstitutionInput input) returns Institution {
        string newId = nextInstitutionId();
        Institution newInstitution = {
            id: newId,
            name: input.name,
            location: input.location
        };
        institutions[newId] = newInstitution;
        return newInstitution;
    }

    resource function put [string id](@http:Payload InstitutionInput input) returns Institution|http:NotFound {
        if !institutions.hasKey(id) {
            return http:NOT_FOUND;
        }
        Institution updated = {
            id: id,
            name: input.name,
            location: input.location
        };
        institutions[id] = updated;
        return updated;
    }
    resource function delete [string id]() returns http:Ok|http:NotFound {
        if !institutions.hasKey(id) {
            return http:NOT_FOUND;
        }
        _ = institutions.remove(id);
        return http:OK;
    }
}