#/usr/bin/bash

set -eEuo pipefail

if [ "$(id -u)" != 0 ]; then
    echo "This script must be run as root!"
    exit 1
fi

DATA_STORE="/data_images"

function setup_data_images() {
    echo "==> Building data images"
    declare -a images=("home" "var")
    if [ -d "$DATA_STORE" ]; then
	for image in "${images[@]}"; do
	    if [ -e "$image.img"]; then
		echo "Sparse disk file for $image already exists in $DATA_STORE"
	    else
		echo "==> Creating sparse disks file for $image"
		dd if=/dev/zero of=$DATA_STORE/$image.img bs=1 count=0 seek=512M
		mkfs.ext4 -F "$DATA_STORE/$image.img"
	    fi
	done
    else
    	echo "$DATA_STORE is not present, please check the boot chain or for failed mount units in systemd"
    fi
}

function main() {
	setup_data_images
}

main

