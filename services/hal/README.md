# &#128187; `hal` - Hardware Abstration Layer service

Provides hardware information as micro-service; updates periodically (default `60` seconds or 1 minute).  This container may be run locally using Docker, pushed to a Docker registry, and published to any [_Open Horizon_][open-horizon] exchange.

## Status

![Supports amd64 Architecture][amd64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/amd64_hal.svg)](https://microbadger.com/images/dcmartin/amd64_hal "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/amd64_hal.svg)](https://microbadger.com/images/dcmartin/amd64_hal "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-amd64]][docker-amd64]

[docker-amd64]: https://hub.docker.com/r/dcmartin/amd64_hal
[pulls-amd64]: https://img.shields.io/docker/pulls/dcmartin/amd64_hal.svg

![Supports arm Architecture][arm-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm_hal.svg)](https://microbadger.com/images/dcmartin/arm_hal "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm_hal.svg)](https://microbadger.com/images/dcmartin/arm_hal "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm]][docker-arm]

[docker-arm]: https://hub.docker.com/r/dcmartin/arm_hal
[pulls-arm]: https://img.shields.io/docker/pulls/dcmartin/arm_hal.svg

![Supports arm64 Architecture][arm64-shield]
[![](https://images.microbadger.com/badges/image/dcmartin/arm64_hal.svg)](https://microbadger.com/images/dcmartin/arm64_hal "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/dcmartin/arm64_hal.svg)](https://microbadger.com/images/dcmartin/arm64_hal "Get your own version badge on microbadger.com")
[![Docker Pulls][pulls-arm64]][docker-arm64]

[docker-arm64]: https://hub.docker.com/r/dcmartin/arm64_hal
[pulls-arm64]: https://img.shields.io/docker/pulls/dcmartin/arm64_hal.svg

[arm64-shield]: https://img.shields.io/badge/arm64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[arm-shield]: https://img.shields.io/badge/arm-yes-green.svg

## Service discovery
+ `org` - `github@dcmartin.com`
+ `url` - `hal`
+ `version` - `0.0.3`

## Service variables
+ `HAL_PERIOD` - seconds between updates; defaults to `60`
+ `LOG_LEVEL` - specify level of logging; default `info`; options include (`debug` and `none`)

## How To Use

Copy this [repository][repository], change to the `hal` directory, then use the **make** command; see below:

```
% mkdir ~/gitdir
% cd ~/gitdir
% git clone http://github.com/dcmartin/open-horizon
% cd open-horizon/hal
% make
...
{
  "hal": null,
  "date": 1554314764,
  "hzn": {
    "agreementid": "",
    "arch": "",
    "cpus": 0,
    "device_id": "",
    "exchange_url": "",
    "host_ips": [
      ""
    ],
    "organization": "",
    "ram": 0,
    "pattern": null
  },
  "config": {
    "log_level": "info",
    "debug": false,
    "period": "60",
    "services": null
  },
  "service": {
    "label": "hal",
    "version": "0.0.3"
  }
}
```
The `hal` payload will be incomplete until the service completes; subsequent `make check` will return complete; see below:
```
{
  "hal": {
    "date": 1554314765,
    "lshw": {
      "id": "156adef23894",
      "class": "system",
      "claimed": true,
      "handle": "DMI:0001",
      "description": "Computer",
      "product": "BHYVE (None)",
      "version": "1.0",
      "serial": "None",
      "width": 64,
      "configuration": {
        "boot": "normal",
        "sku": "None",
        "uuid": "1943F97B-0000-0000-984D-D2936121B805"
      },
      "capabilities": {
        "smbios-3.0": "SMBIOS version 3.0",
        "dmi-3.0": "DMI version 3.0",
        "vsyscall32": "32-bit processes"
      },
      "children": [
        {
          "id": "core",
          "class": "bus",
          "claimed": true,
          "description": "Motherboard",
          "physid": "0",
          "children": [
            {
              "id": "firmware",
              "class": "memory",
              "claimed": true,
              "description": "BIOS",
              "vendor": "BHYVE",
              "physid": "0",
              "version": "1.00",
              "date": "03/14/2014",
              "units": "bytes",
              "size": 65536,
              "capabilities": {
                "isa": "ISA bus",
                "pci": "PCI bus",
                "shadowing": "BIOS shadowing",
                "cdboot": "Booting from CD-ROM/DVD",
                "edd": "Enhanced Disk Drive extensions",
                "acpi": "ACPI",
                "biosbootspecification": "BIOS boot specification",
                "virtualmachine": "This machine is a virtual machine"
              }
            },
            {
              "id": "cpu:0",
              "class": "processor",
              "claimed": true,
              "handle": "DMI:0003",
              "description": "CPU",
              "product": "(None)",
              "vendor": "Intel Corp.",
              "physid": "3",
              "businfo": "cpu@0",
              "serial": "None",
              "slot": "CPU #0",
              "width": 64,
              "capabilities": {
                "x86-64": "64bits extensions (x86-64)",
                "fpu": "mathematical co-processor",
                "fpu_exception": "FPU exceptions reporting",
                "wp": true,
                "vme": "virtual mode extensions",
                "de": "debugging extensions",
                "pse": "page size extensions",
                "tsc": "time stamp counter",
                "msr": "model-specific registers",
                "pae": "4GB+ memory addressing (Physical Address Extension)",
                "mce": "machine check exceptions",
                "cx8": "compare and exchange 8-byte",
                "apic": "on-chip advanced programmable interrupt controller (APIC)",
                "sep": "fast system calls",
                "mtrr": "memory type range registers",
                "pge": "page global enable",
                "mca": "machine check architecture",
                "cmov": "conditional move instruction",
                "pat": "page attribute table",
                "pse36": "36-bit page size extensions",
                "clflush": true,
                "mmx": "multimedia extensions (MMX)",
                "fxsr": "fast floating point save/restore",
                "sse": "streaming SIMD extensions (SSE)",
                "sse2": "streaming SIMD extensions (SSE2)",
                "ss": "self-snoop",
                "ht": "HyperThreading",
                "pbe": "pending break event",
                "syscall": "fast system calls",
                "nx": "no-execute bit (NX)",
                "pdpe1gb": true,
                "constant_tsc": true,
                "rep_good": true,
                "nopl": true,
                "xtopology": true,
                "nonstop_tsc": true,
                "pni": true,
                "pclmulqdq": true,
                "dtes64": true,
                "ds_cpl": true,
                "ssse3": true,
                "sdbg": true,
                "fma": true,
                "cx16": true,
                "xtpr": true,
                "pcid": true,
                "sse4_1": true,
                "sse4_2": true,
                "movbe": true,
                "popcnt": true,
                "aes": true,
                "xsave": true,
                "avx": true,
                "f16c": true,
                "rdrand": true,
                "hypervisor": true,
                "lahf_lm": true,
                "abm": true,
                "3dnowprefetch": true,
                "kaiser": true,
                "fsgsbase": true,
                "bmi1": true,
                "hle": true,
                "avx2": true,
                "bmi2": true,
                "erms": true,
                "rtm": true,
                "xsaveopt": true,
                "arat": true
              }
            },
            {
              "id": "cpu:1",
              "class": "processor",
              "claimed": true,
              "handle": "DMI:0004",
              "description": "CPU",
              "product": "(None)",
              "vendor": "Intel Corp.",
              "physid": "4",
              "businfo": "cpu@1",
              "serial": "None",
              "slot": "CPU #1",
              "width": 64,
              "capabilities": {
                "x86-64": "64bits extensions (x86-64)",
                "fpu": "mathematical co-processor",
                "fpu_exception": "FPU exceptions reporting",
                "wp": true,
                "vme": "virtual mode extensions",
                "de": "debugging extensions",
                "pse": "page size extensions",
                "tsc": "time stamp counter",
                "msr": "model-specific registers",
                "pae": "4GB+ memory addressing (Physical Address Extension)",
                "mce": "machine check exceptions",
                "cx8": "compare and exchange 8-byte",
                "apic": "on-chip advanced programmable interrupt controller (APIC)",
                "sep": "fast system calls",
                "mtrr": "memory type range registers",
                "pge": "page global enable",
                "mca": "machine check architecture",
                "cmov": "conditional move instruction",
                "pat": "page attribute table",
                "pse36": "36-bit page size extensions",
                "clflush": true,
                "mmx": "multimedia extensions (MMX)",
                "fxsr": "fast floating point save/restore",
                "sse": "streaming SIMD extensions (SSE)",
                "sse2": "streaming SIMD extensions (SSE2)",
                "ss": "self-snoop",
                "ht": "HyperThreading",
                "pbe": "pending break event",
                "syscall": "fast system calls",
                "nx": "no-execute bit (NX)",
                "pdpe1gb": true,
                "constant_tsc": true,
                "rep_good": true,
                "nopl": true,
                "xtopology": true,
                "nonstop_tsc": true,
                "pni": true,
                "pclmulqdq": true,
                "dtes64": true,
                "ds_cpl": true,
                "ssse3": true,
                "sdbg": true,
                "fma": true,
                "cx16": true,
                "xtpr": true,
                "pcid": true,
                "sse4_1": true,
                "sse4_2": true,
                "movbe": true,
                "popcnt": true,
                "aes": true,
                "xsave": true,
                "avx": true,
                "f16c": true,
                "rdrand": true,
                "hypervisor": true,
                "lahf_lm": true,
                "abm": true,
                "3dnowprefetch": true,
                "kaiser": true,
                "fsgsbase": true,
                "bmi1": true,
                "hle": true,
                "avx2": true,
                "bmi2": true,
                "erms": true,
                "rtm": true,
                "xsaveopt": true,
                "arat": true
              }
            },
            {
              "id": "cpu:2",
              "class": "processor",
              "claimed": true,
              "handle": "DMI:0005",
              "description": "CPU",
              "product": "(None)",
              "vendor": "Intel Corp.",
              "physid": "5",
              "businfo": "cpu@2",
              "serial": "None",
              "slot": "CPU #2",
              "width": 64,
              "capabilities": {
                "x86-64": "64bits extensions (x86-64)",
                "fpu": "mathematical co-processor",
                "fpu_exception": "FPU exceptions reporting",
                "wp": true,
                "vme": "virtual mode extensions",
                "de": "debugging extensions",
                "pse": "page size extensions",
                "tsc": "time stamp counter",
                "msr": "model-specific registers",
                "pae": "4GB+ memory addressing (Physical Address Extension)",
                "mce": "machine check exceptions",
                "cx8": "compare and exchange 8-byte",
                "apic": "on-chip advanced programmable interrupt controller (APIC)",
                "sep": "fast system calls",
                "mtrr": "memory type range registers",
                "pge": "page global enable",
                "mca": "machine check architecture",
                "cmov": "conditional move instruction",
                "pat": "page attribute table",
                "pse36": "36-bit page size extensions",
                "clflush": true,
                "mmx": "multimedia extensions (MMX)",
                "fxsr": "fast floating point save/restore",
                "sse": "streaming SIMD extensions (SSE)",
                "sse2": "streaming SIMD extensions (SSE2)",
                "ss": "self-snoop",
                "ht": "HyperThreading",
                "pbe": "pending break event",
                "syscall": "fast system calls",
                "nx": "no-execute bit (NX)",
                "pdpe1gb": true,
                "constant_tsc": true,
                "rep_good": true,
                "nopl": true,
                "xtopology": true,
                "nonstop_tsc": true,
                "pni": true,
                "pclmulqdq": true,
                "dtes64": true,
                "ds_cpl": true,
                "ssse3": true,
                "sdbg": true,
                "fma": true,
                "cx16": true,
                "xtpr": true,
                "pcid": true,
                "sse4_1": true,
                "sse4_2": true,
                "movbe": true,
                "popcnt": true,
                "aes": true,
                "xsave": true,
                "avx": true,
                "f16c": true,
                "rdrand": true,
                "hypervisor": true,
                "lahf_lm": true,
                "abm": true,
                "3dnowprefetch": true,
                "kaiser": true,
                "fsgsbase": true,
                "bmi1": true,
                "hle": true,
                "avx2": true,
                "bmi2": true,
                "erms": true,
                "rtm": true,
                "xsaveopt": true,
                "arat": true
              }
            },
            {
              "id": "cpu:3",
              "class": "processor",
              "claimed": true,
              "handle": "DMI:0006",
              "description": "CPU",
              "product": "(None)",
              "vendor": "Intel Corp.",
              "physid": "6",
              "businfo": "cpu@3",
              "serial": "None",
              "slot": "CPU #3",
              "width": 64,
              "capabilities": {
                "x86-64": "64bits extensions (x86-64)",
                "fpu": "mathematical co-processor",
                "fpu_exception": "FPU exceptions reporting",
                "wp": true,
                "vme": "virtual mode extensions",
                "de": "debugging extensions",
                "pse": "page size extensions",
                "tsc": "time stamp counter",
                "msr": "model-specific registers",
                "pae": "4GB+ memory addressing (Physical Address Extension)",
                "mce": "machine check exceptions",
                "cx8": "compare and exchange 8-byte",
                "apic": "on-chip advanced programmable interrupt controller (APIC)",
                "sep": "fast system calls",
                "mtrr": "memory type range registers",
                "pge": "page global enable",
                "mca": "machine check architecture",
                "cmov": "conditional move instruction",
                "pat": "page attribute table",
                "pse36": "36-bit page size extensions",
                "clflush": true,
                "mmx": "multimedia extensions (MMX)",
                "fxsr": "fast floating point save/restore",
                "sse": "streaming SIMD extensions (SSE)",
                "sse2": "streaming SIMD extensions (SSE2)",
                "ss": "self-snoop",
                "ht": "HyperThreading",
                "pbe": "pending break event",
                "syscall": "fast system calls",
                "nx": "no-execute bit (NX)",
                "pdpe1gb": true,
                "constant_tsc": true,
                "rep_good": true,
                "nopl": true,
                "xtopology": true,
                "nonstop_tsc": true,
                "pni": true,
                "pclmulqdq": true,
                "dtes64": true,
                "ds_cpl": true,
                "ssse3": true,
                "sdbg": true,
                "fma": true,
                "cx16": true,
                "xtpr": true,
                "pcid": true,
                "sse4_1": true,
                "sse4_2": true,
                "movbe": true,
                "popcnt": true,
                "aes": true,
                "xsave": true,
                "avx": true,
                "f16c": true,
                "rdrand": true,
                "hypervisor": true,
                "lahf_lm": true,
                "abm": true,
                "3dnowprefetch": true,
                "kaiser": true,
                "fsgsbase": true,
                "bmi1": true,
                "hle": true,
                "avx2": true,
                "bmi2": true,
                "erms": true,
                "rtm": true,
                "xsaveopt": true,
                "arat": true
              }
            },
            {
              "id": "memory",
              "class": "memory",
              "claimed": true,
              "handle": "DMI:0007",
              "description": "System Memory",
              "physid": "7",
              "slot": "System board or motherboard",
              "units": "bytes",
              "size": 68717379584,
              "children": [
                {
                  "id": "bank:0",
                  "class": "memory",
                  "claimed": true,
                  "handle": "DMI:0008",
                  "product": "None",
                  "physid": "0",
                  "serial": "None",
                  "units": "bytes",
                  "size": 34358689792,
                  "width": 64
                },
                {
                  "id": "bank:1",
                  "class": "memory",
                  "claimed": true,
                  "handle": "DMI:0009",
                  "product": "None",
                  "physid": "1",
                  "serial": "None",
                  "units": "bytes",
                  "size": 34358689792,
                  "width": 64
                }
              ]
            },
            {
              "id": "pci",
              "class": "bridge",
              "claimed": true,
              "handle": "PCIBUS:0000:00",
              "description": "Host bridge",
              "product": "Network Appliance Corporation",
              "vendor": "Network Appliance Corporation",
              "physid": "100",
              "businfo": "pci@0000:00:00.0",
              "version": "00",
              "width": 32,
              "clock": 33000000,
              "children": [
                {
                  "id": "network:0",
                  "class": "network",
                  "claimed": true,
                  "handle": "PCI:0000:00:01.0",
                  "description": "Ethernet controller",
                  "product": "Virtio network device",
                  "vendor": "Red Hat, Inc",
                  "physid": "1",
                  "businfo": "pci@0000:00:01.0",
                  "version": "00",
                  "width": 32,
                  "clock": 33000000,
                  "configuration": {
                    "driver": "virtio-pci",
                    "latency": "64"
                  },
                  "capabilities": {
                    "msix": "MSI-X",
                    "msi": "Message Signalled Interrupts",
                    "bus_master": "bus mastering",
                    "cap_list": "PCI capabilities listing",
                    "rom": "extension ROM"
                  }
                },
                {
                  "id": "storage:0",
                  "class": "storage",
                  "claimed": true,
                  "handle": "PCI:0000:00:02.0",
                  "description": "SATA controller",
                  "product": "82801HR/HO/HH (ICH8R/DO/DH) 6 port SATA Controller [AHCI mode]",
                  "vendor": "Intel Corporation",
                  "physid": "2",
                  "businfo": "pci@0000:00:02.0",
                  "version": "00",
                  "width": 32,
                  "clock": 33000000,
                  "configuration": {
                    "driver": "ahci",
                    "latency": "64"
                  },
                  "capabilities": {
                    "storage": true,
                    "msi": "Message Signalled Interrupts",
                    "ahci_1.0": true,
                    "bus_master": "bus mastering",
                    "cap_list": "PCI capabilities listing",
                    "rom": "extension ROM"
                  }
                },
                {
                  "id": "network:1",
                  "class": "network",
                  "claimed": true,
                  "handle": "PCI:0000:00:03.0",
                  "description": "Ethernet controller",
                  "product": "Red Hat, Inc",
                  "vendor": "Red Hat, Inc",
                  "physid": "3",
                  "businfo": "pci@0000:00:03.0",
                  "version": "00",
                  "width": 32,
                  "clock": 33000000,
                  "configuration": {
                    "driver": "virtio-pci",
                    "latency": "64"
                  },
                  "capabilities": {
                    "msix": "MSI-X",
                    "msi": "Message Signalled Interrupts",
                    "bus_master": "bus mastering",
                    "cap_list": "PCI capabilities listing",
                    "rom": "extension ROM"
                  }
                },
                {
                  "id": "storage:1",
                  "class": "storage",
                  "claimed": true,
                  "handle": "PCI:0000:00:04.0",
                  "description": "SATA controller",
                  "product": "82801HR/HO/HH (ICH8R/DO/DH) 6 port SATA Controller [AHCI mode]",
                  "vendor": "Intel Corporation",
                  "physid": "4",
                  "businfo": "pci@0000:00:04.0",
                  "version": "00",
                  "width": 32,
                  "clock": 33000000,
                  "configuration": {
                    "driver": "ahci",
                    "latency": "64"
                  },
                  "capabilities": {
                    "storage": true,
                    "msi": "Message Signalled Interrupts",
                    "ahci_1.0": true,
                    "bus_master": "bus mastering",
                    "cap_list": "PCI capabilities listing",
                    "rom": "extension ROM"
                  }
                },
                {
                  "id": "storage:2",
                  "class": "storage",
                  "claimed": true,
                  "handle": "PCI:0000:00:05.0",
                  "description": "SATA controller",
                  "product": "82801HR/HO/HH (ICH8R/DO/DH) 6 port SATA Controller [AHCI mode]",
                  "vendor": "Intel Corporation",
                  "physid": "5",
                  "businfo": "pci@0000:00:05.0",
                  "version": "00",
                  "width": 32,
                  "clock": 33000000,
                  "configuration": {
                    "driver": "ahci",
                    "latency": "64"
                  },
                  "capabilities": {
                    "storage": true,
                    "msi": "Message Signalled Interrupts",
                    "ahci_1.0": true,
                    "bus_master": "bus mastering",
                    "cap_list": "PCI capabilities listing",
                    "rom": "extension ROM"
                  }
                },
                {
                  "id": "storage:3",
                  "class": "storage",
                  "claimed": true,
                  "handle": "PCI:0000:00:06.0",
                  "description": "SATA controller",
                  "product": "82801HR/HO/HH (ICH8R/DO/DH) 6 port SATA Controller [AHCI mode]",
                  "vendor": "Intel Corporation",
                  "physid": "6",
                  "businfo": "pci@0000:00:06.0",
                  "version": "00",
                  "width": 32,
                  "clock": 33000000,
                  "configuration": {
                    "driver": "ahci",
                    "latency": "64"
                  },
                  "capabilities": {
                    "storage": true,
                    "msi": "Message Signalled Interrupts",
                    "ahci_1.0": true,
                    "bus_master": "bus mastering",
                    "cap_list": "PCI capabilities listing",
                    "rom": "extension ROM"
                  }
                },
                {
                  "id": "generic",
                  "class": "generic",
                  "claimed": true,
                  "handle": "PCI:0000:00:07.0",
                  "description": "Network and computing encryption device",
                  "product": "Virtio RNG",
                  "vendor": "Red Hat, Inc",
                  "physid": "7",
                  "businfo": "pci@0000:00:07.0",
                  "version": "00",
                  "width": 32,
                  "clock": 33000000,
                  "configuration": {
                    "driver": "virtio-pci",
                    "latency": "64"
                  },
                  "capabilities": {
                    "msix": "MSI-X",
                    "msi": "Message Signalled Interrupts",
                    "bus_master": "bus mastering",
                    "cap_list": "PCI capabilities listing",
                    "rom": "extension ROM"
                  }
                },
                {
                  "id": "isa",
                  "class": "bridge",
                  "claimed": true,
                  "handle": "PCI:0000:00:1f.0",
                  "description": "ISA bridge",
                  "product": "82371SB PIIX3 ISA [Natoma/Triton II]",
                  "vendor": "Intel Corporation",
                  "physid": "1f",
                  "businfo": "pci@0000:00:1f.0",
                  "version": "00",
                  "width": 32,
                  "clock": 33000000,
                  "configuration": {
                    "latency": "0"
                  },
                  "capabilities": {
                    "isa": true,
                    "bus_master": "bus mastering"
                  }
                }
              ]
            },
            {
              "id": "scsi:0",
              "class": "storage",
              "claimed": true,
              "physid": "1",
              "logicalname": "scsi0",
              "capabilities": {
                "emulated": "Emulated device"
              },
              "children": [
                {
                  "id": "disk",
                  "class": "disk",
                  "claimed": true,
                  "handle": "SCSI:00:00:00:00",
                  "description": "ATA Disk",
                  "product": "BHYVE SATA DISK",
                  "physid": "0.0.0",
                  "businfo": "scsi@0:0.0.0",
                  "logicalname": "/dev/sda",
                  "dev": "8:0",
                  "version": "001",
                  "serial": "BHYVE-CE00-045F-3FC6",
                  "units": "bytes",
                  "size": 255999344640,
                  "configuration": {
                    "ansiversion": "5",
                    "logicalsectorsize": "512",
                    "sectorsize": "4096",
                    "signature": "9fd2782c"
                  },
                  "capabilities": {
                    "partitioned": "Partitioned disk",
                    "partitioned:dos": "MS-DOS partition table"
                  },
                  "children": [
                    {
                      "id": "volume",
                      "class": "volume",
                      "claimed": true,
                      "description": "EXT4 volume",
                      "vendor": "Linux",
                      "physid": "1",
                      "businfo": "scsi@0:0.0.0,1",
                      "logicalname": [
                        "/dev/sda1",
                        "/etc/resolv.conf",
                        "/etc/hostname",
                        "/etc/hosts"
                      ],
                      "dev": "8:1",
                      "version": "1.0",
                      "serial": "706d5909-b68c-404c-8cf9-841e5396e0d0",
                      "size": 255998296064,
                      "capacity": 255998296064,
                      "configuration": {
                        "created": "2018-10-23 13:21:43",
                        "filesystem": "ext4",
                        "lastmountpoint": "/var/lib",
                        "modified": "2019-03-27 17:16:59",
                        "mount.fstype": "ext4",
                        "mount.options": "rw,relatime,data=ordered",
                        "mounted": "2019-03-27 17:16:59",
                        "state": "mounted"
                      },
                      "capabilities": {
                        "primary": "Primary partition",
                        "bootable": "Bootable partition (active)",
                        "journaled": true,
                        "extended_attributes": "Extended Attributes",
                        "large_files": "4GB+ files",
                        "huge_files": "16TB+ files",
                        "dir_nlink": "directories with 65000+ subdirs",
                        "recover": "needs recovery",
                        "64bit": "64bit filesystem",
                        "extents": "extent-based allocation",
                        "ext4": true,
                        "ext2": "EXT2/EXT3",
                        "initialized": "initialized volume"
                      }
                    }
                  ]
                }
              ]
            },
            {
              "id": "scsi:1",
              "class": "storage",
              "claimed": true,
              "physid": "2",
              "logicalname": "scsi6",
              "capabilities": {
                "emulated": "Emulated device"
              },
              "children": [
                {
                  "id": "cdrom",
                  "class": "disk",
                  "claimed": true,
                  "handle": "SCSI:06:00:00:00",
                  "description": "DVD reader",
                  "physid": "0.0.0",
                  "businfo": "scsi@6:0.0.0",
                  "logicalname": "/dev/sr0",
                  "dev": "11:0",
                  "configuration": {
                    "status": "ready"
                  },
                  "capabilities": {
                    "audio": "Audio CD playback",
                    "dvd": "DVD playback"
                  }
                }
              ]
            },
            {
              "id": "scsi:2",
              "class": "storage",
              "claimed": true,
              "physid": "8",
              "logicalname": "scsi12",
              "capabilities": {
                "emulated": "Emulated device"
              },
              "children": [
                {
                  "id": "cdrom",
                  "class": "disk",
                  "claimed": true,
                  "handle": "SCSI:12:00:00:00",
                  "description": "DVD reader",
                  "physid": "0.0.0",
                  "businfo": "scsi@12:0.0.0",
                  "logicalname": "/dev/sr1",
                  "dev": "11:1",
                  "configuration": {
                    "status": "ready"
                  },
                  "capabilities": {
                    "audio": "Audio CD playback",
                    "dvd": "DVD playback"
                  }
                }
              ]
            },
            {
              "id": "scsi:3",
              "class": "storage",
              "claimed": true,
              "physid": "9",
              "logicalname": "scsi18",
              "capabilities": {
                "emulated": "Emulated device"
              },
              "children": [
                {
                  "id": "cdrom",
                  "class": "disk",
                  "claimed": true,
                  "handle": "SCSI:18:00:00:00",
                  "description": "DVD reader",
                  "physid": "0.0.0",
                  "businfo": "scsi@18:0.0.0",
                  "logicalname": "/dev/sr2",
                  "dev": "11:2",
                  "configuration": {
                    "status": "ready"
                  },
                  "capabilities": {
                    "audio": "Audio CD playback",
                    "dvd": "DVD playback"
                  }
                }
              ]
            }
          ]
        },
        {
          "id": "network",
          "class": "network",
          "claimed": true,
          "description": "Ethernet interface",
          "physid": "1",
          "logicalname": "eth0",
          "serial": "02:42:ac:11:00:06",
          "units": "bit/s",
          "size": 10000000000,
          "configuration": {
            "autonegotiation": "off",
            "broadcast": "yes",
            "driver": "veth",
            "driverversion": "1.0",
            "duplex": "full",
            "ip": "172.17.0.6",
            "link": "yes",
            "multicast": "yes",
            "port": "twisted pair",
            "speed": "10Gbit/s"
          },
          "capabilities": {
            "ethernet": true,
            "physical": "Physical interface"
          }
        }
      ]
    },
    "lsusb": [],
    "lscpu": {
      "Architecture": "x86_64",
      "CPU_op_modes": "32-bit, 64-bit",
      "Byte_Order": "Little Endian",
      "CPUs": "4",
      "On_line_CPUs_list": "0-3",
      "Threads_per_core": "1",
      "Cores_per_socket": "1",
      "Sockets": "4",
      "Vendor_ID": "GenuineIntel",
      "CPU_family": "6",
      "Model": "158",
      "Model_name": "Intel(R) Core(TM) i7-7700K CPU @ 4.20GHz",
      "Stepping": "9",
      "CPU_MHz": "4200.000",
      "BogoMIPS": "8400.00",
      "L1d_cache": "32K",
      "L1i_cache": "32K",
      "L2_cache": "256K",
      "L3_cache": "8192K",
      "Flags": "fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss ht pbe syscall nx pdpe1gb lm constant_tsc rep_good nopl xtopology nonstop_tsc pni pclmulqdq dtes64 ds_cpl ssse3 sdbg fma cx16 xtpr pcid sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand hypervisor lahf_lm abm 3dnowprefetch kaiser fsgsbase bmi1 hle avx2 bmi2 erms rtm xsaveopt arat"
    },
    "lspci": [
      {
        "slot": "00:00.0",
        "device_class_id": "0600",
        "vendor_class_id": "1275",
        "device_id": "1275",
        "vendor_id": "0000"
      },
      {
        "slot": "00:03.0",
        "device_class_id": "0200",
        "vendor_class_id": "1af4",
        "device_id": "103f",
        "vendor_id": "1af4"
      },
      {
        "slot": "00:06.0",
        "device_class_id": "0106",
        "vendor_class_id": "8086",
        "device_id": "2821",
        "vendor_id": "0000"
      },
      {
        "slot": "00:02.0",
        "device_class_id": "0106",
        "vendor_class_id": "8086",
        "device_id": "2821",
        "vendor_id": "0000"
      },
      {
        "slot": "00:05.0",
        "device_class_id": "0106",
        "vendor_class_id": "8086",
        "device_id": "2821",
        "vendor_id": "0000"
      },
      {
        "slot": "00:1f.0",
        "device_class_id": "0601",
        "vendor_class_id": "8086",
        "device_id": "7000",
        "vendor_id": "0000"
      },
      {
        "slot": "00:01.0",
        "device_class_id": "0200",
        "vendor_class_id": "1af4",
        "device_id": "1000",
        "vendor_id": "1af4"
      },
      {
        "slot": "00:04.0",
        "device_class_id": "0106",
        "vendor_class_id": "8086",
        "device_id": "2821",
        "vendor_id": "0000"
      },
      {
        "slot": "00:07.0",
        "device_class_id": "1000",
        "vendor_class_id": "1af4",
        "device_id": "1005",
        "vendor_id": "1af4"
      }
    ],
    "lsblk": [
      {
        "name": "sda",
        "maj:min": "8:0",
        "rm": "0",
        "size": "238.4G",
        "ro": "0",
        "type": "disk",
        "mountpoint": null,
        "children": [
          {
            "name": "sda1",
            "maj:min": "8:1",
            "rm": "0",
            "size": "238.4G",
            "ro": "0",
            "type": "part",
            "mountpoint": "/etc/hosts"
          }
        ]
      },
      {
        "name": "sr0",
        "maj:min": "11:0",
        "rm": "1",
        "size": "477.4M",
        "ro": "0",
        "type": "rom",
        "mountpoint": null
      },
      {
        "name": "sr1",
        "maj:min": "11:1",
        "rm": "1",
        "size": "120K",
        "ro": "0",
        "type": "rom",
        "mountpoint": null
      },
      {
        "name": "sr2",
        "maj:min": "11:2",
        "rm": "1",
        "size": "961.1M",
        "ro": "0",
        "type": "rom",
        "mountpoint": null
      }
    ],
    "lsdf": [
      {
        "mount": "/dev/sda1",
        "spacetotal": "235G",
        "spaceavail": "186G"
      }
    ]
  },
  "date": 1554314764,
  "hzn": {
    "agreementid": "",
    "arch": "",
    "cpus": 0,
    "device_id": "",
    "exchange_url": "",
    "host_ips": [
      ""
    ],
    "organization": "",
    "ram": 0,
    "pattern": null
  },
  "config": {
    "log_level": "info",
    "debug": false,
    "period": "60",
    "services": null
  },
  "service": {
    "label": "hal",
    "version": "0.0.3"
  }
}
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

[userinput]: ../hal/userinput.json
[service-json]: ../hal/service.json
[build-json]: ../hal/build.json
[dockerfile]: ../hal/Dockerfile


[dcmartin]: https://github.com/dcmartin
[issue]: https://github.com/dcmartin/open-horizon/issues
[macos-install]: http://pkg.bluehorizon.network/macos
[open-horizon]: http://github.com/open-horizon/
[repository]: https://github.com/dcmartin/open-horizon
[setup]: ../setup/README.md
