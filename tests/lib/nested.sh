#!/bin/bash

WORK_DIR="${WORK_DIR:-/tmp/work-dir}"
SSH_PORT=${SSH_PORT:-8022}
MON_PORT=${MON_PORT:-8888}
IMAGE_FILE="${WORK_DIR}/ubuntu-core-20.img"

execute_remote(){
    sshpass -p ubuntu ssh -p "$SSH_PORT" -o ConnectTimeout=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@localhost "$*"
}

wait_for_service() {
    local service_name="$1"
    local state="${2:-active}"
    for i in $(seq 300); do
        if systemctl show -p ActiveState "$service_name" | grep -q "ActiveState=$state"; then
            return
        fi
        # show debug output every 1min
        if [ "$i" -gt 0 ] && [ $(( i % 60 )) = 0 ]; then
            systemctl status "$service_name" || true;
        fi
        sleep 1;
    done

    echo "service $service_name did not start"
    exit 1
}

wait_for_ssh(){
    local service_name="$1"
    retry=800
    wait=1
    while ! execute_remote true; do
        if ! systemctl show -p ActiveState "$service_name" | grep -q "ActiveState=active"; then
            echo "Service no longer active"
            return 1
        fi

        retry=$(( retry - 1 ))
        if [ $retry -le 0 ]; then
            echo "Timed out waiting for ssh. Aborting!"
            return 1
        fi
        sleep "$wait"
    done
}

cleanup_nested_core_vm(){
    # stop the VM if it is running
    systemctl stop nested-vm-*

    # delete the image file
    rm -rf "${IMAGE_FILE}"
}

print_nested_status(){
    SVC_NAME="nested-vm-$(systemd-escape "${SPREAD_JOB:-unknown}")"
    systemctl status "${SVC_NAME}" || true
    journalctl -u "${SVC_NAME}" || true
}

start_nested_core_vm_unit(){
    # copy the image file to create a new one to use
    # TODO: maybe create a snapshot qcow image instead?
    mkdir -p "${WORK_DIR}"
    cp /home/core20/pc.img "${IMAGE_FILE}"

    # use only 2G of RAM for qemu-nested
    if [ "${SPREAD_BACKEND}" = "google-nested" ]; then
        PARAM_MEM="-m 4096"
        PARAM_SMP="-smp 2"
    elif [ "${SPREAD_BACKEND}" = "lxd-nested" ]; then
        PARAM_MEM="-m 4096"
        PARAM_SMP="-smp 2"
    elif [ "${SPREAD_BACKEND}" = "qemu-nested" ]; then
        PARAM_MEM="-m 2048"
        PARAM_SMP="-smp 1"
    else
        echo "unknown spread backend ${SPREAD_BACKEND}"
        exit 1
    fi

    PARAM_DISPLAY="-nographic"
    PARAM_NETWORK="-net nic,model=virtio -net user,hostfwd=tcp::${SSH_PORT}-:22"
    PARAM_MONITOR="-monitor tcp:127.0.0.1:${MON_PORT},server,nowait"
    PARAM_RANDOM="-object rng-random,id=rng0,filename=/dev/urandom -device virtio-rng-pci,rng=rng0"
    PARAM_CPU=""
    PARAM_TRACE="-d cpu_reset"
    PARAM_LOG="-D ${WORK_DIR}/qemu.log"
    PARAM_SERIAL="-serial file:${WORK_DIR}/serial.log"
    PARAM_TPM=""

    ATTR_KVM=""
    if [ "$ENABLE_KVM" = "true" ]; then
        ATTR_KVM=",accel=kvm"
        # CPU can be defined just when kvm is enabled
        PARAM_CPU="-cpu host"
        # Increase the number of cpus used once the issue related to kvm and ovmf is fixed
        # https://bugs.launchpad.net/ubuntu/+source/kvm/+bug/1872803
        PARAM_SMP="-smp 1"
    fi

    # with qemu-nested, we can't use kvm acceleration
    if [ "${SPREAD_BACKEND}" = "google-nested" ]; then
        PARAM_MACHINE="-machine ubuntu${ATTR_KVM}"
    elif [ "${SPREAD_BACKEND}" = "lxd-nested" ]; then
        PARAM_MACHINE="-machine ubuntu${ATTR_KVM}"
    elif [ "${SPREAD_BACKEND}" = "qemu-nested" ]; then
        PARAM_MACHINE=""
    else
        echo "unknown spread backend ${SPREAD_BACKEND}"
        exit 1
    fi

    mkdir -p "${WORK_DIR}/image/"
    PARAM_BIOS="-bios /usr/share/OVMF/OVMF_CODE.fd"
    PARAM_MACHINE="-machine q35${ATTR_KVM} -global ICH9-LPC.disable_s3=1"
    PARAM_IMAGE="-drive file=${IMAGE_FILE},cache=none,format=raw,id=disk1,if=none -device virtio-blk-pci,drive=disk1,bootindex=1"

    # Create the systemd unit for running the VM, the qemu parameter order is 
    # important. We run all of the qemu logic through a script that systemd runs
    # for an easier time escaping everything
    SVC_NAME="nested-vm-$(systemd-escape "${SPREAD_JOB:-unknown}")"
    SVC_SCRIPT="/tmp/nested-vm-$RANDOM.sh"
    cat << EOF > "${SVC_SCRIPT}"
#!/bin/sh -e
qemu-system-x86_64 \
    ${PARAM_SMP} \
    ${PARAM_CPU} \
    ${PARAM_MEM} \
    ${PARAM_TRACE} \
    ${PARAM_LOG} \
    ${PARAM_MACHINE} \
    ${PARAM_DISPLAY} \
    ${PARAM_NETWORK} \
    ${PARAM_BIOS} \
    ${PARAM_RANDOM} \
    ${PARAM_IMAGE} \
    ${PARAM_SERIAL} \
    ${PARAM_MONITOR}
EOF
    
    chmod +x "${SVC_SCRIPT}"

    printf '[Unit]\nDescription=QEMU Nested VM for UC20 spread job %s\n[Service]\nType=simple\nExecStart=%s\n' \
        "${SPREAD_JOB:-unknown}" \
        "${SVC_SCRIPT}" \
            > "/run/systemd/system/${SVC_NAME}.service"
    
    systemctl daemon-reload
    systemctl start "${SVC_NAME}"

    # wait for the nested-vm service to appear active
    if ! wait_for_service "${SVC_NAME}"; then
        return 1
    fi

    # Wait until ssh is ready
    if ! wait_for_ssh "${SVC_NAME}"; then
        return 1
    fi
}
