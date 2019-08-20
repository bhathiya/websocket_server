import ballerina/log;
import ballerina/http;
import ballerina/math;
import ballerina/system;
import ballerina/io;

const string UUID = "UUID";
const string UNSUBSCRIBED = "UNSUBSCRIBED";

// In-memory map to save the subscriptions (subscribed resource -> array of subscribers )
map<http:WebSocketCaller[]> subscriptions = {};
// In-memory map to save the notifications
map<json> notificationMap = {};

@http:ServiceConfig {
    basePath: "/backend",
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowMethods: ["GET","POST","PUT"]
    }
}
service NotificationAppUpgrader on new http:Listener(9090) {

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/notificationmanager/notifications/{notificationId}"
    }
    resource function getNotification(http:Caller caller, http:Request req, string notificationId) {
        json? notific = notificationMap[notificationId];
        http:Response response = new;
        if (notific == null) {
            log:printError("Notification : " + notificationId + " cannot be found.");
            response.statusCode = 404;
            response.setJsonPayload({status:"error"});
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
        }

        json res = {status:"ok", data: notific};
 
        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(untaint res);

        // Send response to the client.
        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }

    @http:ResourceConfig {
        methods: ["GET"],
        path: "/notificationmanager/notifications"
    }
    resource function getAllNotifications(http:Caller caller, http:Request req) {
        http:Response response = new;

        json data = [];
        var k = 0;
        foreach var (i, j) in notificationMap {
            data[k] = j;
            k = k + 1;
        }

        json payload = {status:"ok", data: data};

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(untaint payload);

        // Send response to the client.
        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }

        @http:ResourceConfig {
        methods: ["POST"],
        path: "/notificationmanager/notifications"
    }
    resource function addNotification(http:Caller caller, http:Request req) {
        http:Response response = new;
        var payload = req.getJsonPayload();
        if (payload is json) {
            string id = system:uuid();
            json jsonPayload = payload;
            jsonPayload.id = id;
            jsonPayload.url = "https://localhost:9090/notifications/" + id;
            notificationMap[id] = jsonPayload;

            json data = [];
            var k = 0;
            foreach var (i, j) in notificationMap {
                data[k] = j;
                k = k + 1;
            }
            json broadcastMsg = {"type":"data", "data": data, "event":"/notificationmanager/notifications/", "status":"ok"};
            broadcast(broadcastMsg,  "/notificationmanager/notifications/");

            // Create response message.
            json res = { status: "ok" };
            response.setJsonPayload(untaint res);
            response.setHeader("Location", "/notifications/" + id);
            response.statusCode = 201;

            // Send response to the client.
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
        } else {
            response.statusCode = 400;
            response.setPayload("Invalid payload received");
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
        }
    }

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/notificationmanager/notifications/{notificationId}"
    }
    resource function updateSpeedAndLockState(http:Caller caller, http:Request req, string notificationId) {
        json res = {status:"ok"};
        http:Response response = new;
        var reqPayload = req.getJsonPayload();
        json jsonPayload = {};
        string locked = "locked";
        int speed = 10;
        if (reqPayload is json) {
            jsonPayload = reqPayload;
            // Find the requested order from the map and retrieve it in JSON format.
            json payload = notificationMap[notificationId];
            if (payload == null) {
                locked = jsonPayload.lockState==null ? "locked" : jsonPayload.lockState.toString();
                speed = jsonPayload.speed==null ? 10 : <int> jsonPayload.speed;
                payload = {"name":"placeholder", "id":notificationId, "title":"Here you go", 
                "uri":"/notificationmanager/notifications/" + notificationId, "content":"no new content given",
                "lockState":locked, "speed":speed};
            } else {
                locked = jsonPayload.lockState==null ? payload.lockState.toString() : jsonPayload.lockState.toString();
                speed = jsonPayload.speed==null ? <int> payload.speed : <int> jsonPayload.speed;
                payload.lockState = locked;
                payload.speed = speed;
            }
            notificationMap[notificationId] = payload;
            json broadcastMsg = {"status": "ok", "type": "data", "event":"/notificationmanager/notifications/" 
                + notificationId, "data": payload};

            broadcast(broadcastMsg,  "/notificationmanager/notifications/" + notificationId);

            res = {status:"ok"};
        } else {
            res = {status:"error"};
        }

        // Set the JSON payload in the outgoing response message.
        response.setJsonPayload(untaint res);

        // Send response to the client.
        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }

    @http:ResourceConfig {
        methods: ["PUT"],
        path: "/notificationmanager/notifications/{notificationId}"
    }
    resource function updateNotification(http:Caller caller, http:Request req, string notificationId) {
        var updatedNotification = req.getJsonPayload();
        http:Response response = new;
        if (updatedNotification is json) {
            // Find the notification that needs to be updated and retrieve it in JSON format.
            json existingNotification = notificationMap[notificationId];

            json res;

            // Updating existing notification with the attributes of the updated notification.
            if (existingNotification != null) {
                updatedNotification.id = notificationId;
                updatedNotification.url = "https://localhost:9090/notifications/" + notificationId;
                notificationMap[notificationId] = updatedNotification;

                json broadcastMsg = {"type":"data", "data": updatedNotification, "event":"/notificationmanager/notifications/", "status":"ok"};
                broadcast(broadcastMsg, "/notificationmanager/notifications/" + notificationId);    

                res = {status:"ok"};
            } else {
                res = {status:"error"};
            }
            // Set the JSON payload to the outgoing response message to the client.
            response.setJsonPayload(untaint res);
            // Send response to the client.
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
        } else {
            response.statusCode = 400;
            response.setPayload("Invalid payload received");
            var result = caller->respond(response);
            if (result is error) {
                log:printError("Error sending response", err = result);
            }
        }
    }

    @http:ResourceConfig {
        methods: ["DELETE"],
        path: "/notificationmanager/notifications/{notificationId}"
    }
    resource function removeNotification(http:Caller caller, http:Request req, string notificationId) {
        http:Response response = new;
        // Remove the requested notification from the map.
        _ = notificationMap.remove(notificationId);

        json payload = {status:"ok"};
        response.setJsonPayload(untaint payload);

        json data = [];
        var k = 0;
        foreach var (i, j) in notificationMap {
            data[k] = j;
            k = k + 1;
        }
        json broadcastMsg = {"type":"data", "data": data, "event":"/notificationmanager/notifications/", "status":"ok"};
        broadcast(broadcastMsg,  "/notificationmanager/notifications/");

        // Send response to the client.
        var result = caller->respond(response);
        if (result is error) {
            log:printError("Error sending response", err = result);
        }
    }

    // Resource to upgrade from HTTP to WebSocket
    @http:ResourceConfig {
        webSocketUpgrade: {
            upgradePath: "/",
            upgradeService: ChatApp
        }
    }
    resource function upgrader(http:Caller caller, http:Request req) {
        map<string> headers = {};
        http:WebSocketCaller wsEp = caller->acceptWebSocketUpgrade(headers);
        wsEp.attributes[UUID] = system:uuid();
        log:printInfo("A new clinet connected! UUID: " + <string> wsEp.attributes[UUID]);
    }
}


