#!/bin/bash

MOUNT_DIR

function setup_data_images() {
    echo "==> Building data images"
    mkdir -p /data_images
    declare -a images=("home" "var")
    for image in "${images[@]}"; do
        truncate -s 512MB "/data_images/$image.img"
        mkfs.ext4 -F "/data_images/$image.img"
    done
    echo "==> Create sparse disk data images"
}

function mount_data_part() {
	mount /dev/disk/by-label/presistent_part /dev
}


function main() {
	mount_data_part
	setup_data_images
}

main

