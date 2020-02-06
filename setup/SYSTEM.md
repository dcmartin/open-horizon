# System Installation

System installation modifies the operating system boot sequence to install the Open Horizon software.
The `editrc.sh` script modifies the `/etc/rc.local` file to include additional commands to install the Open Horizon software.

Steps in the process:
1. Clone this [repository][repository] and change to that directory
1. Create a new configuration file using the `mkconfig.sh` script
1. Check configuration using `chkconfig.sh`
1. Insert and flash a uSD card with operating system image
1. Run the `editrc.sh` script to mount the uSD card, modify the operating system files, and unmount
1. Eject the uSD card; duplicate as necessary

For each device insert the uSD card and provide power and networking; software installation is tested at boot.
If the requisite `hzn` command is not found, devices will download and install all software; devices are then ready for pattern registration.

** NOTE: A [video][horizon-video-setup] (2m:22s) is available **

## Defaults

Default values for installation are required and may be changed using `mkconfig.sh`; these include:

+ `exchange` - the URL of the Open Horizon exchange; default `alpha`
+ `machine` - the machine type; default `rpi3`
+ `network` - the WiFi network to which the device should attach at boot; default `none`
+ `configuration` - the default configuration; default `none`
+ `pattern` - the default pattern; default `none`
+ `token` - the default device token; default `none`
+ `keys` including both `public` and `private` (for use with SSH access)

Public and private keys are identified from the default `configuration`; if there is no default configuration, the user's SSH RSA credentials are used: `~/.ssh/id_rsa`.
If no keys can be found, new keys are generated using `ssh-keygen`.

## Setups

A URL for the shell script is defined in the configuration file (aka `horizon.json`) as part of the `setup` component; the default `url` is `http://ibm.biz/horizon-setup`.
An alternative script can be defined by either modifying the configuration to indicate an alternative `url` or providing a local `path` to the script.
```
  "setups": [
    { "id": "none" },
    { "id": "horizon", "path": "hzn-install.sh", "url": "http://ibm.biz/horizon-setup" },
    { "id": "hassio", "path": "hassio-install.sh", "url": "http://ibm.biz/hassio-setup" }
  ]
```

## Changelog & Releases

Releases are based on Semantic Versioning, and use the format
of ``MAJOR.MINOR.PATCH``. In a nutshell, the version will be incremented
based on the following:

- ``MAJOR``: Incompatible or major changes.
- ``MINOR``: Backwards-compatible new features and enhancements.
- ``PATCH``: Backwards-compatible bugfixes and package updates.

## Authors & contributors

David C Martin (github@dcmartin.com)

[commits]: https://github.com/dcmartin/open-horizon/setup/commits/master
[contributors]: https://github.com/dcmartin/open-horizon/setup/graphs/contributors
[releases]: https://github.com/dcmartin/open-horizon/setup/releases
[issue]: https://github.com/dcmartin/open-horizon/setup/issues

[horizon-setup]: ../setup/hzn-install.sh
[hassio-setup]: ../setup/hassio-install.sh
[horizon-video-setup]: https://youtu.be/G7-CzOzzSUo

[dcmartin]: https://github.com/dcmartin
[repository]: https://github.com/dcmartin/open-horizon
[basic]: ../setup/BASIC.md
[setup]: ../setup/SETUP.md

[keepchangelog]: http://keepachangelog.com/en/1.0.0/
[open-horizon]: https://github.com/open-horizon
[macos-install]: https://github.com/open-horizon/anax/releases
[examples]: https://github.com/open-horizon/examples
[template]: ../setup/template.json

[ibm-cloud]: http://cloud.ibm.com/
[ibm-cloud-iam]: https://cloud.ibm.com/iam/
