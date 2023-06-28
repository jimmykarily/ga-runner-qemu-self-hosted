#!/bin/bash

set -e

export CLOUD_IMAGE="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-disk-kvm.img"
export IMAGE_SIZE="${IMAGE_SIZE:-50000000000}" # Size in bytes (~50Gb)

declare -a envVars=("TOKEN" "REPO_URL" "RUNNER_NAME" )

checkDeps () {
    for var in ${envVars[@]}; do
        if [ -z "${!var}" ]; then
            echo "${var} environment variable not set"
            exit
        fi
    done

    declare -a Commands=("virt-customize" "virt-resize" "virt-rescue" "qemu-img" "wget" )
    for cmd in ${Commands[@]}; do
        if ! command -v $cmd &> /dev/null
        then
            echo "'$cmd' command could not be found"
            exit
        fi
    done
}

# https://cloud-images.ubuntu.com/jammy/current/
fetchCloudImage () {
    if [ ! -e cloudImage.img ]; then
        echo "cloudImage.img not found, downloading ${CLOUD_IMAGE}"
        wget -O cloudImage.img "${CLOUD_IMAGE}"
    else
        echo "cloudImage.img already exists, download skipped"
    fi
}

# https://askubuntu.com/questions/451673/default-username-password-for-ubuntu-cloud-image
createRootPassword () {
  echo "Creating root password"
  virt-customize -a cloudImage.img --root-password password:root
}

growDisk() {
    qemu-img resize cloudImage.img ${IMAGE_SIZE}
}

# https://gist.github.com/joseluisq/2fcf26ff1b9c59fe998b4fbfcc388342
# growDisk() {
#     actualsize=$(wc -c <"cloudImage.img")
#     if [ $actualsize -lt $IMAGE_SIZE ]; then
#         qemu-img create -f qcow2 -o preallocation=metadata tmpDisk.img "${IMAGE_SIZE}"
#         virt-resize --expand /dev/vda1 cloudImage.img tmpDisk.img
#         mv tmpDisk.img cloudImage.img
#     else
#         echo "Image is already at the right size, no need to grow"
#     fi
# }

# https://serverfault.com/a/976794
# fixBoot () {
#     echo "Fixing boot (https://serverfault.com/a/976794)"
#     virt-rescue cloudImage.img <<<"
#     sudo mount /dev/sda1 /mnt
#     sudo mount --bind /dev /mnt/dev
#     sudo mount --bind /proc /mnt/proc
#     sudo mount --bind /sys /mnt/sys
#     sudo chroot /mnt
#     grub-install /dev/sda
#     "
# }

copyFiles () {
    cat run.sh.tmpl | envsubst "$(printf '$%q,' "${envVars[@]}")" > run.sh
    chmod +x run.sh
    virt-copy-in -a cloudImage.img run.sh /
    rm run.sh
}

startVM () {
    qemu-system-x86_64 \
        -nographic \
        -spice port=9000,addr=127.0.0.1,disable-ticketing=yes \
        -cpu "${CPU:=host}" \
        -m ${MEMORY:=10096} \
        -smp ${CORES:=5} \
        -enable-kvm \
        -monitor unix:/tmp/qemu-monitor.sock,server=on,wait=off \
        -nic bridge,br=br0,model=virtio-net-pci \
        -serial mon:stdio \
        -rtc base=utc,clock=rt \
        -chardev socket,path=qga.sock,server=on,wait=off,id=qga0 \
        -device virtio-serial \
        -device virtserialport,chardev=qga0,name=org.qemu.guest_agent.0 \
        -drive if=virtio,media=disk,file=cloudImage.img
}

checkDeps
fetchCloudImage
createRootPassword
growDisk
copyFiles
startVM

# Need to run growpart /dev/vda 1
#
#fixBoot
