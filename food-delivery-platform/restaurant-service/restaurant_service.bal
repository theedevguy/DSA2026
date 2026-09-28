import ballerina/http;
import ballerina/uuid;

listener http:Listener restaurantListener = new (8083);

type RestaurantInput record {|
    string name;
    string location;
    string openingTime;
    string closingTime;
    MenuItem[] menu = [];
|};

type RestaurantUpdate record {|
    string name;
    string location;
    string openingTime;
    string closingTime;
|};

type MenuItemUpdate record {|
    string name;
    float price;
    int stock;
|};

function findRestaurants(map<json> filter) returns Restaurant[]|error {
    stream<Restaurant, error?> result = check restaurantsCollection->find(filter);
    return from Restaurant r in result select r;
}

service /restaurants on restaurantListener {

    // POST /restaurants - register a restaurant (optionally with a starting menu)
    resource function post .(@http:Payload RestaurantInput input) returns Restaurant|error {
        Restaurant newRestaurant = {
            restaurantId: uuid:createType4AsString(),
            name: input.name,
            location: input.location,
            openingTime: input.openingTime,
            closingTime: input.closingTime,
            menu: input.menu
        };
        check restaurantsCollection->insertOne(newRestaurant);
        return newRestaurant;
    }

    // GET /restaurants - list all
    resource function get .() returns Restaurant[]|error {
        return findRestaurants({});
    }

    // GET /restaurants/{id}
    resource function get [string id]() returns Restaurant|http:NotFound|error {
        Restaurant[] matches = check findRestaurants({restaurantId: id});
        if matches.length() == 0 {
            return http:NOT_FOUND;
        }
        return matches[0];
    }

    // PUT /restaurants/{id} - update details and opening hours
    resource function put [string id](@http:Payload RestaurantUpdate input) returns Restaurant|http:NotFound|error {
        Restaurant[] matches = check findRestaurants({restaurantId: id});
        if matches.length() == 0 {
            return http:NOT_FOUND;
        }
        _ = check restaurantsCollection->updateOne({restaurantId: id}, {set: {name: input.name, location: input.location, openingTime: input.openingTime, closingTime: input.closingTime}});
        Restaurant updated = matches[0];
        updated.name = input.name;
        updated.location = input.location;
        updated.openingTime = input.openingTime;
        updated.closingTime = input.closingTime;
        return updated;
    }

    // POST /restaurants/{id}/menu - add a menu item
    resource function post [string id]/menu(@http:Payload MenuItem item) returns Restaurant|http:NotFound|http:BadRequest|error {
        Restaurant[] matches = check findRestaurants({restaurantId: id});
        if matches.length() == 0 {
            return http:NOT_FOUND;
        }
        Restaurant existing = matches[0];
        foreach MenuItem m in existing.menu {
            if m.itemId == item.itemId {
                return <http:BadRequest>{body: string `Menu item ${item.itemId} already exists.`};
            }
        }
        MenuItem[] newMenu = [...existing.menu, item];
        _ = check restaurantsCollection->updateOne({restaurantId: id}, {set: {menu: newMenu}});
        existing.menu = newMenu;
        return existing;
    }

    // PUT /restaurants/{id}/menu/{itemId} - update name, price or stock
    resource function put [string id]/menu/[string itemId](@http:Payload MenuItemUpdate input) returns Restaurant|http:NotFound|error {
        Restaurant[] matches = check findRestaurants({restaurantId: id});
        if matches.length() == 0 {
            return http:NOT_FOUND;
        }
        Restaurant existing = matches[0];
        boolean found = false;
        MenuItem[] newMenu = [];
        foreach MenuItem m in existing.menu {
            if m.itemId == itemId {
                found = true;
                newMenu.push({itemId: itemId, name: input.name, price: input.price, stock: input.stock});
            } else {
                newMenu.push(m);
            }
        }
        if !found {
            return http:NOT_FOUND;
        }
        _ = check restaurantsCollection->updateOne({restaurantId: id}, {set: {menu: newMenu}});
        existing.menu = newMenu;
        return existing;
    }

    // DELETE /restaurants/{id}/menu/{itemId}
    resource function delete [string id]/menu/[string itemId]() returns Restaurant|http:NotFound|error {
        Restaurant[] matches = check findRestaurants({restaurantId: id});
        if matches.length() == 0 {
            return http:NOT_FOUND;
        }
        Restaurant existing = matches[0];
        MenuItem[] newMenu = existing.menu.filter(function(MenuItem m) returns boolean {
            return m.itemId != itemId;
        });
        if newMenu.length() == existing.menu.length() {
            return http:NOT_FOUND;
        }
        _ = check restaurantsCollection->updateOne({restaurantId: id}, {set: {menu: newMenu}});
        existing.menu = newMenu;
        return existing;
    }
}