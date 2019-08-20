# WebSocket/REST Server
WebSocket/REST server implementation with Ballerina

## Start server
    $ ballerina run ws_server.bal

## REST endpoints
 GET		http://localhost:9090/backend/notificationmanager/notifications<br>
 POST	  http://localhost:9090/backend/notificationmanager/notifications<br> 
 GET		http://localhost:9090/backend/notificationmanager/notifications/{id}<br>
 DELETE	http://localhost:9090/backend/notificationmanager/notifications/{id}<br>
 POST	  http://localhost:9090/backend/notificationmanager/notifications/{id}
 
 POST	  http://localhost:9090/backend/notificationmanager/notifications/{id}
 
 ## WebSocket endpoint
 ws://localhost:9090/backend/
 
 ## Sample requests
 
```
bhathiya@MacBookPro:/websocket_server$ wscat -c ws://localhost:9090/backend/
connected (press CTRL+C to quit)
>
> {"type":"subscribe", "event":"/notificationmanager/notifications/"}
>
< {"status":"ok", "type":"subscribe", "event":"/notificationmanager/notifications/"}
< {"status":"ok", "type":"data", "event":"/notificationmanager/notifications/", "data":[{"title":"Speed Alert", "content":"Reached 100kmph", "subtitle":"Notification", "id":"47802a98-0f49-4169-aedf-3caf67d77b6d", "url":"https://localhost:9090/notifications/47802a98-0f49-4169-aedf-3caf67d77b6d"}]}
>
> {"type":"subscribe", "event":"/notificationmanager/notifications/76802a98-0f49-4169-aedf-aaaf67d77b6v"}
>
< {"status":"ok", "type":"subscribe", "event":"/notificationmanager/notifications/76802a98-0f49-4169-aedf-aaaf67d77b6v"}
< {"status":"ok", "type":"data", "event":"/notificationmanager/notifications/76802a98-0f49-4169-aedf-aaaf67d77b6v", "data":{"name":"placeholder", "id":"76802a98-0f49-4169-aedf-aaaf67d77b6v", "title":"Here you go", "uri":"/notificationmanager/notifications/76802a98-0f49-4169-aedf-aaaf67d77b6v", "content":"no new content given", "lockState":"locked", "speed":10}}
>
> {"type":"unsubscribe", "event":"/notificationmanager/notifications/"}
>
< {"status":"ok"}
```
```
bhathiya@MacBookPro:/websocket_server$ curl -X POST http://localhost:9090/backend/notificationmanager/notifications -H "application/json" -d '{"title":"Speed Alert","content":"Reached 100kmph","subtitle":"Notification"}'
{"status":"ok"}

bhathiya@MacBookPro:/websocket_server$ curl -X POST http://localhost:9090/backend/notificationmanager/notifications/76802a98-0f49-4169-aedf-aaaf67d77b6v -H "application/json" -d '{"lockStatus":"unlocked"}'
{"status":"ok"}
```
