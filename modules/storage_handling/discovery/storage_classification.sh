#!/usr/bin/env bash

# ==============================================================================
# Storage Classification
# ==============================================================================
# modules/storage_handling/discovery/storage_classification.sh
#
# Classifies discovered storage devices.
#
# Provides:
#   - storage_classify_disks()
#
# Requires:
#   - AG_STORAGE_DISKS
#   - lsblk
#
# Populates:
#   - AG_STORAGE_USB_DISKS
#   - AG_STORAGE_INTERNAL_DISKS
#   - AG_STORAGE_OTHER_DISKS
#
# Constraints:
#   - Definitions only; no source-time side effects.
#   - Does not discover devices.
#   - Does not select or modify devices.
# ==============================================================================

# ==============================================================================
# Classify Storage Devices
# ==============================================================================

storage_classify_disks() {

    local device
    local transport

    declare -g -a AG_STORAGE_USB_DISKS=()
    declare -g -a AG_STORAGE_INTERNAL_DISKS=()
    declare -g -a AG_STORAGE_OTHER_DISKS=()

    for device in "${AG_STORAGE_DISKS[@]}"; do

        # ----------------------------------------------------------------------
        # Read device transport
        # ----------------------------------------------------------------------

        if ! transport=$(lsblk -dnro TRAN "$device" 2>/dev/null); then
            warn "Unable to classify storage device: $device"
            AG_STORAGE_OTHER_DISKS+=("$device")
            continue
        fi

        # ----------------------------------------------------------------------
        # Classify device
        # ----------------------------------------------------------------------

        case "$transport" in

            usb)
                AG_STORAGE_USB_DISKS+=("$device")
                ;;

            nvme|sata|ata|sas)
                AG_STORAGE_INTERNAL_DISKS+=("$device")
                ;;

            *)
                AG_STORAGE_OTHER_DISKS+=("$device")
                ;;

        esac

    done

    msg "Storage classification completed"
}
