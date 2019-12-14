#!/bin/bash

if [ "${VENDOR}" != "apple" ] && [ "${OSTYPE}" != "darwin" ]; then
  echo "This script is for macOS only" >&2
  exit 1
fi

## HORIZON CONFIG
if [ "${0%/*}" != "${0}" ]; then
  CONFIG="${0%/*}/horizon.json"
else
  CONFIG="horizon.json"
fi
if [ -z "${1}" ]; then
  if [ -s "${CONFIG}" ]; then
    echo "+++ WARN $0 $$ -- no configuration specified; default found: ${CONFIG}"
  else
    echo "*** ERROR $0 $$ -- no configuration specified; no default: ${CONFIG}; run mkconfig.sh"
    exit 1
  fi
else
  if [ ! -s "${1}" ]; then
    echo "*** ERROR configuration file empty: ${1}"
    exit 1
  fi
  CONFIG="${1}"
fi

if [ -z $(command -v "VBoxManage") ]; then
  echo "*** ERROR $0 $$ -- Virtual Box is not installed"
  exit 1
fi

dev_node=$(df | egrep "/Volumes/boot" | awk '{ print $1 }' | sed 's|disk\([0-9]\)*s.*|disk\1|')
if [ -n "${2}" ]; then
  dev_node="${2}"
fi
# check if the first parameter points to a filename that looks like a
if [ -z "${dev_node}" ]; then
  echo "*** ERROR $0 $$ -- Unspecified device; retry: $0 ${CONFIG} /dev/disk#"
  exit 1
elif [ ! -e "${dev_node}" ]; then
  echo "*** ERROR $0 $$ -- Device $dev_node does not exist"
  exit 1
elif  [[ $dev_node != /dev/disk? ]] ; then
  echo "*** ERROR $0 $$ -- Device $dev_node does not start with /dev/disk, but it should."
  exit 1
fi

vm="horizon"
if [ -n "${2}" ]; then
  vm="${2}"
fi
if [ "$(VBoxManage showvminfo ${vm}| egrep '^Name' | awk '{ print $2 }')" != "${vm}" ]; then
  echo "*** ERROR $0 $$ -- cannot find VirtualBox VM with name: ${vm}"
  exit 1
fi

echo "Setting permissions to disk ..."
sudo chmod 666 $dev_node
if [ $? != 0 ]; then 
  echo "*** ERROR $0 $$ -- Could not set device node permissions. Cannot proceed!"
  exit 1
fi

echo "Unmounting SD card from system ..."
sudo diskutil unmountDisk $dev_node
if [ $? != 0 ]; then
  echo "*** ERROR $0 $$ -- Could not unmount disk $dev_node. Cannot proceed!"
  exit 1
fi

vmdk_file=/tmp/$$.vmdk
if [ -e $vmdk_file ]; then
  echo "WARN: VMDK file should not yet exist!"
  rm -f "${vmdk_file}"
fi

echo "Creating VMDK file that maps to disk $dev_node"
sudo VBoxManage internalcommands createrawvmdk -filename $vmdk_file -rawdisk $dev_node
if [ $? != 0 ]; then
  echo "*** ERROR $0 $$ -- Could not create VMDK file $vmdk_file. Cannot proceed!"
  exit 1
fi

echo "Setting permissions to file node ..."
sudo chmod 666 $vmdk_file
if [ $? != 0 ]; then 
  echo "*** ERROR $0 $$ -- Could not set vdmk file permissions. Cannot proceed!"
  exit 1
fi

echo "Extracting first SATA port ..."
port=`VBoxManage showvminfo "$vm"  | grep '^SATA' | tail -1 | awk '{print $2}' | sed -e 's/(//;s/,//'`
if [ $? != 0 ]; then
  echo "*** ERROR $0 $$ -- Could not find SATA port. You need to manually attach $vmdk_file to the VM."
  exit 1
fi

# take next port
let "port+=1"

echo "Unmounting SD card from system (again)..."
sudo diskutil unmountDisk $dev_node
if [ $? != 0 ]; then
  echo "*** ERROR $0 $$ -- Could not unmount disk $dev_node. Cannot proceed!"
  exit 1
fi

echo "Attaching VMDK file to virtual machine ..."
VBoxManage storageattach "$vm" --medium $vmdk_file --storagectl SATA --port $port --type hdd #--hotpluggable on
if [ $? != 0 ]; then
  echo "*** ERROR $0 $$ -- Could not attach VMDK file to VM. You need to do this manually."
  exit 1
fi

echo "Done!  You can now start the virtual machine"
