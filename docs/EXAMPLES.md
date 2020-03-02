# Examples

## Complexity
The examples are divided into levels of complexity:

+ Level `0` - The null service; does nothing useful.
+ Level `1` - A *synchronous* data capture and response; for low-latency data sources only.
+ Level `2` - An *asynchronous* data capture and response; data is captured independently of request for data; polls source
+ Level `3` - A service which performs analysis of data at edge; e.g. AI inferencing
+ Level `4` - A service which combines other services (i.e. `requiredServices`); also deployable as _pattern_
+ Level `5` - More than one service interoperating within a _pattern_ 
+ Level `6` - Service(s) inter-operating on more than one node.
+ Level `7` - Service -AAS for other nodes (e.g. `couchdb`)
+ Level `8` - Multi-pattern composition (i.e. _application_)



## Example services
Below is a listing of services. Services denoted in *italic* are either WIP or TBD.

Level|Type|Services|Port|Expose|Shared|Description
---|---|---|---|---|---|---|
0|service|[`hello`](../hello)|80|||the minimum "hello world" example; output `{"hello":"world"}` using `socat`
1| service |[`cpu`](../cpu)|80|||synchronous ReStFul service from low-latency data source
2| service |[`wan`](../wan)|80|||asynchronously updating long-latency data source, i.e. wide-area-network monitor
2| service |[`hal`](../hal)|80|||hardware abstraction layer (device capabilities, serial #, etc..)
2|service|[`herald`](../herald)|80, 5959, 5960|5959, 5960||Listen & broadcast on LAN; **Python** `Flask` example
2| *service* |[`record`](../record)|80|||poll microphone and record sound bits; default `5` seconds every `10` seconds
2| *service* |[`fft`](../fft)|80|||capture output from `record` and perform anomaly detection
3| service |[`yolo`](../yolo)|80|||capture image from webcam, detect & classify entities ([darknet](https://pjreddie.com/darknet/)
3| service |[`mqtt`](../mqtt)|80, 1883|1883|X|provide on-device MQTT broker; shared across services
3|*service*|[`herald4pattern`](../herald4pattern)|80, 5959, 5960|5959, 5960||announce the _pattern_ information for the node
4|service|[`yolo2msghub`](../yolo2msghub)|8587|8587||integrate multiple service outputs and send to cloud using Kafka
||+|`cpu`|
||+|`hal`| 
||+|`wan` |
||+|`yolo` |
5| *service* |[`fft4mqtt`](../fft)|80|||process input `mqtt`; perform analysis; post `mqtt`
||+|`mqtt`
4|service |[`yolo4motion`](../yolo4motion)|80|||modified from `yolo` to listen via MQTT to `motion`
||+|`mqtt`
4|service|[`mqtt2kafka`](../mqtt2kafka)|80|||route specified MQTT topics' payloads to Kafka broker
||+|`mqtt`
5 |service|[`motion2mqtt`](../motion2mqtt)|8080, 8081, 8082|8082||capture images using [motion package](https://motion-project.github.io/); send to MQTT
||+|`mqtt`|80, 1883|1883|X|
||+|`hal`|80|||to detect camera
||+|`wan`|80|||to monitor Internet
||+|`cpu`|80|||to monitor CPU load
||service|`yolo4motion`|80|
||+|`mqtt`|80, 1883|1883|X|
5|*service*|[`noize`](../noize)|9191|9191||capture audio after silence and send to MQTT broker
||+|`mqtt`|
4|*service* |[`noize-filter`](../noize-filter)|
||+|`mqtt`
||+|`fft4noize`
6|*service*|[`noize-analysis`](../analysis4fft)|
||+|`fft4noize`|
||+|`fft2mqtt`|
||+|`mqtt`|||X|
||+|`nosqldb`|||x|
||service|`mqtt2kafka`||||route specified MQTT topics' payloads to cloud
||+|mqtt|||X|
7|*service* |[`nosqldb`](../nosqldb)||||noSQL repository; see  [**CouchDB**](http://couchdb.apache.org/)
7|*service*|`grafana`||3306||Graphical analysis; see [**InfluxDB**](https://github.com/influxdata/influxdb)
7|*service*|`influxdb`||8086||Time-series database; see [**Grafana**](https://grafana.com/)
7|*service*|`motion-control`|80|8080, 8081, 8082||Provide control infrastructure for `motion` configuration
||+|`mqtt`|80|81, 1883|X||MQTT broker
||+|`cpu`|80|81, 1883|X||CPU monitor
||+|`hal`|80|81, 1883|X||hardware monitor
||+|`wan`|80|81, 1883|X||Internet monitor
||+|`herald4pattern`|80, 5959, 5960|5959, 5960||Herald of services in _pattern_
7|*service*|`gateway`|80|80|||Web UX for _application_: motion and entity detection and classification
||+|`couchdb`|80|<STD>|X||CouchDB service with replication to/from IBM Cloudant
||+|`mqtt`|80|81, 1883|X||MQTT broker
||+|`cpu`|80|81, 1883|X||CPU monitor
||+|`hal`|80|81, 1883|X||hardware monitor
||+|`wan`|80|81, 1883|X||Internet monitor
||+|`herald4pattern`|80, 5959, 5960|5959, 5960||Herald of services in _pattern_
||+|`mqtt2kafka`|80||X||MQTT to Kafka relay
8|service|`gw4motion`|NA|NA||`gateway` supporting `yolo4motion`
||+|`cpu`|80|81, 1883|X||CPU monitor
||+|`wan`|80|||to monitor Internet
||+|`hal`|80|81, 1883|X||hardware monitor
||+|`nosqldb`|
||service|`mqtt2kafka`|
||+|`mqtt`|
||service|+|`herald4pattern`|80, 5959, 5960|5959, 5960||Herald of services in _pattern_

## Example patterns

Level|Type|Services|Port|Expose|Description
---|---|---|---|---|---|
4|pattern|[`yolo2msghub`](../yolo2msghub)|||poll USB camera image; detect "person" using [`YOLO`](https://pjreddie.com/darknet/yolo/) on _node_; send composite services' data to Kafka.
||service|`yolo2msghub`|80|8587
||+|`cpu`|80
||+|`hal`|80
||+|`wan` |80
||+|`yolo` |80
6|pattern|[`motion-detect`](../motion-detect)|||detect motion with [motion](https://motion-project.github.io/) from USB or other camera(s); classify with [`YOLO`](https://pjreddie.com/darknet/yolo/); send results to non-local MQTT broker (n.b. see `motion-control`)
||service|`motion2mqtt`|8080, 8081, 8082|8080, 8081, 8082||
||+|`mqtt`|80, 1883|1883||
||+|`hal`|80|||
||+|`cpu`|80|||
||service|`yolo4motion`|80|
||service|`mqtt2mqtt`|80||Relay selected local topics to master
||service|`herald4pattern`|80|||
8|pattern|[`motion-control`](../motion-control)|||monitor and control fleet of devices running `motion-detect` pattern; receive MQTT payloads of latest images, GIF animations, classified selected entity(s); aggregate locally and provide Web analysis dashboad
||+|`mqtt`|80, 1883|1883|Master MQTT broker
||+|`hal`|80|||
||+|`wan`|80|||
||+|`cpu`|80|||
||service|`nosqldb`|
||service|`grafana`|
||service|`influxdb`|
||service|`motion-control`|80|80|
||service|`herald4pattern`|80|||
||service|`mqtt2kafka`|
