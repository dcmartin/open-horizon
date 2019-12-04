# `TESTING.md` - How to test

The primary test case is running the [`startup`](startup/README.md) [_service_](TERMINOLOGY.md#22---service), and its required services, as a [_pattern_](TERMINOLOGY.md#23---pattern) on one or more supported machines.

The `startup` service status payload (JSON) reported on port `3093` is also transmitted to Kafka using topic `startup`.  Kafka messages can be captured using the `kafkacat.sh` script in the `startup/` directory.

# Operations
There are four primary operations that may be performed on one more more _machines_:

+ _make_ - install requisite software, accounts, permissions, and register for pattern in organization on exchange
+ _clean_ - unregister, uninstall, purge, and remove _bluehorizon_ and its dependent services and containers
+ _test_ - verify software, pattern, API, and Kafka payload receipt
+ _list_ - list software, pattern, services, workloads, errors, and containers (if any)

## Logging
Log control may be specified through two environment variables:

+ `LOG_LEVEL` - the level of logging specified by keyword (see below)
+ `LOGTO` - the location of the logging output; default: `/dev/stderr` (in most instances)

Logging levels are (lowest to highest):

+ `emerg`
+ `alert`
+ `crit`
+ `error`
+ `warn`
+ `notice`
+ `info`
+ `debug`
+ `trace` 

## Single machines
These operations may be performed on either a single machine or a set. For a single machine, each operation is implemented in a script which performs the operation on a specified machine (i.e. FQDN or IP address), e.g. "127.0.0.1"; there is an optional force flag (`-f`) as well as optional _timeout_ (in seconds).

+ `make-machine.sh`
+ `clean-machine.sh`
+ `test-machine.sh`
+ `list-machine.sh`

## Multiple machines
The operations can also be performed in parallel by specifying the machines in a file named `NODES`; one machine per uncommented line.  

The corresponding scripts may also be provided with the force flag (`-f`) and _timeout_:

+ `make-machines.sh`
+ `clean-machines.sh`
+ `test-machines.sh`
+ `list-machines.sh`

The multiple-machine versions initiate the single-machine script (see above) and aggregate the output from each, one JSON result per line; a progress indicator is output to `stderr` along with any logging information above `LOG_LEVEL` as defined in the environment.  When all single-machine scripts have completed, the aggregate is summarized in JSON; each multiple-machine script will also re-process any previous aggregate and pre-produce the summary, for example:

```
./sh/list-machines.sh test.list-machines.21235.json | jq
```

```
Processing ./sh/list-machine.sh; output: test.list-machines.21235.json; nodes: 314: completed
{
  "output": "test.list-machines.21235.json",
  "total": 314,
  "offline": [],
  "nohzn": [],
  "configured": 314,
  "configuring": [],
  "unconfiguring": [],
  "unconfigured": [],
  "zero_containers": [],
  "start": "2019-07-26T17:13:39Z",
  "finish": "2019-07-26T17:13:40Z",
  "elapsed": 1
}
```

# Operation Details

## _list_
The _list_ operation on a single, or multiple, machine(s), and produce JSON output providing information on the machine, including Docker (n.b. `docker`) version and build; Open Horizon (`horizon`) edge agent and command-line versions; [`node`](TERMINOLOGY.md#21---node) status, `errors`, `workloads`, `services_urls`, and running `containers`.

For example to _list_ a single machine:

```
./sh/list-machine.sh 50.23.147.210 | jq
```

```
{
  "machine": {
    "name": "50.23.147.210",
    "ipaddr": "50.23.147.210",
    "alive": true
  },
  "docker": {
    "version": "18.09.7",
    "build": "2d0083d"
  },
  "horizon": {
    "cli": "2.23.11",
    "agent": "2.23.11"
  },
  "node": {
    "name": "startup-stg-test-vm-seattle13",
    "exchange": "https://stg.edge-fabric.com/v1/",
    "pattern": "dcmartin/startup-stg",
    "state": "configured"
  },
  "workloads": [
    {
      "url": "com.github.dcmartin.open-horizon.startup-stg",
      "org": "dcmartin",
      "version": "0.0.1",
      "arch": "amd64"
    }
  ],
  "services_urls": [
    "com.github.dcmartin.open-horizon.hal-stg",
    "com.github.dcmartin.open-horizon.wan-stg",
    "com.github.dcmartin.open-horizon.startup-stg",
    "com.github.dcmartin.open-horizon.cpu-stg"
  ],
  "errors": [],
  "containers": [
    {
      "name": "3d668c9141e004ed3bb9939bb83f9d8295f65b898d77bee16a80c32448e96d98-startup",
      "image": "dcmartin/amd64_com.github.dcmartin.open-horizon.startup-stg"
    },
    {
      "name": "dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.hal-stg_0.0.3_3ae20897-fe12-4c06-b556-a8199df22504-hal",
      "image": "dcmartin/amd64_com.github.dcmartin.open-horizon.hal-stg"
    },
    {
      "name": "dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.cpu-stg_0.0.3_d9fffb0d-15c3-4f29-b72e-582c61667ad5-cpu",
      "image": "dcmartin/amd64_com.github.dcmartin.open-horizon.cpu-stg"
    },
    {
      "name": "dcmartin-us.ibm.com_com.github.dcmartin.open-horizon.wan-stg_0.0.3_b9a3ad9e-d830-4c04-90bd-7809b3438294-wan",
      "image": "dcmartin/amd64_com.github.dcmartin.open-horizon.wan-stg"
    }
  ]
}
```

Perform _list_ operation on multiple machines (n.b. using `NODES` file with 315 entries):

```
./sh/list-machines.sh
```

```
Running ./sh/list-machine.sh; output: test.list-machines.17001.json; timeout: 3.0; nodes: 315: 0%. 27% 30% 54% 73% 90% 100% completed
{"output":"test.list-machines.17001.json","total":315,"offline":[],"nohzn":[<redacted>],"configured":0,"configuring":[],"unconfiguring":[],"unconfigured":[],"zero_containers":[],"start":"2019-07-26T17:36:19Z","finish":"2019-07-26T17:37:00Z","elapsed":41}
```

## _test_
Tests network and remote access to machine, collects output from the `startup` service status (n.b. port `3093`, aka `3Dg3`), and verifies receipt of Kafka payload.

For example, to _test_ a single machine:

```
sh/test-machine.sh 169.45.52.105 | jq
```

```
{
  "machine": "169.45.52.105",
  "alive": true,
  "responding": true,
  "missing": false,
  "name": "startup-stg-test-vm-montreal18",
  "bad": []
}
```
### `responding`
The `responding` attribute indicates whether the machine is responding to the service status request; the service status may be inquired directly; for example:

```
curl http://169.45.52.105:3093/
```

Which should return a large JSON payload; status includes Docker container details as well as the output from [`hal`](../hal/README.md), [`wan`](../hal/README.md), and [`cpu`](../hal/README.md) services  (not shown).

### `missing`
The `missing` attribute indicates whether the machine's service status JSON payload has been received  by [`hznmonitor`](../hznmonitor/README.md) running on a designated host (n.b. `HZNMONITOR_HOST`), for example:

```
curl http://${HZNMONITOR_HOST}:3094/cgi-bin/summary
```

The `hznmonitor` service provides REST API for common-gateway-interface (CGI) services on port `3094` in the `cgi-bin/` directory.  These services include:

+ `nodes`
+ `patterns`
+ `services`
+ `exchange`
+ `summary`
+ `status`
+ `users`
+ `inspect`
+ `pattern-nodes`

More information may be found in the `hznmonitor` [`README.md`](../hznmonitor/README.md)

## _make_

## _clean_