service ChatApp =  @http:WebSocketServiceConfig service {

    // This resource will trigger when a new text message arrives to the chat server
    resource function onText(http:WebSocketCaller caller, string text) {
        log:printInfo(text);
        // Prepare the message
        io:StringReader sr = new(text, encoding = "UTF-8");
        json msg = {};
        json|error ret = sr.readJson();
        if (ret is error) {
            return;
        } else { 
            msg = ret;
        }
        //subscribe
        if(msg["type"] !== null && msg["event"] !==null && msg["type"].toString() == "subscribe") {
            string event = msg["event"].toString();
            json res = {"status":"ok", "type":"subscribe", "event": event};
            var err = caller->pushText(res.toString());
            if (err is error) {
                log:printError("Error sending message", err = err);
            }
            http:WebSocketCaller[]? subscribers = subscriptions[event];
        
            if (subscribers is ()) {
                http:WebSocketCaller[] subs = [];
                subs[0] = caller;
                subscriptions[event] = subs;  
            } else {
                subscribers[subscribers.length()] = caller;
            } 

            msg = <json> ret;
            json data = [];
            if (event == "/notificationmanager/notifications/"){
                var k = 0;
                foreach var (i, j) in notificationMap {
                    data[k] = j;
                    k = k + 1;
                }   
            } else {
                string id = event.split("/notificationmanager/notifications/")[1];
                data = notificationMap[id];
            }
            
            json res2 = {"status":"ok", "type":"data", "event": event, "data": data};
            err = caller->pushText(res2.toString());
            if (err is error) {
                log:printError("Error sending data", err = err);
            }   
            log:printInfo("Subcsribed: " + <string> getAttributeStr(caller, UUID) + " to: " + event);
        } 

        //unsubscribe
        if(msg["type"] !== null && msg["event"] !== null && msg["type"].toString() == "unsubscribe") {
            unsubscribe(caller, msg["event"].toString());
            json res2 = {"status":"ok"};
            error? err = caller->pushText(res2.toString());
            if (err is error) {
                log:printError("Error sending data", err = err);
            } 
        }        
    }

    // This resource will trigger when a existing connection closes
    resource function onClose(http:WebSocketCaller caller, int statusCode, string reason) {
        unsubscribeFromAll(caller);
        log:printInfo("Disconnected: " + <string> getAttributeStr(caller, UUID));
    }
};

//Unsubcribe the caller from all events
function unsubscribeFromAll(http:WebSocketCaller caller){
    foreach string event in subscriptions.keys() {
        unsubscribe(caller, event);
    }
}

//Unsubcribe the caller from a given event
function unsubscribe(http:WebSocketCaller caller, string event){
    string uuid = <string> getAttributeStr(caller, UUID);
    http:WebSocketCaller[]? subscribers = subscriptions[event];
    if (subscribers is http:WebSocketCaller[]) {
        // Iterate through all available subscriptions for each event
        foreach http:WebSocketCaller subscriber in subscribers {
            // Remove subscriber
            if(<string> getAttributeStr(subscriber, UUID) == uuid) {
                subscriber.attributes[UNSUBSCRIBED] = "true"; 
                log:printInfo("Unsubcsribed: " + <string> getAttributeStr(subscriber, UUID) + " from: " + event);   
            }
        }
    }
}

// Send the text to all subscriptions in the subscriptions map
function broadcast(json text, string event) { 

    http:WebSocketCaller[]? subscribers = subscriptions[event];

    if(subscribers is http:WebSocketCaller[]) {
        // Iterate through all available subscriptions in the subscriptions map
        foreach http:WebSocketCaller subscriber in subscribers {
            // Push the event message to the subscriber
            string? unsubscribed = getAttributeStr(subscriber, UNSUBSCRIBED);
            string uuid = <string> getAttributeStr(subscriber, UUID);
            if (unsubscribed is () || unsubscribed !== "true"){
                log:printInfo("Publishing to subcsriber: " + uuid);
                var err = subscriber->pushText(text.toString());
                if (err is error) {
                    log:printError("Error sending message", err = err);
                }
            } else {
                log:printInfo("Not publishing to unsubcsriber: " + uuid);        
            }
        }
    }
}

// Gets attribute for given key from a WebSocket endpoint
function getAttributeStr(http:WebSocketCaller ep, string key) returns (string|()) {
    return <string?>ep.attributes[key];
}