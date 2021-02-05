# &#127978; `minio` - MINIO object store

Provides a service for an [MINIO](https://minio.io/) server.  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_minio.svg)](https://microbadger.com/images/dcmartin/amd64_minio "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_minio.svg)](https://microbadger.com/images/dcmartin/amd64_minio "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_minio
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_minio.svg

![Supports aarch64 Architecture][aarch64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/aarch64_minio.svg)](https://microbadger.com/images/dcmartin/aarch64_minio "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/aarch64_minio.svg)](https://microbadger.com/images/dcmartin/aarch64_minio "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-aarch64]][docker-aarch64]

[docker-aarch64]: https://hub.docker.com/r/dcmartin/aarch64_minio
[pulls-aarch64]: https://img.shields.io/docker/pulls/dcmartin/aarch64_minio.svg

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/arm-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `service-minio`
+ `version` - `0.0.1`

## Service ports
+ `9001` - `minio` service status; returns `application/json`
+ `9000` - `minio` server at `/api`

## Service variables

+ `MINIO_WORKSPACE` - location of data; default: `"/data/minio"`
+ `MINIO_PROJECT` - name repository; default: `"MyProject"`
+ `MINIO_USERNAME` - 
+ `MINIO_PASSWORD` - 
+ `MINIO_HOST` - hostname; default: `0.0.0.0`
+ `MINIO_PORT` - port; default: `9000`
+ `MINIO_PROTOCOL` - 
+ `LOG_LEVEL` - specify level of logging; default: `"info"`; options below

### Log levels

+ `emerg` - Emergencies - system is unusable.   
+ `alert` - Action must be taken immediately.   
+ `crit` - Critical Conditions.    
+ `error` - Error conditions.   
+ `warn` - Warning conditions.  
+ `notice` - Normal but significant condition.   
+ `info` - Informational.  
+ `debug` - Debug-level messages    

## Description


## How To Use
Copy this [repository][repository], change to the `minio` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/services/minio
% make
...
```

Once the service has been `built`, `run`, and `check` the first time, subsequent `check` will yield status output include the Apache server `status` HTML page, *base64* encoded.

```
% make check
```

```
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
[issue]: https://github.com/dcmartin/open-horizon/issues
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
