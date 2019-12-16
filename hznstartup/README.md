# &#127973;`hznstartup` - new node control

Provides a Web server and coordinator for the [startup](../startup/README.md) service.  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_com.github.dcmartin.open-horizon.hznstartup.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.hznstartup "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_com.github.dcmartin.open-horizon.hznstartup.svg)](https://microbadger.com/images/dcmartin/amd64_com.github.dcmartin.open-horizon.hznstartup "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_com.github.dcmartin.open-horizon.hznstartup
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_com.github.dcmartin.open-horizon.hznstartup.svg

![Supports armhf Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_com.github.dcmartin.open-horizon.hznstartup.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.hznstartup "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_com.github.dcmartin.open-horizon.hznstartup.svg)](https://microbadger.com/images/dcmartin/arm_com.github.dcmartin.open-horizon.hznstartup "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_com.github.dcmartin.open-horizon.hznstartup
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_com.github.dcmartin.open-horizon.hznstartup.svg

![Supports aarch64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_com.github.dcmartin.open-horizon.hznstartup.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.hznstartup "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_com.github.dcmartin.open-horizon.hznstartup.svg)](https://microbadger.com/images/dcmartin/arm64_com.github.dcmartin.open-horizon.hznstartup "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_com.github.dcmartin.open-horizon.hznstartup
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_com.github.dcmartin.open-horizon.hznstartup.svg

[arm64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/armhf-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `com.github.dcmartin.open-horizon.hznstartup`
+ `version` - `0.0.1`

## Service ports
+ `3091` - `hznstartup` service status; returns `application/json`
+ `3092` - Web service for HTML at `/` and CGI scripts at `/cgi-bin`

## Service variables

+ `HZNSTARTUP_GROUP`
+ `LOGTO` - specify where to log; default `"/dev/stderr"`
+ `LOG_LEVEL` - specify level of logging; default: `"info"`; options below
+ `DEBUG` - default: `false`

### Log levels

+ `emerg` - Emergencies - system is unusable.   
+ `alert` - Action must be taken immediately.   
+ `crit` - Critical Conditions.    
+ `error` - Error conditions.   
+ `warn` - Warning conditions.  
+ `notice` - Normal but significant condition.   
+ `info` - Informational.  
+ `debug` - Debug-level messages    
+ `trace1` - Trace messages  
+ `trace2` - Trace messages  
+ `trace3` - Trace messages  
+ `trace4` - Trace messages  
+ `trace5` - Trace messages  
+ `trace6` - Trace messages  
+ `trace7` - Trace messages, dumping large amounts of data   
+ `trace8` - Trace messages, dumping large amounts of data

## Description
Provide Apache2 HTTP Web server for HTML pages and CGI scripts with ExtendedStatus enabled (*local* only).

### HTML pages
Pages may be changed in the `rootfs/var/www/localhost/htdocs/` directory.  The default `index.html` provides a listing of the service environment variables, for example at `http://localhost:8888/`:

### CGI scripts
Scripts may be changed in the `rootfs/var/www/localhost/cgi-bin/` directory.  There is one sample CGI application, `test`, which provides that information as JSON; for example:

```
% curl localhost:3092/cgi-bin/test
```

```
{
  "host": "4366e337e4bb",
  "env": [
    { "key": "HTTP_HOST", "value": "localhost:8888" },
    { "key": "CONTEXT_DOCUMENT_ROOT", "value": "/var/www/localhost/cgi-bin/" },
    { "key": "HTTP_USER_AGENT", "value": "curl/7.54.0" },
    { "key": "SERVER_ADMIN", "value": "root@localhost.local" },
    { "key": "CONTEXT_PREFIX", "value": "/cgi-bin/" },
    { "key": "SERVER_PORT", "value": "8888" },
    { "key": "SERVER_NAME", "value": "localhost" },
    { "key": "QUERY_STRING", "value": "" },
    { "key": "SCRIPT_FILENAME", "value": "/var/www/localhost/cgi-bin/test" },
    { "key": "PWD", "value": "/var/www/localhost/cgi-bin" },
    { "key": "HTTP_ACCEPT", "value": "*/*" },
    { "key": "HZN", "value": "{date:1556404265,hzn:{agreementid:,arch:,cpus:0,device_id:,exchange_url:,host_ips:[],organization:,ram:0,pattern:null}}" },
    { "key": "REQUEST_METHOD", "value": "GET" },
    { "key": "SERVER_SIGNATURE", "value": "<address>Apache/2.4.39 (Unix) Server at localhost Port 8888</address>" },
    { "key": "", "value": "" },
    { "key": "SCRIPT_NAME", "value": "/cgi-bin/test" },
    { "key": "REMOTE_PORT", "value": "49444" },
    { "key": "DOCUMENT_ROOT", "value": "/var/www/localhost/htdocs" },
    { "key": "SHLVL", "value": "1" },
    { "key": "SERVER_PROTOCOL", "value": "HTTP/1.1" },
    { "key": "REQUEST_URI", "value": "/cgi-bin/test" },
    { "key": "PATH", "value": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" },
    { "key": "SERVER_ADDR", "value": "172.17.0.2" },
    { "key": "GATEWAY_INTERFACE", "value": "CGI/1.1" },
    { "key": "REQUEST_SCHEME", "value": "http" },
    { "key": "REMOTE_ADDR", "value": "172.17.0.1" },
    { "key": "SERVER_SOFTWARE", "value": "Apache/2.4.39 (Unix)" },
    { "key": "_", "value": "/usr/bin/env" }
  ]
}
```

## How To Build
Copy this [repository][repository], change to the `hznstartup` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/hznstartup
% make
...
```

Once the service has been `built`, `run`, and `check` the first time, subsequent `check` will yield status output include the Apache server `status` HTML page, *base64* encoded.

```
% make check
```

```
```

### EXAMPLE `status`
The Apache2 Web server status information may be extracted from the status JSON payload, for example:

```
% curl localhost:3091 | jq -r '.hznstartup.status' | base64 --decode > status.html
```

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

[David C Martin][dcmartin] (github@dcmartin.com)


[dcmartin]: https://github.com/dcmartin
[edge-fabric]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/getting-started.html
[edge-install]: https://console.test.cloud.ibm.com/docs/services/edge-fabric/adding-devices.html
[edge-slack]: https://ibm-appsci.slack.com/messages/edge-fabric-users/
[ibm-apikeys]: https://console.bluemix.net/iam/#/apikeys
[ibm-registration]: https://console.bluemix.net/registration/
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: ../setup/README.md
